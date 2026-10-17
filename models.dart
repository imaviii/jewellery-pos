import 'dart:math' as math;

enum Metal { g24, g22, g18, ag }

extension MetalX on Metal {
  String get label => switch (this) {
        Metal.g24 => 'Gold 24K',
        Metal.g22 => 'Gold 22K',
        Metal.g18 => 'Gold 18K',
        Metal.ag => 'Silver',
      };
  double get purity => switch (this) {
        Metal.g24 => 99.9,
        Metal.g22 => 91.6,
        Metal.g18 => 75.0,
        Metal.ag => 92.5,
      };
}

/// Stock item (master data).
class Item {
  int? id;
  String name;
  Metal metal;
  double gross, net, stone, making;
  bool makingPerGram;
  String huid, hsn;

  Item({
    this.id,
    required this.name,
    this.metal = Metal.g22,
    this.gross = 0,
    required this.net,
    this.stone = 0,
    this.makingPerGram = true,
    this.making = 0,
    this.huid = '',
    this.hsn = '7113',
  });

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'metal': metal.name,
        'gross': gross,
        'net': net,
        'stone': stone,
        'mpg': makingPerGram ? 1 : 0,
        'making': making,
        'huid': huid,
        'hsn': hsn,
      };

  factory Item.fromMap(Map<String, Object?> m) => Item(
        id: m['id'] as int?,
        name: m['name'] as String,
        metal: Metal.values.byName(m['metal'] as String),
        gross: (m['gross'] as num).toDouble(),
        net: (m['net'] as num).toDouble(),
        stone: (m['stone'] as num).toDouble(),
        makingPerGram: m['mpg'] == 1,
        making: (m['making'] as num).toDouble(),
        huid: m['huid'] as String,
        hsn: m['hsn'] as String,
      );
}

/// One line on a bill. The rate is frozen when the line is added.
class BillLine {
  String name, huid, hsn;
  Metal metal;
  double net, making, stone, rate;
  bool makingPerGram;

  BillLine({
    required this.name,
    required this.metal,
    required this.net,
    required this.rate,
    this.makingPerGram = true,
    this.making = 0,
    this.stone = 0,
    this.huid = '',
    this.hsn = '7113',
  });

  factory BillLine.fromItem(Item i, double rate) => BillLine(
        name: i.name,
        metal: i.metal,
        net: i.net,
        rate: rate,
        makingPerGram: i.makingPerGram,
        making: i.making,
        stone: i.stone,
        huid: i.huid,
        hsn: i.hsn,
      );

  double get value => net * rate;
  double get makingAmt => makingPerGram ? net * making : value * making / 100;
  double get amount => value + makingAmt + stone;

  Map<String, dynamic> toJson() => {
        'name': name, 'huid': huid, 'hsn': hsn, 'metal': metal.name,
        'net': net, 'making': making, 'stone': stone, 'rate': rate,
        'mpg': makingPerGram,
      };

  factory BillLine.fromJson(Map<String, dynamic> j) => BillLine(
        name: j['name'] as String,
        huid: j['huid'] as String,
        hsn: j['hsn'] as String,
        metal: Metal.values.byName(j['metal'] as String),
        net: (j['net'] as num).toDouble(),
        making: (j['making'] as num).toDouble(),
        stone: (j['stone'] as num).toDouble(),
        rate: (j['rate'] as num).toDouble(),
        makingPerGram: j['mpg'] as bool,
      );
}

/// A bill / invoice. All money maths lives here so it can be unit-tested.
/// NOTE: uses double for simplicity; for production consider integer paise.
class Bill {
  String no, customer, phone;
  DateTime date;
  List<BillLine> lines;
  double exWeight, exPurity, exRate; // old metal exchange
  Metal exMetal;
  double discount, cash, upi, card, gstPct;
  bool voided;

  Bill({
    this.no = '',
    required this.date,
    this.customer = '',
    this.phone = '',
    List<BillLine>? lines,
    this.exWeight = 0,
    this.exPurity = 91.6,
    this.exMetal = Metal.g22,
    this.exRate = 0,
    this.discount = 0,
    this.cash = 0,
    this.upi = 0,
    this.card = 0,
    this.gstPct = 3,
    this.voided = false,
  }) : lines = lines ?? [];

  double get subtotal => lines.fold(0.0, (s, l) => s + l.amount);
  double get taxable => math.max(0.0, subtotal - discount);
  double get gst => taxable * gstPct / 100;
  double get exchangeValue => exWeight * exPurity / 100 * exRate;
  double get total => taxable + gst - exchangeValue;
  double get paid => cash + upi + card;
  double get balance => total - paid;

  Map<String, dynamic> toJson() => {
        'no': no, 'date': date.toIso8601String(), 'customer': customer, 'phone': phone,
        'lines': lines.map((l) => l.toJson()).toList(),
        'exWeight': exWeight, 'exPurity': exPurity, 'exRate': exRate, 'exMetal': exMetal.name,
        'discount': discount, 'cash': cash, 'upi': upi, 'card': card, 'gstPct': gstPct,
      };

  factory Bill.fromJson(Map<String, dynamic> j) => Bill(
        no: j['no'] as String,
        date: DateTime.parse(j['date'] as String),
        customer: j['customer'] as String,
        phone: j['phone'] as String,
        lines: (j['lines'] as List).map((e) => BillLine.fromJson(e as Map<String, dynamic>)).toList(),
        exWeight: (j['exWeight'] as num).toDouble(),
        exPurity: (j['exPurity'] as num).toDouble(),
        exRate: (j['exRate'] as num).toDouble(),
        exMetal: Metal.values.byName(j['exMetal'] as String),
        discount: (j['discount'] as num).toDouble(),
        cash: (j['cash'] as num).toDouble(),
        upi: (j['upi'] as num).toDouble(),
        card: (j['card'] as num).toDouble(),
        gstPct: (j['gstPct'] as num).toDouble(),
      );
}
