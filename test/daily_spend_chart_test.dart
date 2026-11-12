import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sobra_app/models/expense_entry.dart';
import 'package:sobra_app/models/income_entry.dart';
import 'package:sobra_app/models/pay_schedule.dart';
import 'package:sobra_app/screens/transactions_screen.dart';
import 'package:sobra_app/state/sobra_store.dart';
import 'package:sobra_app/theme/app_theme.dart';
import 'package:sobra_app/widgets/pixel_ui.dart';

import 'support/localizations.dart';

ExpenseEntry _on(DateTime day, int amount) => ExpenseEntry(
  id: 'e-${day.day}-$amount',
  amountCentavos: amount,
  category: ExpenseCategory.food,
  note: '',
  occurredAt: day,
  paymentMethod: PaymentMethod.cash,
);

void main() {
  final bounds = CycleBounds(
    start: DateTime(2026, 9, 15),
    end: DateTime(2026, 9, 29),
  );

  group('the days of a cycle', () {
    test('are all there, quiet ones included', () {
      final days = dailySpend(
        bounds: bounds,
        entries: [_on(DateTime(2026, 9, 16, 13), 4200)],
        today: DateTime(2026, 9, 20),
      );
      expect(days, hasLength(15));
      expect(days.first.day, DateTime(2026, 9, 15));
      expect(days.last.day, DateTime(2026, 9, 29));
      expect(days[1].centavos, 4200);
      expect(days[0].centavos, 0);
    });

    test('add up everything spent on the same day', () {
      final days = dailySpend(
        bounds: bounds,
        entries: [
          _on(DateTime(2026, 9, 16, 9), 4200),
          _on(DateTime(2026, 9, 16, 21), 800),
        ],
        today: DateTime(2026, 9, 20),
      );
      expect(days[1].centavos, 5000);
    });

    // The distinction the chart exists to draw: a day that passed without
    // spending is not the same as a day that has not arrived.
    test('tell a quiet day from one that has not happened', () {
      final days = dailySpend(
        bounds: bounds,
        entries: const [],
        today: DateTime(2026, 9, 20),
      );
      final quiet = days.firstWhere((d) => d.day == DateTime(2026, 9, 18));
      final ahead = days.firstWhere((d) => d.day == DateTime(2026, 9, 25));
      expect(quiet.isFuture, isFalse);
      expect(ahead.isFuture, isTrue);
    });

    test('mark today, and only today', () {
      final days = dailySpend(
        bounds: bounds,
        entries: const [],
        today: DateTime(2026, 9, 20, 17, 42),
      );
      expect(days.where((d) => d.isToday), hasLength(1));
      expect(days.firstWhere((d) => d.isToday).day, DateTime(2026, 9, 20));
      expect(days.firstWhere((d) => d.isToday).isFuture, isFalse);
    });

    test('ignore anything dated outside the cycle', () {
      final days = dailySpend(
        bounds: bounds,
        entries: [
          _on(DateTime(2026, 9, 1), 99900),
          _on(DateTime(2026, 10, 5), 99900),
        ],
        today: DateTime(2026, 9, 20),
      );
      expect(days.every((d) => d.centavos == 0), isTrue);
    });

    test('income totals land on the day they came in', () {
      final days = dailyIncome(
        bounds: bounds,
        entries: [
          IncomeEntry(
            id: 'i-1',
            amountCentavos: 300000,
            kind: IncomeKind.extra,
            note: '',
            occurredAt: DateTime(2026, 9, 16, 9),
            destination: PaymentMethod.card,
            allocation: IncomeAllocation.cycle,
          ),
          IncomeEntry(
            id: 'i-2',
            amountCentavos: 50000,
            kind: IncomeKind.salary,
            note: '',
            occurredAt: DateTime(2026, 9, 16, 18),
            destination: PaymentMethod.cash,
            allocation: IncomeAllocation.savings,
          ),
        ],
        today: DateTime(2026, 9, 20),
      );
      expect(days[1].centavos, 350000);
      expect(days[0].centavos, 0);
    });

    test('treat the last day of the cycle as still to come', () {
      final days = dailySpend(
        bounds: bounds,
        entries: const [],
        today: DateTime(2026, 9, 15),
      );
      expect(days.first.isToday, isTrue);
      expect(days.last.isFuture, isTrue);
    });
  });

  group('on the movements screen', () {
    Future<SobraStore> seeded({
      required bool withSpending,
      bool withIncome = false,
    }) async {
      SharedPreferences.setMockInitialValues({});
      var now = DateTime(2026, 9, 15, 9);
      final store = await SobraStore.load(now: () => now);
      await store.configureOnboarding(
        budgetCentavos: 600000,
        schedule: const PaySchedule.semiMonthly(),
      );
      await store.completeOnboarding();
      if (withSpending) {
        for (final day in [16, 18, 19]) {
          now = DateTime(2026, 9, day, 12);
          await store.addExpense(
            amountCentavos: 42000,
            category: ExpenseCategory.food,
            note: '',
            occurredAt: now,
            paymentMethod: PaymentMethod.cash,
          );
        }
      }
      if (withIncome) {
        now = DateTime(2026, 9, 16, 10);
        await store.addIncome(
          amountCentavos: 300000,
          kind: IncomeKind.extra,
          note: '',
          occurredAt: now,
          destination: PaymentMethod.card,
          allocation: IncomeAllocation.cycle,
        );
      }
      now = DateTime(2026, 9, 20, 12);
      await store.refreshForCurrentDate();
      await store.setReducedMotion(true);
      return store;
    }

    Future<void> pump(WidgetTester tester, SobraStore store) async {
      await tester.pumpWidget(
        SobraScope(
          store: store,
          child: MaterialApp(
            localizationsDelegates: sobraLocalizationsDelegates,
            supportedLocales: sobraSupportedLocales,
            theme: buildSobraTheme(),
            home: const Scaffold(body: TransactionsScreen()),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('shows the chart once there is something to draw', (
      tester,
    ) async {
      await pump(tester, await seeded(withSpending: true));

      expect(find.byType(DailySpendChart), findsOneWidget);
      expect(find.text('Gasto por día'), findsOneWidget);
      // 600000 over the 15 days of this quincena.
      expect(find.text('Límite de \$400 al día'), findsOneWidget);
      expect(find.text('15 sep'), findsOneWidget);
      expect(find.text('29 sep'), findsOneWidget);
      expect(find.text('Gasto'), findsOneWidget);
      expect(find.text('Ingreso'), findsOneWidget);
    });

    testWidgets('still draws the cycle before the first expense', (
      tester,
    ) async {
      await pump(tester, await seeded(withSpending: false));

      expect(find.byType(DailySpendChart), findsOneWidget);
      expect(find.text('Gasto por día'), findsOneWidget);
      expect(find.text('Aún no hay gastos'), findsOneWidget);
    });

    testWidgets('draws one bar per day of the cycle', (tester) async {
      await pump(tester, await seeded(withSpending: true));

      final chart = tester.widget<DailySpendChart>(
        find.byType(DailySpendChart),
      );
      expect(chart.days, hasLength(15));
      expect(chart.dailyLimitCentavos, 40000);
      expect(
        chart.days.where((day) => day.centavos > 0).map((day) => day.day),
        [DateTime(2026, 9, 16), DateTime(2026, 9, 18), DateTime(2026, 9, 19)],
      );
    });

    testWidgets('cycle income does not raise the spend chart\'s daily line', (
      tester,
    ) async {
      await pump(tester, await seeded(withSpending: true, withIncome: true));

      final chart = tester.widget<DailySpendChart>(
        find.byType(DailySpendChart),
      );
      expect(
        chart.dailyLimitCentavos,
        40000,
        reason: 'extras belong on the income tab, not this scale',
      );
      expect(find.text('Límite de \$400 al día'), findsOneWidget);
    });

    testWidgets('income tab shows only income, with the cycle total', (
      tester,
    ) async {
      await pump(tester, await seeded(withSpending: true, withIncome: true));

      expect(find.text('Comida'), findsWidgets);
      expect(find.text('Ingreso extra'), findsNothing);

      await tester.tap(find.text('Ingreso'));
      await tester.pump();

      expect(find.text('Ingreso por día'), findsOneWidget);
      expect(find.text('Gasto por día'), findsNothing);
      expect(find.text('Este ciclo \$3,000'), findsOneWidget);
      expect(find.text('Ingreso extra'), findsOneWidget);
      expect(find.text('Comida'), findsNothing);

      final chart = tester.widget<DailySpendChart>(
        find.byType(DailySpendChart),
      );
      expect(chart.dailyLimitCentavos, 0);
      expect(
        chart.days.singleWhere((day) => day.centavos > 0).centavos,
        300000,
      );
    });
  });
}
