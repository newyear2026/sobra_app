import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:sobra_app/models/currency.dart';
import 'package:sobra_app/models/expense_entry.dart';
import 'package:sobra_app/models/income_entry.dart';
import 'package:sobra_app/models/pay_schedule.dart';
import 'package:sobra_app/models/savings_goal.dart';
import 'package:sobra_app/models/store_failure.dart';
import 'package:sobra_app/state/sobra_store.dart';

class _GoalDisk extends InMemorySharedPreferencesStore {
  _GoalDisk() : super.empty();

  bool failStateWrite = false;

  @override
  Future<bool> setValue(String type, String key, Object value) =>
      failStateWrite && key == 'flutter.sobra_state_v2'
      ? Future.value(false)
      : super.setValue(type, key, value);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _GoalDisk disk;
  late SobraStore store;
  late DateTime now;

  setUp(() async {
    now = DateTime(2026, 11, 9, 15);
    disk = _GoalDisk();
    SharedPreferencesStorePlatform.instance = disk;
    SharedPreferences.resetStatic();
    store = await SobraStore.load(now: () => now);
    await store.configureOnboarding(
      budgetCentavos: 600000,
      schedule: const PaySchedule.semiMonthly(),
      cashCentavos: 100000,
    );
    await store.completeOnboarding();
  });
  tearDown(SharedPreferences.resetStatic);

  Future<IncomeEntry> income(
    int amount, {
    DateTime? occurredAt,
    IncomeAllocation allocation = IncomeAllocation.savings,
  }) => store.addIncome(
    amountCentavos: amount,
    kind: IncomeKind.extra,
    note: '',
    occurredAt: occurredAt ?? now,
    destination: PaymentMethod.card,
    allocation: allocation,
  );

  Future<SavingsGoal> create({int starting = 0}) => store.saveSavingsGoal(
    name: 'AirPods 4',
    targetCentavos: 149900,
    startingCentavos: starting,
  );

  test(
    'a new install has no goal; goal fields survive reload and backup',
    () async {
      expect(store.activeSavingsGoal, isNull);
      expect(store.savingsGoalProgressCentavos, 0);
      final goal = await store.saveSavingsGoal(
        name: '  AirPods 4  ',
        targetCentavos: 149900,
        startingCentavos: 30000,
        targetDate: DateTime(2026, 12, 1, 17),
        productUrl: ' https://www.walmart.com.mx/ip/airpods/123 ',
        imageUrl: 'https://images.example.com/airpods.jpg',
        merchantName: ' Walmart México ',
      );
      final backup = store.exportJson();
      expect(jsonDecode(backup)['schemaVersion'], 12);
      final reloaded = await SobraStore.load(now: () => now);
      expect(reloaded.activeSavingsGoal!.toJson(), goal.toJson());
      expect(reloaded.activeSavingsGoal!.name, 'AirPods 4');
      expect(reloaded.activeSavingsGoal!.kind, SavingsGoalKind.product);
      expect(reloaded.activeSavingsGoal!.targetDate, DateTime(2026, 12, 1));
      expect(reloaded.activeSavingsGoal!.merchantName, 'Walmart México');
      expect(reloaded.savingsGoalProgressCentavos, 30000);
      await reloaded.removeSavingsGoal(goal.id);
      await reloaded.importBackup(backup);
      expect(reloaded.activeSavingsGoal!.toJson(), goal.toJson());
      expect(reloaded.savingsGoalProgressCentavos, 30000);
    },
  );

  test('a manually entered product keeps its kind without a link', () async {
    final goal = await store.saveSavingsGoal(
      kind: SavingsGoalKind.product,
      name: 'New sneakers',
      targetCentavos: 149900,
      startingCentavos: 30000,
    );
    final reloaded = await SobraStore.load(now: () => now);
    expect(reloaded.activeSavingsGoal!.kind, SavingsGoalKind.product);
    expect(reloaded.activeSavingsGoal!.productUrl, isNull);
    await reloaded.saveSavingsGoal(
      id: goal.id,
      name: 'Updated sneakers',
      targetCentavos: 150000,
      startingCentavos: 30000,
    );
    expect(reloaded.activeSavingsGoal!.kind, SavingsGoalKind.product);
  });

