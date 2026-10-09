import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

enum VpnStatus { off, connecting, on }

class ProxyNode {
  ProxyNode(this.name, this.type, {this.delay});
  final String name;
  final String type;
  int? delay; // мс; 0 = недоступен; null = не измерялся
}

/// Запускает ядро Mihomo (Clash Meta) отдельным процессом
/// и управляет им через локальный REST API.
class CoreService extends ChangeNotifier {
  static const apiPort = 9097;
  static const mixedPort = 7890;
  static const _secret = 'fourjave-local';
  static const _testUrl = 'https://www.gstatic.com/generate_204';
  static const _tunCfg = {
    'enable': true,
    'stack': 'mixed',
    'auto-route': true,
    'auto-detect-interface': true,
    'dns-hijack': ['any:53'],
  };

  VpnStatus status = VpnStatus.off;
  String? error;
  List<ProxyNode> nodes = [];
  String? group;
  String? selected;
  String mode = 'rule';
  bool tun = false;
  bool systemProxy = true;
  int up = 0;
  int down = 0;

  Process? _proc;
  WebSocketChannel? _ws;
  StreamSubscription? _wsSub;

  static bool get supported => Platform.isWindows;

  Map<String, String> get _h => {
        'Authorization': 'Bearer $_secret',
        'Content-Type': 'application/json',
      };

  Uri _u(String p, [Map<String, String>? q]) => Uri.http('127.0.0.1:$apiPort', p, q);

  String get _corePath {
    final sep = Platform.pathSeparator;
    final dir = File(Platform.resolvedExecutable).parent.path;
    return '$dir${sep}core${sep}mihomo.exe';
  }

  Future<void> connect(String profilePath) async {
    if (status != VpnStatus.off) return;
    error = null;
    if (!supported) {
      error = 'На Android ядро ещё не подключено (нужен VpnService). Сейчас работает версия для Windows.';
      notifyListeners();
      return;
    }
    status = VpnStatus.connecting;
    notifyListeners();
    try {
      final exe = File(_corePath);
      if (!exe.existsSync()) {
        throw 'Не найдено ядро ${exe.path}. Положите mihomo.exe в папку core рядом с 4jave.exe.';
      }
      final base = await getApplicationSupportDirectory();
      final home = Directory('${base.path}${Platform.pathSeparator}core');
      if (!home.existsSync()) home.createSync(recursive: true);
      final cfg = '${home.path}${Platform.pathSeparator}config.yaml';
      await File(profilePath).copy(cfg);

      final proc = await Process.start(exe.path, [
        '-d', home.path,
        '-f', cfg,
        '-ext-ctl', '127.0.0.1:$apiPort',
        '-secret', _secret,
      ]);
      _proc = proc;
      proc.stdout.drain<void>();
      proc.stderr.drain<void>();
      unawaited(proc.exitCode.then((_) {
        if (identical(_proc, proc) && status != VpnStatus.off) {
          error ??= 'Ядро неожиданно остановилось. Проверьте подписку.';
          _cleanup();
        }
      }));

      await _waitApi();
      await _patch({'mixed-port': mixedPort, 'mode': mode, 'allow-lan': false});
      if (tun) await _patch({'tun': _tunCfg});
      await loadProxies();
      if (systemProxy) await _setSystemProxy(true);
      _listenTraffic();
      status = VpnStatus.on;
    } catch (e) {
      error = e.toString();
      await _cleanup();
    }
    notifyListeners();
  }

  Future<void> disconnect() => _cleanup();

  Future<void> _cleanup() async {
    status = VpnStatus.off;
    up = 0;
    down = 0;
    await _wsSub?.cancel();
    _wsSub = null;
    await _ws?.sink.close();
    _ws = null;
    final p = _proc;
    _proc = null;
    p?.kill();
    if (supported) await _setSystemProxy(false);
    notifyListeners();
  }

