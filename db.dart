import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'models.dart';

/// Local SQLite storage. Works fully offline.
class AppDb {
  static Database? _db;
  static Future<Database> get db async => _db ??= await _open();

  static Future<Database> _open() async {
    final path = p.join(await getDatabasesPath(), 'jewellery_pos.db');
    return openDatabase(path, version: 1, onCreate: (d, v) async {
      await d.execute('CREATE TABLE settings(k TEXT PRIMARY KEY, v TEXT)');
      await d.execute('CREATE TABLE items(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, metal TEXT, '
          'gross REAL, net REAL, stone REAL, mpg INTEGER, making REAL, huid TEXT, hsn TEXT)');
      await d.execute('CREATE TABLE bills(id INTEGER PRIMARY KEY AUTOINCREMENT, no TEXT, date TEXT, '
          'total REAL, voided INTEGER DEFAULT 0, json TEXT)');
    });
  }

  static Future<Map<String, String>> settings() async {
    final r = await (await db).query('settings');
    return {for (final m in r) m['k'] as String: m['v'] as String};
  }

  static Future<void> setSetting(String k, String v) async {
    await (await db).insert('settings', {'k': k, 'v': v}, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<List<Item>> items() async {
    final r = await (await db).query('items', orderBy: 'name COLLATE NOCASE');
    return r.map(Item.fromMap).toList();
  }

  static Future<void> upsertItem(Item i) async {
    final d = await db;
    if (i.id == null) {
      final m = i.toMap()..remove('id');
      await d.insert('items', m);
    } else {
      await d.update('items', i.toMap(), where: 'id=?', whereArgs: [i.id]);
    }
  }

  static Future<void> deleteItem(int id) async {
    await (await db).delete('items', where: 'id=?', whereArgs: [id]);
  }

  /// Saves a bill and assigns the next bill number atomically.
  static Future<Bill> saveBill(Bill b) async {
    final d = await db;
    await d.transaction((txn) async {
      final r = await txn.query('settings', where: 'k=?', whereArgs: ['billCounter']);
      final n = (r.isEmpty ? 0 : int.parse(r.first['v'] as String)) + 1;
      b.no = 'JW-${n.toString().padLeft(4, '0')}';
      await txn.insert('settings', {'k': 'billCounter', 'v': '$n'}, conflictAlgorithm: ConflictAlgorithm.replace);
      await txn.insert('bills', {
        'no': b.no, 'date': b.date.toIso8601String(), 'total': b.total, 'voided': 0, 'json': jsonEncode(b.toJson()),
      });
    });
    return b;
  }

  static Future<List<Bill>> bills() async {
    final r = await (await db).query('bills', orderBy: 'id DESC');
    return r.map((m) {
      final b = Bill.fromJson(jsonDecode(m['json'] as String) as Map<String, dynamic>);
      b.voided = m['voided'] == 1;
      return b;
    }).toList();
  }

  /// Bills are never deleted (GST audit trail) - only cancelled.
  static Future<void> voidBill(String no) async {
    await (await db).update('bills', {'voided': 1}, where: 'no=?', whereArgs: [no]);
  }
}

/// App-wide state held in memory, backed by [AppDb].
class AppState extends ChangeNotifier {
  AppState._();
  static final AppState I = AppState._();

  Map<String, String> s = {};
  List<Item> items = [];
  List<Bill> bills = [];

  Future<void> load() async {
    s = await AppDb.settings();
    items = await AppDb.items();
    bills = await AppDb.bills();
    notifyListeners();
  }

  String get shopName => (s['shopName']?.isNotEmpty ?? false) ? s['shopName']! : 'My Jewellers';
  double rate(Metal m) => double.tryParse(s['rate_${m.name}'] ?? '') ?? 0;
  double get gstPct => double.tryParse(s['gstPct'] ?? '') ?? 3;

  Future<void> set(String k, String v) async {
    s[k] = v;
    await AppDb.setSetting(k, v);
    notifyListeners();
  }

  Future<void> saveItem(Item i) async {
    await AppDb.upsertItem(i);
    await load();
  }

  Future<void> deleteItem(int id) async {
    await AppDb.deleteItem(id);
    await load();
  }
}