  test(
    'switching to an amount goal clears product references, not progress',
    () async {
      await income(10000);
      final goal = await store.saveSavingsGoal(
        kind: SavingsGoalKind.product,
        name: 'AirPods',
        targetCentavos: 149900,
        startingCentavos: 30000,
        productUrl: 'https://www.walmart.com.mx/ip/airpods/123',
        imageUrl: 'https://images.example.com/airpods.jpg',
        merchantName: 'Walmart México',
      );
      await income(20000);
      await store.saveSavingsGoal(
        id: goal.id,
        kind: SavingsGoalKind.amount,
        name: 'Emergency fund',
        targetCentavos: 500000,
        startingCentavos: 30000,
        productUrl: goal.productUrl,
        imageUrl: goal.imageUrl,
        merchantName: goal.merchantName,
      );
      final current = store.activeSavingsGoal!;
      expect(current.kind, SavingsGoalKind.amount);
      expect(current.productUrl, isNull);
      expect(current.imageUrl, isNull);
      expect(current.merchantName, isNull);
      expect(current.createdAt, goal.createdAt);
      expect(current.excludedIncomeIds, goal.excludedIncomeIds);
      expect(store.savingsGoalProgressCentavos, 50000);
      expect(
        (await SobraStore.load(now: () => now)).activeSavingsGoal!.kind,
        SavingsGoalKind.amount,
      );
    },
  );

  test('schema 12 goals without kind infer either entry path', () async {
    final goal = await create();
    for (final product in [false, true]) {
      final legacy = jsonDecode(store.exportJson()) as Map<String, dynamic>;
      final legacyGoal = legacy['activeSavingsGoal'] as Map<String, dynamic>;
      legacyGoal.remove('kind');
      legacyGoal['productUrl'] = product
          ? 'https://www.example.com/product'
          : null;
      await store.importBackup(jsonEncode(legacy));
      expect(store.activeSavingsGoal!.id, goal.id);
      expect(
        store.activeSavingsGoal!.kind,
        product ? SavingsGoalKind.product : SavingsGoalKind.amount,
      );
      expect(jsonDecode(store.exportJson())['schemaVersion'], 12);
    }
  });

  test(
    'a 100 million won amount goal preserves units and needs no product',
    () async {
      await store.setCurrency(Currency.krw);
      await store.saveSavingsGoal(
        kind: SavingsGoalKind.amount,
        name: '1억 모으기',
        targetCentavos: 10000000000,
        startingCentavos: 2000000000,
      );
      await income(500000000);
      final reloaded = await SobraStore.load(now: () => now);
      expect(reloaded.currency, Currency.krw);
      expect(reloaded.activeSavingsGoal!.kind, SavingsGoalKind.amount);
      expect(reloaded.activeSavingsGoal!.targetCentavos, 10000000000);
      expect(reloaded.activeSavingsGoal!.productUrl, isNull);
      expect(reloaded.activeSavingsGoal!.imageUrl, isNull);
      expect(reloaded.savingsGoalProgressCentavos, 2500000000);
    },
  );

  test('goal mutations never change budget, wallet or XP', () async {
    final balance = (
      store.todayRemainingCentavos,
      store.remainingBudgetCentavos,
      store.expectedCashCentavos,
      store.xpProgress.totalXp,
    );
    void unchanged() => expect((
      store.todayRemainingCentavos,
      store.remainingBudgetCentavos,
      store.expectedCashCentavos,
      store.xpProgress.totalXp,
    ), balance);
    final goal = await create(starting: 40000);
    unchanged();
    await store.saveSavingsGoal(
      id: goal.id,
      name: 'Travel',
      targetCentavos: 500000,
      startingCentavos: 45000,
    );
    unchanged();
    await store.removeSavingsGoal(goal.id);
    unchanged();
    expect(store.activeSavingsGoal, isNull);
  });

