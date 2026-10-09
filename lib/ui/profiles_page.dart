import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/profile_store.dart';
import '../theme.dart';

class ProfilesPage extends StatefulWidget {
  const ProfilesPage({super.key});
  @override
  State<ProfilesPage> createState() => _ProfilesPageState();
}

class _ProfilesPageState extends State<ProfilesPage> {
  bool _busy = false;

  void _msg(String t) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));

  Future<void> _run(Future<void> Function() job, String ok) async {
    setState(() => _busy = true);
    try {
      await job();
      if (mounted) _msg(ok);
    } catch (e) {
      if (mounted) _msg(e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _add() async {
    final url = TextEditingController();
    final name = TextEditingController();
    final go = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Новая подписка'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: url, autofocus: true, decoration: const InputDecoration(labelText: 'Ссылка на подписку')),
          const SizedBox(height: 8),
          TextField(controller: name, decoration: const InputDecoration(labelText: 'Название (необязательно)')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Отмена')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Добавить')),
        ],
      ),
    );
    if (go != true || !mounted) return;
    final store = context.read<ProfileStore>();
    await _run(() => store.add(url.text, name: name.text), 'Подписка добавлена');
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ProfileStore>();
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Expanded(child: Text('Подписки', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700))),
          FilledButton.icon(onPressed: _busy ? null : _add, icon: const Icon(Icons.add_rounded), label: const Text('Добавить')),
        ]),
        if (_busy) const Padding(padding: EdgeInsets.only(top: 12), child: LinearProgressIndicator()),
        const SizedBox(height: 12),
        Expanded(
          child: store.profiles.isEmpty
              ? const Center(child: Text('Добавьте ссылку на подписку Clash/Mihomo', style: TextStyle(color: J.muted)))
              : ListView.separated(
                  itemCount: store.profiles.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final p = store.profiles[i];
                    final sel = p.id == store.currentId;
                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: sel ? J.wave : Colors.transparent, width: 1.5),
                      ),
                      child: ListTile(
                        onTap: () => store.select(p),
                        title: Text(p.name),
                        subtitle: Text(
                          p.updated == null ? p.url : 'Обновлено ${p.updated!.toLocal().toString().substring(0, 16)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: J.muted),
                        ),
                        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                          IconButton(
                            tooltip: 'Обновить',
                            icon: const Icon(Icons.refresh_rounded),
                            onPressed: _busy ? null : () => _run(() => store.refresh(p), 'Подписка обновлена'),
                          ),
                          IconButton(
                            tooltip: 'Удалить',
                            icon: const Icon(Icons.delete_outline_rounded),
                            onPressed: () => store.remove(p),
                          ),
                        ]),
                      ),
                    );
                  },
                ),
        ),
      ]),
    );
  }
}
