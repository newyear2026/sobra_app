import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:sobra_app/main.dart';
import 'package:sobra_app/models/expense_entry.dart';
import 'package:sobra_app/models/pay_schedule.dart';
import 'package:sobra_app/models/recurring_expense.dart';
import 'package:sobra_app/models/store_failure.dart';
import 'package:sobra_app/models/xp_event.dart';
import 'package:sobra_app/services/purchase_service.dart';
import 'package:sobra_app/services/receipt_store.dart';
import 'package:sobra_app/state/sobra_store.dart';

import 'support/fake_purchase_backend.dart';

class _Disk extends InMemorySharedPreferencesStore {
  _Disk() : super.empty();
  String? failKey;
  bool throwOnFailure = false;
  bool failReads = false;
  Future<bool> Function(String key)? beforeWrite;
  int writes = 0;

  @override
  Future<Map<String, Object>> getAll() {
    if (failReads) throw StateError('read unavailable');
    return super.getAll();
  }

  @override
  Future<bool> setValue(String type, String key, Object value) async {
    writes++;
    if (beforeWrite != null && !await beforeWrite!(key)) return false;
    if (key == failKey) {
      if (throwOnFailure) throw StateError('disk unavailable');
      return false;
    }
    return super.setValue(type, key, value);
  }

  Future<String?> raw(String key) async =>
      (await getAll())['flutter.$key'] as String?;
  Future<Map<String, dynamic>> ledger() async =>
      jsonDecode((await raw('sobra_state_v2'))!) as Map<String, dynamic>;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _Disk disk;
  late DateTime now;
  setUp(() {
    disk = _Disk();
    SharedPreferencesStorePlatform.instance = disk;
    SharedPreferences.resetStatic();
    now = DateTime(2026, 10, 1, 12);
  });
  tearDown(SharedPreferences.resetStatic);

  Future<SobraStore> ready({int? budget = 600000}) async {
    final store = await SobraStore.load(now: () => now);
    await store.configureOnboarding(
      budgetCentavos: budget,
      schedule: const PaySchedule.weekly(weeklyPayDay: DateTime.thursday),
      cashCentavos: 200000,
    );
    await store.completeOnboarding();
    now = now.add(const Duration(minutes: 1));
    store.takePendingXpNotice();
    return store;
  }

  Future<ExpenseEntry> spend(SobraStore store, {String note = 'Retry'}) =>
      store.addExpense(
        amountCentavos: 18000,
        category: ExpenseCategory.food,
        note: note,
        occurredAt: now,
        paymentMethod: PaymentMethod.cash,
      );

  for (final key in ['sobra_state_backup_v2', 'sobra_state_v2']) {
    for (final throws in [false, true]) {
      test(
        '$key failure (throws=$throws) rolls back expense, cash, XP and notifications',
        () async {
          final store = await ready();
          final before = store.exportJson();
          var notifications = 0;
          store.addListener(() => notifications++);
          disk
            ..failKey = 'flutter.$key'
            ..throwOnFailure = throws;
          await expectLater(
            spend(store),
            throws ? throwsStateError : throwsA(isA<SobraStoreException>()),
          );
          expect(store.exportJson(), before);
          expect(store.takePendingXpNotice(), isNull);
          expect(notifications, 0);
          expect(
            jsonDecode((await disk.raw('sobra_state_v2'))!),
            jsonDecode(before),
          );
          disk.failKey = null;
          await spend(store);
          expect(notifications, 1);
          expect(store.transactions, hasLength(1));
          expect(store.expectedCashCentavos, 182000);
          expect(
            jsonDecode((await disk.raw('sobra_state_backup_v2'))!),
            jsonDecode(before),
          );
          expect(
            (await SobraStore.load(now: () => now)).transactions,
            hasLength(1),
          );
        },
      );
    }
  }

  test(
    'failed cache reload cannot turn an unsaved expense into the next backup',
    () async {
      final store = await ready();
      final original = store.exportJson();
      disk
        ..failKey = 'flutter.sobra_state_v2'
        ..failReads = true;
      await expectLater(spend(store), throwsA(isA<SobraStoreException>()));
      expect(store.exportJson(), original);
      disk.failKey = null;
      await spend(store);
      disk.failReads = false;
      expect(
        jsonDecode((await disk.raw('sobra_state_backup_v2'))!),
        jsonDecode(original),
      );
      expect((await disk.ledger())['transactions'], hasLength(1));
    },
  );

