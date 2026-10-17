import 'package:flutter/material.dart';
import '../db.dart';
import '../models.dart';
import '../util.dart';
import '../widgets.dart';

class ItemsScreen extends StatelessWidget {
  const ItemsScreen({super.key});

  Future<void> _edit(BuildContext context, Item? it) async {
    final name = TextEditingController(text: it?.name ?? '');
    final huid = TextEditingController(text: it?.huid ?? '');
    final hsn = TextEditingController(text: it?.hsn ?? '7113');
    final gross = TextEditingController(text: it == null ? '' : plain(it.gross));
    final net = TextEditingController(text: it == null ? '' : plain(it.net));
    final stone = TextEditingController(text: it == null ? '' : plain(it.stone));
    final making = TextEditingController(text: it == null ? '' : plain(it.making));
    Metal metal = it?.metal ?? Metal.g22;
    bool perGram = it?.makingPerGram ?? true;
    TextField numField(TextEditingController c, String label) =>
        TextField(controller: c, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: dec(label));
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, set) => AlertDialog(
          title: Text(it == null ? 'New item' : 'Edit item'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: name, decoration: dec('Name')),
              const SizedBox(height: 8),
              DropdownButtonFormField<Metal>(value: metal, decoration: dec('Metal'), items: metalItems(), onChanged: (m) => set(() => metal = m!)),
              const SizedBox(height: 8),
              TextField(controller: huid, decoration: dec('HUID (hallmark)')),
              const SizedBox(height: 8),
              numField(gross, 'Gross weight (g)'),
              const SizedBox(height: 8),
              numField(net, 'Net weight (g)'),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(perGram ? 'Making ₹ per gram' : 'Making % of value'),
                value: perGram,
                onChanged: (v) => set(() => perGram = v),
              ),
              numField(making, 'Making value'),
              const SizedBox(height: 8),
              numField(stone, 'Stone charge ₹'),
              const SizedBox(height: 8),
              TextField(controller: hsn, decoration: dec('HSN code')),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Save')),
          ],
        ),
      ),
    );
    if (ok != true) return;
    if (name.text.trim().isEmpty || parse(net.text) <= 0) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name and net weight are required')));
      }
      return;
    }
    await AppState.I.saveItem(Item(
      id: it?.id,
      name: name.text.trim(),
      metal: metal,
      huid: huid.text.trim(),
      gross: parse(gross.text),
      net: parse(net.text),
      makingPerGram: perGram,
      making: parse(making.text),
      stone: parse(stone.text),
      hsn: hsn.text.trim().isEmpty ? '7113' : hsn.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final st = AppState.I;
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(context, null),
        icon: const Icon(Icons.add),
        label: const Text('Add item'),
      ),
      body: AnimatedBuilder(
        animation: st,
        builder: (context, _) => st.items.isEmpty
            ? const Center(child: Text('No items yet. Tap “Add item”.'))
            : ListView(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
                children: [
                  for (final i in st.items)
                    Card(
                      child: ListTile(
                        title: Text(i.name),
                        subtitle: Text('${i.metal.label} · ${plain(i.net)} g net · making '
                            '${i.makingPerGram ? '₹${plain(i.making)}/g' : '${plain(i.making)}%'}'
                            '${i.huid.isNotEmpty ? '\nHUID ${i.huid}' : ''}'),
                        isThreeLine: i.huid.isNotEmpty,
                        onTap: () => _edit(context, i),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () async {
                            final yes = await showDialog<bool>(
                              context: context,
                              builder: (c) => AlertDialog(content: Text('Delete ${i.name}?'), actions: [
                                TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('No')),
                                TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Delete')),
                              ]),
                            );
                            if (yes == true) await st.deleteItem(i.id!);
                          },
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
