import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sobra_app/models/cash_reconciliation.dart';
import 'package:sobra_app/models/expense_entry.dart';
import 'package:sobra_app/models/pay_schedule.dart';
import 'package:sobra_app/screens/register_screen.dart';
import 'package:sobra_app/services/receipt_store.dart';
import 'package:sobra_app/state/sobra_store.dart';
import 'package:sobra_app/widgets/receipt_field.dart';
import 'package:sobra_app/widgets/transaction_row.dart';

import 'support/localizations.dart';

/// A receipt store with no camera and no disk.
///
/// [capture] hands back whatever the test queued, which is the only part of
/// the real store a widget cannot drive: the picker is a platform channel.
class FakeReceiptStore implements ReceiptStore {
  FakeReceiptStore({this.nextName = 'ticket.jpg', this.supported = true});

  /// What the next [capture] returns. Null stands for a cancelled picker.
  String? nextName;
  final bool supported;
  final List<ReceiptSource> captures = <ReceiptSource>[];
  final List<String> removed = <String>[];

  @override
  bool get isSupported => supported;

  @override
  Future<String?> capture(ReceiptSource source) async {
    captures.add(source);
    return nextName;
  }

  // No bytes behind the name, so every thumbnail renders its "photo is gone"
  // state. That is the branch a test can reach without a real image on disk.
  @override
  File? fileFor(String name) => null;

  @override
  Future<void> remove(String name) async => removed.add(name);

  @override
  Future<int> sweepOrphans(Iterable<String> referenced) async => 0;
}

/// A store whose picker fails, standing in for a denied permission or a disk
/// that will not take the file.
class ThrowingReceiptStore implements ReceiptStore {
  @override
  bool get isSupported => true;

  @override
  Future<String?> capture(ReceiptSource source) async =>
      throw const FileSystemException('no camera');

  @override
  File? fileFor(String name) => null;

  @override
  Future<void> remove(String name) async {}

  @override
  Future<int> sweepOrphans(Iterable<String> referenced) async => 0;
}

