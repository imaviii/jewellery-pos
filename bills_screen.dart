import 'package:flutter/material.dart';
import '../db.dart';
import '../util.dart';
import '../widgets.dart';
import 'invoice_screen.dart';

class BillsScreen extends StatelessWidget {
  const BillsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final st = AppState.I;
    return AnimatedBuilder(
      animation: st,
      builder: (context, _) {
        final now = DateTime.now();
        final today = st.bills.where((b) => !b.voided && DateUtils.isSameDay(b.date, now)).toList();
        double sum(double Function(dynamic) f) => today.fold(0.0, (s, b) => s + f(b));
        return ListView(padding: const EdgeInsets.all(12), children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Today', style: Theme.of(context).textTheme.titleSmall),
                kv('Bills', '${today.length}'),
                kv('Sales', inr.format(sum((b) => b.total)), bold: true),
                kv('Cash', inr.format(sum((b) => b.cash))),
                kv('UPI', inr.format(sum((b) => b.upi))),
                kv('Card', inr.format(sum((b) => b.card))),
              ]),
            ),
          ),
          if (st.bills.isEmpty) const Padding(padding: EdgeInsets.all(24), child: Center(child: Text('No bills yet.'))),
          for (final b in st.bills)
            Card(
              child: ListTile(
                title: Text('${b.no}${b.voided ? '  (cancelled)' : ''}'),
                subtitle: Text('${b.customer.isEmpty ? 'Walk-in' : b.customer}\n${dateFmt.format(b.date)}'),
                isThreeLine: true,
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => InvoiceScreen(bill: b))),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(inr.format(b.total), style: Theme.of(context).textTheme.titleSmall),
                  if (!b.voided)
                    PopupMenuButton<String>(
                      onSelected: (v) async {
                        if (v == 'void') {
                          await AppDb.voidBill(b.no);
                          await st.load();
                        }
                      },
                      itemBuilder: (_) => const [PopupMenuItem(value: 'void', child: Text('Cancel bill'))],
                    ),
                ]),
              ),
            ),
        ]);
      },
    );
  }
}
