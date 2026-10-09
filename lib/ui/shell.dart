import 'package:flutter/material.dart';

import '../theme.dart';
import 'home_page.dart';
import 'profiles_page.dart';
import 'servers_page.dart';
import 'settings_page.dart';

class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _i = 0;
  static const _pages = <Widget>[HomePage(), ServersPage(), ProfilesPage(), SettingsPage()];
  static const _items = [
    (Icons.waves_rounded, 'Главная'),
    (Icons.public_rounded, 'Серверы'),
    (Icons.link_rounded, 'Подписки'),
    (Icons.tune_rounded, 'Настройки'),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final wide = c.maxWidth >= 720;
      final body = SafeArea(child: IndexedStack(index: _i, children: _pages));
      if (wide) {
        return Scaffold(
          body: Row(children: [
            NavigationRail(
              selectedIndex: _i,
              onDestinationSelected: (v) => setState(() => _i = v),
              labelType: NavigationRailLabelType.all,
              leading: const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text('4jave', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: J.wave)),
              ),
              destinations: [
                for (final e in _items) NavigationRailDestination(icon: Icon(e.$1), label: Text(e.$2)),
              ],
            ),
            Expanded(child: body),
          ]),
        );
      }
      return Scaffold(
        body: body,
        bottomNavigationBar: NavigationBar(
          selectedIndex: _i,
          onDestinationSelected: (v) => setState(() => _i = v),
          destinations: [
            for (final e in _items) NavigationDestination(icon: Icon(e.$1), label: e.$2),
          ],
        ),
      );
    });
  }
}