  test(
    'failed variable fixed payment restores estimate and retry writes exactly once',
    () async {
      final store = await ready();
      final bill = await store.addRecurringExpense(
        name: 'Rent',
        amountCentavos: 100000,
        category: ExpenseCategory.home,
        paymentMethod: PaymentMethod.cash,
        frequency: FixedFrequency.monthly,
        firstDueDate: now,
        isVariable: true,
      );
      final before = store.exportJson();
      Future<ExpenseEntry> pay() => store.recordFixedPayment(
        recurringId: bill.id,
        occurrenceDate: now,
        amountCentavos: 90000,
      );
      disk.failKey = 'flutter.sobra_state_v2';
      await expectLater(pay(), throwsA(isA<SobraStoreException>()));
      expect(store.exportJson(), before);
      disk.failKey = null;
      await Future.wait([pay(), pay()]);
      expect((await disk.ledger())['transactions'], hasLength(1));
      expect(store.recurringExpenses.single.amountCentavos, 90000);
      expect(store.expectedCashCentavos, 110000);
    },
  );

  test(
    'failed edits and deletes preserve the saved expense and balance',
    () async {
      final store = await ready();
      final entry = await spend(store);
      final before = store.exportJson();
      disk.failKey = 'flutter.sobra_state_v2';
      await expectLater(
        store.updateExpense(entry.copyWith(amountCentavos: 42000)),
        throwsA(isA<SobraStoreException>()),
      );
      expect(store.exportJson(), before);
      await expectLater(
        store.deleteExpense(entry.id),
        throwsA(isA<SobraStoreException>()),
      );
      expect(store.exportJson(), before);
    },
  );

  test(
    'a queued successful mutation cannot include a failed concurrent expense',
    () async {
      final store = await ready();
      final entered = Completer<void>();
      final release = Completer<void>();
      disk.beforeWrite = (key) async {
        if (key == 'flutter.sobra_state_v2' && !entered.isCompleted) {
          entered.complete();
          await release.future;
          return false;
        }
        return true;
      };
      final failed = expectLater(
        spend(store, note: 'Failed'),
        throwsA(isA<SobraStoreException>()),
      );
      await entered.future;
      final succeeded = spend(store, note: 'Saved');
      release.complete();
      await failed;
      await succeeded;
      expect(store.transactions.single.note, 'Saved');
      expect(store.expectedCashCentavos, 182000);
      expect((await disk.ledger())['transactions'], hasLength(1));
    },
  );

  test(
    'purchase replays stay unacknowledged on every failed save in one session',
    () async {
      final store = await ready();
      final backend = FakeBackend();
      final purchases = SobraPurchases(
        backend: backend,
        store: store,
        restoreOnStart: false,
      );
      addTearDown(purchases.dispose);
      addTearDown(backend.close);
      await purchases.start();
      disk.failKey = 'flutter.sobra_state_v2';
      for (final status in [
        PurchaseStatus.purchased,
        PurchaseStatus.restored,
      ]) {
        backend.emit([detailsFor('sobra.character.platypus', status)]);
        await pumpEventQueue();
        expect(backend.completed, isEmpty);
        expect(store.ownedCatalogIds, isNot(contains('platypus')));
      }
      disk.failKey = null;
      backend.emit([
        detailsFor('sobra.character.platypus', PurchaseStatus.restored),
      ]);
      await pumpEventQueue();
      expect(backend.completed, ['sobra.character.platypus']);
      expect((await disk.ledger())['ownedCatalogIds'], contains('platypus'));
    },
  );

