import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

import 'core/core_service.dart';
import 'core/profile_store.dart';
import 'theme.dart';
import 'ui/shell.dart';

class _CloseHandler with WindowListener {
  _CloseHandler(this.core);
  final CoreService core;

  @override
  Future<void> onWindowClose() async {
    await core.disconnect();
    await windowManager.destroy();
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final core = CoreService();
  final store = ProfileStore();
  await store.load();

  if (Platform.isWindows) {
    await windowManager.ensureInitialized();
    await windowManager.setPreventClose(true);
    windowManager.addListener(_CloseHandler(core));
    await windowManager.waitUntilReadyToShow(
      const WindowOptions(size: Size(1000, 680), minimumSize: Size(420, 640), title: '4jave', center: true),
      () async {
        await windowManager.show();
        await windowManager.focus();
      },
    );
  }

  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: core),
      ChangeNotifierProvider.value(value: store),
    ],
    child: MaterialApp(
      title: '4jave',
      debugShowCheckedModeBanner: false,
      theme: J.theme(),
      home: const Shell(),
    ),
  ));
}
