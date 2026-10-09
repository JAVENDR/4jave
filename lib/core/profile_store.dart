import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yaml/yaml.dart';

class Profile {
  Profile({required this.id, required this.name, required this.url, required this.path, this.updated});
  final String id;
  String name;
  final String url;
  final String path;
  DateTime? updated;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'url': url,
        'path': path,
        'updated': updated?.toIso8601String(),
      };

  factory Profile.fromJson(Map<String, dynamic> j) => Profile(
        id: j['id'] as String,
        name: j['name'] as String,
        url: j['url'] as String,
        path: j['path'] as String,
        updated: j['updated'] == null ? null : DateTime.tryParse(j['updated'] as String),
      );
}

class ProfileStore extends ChangeNotifier {
  final List<Profile> profiles = [];
  String? currentId;
  late SharedPreferences _prefs;

  Profile? get current {
    for (final p in profiles) {
      if (p.id == currentId) return p;
    }
    return null;
  }

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final raw = _prefs.getString('profiles');
    if (raw != null) {
      final list = jsonDecode(raw) as List;
      profiles
        ..clear()
        ..addAll(list.map((e) => Profile.fromJson(Map<String, dynamic>.from(e as Map))));
    }
    currentId = _prefs.getString('currentId');
    if (current == null && profiles.isNotEmpty) currentId = profiles.first.id;
    notifyListeners();
  }

  Future<void> _save() async {
    await _prefs.setString('profiles', jsonEncode(profiles.map((e) => e.toJson()).toList()));
    if (currentId != null) {
      await _prefs.setString('currentId', currentId!);
    } else {
      await _prefs.remove('currentId');
    }
  }

  Future<String> _download(String url) async {
    final res = await http
        .get(Uri.parse(url), headers: {'User-Agent': 'clash.meta/4jave'})
        .timeout(const Duration(seconds: 20));
    if (res.statusCode != 200) {
      throw 'Сервер подписки ответил кодом ${res.statusCode}';
    }
    final body = utf8.decode(res.bodyBytes, allowMalformed: true);
    final dynamic doc;
    try {
      doc = loadYaml(body);
    } catch (_) {
      throw 'Ответ подписки не удалось разобрать как YAML. Нужна ссылка для Clash/Mihomo.';
    }
    if (doc is! YamlMap || doc['proxies'] == null) {
      throw 'В подписке нет списка proxies. Запросите у провайдера ссылку формата Clash/Mihomo.';
    }
    return body;
  }

  Future<File> _fileFor(String id) async {
    final base = await getApplicationSupportDirectory();
    final dir = Directory('${base.path}${Platform.pathSeparator}profiles');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return File('${dir.path}${Platform.pathSeparator}$id.yaml');
  }

  Future<void> add(String url, {String? name}) async {
    final uri = Uri.tryParse(url.trim());
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) throw 'Некорректная ссылка';
    final body = await _download(url.trim());
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final f = await _fileFor(id);
    await f.writeAsString(body);
    profiles.add(Profile(
      id: id,
      name: (name == null || name.trim().isEmpty) ? uri.host : name.trim(),
      url: url.trim(),
      path: f.path,
      updated: DateTime.now(),
    ));
    currentId ??= id;
    await _save();
    notifyListeners();
  }

  Future<void> refresh(Profile p) async {
    final body = await _download(p.url);
    await File(p.path).writeAsString(body);
    p.updated = DateTime.now();
    await _save();
    notifyListeners();
  }

  Future<void> select(Profile p) async {
    currentId = p.id;
    await _save();
    notifyListeners();
  }

  Future<void> remove(Profile p) async {
    profiles.remove(p);
    final f = File(p.path);
    if (f.existsSync()) f.deleteSync();
    if (currentId == p.id) currentId = profiles.isEmpty ? null : profiles.first.id;
    await _save();
    notifyListeners();
  }
}
