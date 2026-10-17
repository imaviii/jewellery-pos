import 'package:flutter_test/flutter_test.dart';
import 'package:jewellery_pos/models.dart';

void main() {
  test('bill maths: making per gram, discount, GST and old-gold exchange', () {
    final b = Bill(date: DateTime(2026, 10, 23), gstPct: 3, discount: 500, exWeight: 5, exPurity: 91.6, exRate: 7000);
    b.lines.add(BillLine(name: 'Chain', metal: Metal.g22, net: 10, rate: 7000, making: 450));
    expect(b.lines.first.value, 70000);
    expect(b.lines.first.makingAmt, 4500);
    expect(b.subtotal, 74500);
    expect(b.taxable, 74000);
    expect(b.gst, closeTo(2220, 0.001));
    expect(b.exchangeValue, closeTo(32060, 0.001));
    expect(b.total, closeTo(44160, 0.001));
  });

  test('making as percentage of value plus stone', () {
    final l = BillLine(name: 'Ring', metal: Metal.g22, net: 4, rate: 7000, makingPerGram: false, making: 12, stone: 1500);
    expect(l.makingAmt, closeTo(3360, 0.001));
    expect(l.amount, closeTo(32860, 0.001));
  });
}