  test(
    'baseline excludes existing same-day income; new savings track edits',
    () async {
      final oldSavings = await income(50000);
      final oldCycle = await income(30000, allocation: IncomeAllocation.cycle);
      final goal = await create(starting: 50000);
      expect(goal.excludedIncomeIds, containsAll([oldSavings.id, oldCycle.id]));
      expect(() => goal.excludedIncomeIds.clear(), throwsUnsupportedError);
      expect(store.savingsGoalProgressCentavos, 50000);

      final added = await income(20000);
      await income(9000, occurredAt: DateTime(2026, 11, 8));
      await income(11000, allocation: IncomeAllocation.cycle);
      expect(store.savingsGoalProgressCentavos, 70000);
      await store.updateIncome(
        IncomeEntry(
          id: added.id,
          amountCentavos: 25000,
          kind: added.kind,
          note: added.note,
          occurredAt: added.occurredAt,
          destination: added.destination,
          allocation: added.allocation,
        ),
      );
      expect(store.savingsGoalProgressCentavos, 75000);
      await store.deleteIncome(added.id);
      expect(store.savingsGoalProgressCentavos, 50000);
      await store.restoreIncome(added);
      expect(store.savingsGoalProgressCentavos, 70000);

      // Editing a pre-goal record into savings must not count money already
      // available when the user supplied the starting amount.
      await store.updateIncome(
        IncomeEntry(
          id: oldCycle.id,
          amountCentavos: oldCycle.amountCentavos,
          kind: oldCycle.kind,
          note: oldCycle.note,
          occurredAt: oldCycle.occurredAt,
          destination: oldCycle.destination,
          allocation: IncomeAllocation.savings,
        ),
      );
      expect(store.savingsGoalProgressCentavos, 70000);
    },
  );

  test(
    'editing preserves the baseline and progress survives a new cycle',
    () async {
      await income(9000);
      final goal = await create(starting: 1000);
      final createdAt = goal.createdAt;
      await income(2000);
      now = DateTime(2026, 11, 16, 9);
      await store.refreshForCurrentDate();
      await store.saveSavingsGoal(
        id: goal.id,
        name: 'Edited',
        targetCentavos: 10000,
        startingCentavos: 4000,
        targetDate: DateTime(2026, 12, 1),
      );
      await income(5000);
      expect(store.activeSavingsGoal!.createdAt, createdAt);
      expect(
        store.activeSavingsGoal!.excludedIncomeIds,
        goal.excludedIncomeIds,
      );
      expect(store.savingsGoalProgressCentavos, 11000);
      expect(
        (await SobraStore.load(now: () => now)).savingsGoalProgressCentavos,
        11000,
      );
    },
  );

  test(
    'old and stale forms cannot replace or delete the active goal',
    () async {
      final old = await create();
      await expectLater(create(), throwsStateError);
      await store.removeSavingsGoal(old.id);
      final next = await create();
      expect(next.id, isNot(old.id));
      await expectLater(
        store.saveSavingsGoal(
          id: old.id,
          name: 'Stale',
          targetCentavos: 100,
          startingCentavos: 0,
        ),
        throwsStateError,
      );
      await expectLater(store.removeSavingsGoal(old.id), throwsStateError);
      expect(store.activeSavingsGoal!.id, next.id);
      expect(store.savingsGoalProgressCentavos, 0);
    },
  );

  test(
    'failed creation, edit and removal roll back without notifications',
    () async {
      var notifications = 0;
      store.addListener(() => notifications++);
      disk.failStateWrite = true;
      await expectLater(create(), throwsA(isA<SobraStoreException>()));
      expect(store.activeSavingsGoal, isNull);
      expect(notifications, 0);
      disk.failStateWrite = false;
      final goal = await create(starting: 1000);
      final before = store.exportJson();
      notifications = 0;
      disk.failStateWrite = true;
      await expectLater(
        store.saveSavingsGoal(
          id: goal.id,
          name: 'Failed edit',
          targetCentavos: 200000,
          startingCentavos: 4000,
        ),
        throwsA(isA<SobraStoreException>()),
      );
      expect(store.exportJson(), before);
      await expectLater(
        store.removeSavingsGoal(goal.id),
        throwsA(isA<SobraStoreException>()),
      );
      expect(store.exportJson(), before);
      expect(notifications, 0);
      disk.failStateWrite = false;
      await store.removeSavingsGoal(goal.id);
      expect((await SobraStore.load(now: () => now)).activeSavingsGoal, isNull);
    },
  );

