import 'package:flutter/material.dart';
import '../db.dart';
import '../models.dart';
import '../util.dart';
import '../widgets.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final st = AppState.I;

  Widget _text(String key, String label, {TextInputType? type}) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: TextField(
          controller: TextEditingController(text: st.s[key] ?? ''),
          keyboardType: type,
          decoration: dec(label),
          onChanged: (v) => st.set(key, v),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final title = Theme.of(context).textTheme.titleSmall;
    return ListView(padding: const EdgeInsets.all(12), children: [
      Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Today’s rate (₹ per gram)', style: title),
            const SizedBox(height: 8),
            for (final m in Metal.values)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: NumField(label: m.label, initial: st.rate(m), onChanged: (v) => st.set('rate_${m.name}', plain(v))),
              ),
          ]),
        ),
      ),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Shop details (printed on invoice)', style: title),
            const SizedBox(height: 8),
            _text('shopName', 'Shop name'),
            _text('gstin', 'GSTIN'),
            _text('address', 'Address'),
            _text('phone', 'Phone', type: TextInputType.phone),
            _text('gstPct', 'GST % on jewellery', type: const TextInputType.numberWithOptions(decimal: true)),
          ]),
        ),
      ),
      const Card(
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Text('Data is stored on this phone only (SQLite). Cloud backup and multi-shop sync are the next milestone.'),
        ),
      ),
    ]);
  }
}
