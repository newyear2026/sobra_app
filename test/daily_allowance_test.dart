import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sobra_app/main.dart';
import 'package:sobra_app/models/expense_entry.dart';
import 'package:sobra_app/models/pay_schedule.dart';
import 'package:sobra_app/state/sobra_store.dart';

import 'support/localizations.dart';

/// Sep 8 2026 sits in the Aug 31 – Sep 14 half of a semi-monthly schedule,
/// so seven days are left counting today.
final _now = DateTime(2026, 9, 8, 12);

Future<SobraStore> _storeSpending({required DateTime on}) async {
  SharedPreferences.setMockInitialValues({});
  final store = await SobraStore.load(now: () => _now);
  await store.configureOnboarding(
    budgetCentavos: 900000,
    schedule: const PaySchedule.semiMonthly(),
  );
  await store.completeOnboarding();
  await store.setReducedMotion(true);
  await store.addExpense(
    amountCentavos: 100000,
    category: ExpenseCategory.transport,
    note: 'Transporte',
    occurredAt: on,
    paymentMethod: PaymentMethod.cash,
  );
  return store;
}

void main() {
  test('the cycle balance is the same whichever day the money left', () async {
    for (final day in [DateTime(2026, 9, 7, 12), _now]) {
      final store = await _storeSpending(on: day);
      expect(store.daysRemaining, 7);
      expect(store.remainingBudgetCentavos, 800000);
    }
  });

  test('a spend from an earlier day only reshapes the daily slice', () async {
    final store = await _storeSpending(on: DateTime(2026, 9, 7, 12));

    expect(store.spentTodayCentavos, 0);
    expect(store.spentBeforeTodayCentavos, 100000);
    // 9,000 − 1,000 already gone, spread over the seven days left.
    expect(store.dailyAllowanceCentavos, 114285);
    // Nothing has been spent today, so the whole slice is still there and the
    // headline necessarily repeats the limit under it.
    expect(store.todayRemainingCentavos, store.dailyAllowanceCentavos);
  });

  test('a spend from today comes off today', () async {
    final store = await _storeSpending(on: _now);

    expect(store.spentTodayCentavos, 100000);
    expect(store.spentBeforeTodayCentavos, 0);
    // Nothing was gone at the start of the day, so the slice is 9,000 / 7.
    expect(store.dailyAllowanceCentavos, 128571);
    expect(store.todayRemainingCentavos, 28571);
  });

  testWidgets('Inicio reads back the earlier-day case exactly', (tester) async {
    useSpanishDevice(tester);
    final store = await _storeSpending(on: DateTime(2026, 9, 7, 12));
    await tester.pumpWidget(SobraApp(store: store));
    await tester.pump();

    expect(find.text('Hoy te queda'), findsOneWidget);
    expect(find.text('\$1,142.85 MXN'), findsOneWidget);
    expect(
      find.text('Límite de hoy \$1,142.85 · Quedan \$8,000 en el ciclo'),
      findsOneWidget,
    );
  });

  testWidgets('Inicio reads back the today case exactly', (tester) async {
    useSpanishDevice(tester);
    final store = await _storeSpending(on: _now);
    await tester.pumpWidget(SobraApp(store: store));
    await tester.pump();

    expect(find.text('\$285.71 MXN'), findsOneWidget);
    expect(
      find.text('Límite de hoy \$1,285.71 · Quedan \$8,000 en el ciclo'),
      findsOneWidget,
    );
  });
}
