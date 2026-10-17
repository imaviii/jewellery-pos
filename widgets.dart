import 'package:flutter/material.dart';
import 'models.dart';
import 'util.dart';

InputDecoration dec(String label) =>
    InputDecoration(labelText: label, border: const OutlineInputBorder(), isDense: true);

/// Numeric text field that reports a double on every change.
class NumField extends StatefulWidget {
  final String label;
  final double initial;
  final ValueChanged<double> onChanged;
  const NumField({super.key, required this.label, required this.initial, required this.onChanged});
  @override
  State<NumField> createState() => _NumFieldState();
}

class _NumFieldState extends State<NumField> {
  late final TextEditingController c =
      TextEditingController(text: widget.initial == 0 ? '' : plain(widget.initial));
  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TextField(
        controller: c,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: dec(widget.label),
        onChanged: (t) => widget.onChanged(parse(t)),
      );
}

class Warn extends StatelessWidget {
  final String text;
  const Warn(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Card(
        color: Theme.of(context).colorScheme.tertiaryContainer,
        child: Padding(padding: const EdgeInsets.all(12), child: Text(text)),
      );
}

Widget kv(String k, String v, {bool bold = false, Color? color}) {
  final st = TextStyle(fontWeight: bold ? FontWeight.bold : null, fontSize: bold ? 17 : null, color: color);
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(k, style: st), Text(v, style: st)]),
  );
}

List<DropdownMenuItem<Metal>> metalItems() =>
    [for (final m in Metal.values) DropdownMenuItem(value: m, child: Text(m.label))];