  Future<void> _waitApi() async {
    for (var i = 0; i < 40; i++) {
      try {
        final r = await http.get(_u('/version'), headers: _h).timeout(const Duration(seconds: 1));
        if (r.statusCode == 200) return;
      } catch (_) {}
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
    throw 'Ядро не ответило за 10 секунд. Возможно, порт $apiPort занят или конфиг неверный.';
  }

  Future<void> _patch(Map<String, dynamic> body) async {
    final r = await http.patch(_u('/configs'), headers: _h, body: jsonEncode(body));
    if (r.statusCode >= 300) throw 'Ядро отклонило настройки: ${r.body}';
  }

  Future<void> loadProxies() async {
    final r = await http.get(_u('/proxies'), headers: _h);
    final all = (jsonDecode(r.body)['proxies'] as Map).cast<String, dynamic>();
    String? g;
    for (final e in all.entries) {
      final v = e.value as Map;
      if (e.key != 'GLOBAL' && v['type'] == 'Selector' && v['all'] is List) {
        g = e.key;
        break;
      }
    }
    g ??= all.containsKey('GLOBAL') ? 'GLOBAL' : null;
    group = g;
    if (g == null) {
      nodes = [];
      notifyListeners();
      return;
    }
    final grp = all[g] as Map;
    selected = grp['now'] as String?;
    nodes = (grp['all'] as List).map((n) {
      final p = all[n] as Map?;
      final hist = p?['history'];
      int? d;
      if (hist is List && hist.isNotEmpty) d = ((hist.last as Map)['delay'] as num?)?.toInt();
      return ProxyNode(n as String, (p?['type'] ?? '') as String, delay: d);
    }).toList();
    notifyListeners();
  }

  Future<void> select(ProxyNode n) async {
    if (group == null) return;
    await http.put(_u('/proxies/${Uri.encodeComponent(group!)}'),
        headers: _h, body: jsonEncode({'name': n.name}));
    selected = n.name;
    notifyListeners();
  }

  Future<void> testDelay(ProxyNode n) async {
    try {
      final r = await http
          .get(_u('/proxies/${Uri.encodeComponent(n.name)}/delay', {'url': _testUrl, 'timeout': '5000'}), headers: _h)
          .timeout(const Duration(seconds: 7));
      n.delay = r.statusCode == 200 ? (jsonDecode(r.body)['delay'] as num).toInt() : 0;
    } catch (_) {
      n.delay = 0;
    }
    notifyListeners();
  }

  Future<void> testAll() async {
    for (var i = 0; i < nodes.length; i += 8) {
      await Future.wait(nodes.skip(i).take(8).map(testDelay));
    }
  }

  Future<void> setMode(String m) async {
    mode = m;
    if (status == VpnStatus.on) {
      await _patch({'mode': m});
      await loadProxies();
    }
    notifyListeners();
  }

  Future<void> setTun(bool v) async {
    final prev = tun;
    tun = v;
    if (status == VpnStatus.on) {
      try {
        await _patch({'tun': {..._tunCfg, 'enable': v}});
      } catch (e) {
        tun = prev;
        error = 'Не удалось переключить TUN (нужен запуск от администратора): $e';
      }
    }
    notifyListeners();
  }

  Future<void> setSystemProxy(bool v) async {
    systemProxy = v;
    if (status == VpnStatus.on) await _setSystemProxy(v);
    notifyListeners();
  }

  void _listenTraffic() {
    _ws = WebSocketChannel.connect(Uri.parse('ws://127.0.0.1:$apiPort/traffic?token=$_secret'));
    _wsSub = _ws!.stream.listen((m) {
      final j = jsonDecode(m as String) as Map;
      up = (j['up'] as num).toInt();
      down = (j['down'] as num).toInt();
      notifyListeners();
    }, onError: (_) {});
  }

  Future<void> _setSystemProxy(bool on) async {
    if (!Platform.isWindows) return;
    const key = r'HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings';
    await Process.run('reg', ['add', key, '/v', 'ProxyEnable', '/t', 'REG_DWORD', '/d', on ? '1' : '0', '/f']);
    if (on) {
      await Process.run('reg', ['add', key, '/v', 'ProxyServer', '/t', 'REG_SZ', '/d', '127.0.0.1:$mixedPort', '/f']);
    }
  }

  @override
  void dispose() {
    _proc?.kill();
    super.dispose();
  }
}
