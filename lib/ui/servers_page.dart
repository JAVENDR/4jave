import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/core_service.dart';
import '../theme.dart';

class ServersPage extends StatelessWidget {
  const ServersPage({super.key});

  Color _delayColor(int? d) {
    if (d == null) return J.muted;
    if (d == 0) return J.coral;
    if (d < 250) return J.wave;
    if (d < 600) return J.amber;
    return J.coral;
  }

  @override
  Widget build(BuildContext context) {
    final core = context.watch<CoreService>();
    final on = core.status == VpnStatus.on;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Expanded(child: Text('Серверы', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700))),
          IconButton(
            tooltip: 'Проверить пинг',
            onPressed: on ? core.testAll : null,
            icon: const Icon(Icons.speed_rounded),
          ),
        ]),
        const SizedBox(height: 12),
        Expanded(
          child: !on || core.nodes.isEmpty
              ? Center(
                  child: Text(
                    on ? 'В подписке нет серверов' : 'Подключитесь, чтобы увидеть список серверов',
                    style: const TextStyle(color: J.muted),
                  ),
                )
              : ListView.separated(
                  itemCount: core.nodes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final n = core.nodes[i];
                    final sel = n.name == core.selected;
                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: sel ? J.wave : Colors.transparent, width: 1.5),
                      ),
                      child: ListTile(
                        onTap: () => core.select(n),
                        title: Text(n.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text(n.type, style: const TextStyle(color: J.muted)),
                        trailing: InkWell(
                          onTap: () => core.testDelay(n),
                          child: Text(
                            n.delay == null ? '—' : (n.delay == 0 ? 'Таймаут' : '${n.delay} мс'),
                            style: TextStyle(color: _delayColor(n.delay), fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ]),
    );
  }
}
