import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sobra_app/models/cash_reconciliation.dart';
import 'package:sobra_app/models/expense_entry.dart';
import 'package:sobra_app/models/income_entry.dart';
import 'package:sobra_app/models/pay_schedule.dart';
import 'package:sobra_app/models/store_failure.dart';
import 'package:sobra_app/state/sobra_store.dart';

void main() {
  late DateTime now;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    now = DateTime(2026, 9, 4, 10, 30, 45);
  });

  Future<SobraStore> loadStore() => SobraStore.load(now: () => now);

  test('pay schedules calculate stable boundaries including month end', () {
    const semiMonthly = PaySchedule.semiMonthly(firstPayDay: 15);
    expect(
      semiMonthly.boundsFor(DateTime(2026, 9, 16)).start,
      DateTime(2026, 9, 15),
    );
    expect(
      semiMonthly.boundsFor(DateTime(2026, 9, 16)).end,
      DateTime(2026, 9, 29),
    );
    expect(
      semiMonthly.boundsFor(DateTime(2026, 9, 30)).start,
      DateTime(2026, 9, 30),
    );
    expect(
      semiMonthly.boundsFor(DateTime(2026, 9, 30)).end,
      DateTime(2026, 10, 14),
    );

    const monthly = PaySchedule.monthly(monthlyPayDay: 31);
    expect(
      monthly.boundsFor(DateTime(2028, 2, 29)).start,
      DateTime(2028, 2, 29),
    );
    expect(monthly.boundsFor(DateTime(2028, 2, 29)).end, DateTime(2028, 3, 30));
  });

  test('daily allowance stays fixed today and recalculates tomorrow', () async {
    final store = await loadStore();
    await store.configureOnboarding(
      budgetCentavos: 600000,
      schedule: PaySchedule.irregular(
        planningHorizonDays: 15,
        irregularCycleStart: DateTime(2026, 9),
      ),
    );
    expect(store.daysRemaining, 12);
    expect(store.dailyAllowanceCentavos, 50000);

    await store.addExpense(
      amountCentavos: 60000,
      category: ExpenseCategory.food,
      note: 'Comida',
      occurredAt: now,
      paymentMethod: PaymentMethod.card,
    );
    expect(store.dailyAllowanceCentavos, 50000);
    // 600 spent against a 500 allowance, but the cycle is still 5,400 up, so
    // the day floors at zero instead of reporting a hole that is not there.
    expect(store.todayRemainingCentavos, 0);

    now = DateTime(2026, 9, 5, 8);
    await store.refreshForCurrentDate();
    expect(store.daysRemaining, 11);
    expect(store.dailyAllowanceCentavos, 49090);
  });

  test(
    'an overspent cycle reports its own deficit, today and tomorrow',
    () async {
      final store = await loadStore();
      await store.configureOnboarding(
        budgetCentavos: 600000,
        schedule: PaySchedule.irregular(
          planningHorizonDays: 15,
          irregularCycleStart: DateTime(2026, 9),
        ),
      );
      await store.addExpense(
        amountCentavos: 800000,
        category: ExpenseCategory.transport,
        note: 'Transporte',
        occurredAt: now,
        paymentMethod: PaymentMethod.cash,
      );

      // Not the 500 allowance minus an 8,000 expense: that subtracts a
      // cycle-level amount from a per-day slice and reads several times worse
      // than the cycle actually is.
      expect(store.remainingBudgetCentavos, -200000);
      expect(store.todayRemainingCentavos, -200000);

      // Nor does it heal overnight, the way spreading the overspend across the
      // days that are left would.
      now = DateTime(2026, 9, 5, 8);
      await store.refreshForCurrentDate();
      expect(store.todayRemainingCentavos, -200000);
    },
  );

  test('irregular planning windows renew continuously', () async {
    final store = await loadStore();
    await store.configureOnboarding(
      budgetCentavos: 700000,
      schedule: PaySchedule.irregular(
        planningHorizonDays: 7,
        irregularCycleStart: DateTime(2026, 9, 1),
      ),
    );
    await store.addExpense(
      amountCentavos: 7000,
      category: ExpenseCategory.food,
      note: 'Ciclo anterior',
      occurredAt: now,
      paymentMethod: PaymentMethod.card,
    );

    now = DateTime(2026, 9, 8, 8);
    await store.refreshForCurrentDate();

    expect(store.cycleStart, DateTime(2026, 9, 8));
    expect(store.cycleEnd, DateTime(2026, 9, 14));
    expect(store.daysRemaining, 7);
    expect(store.totalSpentCentavos, 0);
    expect(store.dailyAllowanceCentavos, 100000);

    now = DateTime(2026, 9, 22, 8);
    await store.refreshForCurrentDate();
    expect(store.cycleStart, DateTime(2026, 9, 22));
    expect(store.cycleEnd, DateTime(2026, 9, 28));
  });

  test('cash shortage is classified in place instead of duplicated', () async {
    final store = await loadStore();
    await store.configureOnboarding(
      budgetCentavos: 600000,
      schedule: const PaySchedule.semiMonthly(),
      cashCentavos: 200000,
    );
    now = DateTime(2026, 9, 4, 11);
    await store.reconcileCashCount(
      actualCentavos: 197000,
      resolution: CashResolution.pending,
    );

    final pending = store.latestPendingCashExpense!;
    expect(store.transactions, hasLength(1));
    expect(store.totalSpentCentavos, 3000);
    expect(pending.isPendingCashAdjustment, isTrue);

    await store.classifyPendingCashExpense(
      expenseId: pending.id,
      category: ExpenseCategory.food,
      note: 'Tacos',
    );
    expect(store.transactions, hasLength(1));
    expect(store.transactions.single.note, 'Tacos');
    expect(store.transactions.single.isPendingCashAdjustment, isFalse);
    expect(store.totalSpentCentavos, 3000);
    expect(store.expectedCashCentavos, 197000);
  });

  test('extra cash can become separately allocated income', () async {
    final store = await loadStore();
    await store.configureOnboarding(
      budgetCentavos: 600000,
      schedule: const PaySchedule.semiMonthly(),
      cashCentavos: 150000,
    );
    now = DateTime(2026, 9, 4, 11);
    await store.reconcileCashCount(
      actualCentavos: 234000,
      resolution: CashResolution.income,
      note: 'Propinas',
      incomeAllocation: IncomeAllocation.cycle,
    );

    expect(store.incomes, hasLength(1));
    expect(store.incomes.single.amountCentavos, 84000);
    expect(store.totalBudgetCentavos, 684000);
    expect(store.expectedCashCentavos, 234000);
  });

  test(
    'cash transfer can reconcile a shortage without spending budget',
    () async {
      final store = await loadStore();
      await store.configureOnboarding(
        budgetCentavos: 600000,
        schedule: const PaySchedule.semiMonthly(),
        cashCentavos: 200000,
      );
      now = DateTime(2026, 9, 4, 11);

      final reconciliation = await store.reconcileCashCount(
        actualCentavos: 170000,
        resolution: CashResolution.transfer,
      );

      expect(store.transactions, isEmpty);
      expect(store.totalSpentCentavos, 0);
      expect(store.totalBudgetCentavos, 600000);
      expect(store.expectedCashCentavos, 170000);
      expect(reconciliation!.differenceCentavos, -30000);
      expect(reconciliation.resolution, CashResolution.transfer);
    },
  );

  test('a downward count correction does not create an expense', () async {
    final store = await loadStore();
    await store.configureOnboarding(
      budgetCentavos: 600000,
      schedule: const PaySchedule.semiMonthly(),
      cashCentavos: 200000,
    );
    now = DateTime(2026, 9, 4, 11);

    await store.reconcileCashCount(
      actualCentavos: 170000,
      resolution: CashResolution.correction,
    );

    expect(store.transactions, isEmpty);
    expect(store.totalSpentCentavos, 0);
    expect(store.expectedCashCentavos, 170000);
  });

  test(
    'cash reconciliation rejects a resolution in the wrong direction',
    () async {
      final store = await loadStore();
      await store.configureOnboarding(
        budgetCentavos: 600000,
        schedule: const PaySchedule.semiMonthly(),
        cashCentavos: 200000,
      );
      now = DateTime(2026, 9, 4, 11);

      await expectLater(
        store.reconcileCashCount(
          actualCentavos: 170000,
          resolution: CashResolution.income,
        ),
        throwsArgumentError,
      );
      await expectLater(
        store.reconcileCashCount(
          actualCentavos: 230000,
          resolution: CashResolution.expense,
        ),
        throwsArgumentError,
      );
    },
  );

  test('cash stays unknown until the first physical count', () async {
    final store = await loadStore();
    await store.configureOnboarding(
      budgetCentavos: 600000,
      schedule: const PaySchedule.semiMonthly(),
    );
    expect(store.hasCashBaseline, isFalse);

    await store.addExpense(
      amountCentavos: 4600,
      category: ExpenseCategory.other,
      note: 'Anterior',
      occurredAt: DateTime(2025, 9, 4, 12),
      paymentMethod: PaymentMethod.cash,
    );
    expect(store.expectedCashCentavos, 0);
    expect(store.hasCashBaseline, isFalse);
  });

  test('future movements are rejected by the store', () async {
    final store = await loadStore();
    await expectLater(
      store.addExpense(
        amountCentavos: 1000,
        category: ExpenseCategory.other,
        note: 'Futuro',
        occurredAt: DateTime(2026, 9, 5),
        paymentMethod: PaymentMethod.card,
      ),
      throwsA(
        isA<SobraStoreException>().having(
          (error) => error.failure,
          'failure',
          StoreFailure.futureMovement,
        ),
      ),
    );
  });

  test('budget change can preserve or recalculate category limits', () async {
    final store = await loadStore();
    await store.configureOnboarding(
      budgetCentavos: 600000,
      schedule: const PaySchedule.semiMonthly(),
    );
    final original = Map.of(store.categoryLimits);

    await store.setTotalBudget(300000);
    expect(store.categoryLimits, original);

    await store.setTotalBudget(300000, adjustCategoryLimits: true);
    expect(store.categoryLimits.values.reduce((a, b) => a + b), 300000);
  });

  test('corrupted storage is preserved and opens recovery state', () async {
    const corrupted = '{"transactions": [broken';
    SharedPreferences.setMockInitialValues({'sobra_state_v2': corrupted});
    final store = await loadStore();
    final preferences = await SharedPreferences.getInstance();

    expect(store.hasStorageError, isTrue);
    expect(store.exportCorruptedJson, corrupted);
    expect(preferences.getString('sobra_state_v2'), corrupted);
  });

  test('a file saved before schedules lands on the new-user cycle', () async {
    // The legacy-restore path used to name its own semi-monthly days, so an
    // old file opened onto a cycle the settings screen cannot display or edit.
    SharedPreferences.setMockInitialValues({
      'sobra_state_v2': jsonEncode({
        'transactions': <Object?>[],
        'totalBudgetCentavos': 600000,
        'countedCashCentavos': 0,
        'expectedCashCentavos': 0,
        'hasCompletedOnboarding': true,
      }),
    });
    final restored = await loadStore();

    SharedPreferences.setMockInitialValues({});
    final fresh = await loadStore();

    expect(restored.paySchedule.type, fresh.paySchedule.type);
    expect(restored.paySchedule.firstPayDay, fresh.paySchedule.firstPayDay);
    expect(restored.paySchedule.secondPayDay, fresh.paySchedule.secondPayDay);
    expect(restored.cycleStart, fresh.cycleStart);
    expect(restored.cycleEnd, fresh.cycleEnd);
  });

  test('a file saved before the budget could be skipped reads as budgeted', () async {
    // The flag is absent from every state written before onboarding could
    // leave the budget unanswered, and those users did answer it. Reading a
    // missing flag as "not set" would blank the figures of everyone who
    // already has a budget.
    SharedPreferences.setMockInitialValues({
      'sobra_state_v2': jsonEncode({
        'transactions': <Object?>[],
        'totalBudgetCentavos': 600000,
        'countedCashCentavos': 0,
        'expectedCashCentavos': 0,
        'hasCompletedOnboarding': true,
      }),
    });

    final restored = await loadStore();

    expect(restored.hasBudget, isTrue);
    expect(restored.totalBudgetCentavos, 600000);
  });

  test('an unanswered budget reports zero rather than a deficit', () async {
    SharedPreferences.setMockInitialValues({
      'sobra_state_v2': jsonEncode({
        'transactions': <Object?>[],
        'totalBudgetCentavos': 600000,
        'hasBudget': false,
        'countedCashCentavos': 0,
        'expectedCashCentavos': 0,
        'hasCompletedOnboarding': true,
      }),
    });
    final store = await loadStore();

    expect(store.hasBudget, isFalse);
    expect(store.todayRemainingCentavos, 0);
    expect(store.remainingBudgetCentavos, 0);
    expect(store.dailyAllowanceCentavos, 0);
    expect(store.budgetProgress, 0);
    expect(store.projectedRemainderCentavos, 0);

    // Spending is what a budget of zero would turn into a growing deficit,
    // and the home screen would then present an overrun to somebody who was
    // never asked to stay under anything.
    await store.addExpense(
      amountCentavos: 12000,
      category: ExpenseCategory.food,
      note: 'Tacos',
      occurredAt: now,
      paymentMethod: PaymentMethod.cash,
    );

    expect(store.totalSpentCentavos, 12000);
    expect(store.todayRemainingCentavos, 0);
    expect(store.remainingBudgetCentavos, 0);
  });

  test('setting a budget answers the question for good', () async {
    SharedPreferences.setMockInitialValues({
      'sobra_state_v2': jsonEncode({
        'transactions': <Object?>[],
        'totalBudgetCentavos': 600000,
        'hasBudget': false,
        'countedCashCentavos': 0,
        'expectedCashCentavos': 0,
        'hasCompletedOnboarding': true,
      }),
    });
    final store = await loadStore();
    expect(store.hasBudget, isFalse);

    await store.setTotalBudget(450000);

    expect(store.hasBudget, isTrue);
    expect(store.totalBudgetCentavos, 450000);
    expect(store.todayRemainingCentavos, greaterThan(0));

    final reopened = await loadStore();
    expect(reopened.hasBudget, isTrue);
  });

  test('income, onboarding choices and completion persist', () async {
    final store = await loadStore();
    await store.configureOnboarding(
      budgetCentavos: 720000,
      schedule: const PaySchedule.weekly(weeklyPayDay: DateTime.friday),
      cashCentavos: 95000,
    );
    await store.addIncome(
      amountCentavos: 10000,
      kind: IncomeKind.extra,
      note: 'Extra',
      occurredAt: now,
      destination: PaymentMethod.card,
      allocation: IncomeAllocation.savings,
    );
    await store.completeOnboarding();

    final restored = await loadStore();
    expect(restored.hasCompletedOnboarding, isTrue);
    expect(restored.paySchedule.type, PayCycleType.weekly);
    expect(restored.countedCashCentavos, 95000);
    expect(restored.incomes.single.note, 'Extra');
  });
}