  test(
    'legacy backups without a goal still load and explicitly clear one',
    () async {
      final legacy = jsonDecode(store.exportJson()) as Map<String, dynamic>;
      legacy.remove('activeSavingsGoal');
      legacy['schemaVersion'] = 11;
      await create();
      await store.importBackup(jsonEncode(legacy));
      expect(store.activeSavingsGoal, isNull);
      expect(store.savingsGoalProgressCentavos, 0);
      expect(store.hasStorageError, isFalse);
    },
  );

  test('invalid model values fail without modifying a saved goal', () async {
    final goal = await create();
    final before = store.exportJson();
    final values = <Map<String, Object?>>[
      {'name': '   '},
      {'name': 'a' * 61},
      {'targetCentavos': 0},
      {'targetCentavos': SavingsGoal.maxAmountCentavos + 1},
      {'startingCentavos': -1},
      {'startingCentavos': SavingsGoal.maxAmountCentavos + 1},
      {'productUrl': 'javascript:alert(1)'},
      {'imageUrl': 'https://127.0.0.1/image.png'},
      {'targetDate': DateTime(2026, 11, 8)},
    ];
    for (final changes in values) {
      await expectLater(
        store.saveSavingsGoal(
          id: goal.id,
          kind: SavingsGoalKind.product,
          name: changes['name'] as String? ?? 'AirPods',
          targetCentavos: changes['targetCentavos'] as int? ?? 149900,
          startingCentavos: changes['startingCentavos'] as int? ?? 0,
          productUrl: changes['productUrl'] as String?,
          imageUrl: changes['imageUrl'] as String?,
          targetDate: changes['targetDate'] as DateTime?,
        ),
        throwsArgumentError,
        reason: '$changes',
      );
      expect(store.exportJson(), before);
    }
  });

  test('malformed goal backups do not replace current data', () async {
    final goal = await create();
    final before = store.exportJson();
    for (final change in <void Function(Map<String, dynamic>)>[
      (g) => g['kind'] = 'unknown',
      (g) => g['kind'] = null,
      (g) => g['kind'] = 1,
      (g) => g['productUrl'] = 'https://www.example.com/product',
      (g) => g['targetCentavos'] = 1.5,
      (g) => g['createdAt'] = '2026-02-31T10:00:00',
      (g) => g['targetDate'] = 'invalid',
      (g) => g['excludedIncomeIds'] = ['a', 'a'],
      (g) => g['excludedIncomeIds'] = [3],
      (g) => g.remove('excludedIncomeIds'),
      (g) => g['imageUrl'] = 'file:///private/data',
    ]) {
      final incoming = jsonDecode(before) as Map<String, dynamic>;
      change(incoming['activeSavingsGoal'] as Map<String, dynamic>);
      await expectLater(
        store.importBackup(jsonEncode(incoming)),
        throwsFormatException,
      );
      expect(store.activeSavingsGoal!.id, goal.id);
      expect(store.exportJson(), before);
    }
  });

  test('product links accept ordinary HTTPS URLs only', () {
    for (final url in [
      'https://www.amazon.com.mx/dp/ABC?color=white',
      'https://articulo.mercadolibre.com.mx/MLM-123',
      'https://img.ltwebstatic.com/a.jpg',
    ]) {
      expect(SavingsGoal.isSupportedUrl(url), isTrue, reason: url);
    }
    for (final url in [
      'http://example.com/product',
      'https://user:password@example.com/product',
      'https://localhost/product',
      'https://device.local/product',
      'https://127.0.0.1/product',
      'https://[::1]/product',
      'https://example.com:8080/product',
      'file:///tmp/photo.png',
    ]) {
      expect(SavingsGoal.isSupportedUrl(url), isFalse, reason: url);
    }
  });
}
