import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/core_service.dart';
import '../core/profile_store.dart';
import '../theme.dart';

String fmtSpeed(int b) {
  if (b < 1024) return '$b Б/с';
  if (b < 1024 * 1024) return '${(b / 1024).toStringAsFixed(1)} КБ/с';
  return '${(b / 1024 / 1024).toStringAsFixed(1)} МБ/с';
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final core = context.watch<CoreService>();
    final store = context.watch<ProfileStore>();
    final on = core.status == VpnStatus.on;
    final busy = core.status == VpnStatus.connecting;
    final color = on ? J.wave : (busy ? J.amber : J.surface2);
    final title = on ? 'Подключено' : (busy ? 'Подключаемся…' : 'Отключено');

    Future<void> toggle() async {
      if (busy) return;
      if (on) return core.disconnect();
      final p = store.current;
      if (p == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Сначала добавьте подписку на вкладке «Подписки»')),
        );
        return;
      }
      await core.connect(p.path);
    }

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Semantics(
              button: true,
              label: on ? 'Отключиться' : 'Подключиться',
              child: GestureDetector(
                onTap: toggle,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutCubic,
                  width: 190,
                  height: 190,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [color, color.withValues(alpha: 0.55)]),
                    boxShadow: [BoxShadow(color: color.withValues(alpha: on || busy ? 0.45 : 0), blurRadius: 48, spreadRadius: 6)],
                  ),
                  child: busy
                      ? const Center(child: SizedBox(width: 56, height: 56, child: CircularProgressIndicator(strokeWidth: 4, color: J.deep)))
                      : Icon(Icons.power_settings_new_rounded, size: 72, color: on ? J.deep : J.muted),
                ),
              ),
            ),
            const SizedBox(height: 28),
            Text(title, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(
              on ? (core.selected ?? '—') : (store.current?.name ?? 'Подписка не выбрана'),
              style: const TextStyle(color: J.muted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            Row(children: [
              Expanded(child: _Stat(icon: Icons.south_rounded, label: 'Загрузка', value: fmtSpeed(core.down))),
              const SizedBox(width: 12),
              Expanded(child: _Stat(icon: Icons.north_rounded, label: 'Отдача', value: fmtSpeed(core.up))),
            ]),
            if (core.error != null) ...[
              const SizedBox(height: 20),
              Card(
                color: J.coral.withValues(alpha: 0.15),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(children: [
                    const Icon(Icons.error_outline_rounded, color: J.coral),
                    const SizedBox(width: 12),
                    Expanded(child: Text(core.error!)),
                  ]),
                ),
              ),
            ],
          ]),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          Icon(icon, color: J.wave),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: const TextStyle(color: J.muted, fontSize: 12)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
            ]),
          ),
        ]),
      ),
    );
  }
}
