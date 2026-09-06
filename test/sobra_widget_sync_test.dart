import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sobra_app/models/expense_entry.dart';
import 'package:sobra_app/models/income_entry.dart';
import 'package:sobra_app/models/pay_schedule.dart';
import 'package:sobra_app/services/sobra_widget_sync.dart';
import 'package:sobra_app/state/sobra_store.dart';

void main() {
  test('widget snapshot contains current budget and two newest movements', () async {
    SharedPreferences.setMockInitialValues({});
    final now = DateTime(2026, 9, 5, 12);
    final store = await SobraStore.load(now: () => now);
    await store.configureOnboarding(
      budgetCentavos: 600000,
      schedule: PaySchedule.irregular(
        planningHorizonDays: 15,
        irregularCycleStart: DateTime(2026, 9, 1),
      ),
    );
    await store.completeOnboarding();
    await store.addExpense(
      amountCentavos: 1800,
      category: ExpenseCategory.transport,
      note: 'Metro',
      occurredAt: now.subtract(const Duration(minutes: 2)),
      paymentMethod: PaymentMethod.card,
    );
    await store.addIncome(
      amountCentavos: 25000,
      kind: IncomeKind.extra,
      note: 'Reembolso',
      occurredAt: now.subtract(const Duration(minutes: 1)),
      destination: PaymentMethod.card,
      allocation: IncomeAllocation.savings,
    );

    final snapshot = SobraWidgetSnapshot.fromStore(store);
    final payload = snapshot.toPlatformMap();

    expect(payload['hasData'], isTrue);
    expect(payload['daysRemaining'], 11);
    expect(payload['totalBudgetCentavos'], 600000);
    expect(payload['totalSpentCentavos'], 1800);
    expect(payload['progressSegments'], 1);
    expect(payload['movementCount'], 2);
    expect(payload['movement1Title'], 'Reembolso');
    expect(payload['movement1Kind'], 'income');
    expect(payload['movement2Title'], 'Metro');
    expect(payload['movement2Kind'], 'transport');
  });

  test('the payload carries exactly the keys Android reads', () async {
    // MainActivity.saveWidgetData reads these by name and falls back to 0 or ""
    // for anything missing, so a rename on this side does not fail — the widget
    // just quietly shows zeroes. Pin the contract instead.
    SharedPreferences.setMockInitialValues({});
    final now = DateTime(2026, 9, 5, 12);
    final store = await SobraStore.load(now: () => now);
    await store.configureOnboarding(
      budgetCentavos: 600000,
      schedule: const PaySchedule.semiMonthly(),
    );
    await store.completeOnboarding();
    await store.addExpense(
      amountCentavos: 1800,
      category: ExpenseCategory.transport,
      note: 'Metro',
      occurredAt: now,
      paymentMethod: PaymentMethod.card,
    );

    expect(SobraWidgetSnapshot.fromStore(store).toPlatformMap().keys.toSet(), {
      'hasData',
      'todayRemainingCentavos',
      'daysRemaining',
      'totalBudgetCentavos',
      'totalSpentCentavos',
      'progressSegments',
      'reducedMotion',
      'movementCount',
      'movement1Title',
      'movement1AmountCentavos',
      'movement1Kind',
    });
  });

  test('a fresh install reports no data rather than zeroes', () async {
    SharedPreferences.setMockInitialValues({});
    final store = await SobraStore.load(now: () => DateTime(2026, 9, 5, 12));
    final payload = SobraWidgetSnapshot.fromStore(store).toPlatformMap();

    expect(payload['hasData'], isFalse);
    expect(payload['movementCount'], 0);
  });

  test('an overspent cycle reports a full bar and a negative day', () async {
    SharedPreferences.setMockInitialValues({});
    final now = DateTime(2026, 9, 5, 12);
    final store = await SobraStore.load(now: () => now);
    await store.configureOnboarding(
      budgetCentavos: 600000,
      schedule: const PaySchedule.semiMonthly(),
    );
    await store.completeOnboarding();
    await store.addExpense(
      amountCentavos: 700000,
      category: ExpenseCategory.other,
      note: 'Refrigerador',
      occurredAt: now,
      paymentMethod: PaymentMethod.card,
    );

    final payload = SobraWidgetSnapshot.fromStore(store).toPlatformMap();
    expect(payload['todayRemainingCentavos'], lessThan(0));
    // The bar saturates: 116% and 100% both send 10. The negative amount is
    // the only thing left that says the cycle went over.
    expect(payload['progressSegments'], 10);
  });

  test('snapshot never sends more than two movements', () async {
    SharedPreferences.setMockInitialValues({});
    final now = DateTime(2026, 9, 5, 12);
    final store = await SobraStore.load(now: () => now);
    await store.configureOnboarding(
      budgetCentavos: 600000,
      schedule: const PaySchedule.semiMonthly(),
    );
    for (var index = 0; index < 3; index++) {
      await store.addExpense(
        amountCentavos: 1000 + index,
        category: ExpenseCategory.other,
        note: 'Movimiento $index',
        occurredAt: now.subtract(Duration(minutes: index)),
        paymentMethod: PaymentMethod.card,
      );
    }

    final payload = SobraWidgetSnapshot.fromStore(store).toPlatformMap();
    expect(payload['movementCount'], 2);
    expect(payload, isNot(contains('movement3Title')));
  });
}