  test(
    'corrupt startup preserves original and photos; failed recovery stays protected',
    () async {
      final healthy = await ready();
      final saved = healthy.exportJson();
      const broken = '{damaged ledger';
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('sobra_state_backup_v2', saved);
      await prefs.setString('sobra_state_v2', broken);
      final beforeWrites = disk.writes;
      final store = await SobraStore.load(now: () => now);
      expect(disk.writes, beforeWrites);
      expect(store.hasStorageError, isTrue);
      final directory = await Directory.systemTemp.createTemp(
        'sobra-recovery-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final photo = File('${directory.path}/receipt-existing.jpg');
      await photo.writeAsString('fixture');
      await prepareReceipts(FileReceiptStore(directory: directory), store);
      expect(await photo.exists(), isTrue);
      final backend = FakeBackend()
        ..ownedProductIds = ['sobra.character.platypus'];
      var restores = 0;
      backend.onRestore = () => restores++;
      final purchases = SobraPurchases(backend: backend, store: store);
      addTearDown(purchases.dispose);
      addTearDown(backend.close);
      await purchases.start();
      await purchases.refreshOnResume();
      backend.emit([
        detailsFor('sobra.character.platypus', PurchaseStatus.restored),
      ]);
      await pumpEventQueue();
      expect(restores, 0);
      expect(backend.completed, isEmpty);
      await store.refreshForCurrentDate();
      await expectLater(
        store.grantCatalogEntry('platypus'),
        throwsA(isA<SobraStoreException>()),
      );
      expect(await disk.raw('sobra_state_v2'), broken);
      disk.failKey = 'flutter.sobra_state_v2';
      await expectLater(
        store.restoreBackup(),
        throwsA(isA<SobraStoreException>()),
      );
      expect(store.hasStorageError, isTrue);
      expect(store.exportCorruptedJson, broken);
      expect(await disk.raw('sobra_state_v2'), broken);
      disk.failKey = null;
      expect(await store.restoreBackup(), isTrue);
      await pumpEventQueue();
      expect(store.hasStorageError, isFalse);
      expect(await disk.raw('sobra_state_corrupt_v2'), broken);
      expect(backend.completed, ['sobra.character.platypus']);
      expect((await disk.ledger())['ownedCatalogIds'], contains('platypus'));
      expect(await photo.exists(), isTrue);
    },
  );

  test(
    'fresh-start archive or main-write failure cannot exit recovery',
    () async {
      const broken = '{original';
      await (await SharedPreferences.getInstance()).setString(
        'sobra_state_v2',
        broken,
      );
      final store = await SobraStore.load(now: () => now);
      for (final key in ['sobra_state_corrupt_v2', 'sobra_state_v2']) {
        disk.failKey = 'flutter.$key';
        await expectLater(
          store.startFreshAfterCorruption(),
          throwsA(isA<SobraStoreException>()),
        );
        expect(store.hasStorageError, isTrue);
        expect(store.exportCorruptedJson, broken);
        expect(await disk.raw('sobra_state_v2'), broken);
      }
      disk.failKey = null;
      await store.startFreshAfterCorruption();
      expect(store.hasStorageError, isFalse);
      expect(await disk.raw('sobra_state_corrupt_v2'), broken);
    },
  );

  test(
    'an unset budget never settles or rewards, including after restart',
    () async {
      final store = await ready(budget: null);
      now = DateTime(2026, 11, 5, 12);
      await store.refreshForCurrentDate();
      await store.noteBudgetReviewed();
      final reopened = await SobraStore.load(now: () => now);
      expect(reopened.cycleRecords, isEmpty);
      expect(reopened.totalXp, 0);
      expect(reopened.successfulCycles, 0);
      expect(reopened.budgetTrackingStartedAt, isNull);
      expect(reopened.lastSettledCycleEnd, isNull);
    },
  );

  test(
    'first chosen budget excludes earlier days and survives export and restart',
    () async {
      final store = await ready(budget: null);
      now = DateTime(2026, 10, 10, 12);
      await store.setTotalBudget(450000);
      expect(store.budgetTrackingStartedAt, DateTime(2026, 10, 10));
      final reopened = await SobraStore.load(now: () => now);
      expect(reopened.budgetTrackingStartedAt, DateTime(2026, 10, 10));
      now = DateTime(2026, 10, 15, 12);
      await reopened.settleCycles();
      expect(reopened.cycleRecords, isEmpty);
      expect(reopened.successfulCycles, 0);
      expect(reopened.xpEvents.single.kind, XpEventKind.daysUnderDailyLimit);
      expect(reopened.xpEvents.single.quantity, 5);
      now = DateTime(2026, 10, 22, 12);
      await reopened.settleCycles();
      expect(reopened.cycleRecords.single.start, DateTime(2026, 10, 15));
      expect(reopened.successfulCycles, 1);
      expect(reopened.totalXp, 155);
    },
  );

  test(
    'settlement save failure rolls back rewards and the cycle cursor',
    () async {
      final store = await ready();
      final before = store.exportJson();
      now = DateTime(2026, 10, 8, 12);
      disk.failKey = 'flutter.sobra_state_v2';
      await expectLater(
        store.settleCycles(),
        throwsA(isA<SobraStoreException>()),
      );
      expect(store.exportJson(), before);
      expect(store.takePendingXpNotice(), isNull);
      disk.failKey = null;
      await store.settleCycles();
      expect(store.cycleRecords, hasLength(1));
      expect(store.totalXp, 130);
    },
  );
}
