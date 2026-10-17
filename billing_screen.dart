import 'package:flutter/material.dart';
import '../db.dart';
import '../models.dart';
import '../util.dart';
import '../widgets.dart';
import 'invoice_screen.dart';

class BillingScreen extends StatefulWidget {
  const BillingScreen({super.key});
  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  final st = AppState.I;
  late Bill b;
  final cust = TextEditingController();
  final phone = TextEditingController();
  TextEditingController? _search;
  int gen = 0; // bumps after a bill is saved so NumFields reset

  @override
  void initState() {
    super.initState();
    _fresh();
  }

  void _fresh() {
    b = Bill(date: DateTime.now(), gstPct: st.gstPct);
    cust.clear();
    phone.clear();
    gen++;
  }

  String _sub(BillLine l) {
    final mk = l.makingPerGram ? '₹${plain(l.making)}/g' : '${plain(l.making)}%';
    final stone = l.stone > 0 ? ' · Stone ₹${plain(l.stone)}' : '';
    return '${l.metal.label} · ${plain(l.net)} g @ ${num2.format(l.rate)}\nMaking $mk$stone';
  }

  void _snack(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<bool> _confirm(String msg) async =>
      await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(content: Text(msg), actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('No')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Yes')),
        ]),
      ) ??
      false;

  Future<void> _addCustom() async {
    final l = BillLine(name: 'Custom item', metal: Metal.g22, net: 0, rate: st.rate(Metal.g22));
    setState(() => b.lines.add(l));
    await _editLine(l);
  }

  Future<void> _editLine(BillLine l) async {
    final name = TextEditingController(text: l.name);
    final net = TextEditingController(text: plain(l.net));
    final mk = TextEditingController(text: plain(l.making));
    final stone = TextEditingController(text: plain(l.stone));
    final rate = TextEditingController(text: plain(l.rate));
    Metal metal = l.metal;
    bool perGram = l.makingPerGram;
    TextField numField(TextEditingController c, String label) =>
        TextField(controller: c, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: dec(label));
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, set) => AlertDialog(
          title: const Text('Edit line'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: name, decoration: dec('Item name')),
              const SizedBox(height: 8),
              DropdownButtonFormField<Metal>(
                value: metal,
                decoration: dec('Metal'),
                items: metalItems(),
                onChanged: (m) => set(() {
                  metal = m!;
                  rate.text = plain(st.rate(m));
                }),
              ),
              const SizedBox(height: 8),
              numField(net, 'Net weight (g)'),
              const SizedBox(height: 8),
              numField(rate, 'Rate ₹/g'),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(perGram ? 'Making ₹ per gram' : 'Making % of value'),
                value: perGram,
                onChanged: (v) => set(() => perGram = v),
              ),
              numField(mk, 'Making value'),
              const SizedBox(height: 8),
              numField(stone, 'Stone charge ₹'),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('OK')),
          ],
        ),
      ),
    );
    if (ok == true) {
      setState(() {
        l.name = name.text.trim().isEmpty ? l.name : name.text.trim();
        l.metal = metal;
        l.net = parse(net.text);
        l.rate = parse(rate.text);
        l.makingPerGram = perGram;
        l.making = parse(mk.text);
        l.stone = parse(stone.text);
      });
    }
  }

  Future<void> _save() async {
    if (b.lines.isEmpty) return _snack('Add at least one item');
    if (b.lines.any((l) => l.rate <= 0) && !await _confirm('Some lines have rate 0. Continue?')) return;
    b.date = DateTime.now();
    b.gstPct = st.gstPct;
    b.exRate = st.rate(b.exMetal);
    await AppDb.saveBill(b);
    await st.load();
    final saved = b;
    if (!mounted) return;
    setState(_fresh);
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => InvoiceScreen(bill: saved)));
  }

  @override
  Widget build(BuildContext context) {
    b.exRate = st.rate(b.exMetal);
    final bold = Theme.of(context).textTheme.titleSmall;
    return AnimatedBuilder(
      animation: st,
      builder: (context, _) => ListView(
        padding: const EdgeInsets.all(12),
        children: [
          if (Metal.values.every((m) => st.rate(m) == 0)) const Warn('Set today’s metal rates in Setup before billing.'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(children: [
                Expanded(child: TextField(controller: cust, decoration: dec('Customer name'), onChanged: (v) => b.customer = v)),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: phone, keyboardType: TextInputType.phone, decoration: dec('Phone'), onChanged: (v) => b.phone = v)),
              ]),
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(children: [
                Expanded(
                  child: Autocomplete<Item>(
                    displayStringForOption: (i) => i.name,
                    optionsBuilder: (v) {
                      final q = v.text.trim().toLowerCase();
                      if (q.isEmpty) return const Iterable<Item>.empty();
                      return st.items.where((i) => i.name.toLowerCase().contains(q) || i.huid.toLowerCase().contains(q));
                    },
                    fieldViewBuilder: (ctx, ctrl, focus, onSubmit) {
                      _search = ctrl;
                      return TextField(controller: ctrl, focusNode: focus, decoration: dec('Search item name / HUID'));
                    },
                    onSelected: (i) {
                      setState(() => b.lines.add(BillLine.fromItem(i, st.rate(i.metal))));
                      _search?.clear();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.tonal(onPressed: _addCustom, child: const Text('Custom')),
              ]),
            ),
          ),
          for (final l in b.lines)
            Card(
              child: ListTile(
                title: Text(l.name),
                subtitle: Text(_sub(l)),
                isThreeLine: true,
                onTap: () => _editLine(l),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(inr.format(l.amount), style: bold),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() => b.lines.remove(l))),
                ]),
              ),
            ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Old metal exchange', style: bold),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(child: NumField(key: ValueKey('exw$gen'), label: 'Weight (g)', initial: b.exWeight, onChanged: (v) => setState(() => b.exWeight = v))),
                  const SizedBox(width: 8),
                  Expanded(child: NumField(key: ValueKey('exp$gen'), label: 'Purity %', initial: b.exPurity, onChanged: (v) => setState(() => b.exPurity = v))),
                ]),
                const SizedBox(height: 8),
                DropdownButtonFormField<Metal>(
                  value: b.exMetal,
                  decoration: dec('Metal'),
                  items: metalItems(),
                  onChanged: (m) => setState(() => b.exMetal = m!),
                ),
              ]),
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Discount & payment', style: bold),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(child: NumField(key: ValueKey('d$gen'), label: 'Discount ₹', initial: b.discount, onChanged: (v) => setState(() => b.discount = v))),
                  const SizedBox(width: 8),
                  Expanded(child: NumField(key: ValueKey('c$gen'), label: 'Cash ₹', initial: b.cash, onChanged: (v) => setState(() => b.cash = v))),
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(child: NumField(key: ValueKey('u$gen'), label: 'UPI ₹', initial: b.upi, onChanged: (v) => setState(() => b.upi = v))),
                  const SizedBox(width: 8),
                  Expanded(child: NumField(key: ValueKey('k$gen'), label: 'Card ₹', initial: b.card, onChanged: (v) => setState(() => b.card = v))),
                ]),
              ]),
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(children: [
                kv('Subtotal', inr.format(b.subtotal)),
                kv('Discount', '- ${inr.format(b.discount)}'),
                kv('CGST ${plain(st.gstPct / 2)}%', inr.format(b.taxable * st.gstPct / 200)),
                kv('SGST ${plain(st.gstPct / 2)}%', inr.format(b.taxable * st.gstPct / 200)),
                kv('Old metal exchange', '- ${inr.format(b.exchangeValue)}'),
                const Divider(),
                kv('Total', inr.format(b.total), bold: true),
                kv('Paid', inr.format(b.paid)),
                kv(b.balance >= 0 ? 'Balance due' : 'Change / refund', inr.format(b.balance.abs()),
                    bold: true, color: b.balance > 0.5 ? Colors.red : Colors.green),
              ]),
            ),
          ),
          Row(children: [
            Expanded(child: FilledButton.icon(onPressed: _save, icon: const Icon(Icons.receipt), label: const Text('Save & invoice'))),
            const SizedBox(width: 8),
            OutlinedButton(onPressed: () => setState(_fresh), child: const Text('Clear')),
          ]),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
