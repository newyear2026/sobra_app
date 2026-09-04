import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sobra_app/models/cash_reconciliation.dart';
import 'package:sobra_app/models/expense_entry.dart';
import 'package:sobra_app/models/income_entry.dart';
import 'package:sobra_app/models/pay_schedule.dart';
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
    expect(store.todayRemainingCentavos, -10000);

    now = DateTime(2026, 9, 5, 8);
    await store.refreshForCurrentDate();
    expect(store.daysRemaining, 11);
    expect(store.dailyAllowanceCentavos, 49090);
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
      throwsArgumentError,
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
