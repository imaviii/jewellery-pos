import 'package:intl/intl.dart';

final inr = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
final num2 = NumberFormat('#,##0.00', 'en_IN');
final dateFmt = DateFormat('dd MMM yyyy, hh:mm a');

String plain(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();
double parse(String t) => double.tryParse(t.trim()) ?? 0;
