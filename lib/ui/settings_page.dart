import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/core_service.dart';
import '../theme.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final core = context.watch<CoreService>();
    return ListView(padding: const EdgeInsets.all(20), children: [
      const Text('Настройки', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
      const SizedBox(height: 16),
      const Text('Режим маршрутизации', style: TextStyle(color: J.muted)),
      const SizedBox(height: 8),
      SegmentedButton<String>(
        segments: const [
          ButtonSegment(value: 'rule', label: Text('Правила')),
          ButtonSegment(value: 'global', label: Text('Глобально')),
          ButtonSegment(value: 'direct', label: Text('Напрямую')),
        ],
        selected: {core.mode},
        onSelectionChanged: (s) => core.setMode(s.first),
      ),
      const SizedBox(height: 16),
      Card(
        child: Column(children: [
          SwitchListTile(
            title: const Text('Системный прокси'),
            subtitle: const Text('Направлять трафик Windows через 4jave'),
            value: core.systemProxy,
            onChanged: core.setSystemProxy,
          ),
          SwitchListTile(
            title: const Text('Режим TUN'),
            subtitle: const Text('Перехват всего трафика. Нужен запуск от администратора'),
            value: core.tun,
            onChanged: core.setTun,
          ),
        ]),
      ),
      const SizedBox(height: 16),
      const Card(
        child: ListTile(
          title: Text('4jave 0.1.0'),
          subtitle: Text('Ядро: Mihomo (GPL-3.0)', style: TextStyle(color: J.muted)),
        ),
      ),
    ]);
  }
}
