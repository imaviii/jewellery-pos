import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'db.dart';
import 'models.dart';
import 'util.dart';

/// Builds an A5 tax-invoice PDF. Uses "Rs." because the built-in PDF font has no rupee glyph.
Future<Uint8List> buildInvoicePdf(Bill b, AppState st) async {
  final doc = pw.Document();
  String m(double v) => 'Rs. ${num2.format(v)}';
  pw.Widget cell(String t, {bool bold = false, pw.TextAlign align = pw.TextAlign.right}) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 2),
        child: pw.Text(t,
            textAlign: align,
            style: pw.TextStyle(fontSize: 9, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
      );
  pw.Widget right(String t, {bool bold = false}) => pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text(t, style: pw.TextStyle(fontSize: bold ? 12 : 9, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
      );

  doc.addPage(pw.MultiPage(
    pageFormat: PdfPageFormat.a5,
    margin: const pw.EdgeInsets.all(24),
    build: (ctx) => [
      pw.Center(child: pw.Text(st.shopName, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold))),
      if ((st.s['address'] ?? '').isNotEmpty) pw.Center(child: pw.Text(st.s['address']!, style: const pw.TextStyle(fontSize: 9))),
      if ((st.s['phone'] ?? '').isNotEmpty) pw.Center(child: pw.Text('Ph: ${st.s['phone']}', style: const pw.TextStyle(fontSize: 9))),
      if ((st.s['gstin'] ?? '').isNotEmpty) pw.Center(child: pw.Text('GSTIN: ${st.s['gstin']}', style: const pw.TextStyle(fontSize: 9))),
      pw.SizedBox(height: 4),
      pw.Center(child: pw.Text(b.voided ? 'TAX INVOICE (CANCELLED)' : 'TAX INVOICE', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold))),
      pw.SizedBox(height: 6),
      pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
        pw.Text('No: ${b.no}', style: const pw.TextStyle(fontSize: 9)),
        pw.Text(dateFmt.format(b.date), style: const pw.TextStyle(fontSize: 9)),
      ]),
      pw.Text('Customer: ${b.customer.isEmpty ? 'Walk-in' : b.customer} ${b.phone}', style: const pw.TextStyle(fontSize: 9)),
      pw.SizedBox(height: 6),
      pw.Table(
        border: const pw.TableBorder(horizontalInside: pw.BorderSide(width: .3), bottom: pw.BorderSide(width: .6), top: pw.BorderSide(width: .6)),
        columnWidths: {
          0: const pw.FlexColumnWidth(3.2),
          1: const pw.FlexColumnWidth(1),
          2: const pw.FlexColumnWidth(1.4),
          3: const pw.FlexColumnWidth(1.4),
          4: const pw.FlexColumnWidth(1.6),
        },
        children: [
          pw.TableRow(children: [
            cell('Item', bold: true, align: pw.TextAlign.left),
            cell('Wt g', bold: true),
            cell('Rate', bold: true),
            cell('Making', bold: true),
            cell('Amount', bold: true),
          ]),
          for (final l in b.lines)
            pw.TableRow(children: [
              cell('${l.name}\n${l.metal.label}, HSN ${l.hsn}${l.huid.isNotEmpty ? ', HUID ${l.huid}' : ''}'
                  '${l.stone > 0 ? ', stone ${num2.format(l.stone)}' : ''}', align: pw.TextAlign.left),
              cell(plain(l.net)),
              cell(num2.format(l.rate)),
              cell(num2.format(l.makingAmt)),
              cell(num2.format(l.amount)),
            ]),
        ],
      ),
      pw.SizedBox(height: 8),
      right('Subtotal  ${m(b.subtotal)}'),
      right('Discount  - ${m(b.discount)}'),
      right('CGST ${plain(b.gstPct / 2)}%  ${m(b.gst / 2)}'),
      right('SGST ${plain(b.gstPct / 2)}%  ${m(b.gst / 2)}'),
      if (b.exWeight > 0) right('Old ${b.exMetal.label} ${plain(b.exWeight)} g @ ${plain(b.exPurity)}%  - ${m(b.exchangeValue)}'),
      pw.SizedBox(height: 3),
      right('TOTAL  ${m(b.total)}', bold: true),
      right('Paid  ${m(b.paid)}  (cash ${num2.format(b.cash)}, UPI ${num2.format(b.upi)}, card ${num2.format(b.card)})'),
      right('Balance  ${m(b.balance)}', bold: true),
      pw.SizedBox(height: 16),
      pw.Center(child: pw.Text('Thank you! Visit again.', style: const pw.TextStyle(fontSize: 9))),
    ],
  ));
  return doc.save();
}