void main() {
  late DateTime now;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    now = DateTime(2026, 9, 4, 10, 30, 45);
  });

  Future<SobraStore> loadStore() async {
    final store = await SobraStore.load(now: () => now);
    await store.configureOnboarding(
      budgetCentavos: 600000,
      schedule: const PaySchedule.semiMonthly(),
      cashCentavos: 124000,
    );
    await store.completeOnboarding();
    return store;
  }

  group('the model', () {
    test('carries a receipt name through JSON', () {
      final entry = ExpenseEntry(
        id: 'expense-1',
        amountCentavos: 25000,
        category: ExpenseCategory.food,
        note: 'Taquería',
        occurredAt: now,
        paymentMethod: PaymentMethod.cash,
        receiptFileName: 'receipt-1.jpg',
      );

      final restored = ExpenseEntry.fromJson(entry.toJson());

      expect(restored.receiptFileName, 'receipt-1.jpg');
      expect(restored.hasReceipt, isTrue);
    });

    test('reads an entry saved before receipts existed', () {
      // Every expense already on a user's phone looks like this. Loading one
      // must not throw and must not invent a photo.
      final restored = ExpenseEntry.fromJson({
        'id': 'expense-1',
        'amountCentavos': 25000,
        'category': 'food',
        'note': 'Taquería',
        'occurredAt': now.toIso8601String(),
        'paymentMethod': 'cash',
      });

      expect(restored.receiptFileName, isNull);
      expect(restored.hasReceipt, isFalse);
    });

    test('copyWith can take a receipt away, not only set one', () {
      final entry = ExpenseEntry(
        id: 'expense-1',
        amountCentavos: 25000,
        category: ExpenseCategory.food,
        note: '',
        occurredAt: now,
        paymentMethod: PaymentMethod.cash,
        receiptFileName: 'receipt-1.jpg',
      );

      expect(entry.copyWith(note: 'x').receiptFileName, 'receipt-1.jpg');
      expect(entry.copyWith(clearReceipt: true).receiptFileName, isNull);
    });
  });

  group('the store', () {
    test('saves a receipt name with a new expense', () async {
      final store = await loadStore();

      final entry = await store.addExpense(
        amountCentavos: 25000,
        category: ExpenseCategory.food,
        note: 'Taquería',
        occurredAt: now,
        paymentMethod: PaymentMethod.cash,
        receiptFileName: 'receipt-1.jpg',
      );

      expect(entry.receiptFileName, 'receipt-1.jpg');
      expect(store.referencedReceipts, ['receipt-1.jpg']);
    });

    test('lists only the receipts still attached to something', () async {
      final store = await loadStore();
      final kept = await store.addExpense(
        amountCentavos: 10000,
        category: ExpenseCategory.food,
        note: '',
        occurredAt: now,
        paymentMethod: PaymentMethod.cash,
        receiptFileName: 'keep.jpg',
      );
      final dropped = await store.addExpense(
        amountCentavos: 20000,
        category: ExpenseCategory.transport,
        note: '',
        occurredAt: now,
        paymentMethod: PaymentMethod.card,
        receiptFileName: 'drop.jpg',
      );
      await store.addExpense(
        amountCentavos: 30000,
        category: ExpenseCategory.home,
        note: '',
        occurredAt: now,
        paymentMethod: PaymentMethod.card,
      );

      await store.deleteExpense(dropped.id);

      expect(store.referencedReceipts, [kept.receiptFileName]);
    });

    test('detaching a receipt survives the round trip', () async {
      final store = await loadStore();
      final entry = await store.addExpense(
        amountCentavos: 25000,
        category: ExpenseCategory.food,
        note: '',
        occurredAt: now,
        paymentMethod: PaymentMethod.cash,
        receiptFileName: 'receipt-1.jpg',
      );

      await store.updateExpense(entry.copyWith(clearReceipt: true));
      final reloaded = await SobraStore.load(now: () => now);

      expect(reloaded.transactions.single.receiptFileName, isNull);
    });

    test('a cash-count expense keeps a receipt the user attaches', () async {
      // `updateExpense` pins a measured amount and date, letting only what the
      // user actually knows through. A photo is that kind of knowledge.
      final store = await loadStore();
      await store.reconcileCashCount(
        actualCentavos: 100000,
        resolution: CashResolution.pending,
      );
      final pending = store.latestPendingCashExpense;
      expect(pending, isNotNull);

      await store.classifyPendingCashExpense(
        expenseId: pending!.id,
        category: ExpenseCategory.food,
        note: 'Mercado',
        receiptFileName: 'receipt-1.jpg',
      );

      final settled = store.transactions.firstWhere(
        (entry) => entry.id == pending.id,
      );
      expect(settled.receiptFileName, 'receipt-1.jpg');
      expect(settled.isPendingCashAdjustment, isFalse);
    });
  });

  group('the file store', () {
    late Directory directory;

    setUp(() {
      directory = Directory.systemTemp.createTempSync('sobra-receipts');
    });

    tearDown(() {
      if (directory.existsSync()) directory.deleteSync(recursive: true);
    });

    test('sweeps what nothing points at and keeps what does', () async {
      final store = FileReceiptStore(directory: directory);
      File('${directory.path}/keep.jpg').writeAsStringSync('a');
      File('${directory.path}/orphan.jpg').writeAsStringSync('b');

      final removed = await store.sweepOrphans(['keep.jpg']);

      expect(removed, 1);
      expect(File('${directory.path}/keep.jpg').existsSync(), isTrue);
      expect(File('${directory.path}/orphan.jpg').existsSync(), isFalse);
    });

    test('resolves a stored name, and reports a missing one', () async {
      final store = FileReceiptStore(directory: directory);
      File('${directory.path}/there.jpg').writeAsStringSync('a');
      await store.warmUp();

      expect(store.fileFor('there.jpg'), isNotNull);
      expect(store.fileFor('gone.jpg'), isNull);
    });

    test('removing deletes the file', () async {
      final store = FileReceiptStore(directory: directory);
      final file = File('${directory.path}/receipt.jpg')
        ..writeAsStringSync('a');

      await store.remove('receipt.jpg');

      expect(file.existsSync(), isFalse);
      // A name with no file behind it is not an error worth throwing over.
      await expectLater(store.remove('never-existed.jpg'), completes);
    });
  });

  group('the register screen', () {
    // Pumped directly rather than through the shell: `AppShell` keeps all five
    // tabs in one `IndexedStack`, so a finder matches the register form even
    // when another tab is showing, and a tap lands on the hidden sibling. A
    // tall viewport keeps the whole form on screen, scrolling out of the way.
    Future<void> openRegister(
      WidgetTester tester,
      ReceiptStore receipts,
      SobraStore store, {
      VoidCallback? onSaved,
    }) async {
      tester.view.physicalSize = const Size(520, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ReceiptScope(
          store: receipts,
          child: SobraScope(
            store: store,
            child: MaterialApp(
              locale: const Locale('es', 'MX'),
              localizationsDelegates: sobraLocalizationsDelegates,
              supportedLocales: sobraSupportedLocales,
              home: Scaffold(body: RegisterScreen(onSaved: onSaved ?? () {})),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    Future<void> save(WidgetTester tester) async {
      await tester.tap(find.text('Guardar'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1400));
    }

    testWidgets('attaching a photo puts it on the saved expense', (
      tester,
    ) async {
      final store = await loadStore();
      final receipts = FakeReceiptStore(nextName: 'receipt-7.jpg');
      await openRegister(tester, receipts, store);

      expect(find.text('Ticket'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField).first, '250');
      await tester.tap(find.text('Cámara'));
      await tester.pump();

      expect(receipts.captures, [ReceiptSource.camera]);
      expect(find.text('Ticket adjunto'), findsOneWidget);

      await save(tester);

      expect(store.transactions.single.receiptFileName, 'receipt-7.jpg');
    });

    testWidgets('a cancelled picker leaves the form alone', (tester) async {
      final store = await loadStore();
      final receipts = FakeReceiptStore(nextName: null);
      await openRegister(tester, receipts, store);

      await tester.tap(find.text('Galería'));
      await tester.pump();

      expect(receipts.captures, [ReceiptSource.gallery]);
      expect(find.text('Ticket adjunto'), findsNothing);
      expect(find.text('Cámara'), findsOneWidget);
    });

    testWidgets('removing clears the attachment before saving', (tester) async {
      final store = await loadStore();
      final receipts = FakeReceiptStore(nextName: 'receipt-7.jpg');
      await openRegister(tester, receipts, store);

      await tester.enterText(find.byType(TextFormField).first, '250');
      await tester.tap(find.text('Cámara'));
      await tester.pump();
      await tester.tap(find.text('Quitar'));
      await tester.pump();

      expect(find.text('Ticket adjunto'), findsNothing);

      await save(tester);

      expect(store.transactions.single.receiptFileName, isNull);
    });

    testWidgets('the next expense does not inherit the last photo', (
      tester,
    ) async {
      final store = await loadStore();
      final receipts = FakeReceiptStore(nextName: 'receipt-7.jpg');
      await openRegister(tester, receipts, store);

      await tester.enterText(find.byType(TextFormField).first, '250');
      await tester.tap(find.text('Cámara'));
      await tester.pump();
      await save(tester);

      // The form is reused for the next entry, so a photo left behind would
      // quietly attach itself to an expense it has nothing to do with.
      expect(find.text('Ticket adjunto'), findsNothing);
      await tester.enterText(find.byType(TextFormField).first, '90');
      await save(tester);

      expect(store.transactions, hasLength(2));
      expect(
        store.transactions.where((entry) => entry.hasReceipt),
        hasLength(1),
      );
    });

    testWidgets('a picker that throws says so and keeps the form', (
      tester,
    ) async {
      final store = await loadStore();
      final receipts = ThrowingReceiptStore();
      await openRegister(tester, receipts, store);

      await tester.tap(find.text('Cámara'));
      await tester.pump();

      expect(find.text('No se pudo guardar la foto.'), findsOneWidget);
      expect(find.text('Ticket adjunto'), findsNothing);
      // The camera is offered again rather than left disabled.
      expect(find.text('Cámara'), findsOneWidget);
    });

    testWidgets('a build with nowhere to put a file offers no camera', (
      tester,
    ) async {
      final store = await loadStore();
      await openRegister(tester, FakeReceiptStore(supported: false), store);

      expect(find.text('Ticket'), findsNothing);
      expect(find.text('Cámara'), findsNothing);
      // The rest of the form is untouched.
      expect(find.text('Guardar'), findsOneWidget);
    });

    testWidgets('income has no receipt field', (tester) async {
      final store = await loadStore();
      await openRegister(tester, FakeReceiptStore(), store);

      expect(find.text('Ticket'), findsOneWidget);
      await tester.tap(find.text('Ingreso'));
      await tester.pump();

      expect(find.text('Ticket'), findsNothing);
    });
  });

  group('the ledger row', () {
    // The row is pumped on its own rather than through a screen: the home and
    // Movimientos lists are lazy slivers, so a row below the fold is never
    // built, and the home screen carries an unrelated 4 px overflow at this
    // width that would mask a real one here.
    //
    // The row marks an attached photo with a glyph, not the photo: at row size
    // a receipt crop is unreadable and only ever said "there is a photo".
    Future<void> pumpRow(
      WidgetTester tester,
      SobraStore store,
      ExpenseEntry entry,
    ) async {
      tester.view.physicalSize = const Size(360, 720);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ReceiptScope(
          store: FakeReceiptStore(),
          child: SobraScope(
            store: store,
            child: MaterialApp(
              locale: const Locale('es', 'MX'),
              localizationsDelegates: sobraLocalizationsDelegates,
              supportedLocales: sobraSupportedLocales,
              home: Scaffold(
                body: MovementRow(
                  movement: store.movements.firstWhere(
                    (movement) => movement.id == entry.id,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('marks an expense that has a photo', (tester) async {
      final store = await loadStore();
      final entry = await store.addExpense(
        amountCentavos: 125000,
        category: ExpenseCategory.food,
        note: 'Una nota bastante larga para apretar la fila',
        occurredAt: now,
        paymentMethod: PaymentMethod.cash,
        receiptFileName: 'receipt-1.jpg',
      );

      await pumpRow(tester, store, entry);

      expect(find.byIcon(Icons.receipt_long), findsOneWidget);
      // The photo itself stays out of the list; it opens from the edit sheet.
      expect(find.byType(ReceiptThumbnail), findsNothing);
      // A long note and a five-figure amount on a 360 px phone is the tightest
      // the row gets; the marker must not push it over.
      expect(tester.takeException(), isNull);
    });

    testWidgets('leaves a row without a photo unmarked', (tester) async {
      final store = await loadStore();
      final entry = await store.addExpense(
        amountCentavos: 30000,
        category: ExpenseCategory.transport,
        note: 'Sin ticket',
        occurredAt: now,
        paymentMethod: PaymentMethod.card,
      );

      await pumpRow(tester, store, entry);

      expect(find.byIcon(Icons.receipt_long), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
