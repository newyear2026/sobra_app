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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late DateTime now;
  late SobraStore store;
  late _Disk disk;
  late DateTime cycleStart;
  late ExpenseEntry expense;

  setUp(() async {
    disk = _Disk();
    SharedPreferencesStorePlatform.instance = disk;
    SharedPreferences.resetStatic();
    now = DateTime(2026, 11, 1, 10);
    store = await SobraStore.load(now: () => now);
    await store.configureOnboarding(
      budgetCentavos: 100000,
      cashCentavos: 50000,
      schedule: const PaySchedule.weekly(weeklyPayDay: DateTime.monday),
    );
    await store.completeOnboarding();
    now = DateTime(2026, 11, 4, 10);
    expense = await store.addExpense(
      amountCentavos: 80000,
      category: ExpenseCategory.food,
      note: '',
      occurredAt: now,
      paymentMethod: PaymentMethod.card,
    );
    now = DateTime(2026, 11, 9, 10);
    await store.settleCycles();
    cycleStart = store.cycleRecords.first.start;
    expect(store.cycleRecords.first.resultCentavos, 20000);
  });
  tearDown(SharedPreferences.resetStatic);

  Future<SavingsGoal> create({
    int target = 100000,
    int starting = 10000,
    String? replacing,
  }) => store.saveSavingsGoal(
    name: 'My goal',
    targetCentavos: target,
    startingCentavos: starting,
    replacingCompletedGoalId: replacing,
  );
  Future<void> allocate(String id, int amount) =>
      store.allocateCycleToSavingsGoal(
        cycleStart: cycleStart,
        goalId: id,
        amountCentavos: amount,
      );
  Future<void> changeExpense(int amount) => store.updateExpense(
    ExpenseEntry(
      id: expense.id,
      amountCentavos: amount,
      category: expense.category,
      note: '',
      occurredAt: expense.occurredAt,
      paymentMethod: expense.paymentMethod,
    ),
  );

  test(
    'allocation is an editable idempotent earmark, never new income',
    () async {
      final goal = await create();
      final before = (
        store.todayRemainingCentavos,
        store.remainingBudgetCentavos,
        store.expectedCashCentavos,
        store.xpProgress.totalXp,
        jsonDecode(store.exportJson())['incomes'].toString(),
      );
      await Future.wait([allocate(goal.id, 10000), allocate(goal.id, 10000)]);
      expect(store.goalAllocationForCycle(cycleStart), 10000);
      expect(store.savingsGoalProgressCentavos, 20000);
      expect(
        jsonDecode(store.exportJson())['goalCycleAllocations'],
        hasLength(1),
      );
      await allocate(goal.id, 15000);
      expect(store.savingsGoalProgressCentavos, 25000);
      expect((
        store.todayRemainingCentavos,
        store.remainingBudgetCentavos,
        store.expectedCashCentavos,
        store.xpProgress.totalXp,
        jsonDecode(store.exportJson())['incomes'].toString(),
      ), before);
      final restored = await SobraStore.load(now: () => now);
      expect(restored.savingsGoalProgressCentavos, 25000);
      expect(restored.pendingSavingsGoalCycle, isNull);
    },
  );

  test(
    'prompt dismissal survives reload and never cascades to old cycles',
    () async {
      expect(store.pendingSavingsGoalCycle?.start, cycleStart);
      await store.acknowledgeSavingsGoalCyclePrompt(cycleStart);
      expect(
        (await SobraStore.load(now: () => now)).pendingSavingsGoalCycle,
        isNull,
      );
      now = DateTime(2026, 11, 23, 10);
      await store.settleCycles();
      final newest = store.cycleRecords.first.start;
      expect(store.pendingSavingsGoalCycle?.start, newest);
      await store.acknowledgeSavingsGoalCyclePrompt(newest);
      expect(store.pendingSavingsGoalCycle, isNull);
      // The older cycle remains available for an explicit history action.
      expect(store.availableGoalAllocationForCycle(cycleStart), 20000);
    },
  );

  test('invalid and stale requests never change records', () async {
    final goal = await create();
    final before = store.exportJson();
    for (final amount in [0, -1, 20001]) {
      await expectLater(allocate(goal.id, amount), throwsArgumentError);
      expect(store.exportJson(), before);
    }
    await expectLater(allocate('stale', 100), throwsStateError);
    await expectLater(
      store.allocateCycleToSavingsGoal(
        cycleStart: DateTime(2026, 11, 9),
        goalId: goal.id,
        amountCentavos: 100,
      ),
      throwsStateError,
    );
    expect(store.exportJson(), before);
    await changeExpense(110000);
    expect(store.availableGoalAllocationForCycle(cycleStart), 0);
    expect(store.pendingSavingsGoalCycle, isNull);
    await expectLater(allocate(goal.id, 100), throwsArgumentError);
  });

  test(
    'late ledger edits adjust effective progress without duplicate money',
    () async {
      final first = await create();
      await allocate(first.id, 10000);
      await store.removeSavingsGoal(first.id);
      final second = await create(starting: 0);
      expect(store.availableGoalAllocationForCycle(cycleStart), 10000);
      await allocate(second.id, 10000);
      await changeExpense(85000);
      expect(store.availableGoalAllocationForCycle(cycleStart), 5000);
      expect(store.goalAllocationForCycle(cycleStart), 5000);
      expect(store.savingsGoalProgressCentavos, 5000);
      await changeExpense(95000);
      expect(store.savingsGoalProgressCentavos, 0);
      await changeExpense(80000);
      expect(store.savingsGoalProgressCentavos, 10000);
      expect(
        (await SobraStore.load(now: () => now)).savingsGoalProgressCentavos,
        10000,
      );
    },
  );

  test(
    'completion acknowledges once and replacement archives atomically',
    () async {
      final first = await create(target: 30000, starting: 10000);
      expect(store.pendingSavingsGoalCompletionId, isNull);
      await allocate(first.id, 20000);
      expect(store.isSavingsGoalComplete, isTrue);
      expect(store.pendingSavingsGoalCompletionId, first.id);
      await store.acknowledgeSavingsGoalCompletion(first.id);
      final completionTime = now;
      expect(
        (await SobraStore.load(now: () => now)).pendingSavingsGoalCompletionId,
        isNull,
      );
      now = now.add(const Duration(hours: 1));
      final newGoal = await create(starting: 0, replacing: first.id);
      expect(newGoal.id, isNot(first.id));
      expect(store.savingsGoalProgressCentavos, 0);
      expect(store.availableGoalAllocationForCycle(cycleStart), 0);
      expect(store.completedSavingsGoals.single.goal.id, first.id);
      expect(store.completedSavingsGoals.single.progressCentavos, 30000);
      expect(store.completedSavingsGoals.single.completedAt, completionTime);
      final backup = store.exportJson();
      await store.importBackup(backup);
      expect(store.completedSavingsGoals.single.goal.id, first.id);
      expect(store.activeSavingsGoal!.id, newGoal.id);
      await expectLater(create(replacing: first.id), throwsStateError);
      await expectLater(create(replacing: newGoal.id), throwsStateError);
    },
  );

  test(
    'new goal baseline excludes savings incomes from completed goal',
    () async {
      final first = await create(target: 20000);
      await store.addIncome(
        amountCentavos: 10000,
        kind: IncomeKind.extra,
        note: '',
        occurredAt: now,
        destination: PaymentMethod.card,
        allocation: IncomeAllocation.savings,
      );
      expect(store.isSavingsGoalComplete, isTrue);
      await create(starting: 0, replacing: first.id);
      expect(store.savingsGoalProgressCentavos, 0);
      await store.addIncome(
        amountCentavos: 5000,
        kind: IncomeKind.extra,
        note: '',
        occurredAt: now,
        destination: PaymentMethod.card,
        allocation: IncomeAllocation.savings,
      );
      expect(store.savingsGoalProgressCentavos, 5000);
    },
  );

  test(
    'failed acknowledgement, allocation, replacement roll back fully',
    () async {
      final first = await create(target: 30000);
      var before = store.exportJson();
      var notices = 0;
      store.addListener(() => notices++);
      disk.fail = true;
      await expectLater(
        store.acknowledgeSavingsGoalCyclePrompt(cycleStart),
        throwsA(isA<SobraStoreException>()),
      );
      await expectLater(
        allocate(first.id, 20000),
        throwsA(isA<SobraStoreException>()),
      );
      expect(store.exportJson(), before);
      expect(notices, 0);
      disk.fail = false;
      await allocate(first.id, 20000);
      before = store.exportJson();
      notices = 0;
      disk.fail = true;
      await expectLater(
        store.acknowledgeSavingsGoalCompletion(first.id),
        throwsA(isA<SobraStoreException>()),
      );
      await expectLater(
        create(replacing: first.id),
        throwsA(isA<SobraStoreException>()),
      );
      expect(store.exportJson(), before);
      expect(store.completedSavingsGoals, isEmpty);
      expect(notices, 0);
    },
  );

  test('malformed allocation and completion backups are rejected', () async {
    final first = await create(target: 30000);
    await allocate(first.id, 20000);
    await store.acknowledgeSavingsGoalCompletion(first.id);
    await create(starting: 0, replacing: first.id);
    final before = store.exportJson();
    for (final mutate in <void Function(Map<String, dynamic>)>[
      (j) => j['goalCycleAllocations'].add(j['goalCycleAllocations'].first),
      (j) => j['goalCycleAllocations'].first['amountCentavos'] = 100001,
      (j) => j['goalCycleAllocations'].first['amountCentavos'] = 0,
      (j) => j['goalCycleAllocations'].first['cycleStart'] = '2026-02-31',
      (j) => j['goalCycleAllocations'].first['cycleStart'] =
          '2026-11-01T00:00:00.000',
      (j) =>
          j['goalPromptedCycleStarts'].add(j['goalPromptedCycleStarts'].first),
      (j) => j['goalCompletionAcknowledgements'].first['completedAt'] =
          '2026-02-31',
      (j) => j['completedSavingsGoals'].first['progressCentavos'] = 29999,
      (j) => j['completedSavingsGoals'].add(j['completedSavingsGoals'].first),
    ]) {
      final json = jsonDecode(before) as Map<String, dynamic>;
      mutate(json);
      await expectLater(
        store.importBackup(jsonEncode(json)),
        throwsFormatException,
      );
      expect(store.exportJson(), before);
    }
  });

  test(
    'fresh start clears allocations, history and acknowledgements',
    () async {
      final first = await create(target: 30000);
      await allocate(first.id, 20000);
      await store.acknowledgeSavingsGoalCompletion(first.id);
      await create(starting: 0, replacing: first.id);
      await store.startFreshAfterCorruption();
      final json = jsonDecode(store.exportJson()) as Map<String, dynamic>;
      expect(store.activeSavingsGoal, isNull);
      expect(store.completedSavingsGoals, isEmpty);
      expect(store.pendingSavingsGoalCycle, isNull);
      expect(store.pendingSavingsGoalCompletionId, isNull);
      for (final key in [
        'goalCycleAllocations',
        'completedSavingsGoals',
        'goalPromptedCycleStarts',
        'goalCompletionAcknowledgements',
      ]) {
        expect(json[key], isEmpty);
      }
    },
  );

  test(
    'duplicate allocations in local storage enter recovery unchanged',
    () async {
      final goal = await create();
      await allocate(goal.id, 10000);
      final json = jsonDecode(store.exportJson()) as Map<String, dynamic>;
      json['goalCycleAllocations'].add(json['goalCycleAllocations'].first);
      final raw = jsonEncode(json);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('sobra_state_v2', raw);
      final restored = await SobraStore.load(now: () => now);
      expect(restored.hasStorageError, isTrue);
      expect(prefs.getString('sobra_state_v2'), raw);
      expect(restored.savingsGoalProgressCentavos, 0);
    },
  );

  test(
    'legacy backups omit all new fields without changing old goal progress',
    () async {
      await create();
      final json = jsonDecode(store.exportJson()) as Map<String, dynamic>;
      for (final key in [
        'goalCycleAllocations',
        'completedSavingsGoals',
        'goalPromptedCycleStarts',
        'goalCompletionAcknowledgements',
      ]) {
        json.remove(key);
      }
      await store.importBackup(jsonEncode(json));
      expect(store.savingsGoalProgressCentavos, 10000);
      expect(store.completedSavingsGoals, isEmpty);
    },
  );
}
