# Jewellery POS (Flutter, Android)

Offline-first billing app for jewellery shops: daily metal rates, stock items with HUID,
bills with making/stone/GST, old-gold exchange, split payments (cash/UPI/card),
PDF invoices (print / share on WhatsApp), cancel-not-delete audit trail, daily summary.

## Run it
1. Install Flutter (https://docs.flutter.dev/get-started/install) and an Android phone or emulator.
2. In an empty folder run:  `flutter create jewellery_pos`
3. Copy this project's `lib/`, `test/` and `pubspec.yaml` over the generated ones.
4. `cd jewellery_pos && flutter pub get && flutter test && flutter run`
5. Release APK for pilots:  `flutter build apk --release`  (output in build/app/outputs/flutter-apk/)

First launch: open **Setup**, enter today's rates and shop details, then add items.

## Structure
- `lib/models.dart`   Item, BillLine, Bill - ALL money maths (unit-tested in test/calc_test.dart)
- `lib/db.dart`       SQLite storage (sqflite) + AppState
- `lib/screens/`      Billing, Items, Bills, Setup, Invoice
- `lib/invoice_pdf.dart`  A5 invoice PDF

## Known gaps / next milestones
- Cloud sync + multi-shop accounts + staff roles (Supabase) - needed before selling
- Subscriptions/licensing (Razorpay), Excel stock import, barcode scan, Bluetooth thermal printer
- Local-language UI, GST report export, customer ledger, wastage, repairs/orders
- Money uses double; move to integer paise before production
- Have a CA verify GST / HUID / old-gold exchange rules for your state before selling

## Build the APK without installing anything (GitHub Actions)
1. Create a free GitHub account and a new repository.
2. Upload everything in this folder, including `.github/workflows/build-apk.yml`.
3. Open the repo's **Actions** tab -> **Build APK** -> **Run workflow**.
4. After ~5-10 minutes open the finished run and download the `jewellery-pos-apk` artifact.
5. Unzip it, send `app-release.apk` to your phone and install it (allow "install unknown apps").
If analyze/tests show errors, the APK still builds; open the run log to see them.
