import 'package:flutter/material.dart';
import 'db.dart';
import 'models.dart';
import 'util.dart';
import 'screens/billing_screen.dart';
import 'screens/items_screen.dart';
import 'screens/bills_screen.dart';
import 'screens/settings_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppState.I.load();
  runApp(const JewelleryPosApp());
}

class JewelleryPosApp extends StatelessWidget {
  const JewelleryPosApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Jewellery POS',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(useMaterial3: true, colorSchemeSeed: const Color(0xFF7A4B00)),
        darkTheme: ThemeData(useMaterial3: true, colorSchemeSeed: const Color(0xFFE0B04A), brightness: Brightness.dark),
        home: const Shell(),
      );
}

class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int i = 0;
  @override
  Widget build(BuildContext context) {
    final st = AppState.I;
    return Scaffold(
      appBar: AppBar(
        title: AnimatedBuilder(
          animation: st,
          builder: (context, _) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(st.shopName),
            Text('22K today: ${inr.format(st.rate(Metal.g22))}/g', style: Theme.of(context).textTheme.bodySmall),
          ]),
        ),
      ),
      // IndexedStack keeps a half-made bill alive while you check Items or Bills.
      body: IndexedStack(index: i, children: const [BillingScreen(), ItemsScreen(), BillsScreen(), SettingsScreen()]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: i,
        onDestinationSelected: (v) => setState(() => i = v),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.receipt_long), label: 'Bill'),
          NavigationDestination(icon: Icon(Icons.diamond_outlined), label: 'Items'),
          NavigationDestination(icon: Icon(Icons.history), label: 'Bills'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Setup'),
        ],
      ),
    );
  }
}
