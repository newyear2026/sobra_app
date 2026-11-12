import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:sobra_app/models/expense_entry.dart';
import 'package:sobra_app/models/income_entry.dart';
import 'package:sobra_app/models/pay_schedule.dart';
import 'package:sobra_app/models/savings_goal.dart';
import 'package:sobra_app/models/store_failure.dart';
import 'package:sobra_app/state/sobra_store.dart';

class _Disk extends InMemorySharedPreferencesStore {
  _Disk() : super.empty();
  bool fail = false;
  @override
  Future<bool> setValue(String type, String key, Object value) =>
      fail && key == 'flutter.sobra_state_v2'
      ? Future.value(false)
      : super.setValue(type, key, value);
}

class _Fixture {
  DateTime now = DateTime(2026, 11, 2, 10);
  late SobraStore store;
  late IncomeEntry income;
  late SavingsGoal goal;
  final start = DateTime(2026, 11, 2);

  Future<void> init({bool allocate = true}) async {
    store = await SobraStore.load(now: () => now);
    await store.configureOnboarding(
      budgetCentavos: 100000,
      cashCentavos: 0,
      schedule: const PaySchedule.weekly(weeklyPayDay: DateTime.monday),
    );
    await store.completeOnboarding();
    goal = await store.saveSavingsGoal(
      name: 'Goal', targetCentavos: 1000000, startingCentavos: 0,
    );
    now = DateTime(2026, 11, 3, 10);
    income = await store.addIncome(
      amountCentavos: 20000, kind: IncomeKind.extra, note: '', occurredAt: now,
      destination: PaymentMethod.card, allocation: IncomeAllocation.cycle,
    );
    await store.addExpense(
      amountCentavos: 100000, category: ExpenseCategory.food, note: '',
      occurredAt: now, paymentMethod: PaymentMethod.card,
    );
    now = DateTime(2026, 11, 9, 10);
    await store.settleCycles();
    expect(store.cycleRecords.first.budgetCentavos, 120000);
    expect(store.cycleRecords.first.resultCentavos, 20000);
    if (allocate) {
      await store.allocateCycleToSavingsGoal(
        cycleStart: start, goalId: goal.id, amountCentavos: 20000,
      );
    }
  }

  IncomeEntry edited({int? amount, DateTime? at, IncomeAllocation? allocation}) =>
      IncomeEntry(
        id: income.id, amountCentavos: amount ?? income.amountCentavos,
        kind: income.kind, note: '', occurredAt: at ?? income.occurredAt,
        destination: income.destination, allocation: allocation ?? income.allocation,
      );

  Map<String, dynamic> json() => jsonDecode(store.exportJson()) as Map<String, dynamic>;
  Object baseline() => json()['goalCycleIncomeBaselines'];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _Disk disk;
  late _Fixture fixture;
  setUp(() async {
    disk = _Disk();
    SharedPreferencesStorePlatform.instance = disk;
    SharedPreferences.resetStatic();
    fixture = _Fixture();
    await fixture.init();
  });
  tearDown(SharedPreferences.resetStatic);

  test('closed-cycle income switched to savings is counted only once', () async {
    final store = fixture.store;
    expect(store.savingsGoalProgressCentavos, 20000);
    await store.updateIncome(fixture.edited(allocation: IncomeAllocation.savings));
    expect(store.savingsGoalProgressCentavos, 20000);
    expect(store.goalAllocationForCycle(fixture.start), 0);
    expect(store.cycleRecords.first.budgetCentavos, 120000);
    expect(store.cycleRecords.first.resultCentavos, 20000);
    await store.updateIncome(fixture.income);
    expect(store.goalAllocationForCycle(fixture.start), 20000);
    expect(store.savingsGoalProgressCentavos, 20000);
  });

  test('decrease or increase follows only the originally funded amount', () async {
    final store = fixture.store;
    final baseline = fixture.baseline();
    await store.updateIncome(fixture.edited(amount: 10000));
    expect(store.savingsGoalProgressCentavos, 10000);
    await store.updateIncome(fixture.edited(amount: 40000));
    expect(store.savingsGoalProgressCentavos, 20000);
    expect(store.availableGoalAllocationForCycle(fixture.start), 20000);
    expect(fixture.baseline(), baseline);
  });

  test('deleting then undoing income restores the original earmark', () async {
    final store = fixture.store;
    await store.deleteIncome(fixture.income.id);
    expect(store.savingsGoalProgressCentavos, 0);
    expect(store.availableGoalAllocationForCycle(fixture.start), 0);
    await store.restoreIncome(fixture.income);
    expect(store.savingsGoalProgressCentavos, 20000);
  });

  test('moving income between cycles cannot fund both cycles', () async {
    final store = fixture.store;
    await store.updateIncome(fixture.edited(at: DateTime(2026, 11, 9)));
    expect(store.savingsGoalProgressCentavos, 0);
    expect(store.availableGoalAllocationForCycle(fixture.start), 0);
    await store.updateIncome(fixture.edited(at: DateTime(2026, 11, 7)));
    expect(store.savingsGoalProgressCentavos, 20000);
  });

  test('late new income never enlarges the closed-cycle limit', () async {
    final store = fixture.store;
    await store.addIncome(
      amountCentavos: 50000, kind: IncomeKind.extra, note: '',
      occurredAt: DateTime(2026, 11, 4), destination: PaymentMethod.card,
      allocation: IncomeAllocation.cycle,
    );
    expect(store.availableGoalAllocationForCycle(fixture.start), 20000);
    expect(store.savingsGoalProgressCentavos, 20000);
  });

