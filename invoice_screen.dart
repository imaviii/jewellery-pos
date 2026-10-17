import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../db.dart';
import '../invoice_pdf.dart';
import '../models.dart';
import '../util.dart';
import '../widgets.dart';

class InvoiceScreen extends StatelessWidget {
  final Bill bill;
  const InvoiceScreen({super.key, required this.bill});

  @override
  Widget build(BuildContext context) {
    final st = AppState.I;
    final b = bill;
    return Scaffold(
      appBar: AppBar(title: Text(b.no)),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            Expanded(
              child: FilledButton.icon(
                icon: const Icon(Icons.print),
                label: const Text('Print'),
                onPressed: () => Printing.layoutPdf(onLayout: (_) => buildInvoicePdf(b, st)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.share),
                label: const Text('Share PDF'),
                onPressed: () async => Printing.sharePdf(bytes: await buildInvoicePdf(b, st), filename: '${b.no}.pdf'),
              ),
            ),
          ]),
        ),
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Center(child: Text(st.shopName, style: Theme.of(context).textTheme.titleLarge)),
        if ((st.s['address'] ?? '').isNotEmpty) Center(child: Text(st.s['address']!)),
        if ((st.s['gstin'] ?? '').isNotEmpty) Center(child: Text('GSTIN: ${st.s['gstin']}')),
        Center(child: Text(b.voided ? 'TAX INVOICE (CANCELLED)' : 'TAX INVOICE', style: const TextStyle(fontWeight: FontWeight.bold))),
        const SizedBox(height: 8),
        kv(b.no, dateFmt.format(b.date)),
        Text('Customer: ${b.customer.isEmpty ? 'Walk-in' : b.customer} ${b.phone}'),
        const Divider(),
        for (final l in b.lines)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l.name),
            subtitle: Text('${l.metal.label} · ${plain(l.net)} g @ ${num2.format(l.rate)} · HSN ${l.hsn}'
                '${l.huid.isNotEmpty ? ' · HUID ${l.huid}' : ''}\nMaking ${inr.format(l.makingAmt)}'
                '${l.stone > 0 ? ' · Stone ${inr.format(l.stone)}' : ''}'),
            isThreeLine: true,
            trailing: Text(inr.format(l.amount)),
          ),
        const Divider(),
        kv('Subtotal', inr.format(b.subtotal)),
        kv('Discount', '- ${inr.format(b.discount)}'),
        kv('CGST ${plain(b.gstPct / 2)}%', inr.format(b.gst / 2)),
        kv('SGST ${plain(b.gstPct / 2)}%', inr.format(b.gst / 2)),
        if (b.exWeight > 0) kv('Old ${b.exMetal.label} ${plain(b.exWeight)} g', '- ${inr.format(b.exchangeValue)}'),
        const Divider(),
        kv('Total', inr.format(b.total), bold: true),
        kv('Paid', inr.format(b.paid)),
        kv('Balance', inr.format(b.balance), bold: true),
      ]),
    );
  }
}