  test('baseline survives edits, reload and backup without rebasing', () async {
    final baseline = fixture.baseline();
    await fixture.store.updateIncome(fixture.edited(amount: 10000));
    final reloaded = await SobraStore.load(now: () => fixture.now);
    expect(reloaded.savingsGoalProgressCentavos, 10000);
    final backup = reloaded.exportJson();
    await reloaded.importBackup(backup);
    expect(reloaded.savingsGoalProgressCentavos, 10000);
    expect(jsonDecode(reloaded.exportJson())['goalCycleIncomeBaselines'], baseline);
  });

  test('legacy migration is persisted once before later income changes', () async {
    final old = fixture.json()..remove('goalCycleIncomeBaselines');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('sobra_state_v2', jsonEncode(old));
    final migrated = await SobraStore.load(now: () => fixture.now);
    final persisted = jsonDecode(prefs.getString('sobra_state_v2')!);
    expect(persisted['goalCycleIncomeBaselines'], isNotEmpty);
    await migrated.updateIncome(fixture.edited(amount: 10000));
    expect(migrated.savingsGoalProgressCentavos, 10000);
    expect((await SobraStore.load(now: () => fixture.now)).savingsGoalProgressCentavos, 10000);
  });

  test('migration write failure keeps readable ledger and retries atomically', () async {
    final old = fixture.json()..remove('goalCycleIncomeBaselines');
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(old);
    await prefs.setString('sobra_state_v2', raw);
    disk.fail = true;
    final migrated = await SobraStore.load(now: () => fixture.now);
    expect(migrated.hasStorageError, isFalse);
    expect(migrated.savingsGoalProgressCentavos, 20000);
    // Read the platform store itself: SharedPreferences caches a value even
    // when the platform write fails, so `prefs` would show the unsaved state.
    expect((await disk.getAll())['flutter.sobra_state_v2'], raw);
    await expectLater(
      migrated.updateIncome(fixture.edited(allocation: IncomeAllocation.savings)),
      throwsA(isA<SobraStoreException>()),
    );
    expect(migrated.savingsGoalProgressCentavos, 20000);
    disk.fail = false;
    await migrated.updateIncome(fixture.edited(allocation: IncomeAllocation.savings));
    expect(migrated.savingsGoalProgressCentavos, 20000);
    expect(migrated.goalAllocationForCycle(fixture.start), 0);
    final reloaded = await SobraStore.load(now: () => fixture.now);
    expect(reloaded.savingsGoalProgressCentavos, 20000);
    expect(reloaded.goalAllocationForCycle(fixture.start), 0);
  });

  test('failed income correction rolls baseline and progress back', () async {
    final before = fixture.store.exportJson();
    disk.fail = true;
    await expectLater(
      fixture.store.updateIncome(fixture.edited(amount: 10000)),
      throwsA(isA<SobraStoreException>()),
    );
    expect(fixture.store.exportJson(), before);
    disk.fail = false;
    await fixture.store.updateIncome(fixture.edited(amount: 10000));
    expect(fixture.store.savingsGoalProgressCentavos, 10000);
  });

  test('corrections cannot release reservations made for another goal', () async {
    final store = fixture.store;
    await store.allocateCycleToSavingsGoal(
      cycleStart: fixture.start, goalId: fixture.goal.id, amountCentavos: 10000,
    );
    await store.removeSavingsGoal(fixture.goal.id);
    final second = await store.saveSavingsGoal(name: 'Second', targetCentavos: 100000, startingCentavos: 0);
    await store.allocateCycleToSavingsGoal(cycleStart: fixture.start, goalId: second.id, amountCentavos: 10000);
    await store.updateIncome(fixture.edited(amount: 15000));
    expect(store.savingsGoalProgressCentavos, 5000);
    await store.updateIncome(fixture.edited(amount: 5000));
    expect(store.savingsGoalProgressCentavos, 0);
  });

  test('zero adjusted leftover never queues an unusable cycle popup', () async {
    final second = _Fixture();
    // This is a fresh isolated store with no allocation or prompt ack.
    SharedPreferences.setMockInitialValues({});
    await second.init(allocate: false);
    expect(second.store.pendingSavingsGoalCycle, isNotNull);
    await second.store.updateIncome(second.edited(allocation: IncomeAllocation.savings));
    expect(second.store.availableGoalAllocationForCycle(second.start), 0);
    expect(second.store.pendingSavingsGoalCycle, isNull);
  });

  test('malformed baselines are rejected without changing the ledger', () async {
    final before = fixture.store.exportJson();
    for (final mutate in <void Function(Map<String, dynamic>)>[
      (j) => j['goalCycleIncomeBaselines'].add(j['goalCycleIncomeBaselines'].first),
      (j) => j['goalCycleIncomeBaselines'].clear(),
      (j) => j['goalCycleIncomeBaselines'].first['cycleStart'] = '2026-02-31',
      (j) => j['goalCycleIncomeBaselines'].first['cycleStart'] = '2026-10-01',
      (j) => j['goalCycleIncomeBaselines'].first['incomes'][fixture.income.id] = -1,
      (j) => j['goalCycleIncomeBaselines'].first['incomes'][fixture.income.id] = 1.5,
      (j) => j['goalCycleIncomeBaselines'].first['incomes'][fixture.goal.id] = 100,
    ]) {
      final edited = jsonDecode(before) as Map<String, dynamic>;
      mutate(edited);
      await expectLater(fixture.store.importBackup(jsonEncode(edited)), throwsFormatException);
      expect(fixture.store.exportJson(), before);
    }
  });

  test('fresh start clears baseline records', () async {
    await fixture.store.startFreshAfterCorruption();
    expect(fixture.json()['goalCycleIncomeBaselines'], isEmpty);
  });
}
