import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sobra_app/models/expense_entry.dart';
import 'package:sobra_app/models/pay_schedule.dart';
import 'package:sobra_app/screens/budget_screen.dart';
import 'package:sobra_app/screens/cycle_history_screen.dart';
import 'package:sobra_app/state/sobra_store.dart';
import 'package:sobra_app/theme/app_theme.dart';
import 'package:sobra_app/widgets/pixel_ui.dart';

import 'support/localizations.dart';

void main() {
  late DateTime now;

  /// A store that has lived through a few weekly cycles, spending [perCycle]
  /// on the first tracked day of each so some close green and some do not.
  Future<SobraStore> lived(List<int> perCycle) async {
    SharedPreferences.setMockInitialValues({});
    now = DateTime(2026, 9, 4, 9);
    final store = await SobraStore.load(now: () => now);
    await store.configureOnboarding(
      budgetCentavos: 100000,
      schedule: const PaySchedule.weekly(),
    );
    await store.completeOnboarding();

    for (var i = 0; i < perCycle.length; i++) {
      now = DateTime(2026, 9, 5 + i * 7, 12);
      if (perCycle[i] > 0) {
        await store.addExpense(
          amountCentavos: perCycle[i],
          category: ExpenseCategory.food,
          note: '',
          occurredAt: now,
          paymentMethod: PaymentMethod.cash,
        );
      }
    }
    now = DateTime(2026, 9, 4 + perCycle.length * 7 + 1, 9);
    await store.settleCycles();
    await store.setReducedMotion(true);
    return store;
  }

  Future<void> pump(WidgetTester tester, SobraStore store, Widget home) async {
    await tester.pumpWidget(
      SobraScope(
        store: store,
        child: MaterialApp(
          localizationsDelegates: sobraLocalizationsDelegates,
          supportedLocales: sobraSupportedLocales,
          theme: buildSobraTheme(),
          home: Scaffold(backgroundColor: AppColors.surface, body: home),
        ),
      ),
    );
    await tester.pump();
  }

  group('the history screen', () {
    testWidgets('lists a row per closed cycle, newest first', (tester) async {
      final store = await lived([20000, 260000, 30000]);
      await pump(tester, store, const CycleHistoryScreen());

      expect(store.cycleRecords, hasLength(3));
      expect(find.text('Ciclos anteriores'), findsOneWidget);
      expect(find.textContaining('Presupuesto'), findsNWidgets(3));

      final ranges = tester
          .widgetList<Text>(find.byType(Text))
          .map((text) => text.data)
          .whereType<String>()
          .where((label) => label.contains('–'))
          .toList();
      expect(ranges, hasLength(3));
      expect(ranges.first, '18 sep–24 sep');
      expect(ranges.last, '4 sep–10 sep');
    });

    testWidgets('says how many stayed inside the budget', (tester) async {
      final store = await lived([20000, 260000, 30000]);
      await pump(tester, store, const CycleHistoryScreen());

      expect(find.text('2 de 3 ciclos en verde'), findsOneWidget);
    });

    testWidgets('shows what each cycle had left, or went over by', (
      tester,
    ) async {
      final store = await lived([20000, 260000]);
      await pump(tester, store, const CycleHistoryScreen());

      expect(find.text('+\$800'), findsOneWidget);
      expect(find.text('$minusSign\$1,600'), findsOneWidget);
    });

    // The screen is reachable in principle before anything has closed, so it
    // has to say so rather than render a bare page.
    testWidgets('has something to say with no history at all', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final store = await SobraStore.load(now: () => DateTime(2026, 9, 4));
      await store.configureOnboarding(
        budgetCentavos: 100000,
        schedule: const PaySchedule.weekly(),
      );
      await store.completeOnboarding();

      await pump(tester, store, const CycleHistoryScreen());
      expect(find.text('Aún no se ha cerrado ningún ciclo.'), findsOneWidget);
    });
  });

  group('the budget screen', () {
    testWidgets('offers the history once a cycle has closed', (tester) async {
      final store = await lived([20000, 260000]);
      await pump(tester, store, const BudgetScreen());

      expect(find.byType(CycleHistorySummary), findsOneWidget);
      expect(find.text('1 de 2 ciclos en verde'), findsOneWidget);
    });

    // Keeps the screen from growing a dead card in its first fortnight.
    testWidgets('stays quiet before the first cycle closes', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final store = await SobraStore.load(now: () => DateTime(2026, 9, 4));
      await store.configureOnboarding(
        budgetCentavos: 100000,
        schedule: const PaySchedule.weekly(),
      );
      await store.completeOnboarding();
      await store.setReducedMotion(true);

      await pump(tester, store, const BudgetScreen());
      expect(find.byType(CycleHistorySummary), findsNothing);
    });

    testWidgets('opens the history when tapped', (tester) async {
      final store = await lived([20000, 260000]);
      await pump(tester, store, const BudgetScreen());

      await tester.tap(find.byType(CycleHistorySummary));
      await tester.pumpAndSettle();

      expect(find.byType(CycleHistoryScreen), findsOneWidget);
      expect(find.text('Ciclos anteriores'), findsOneWidget);
    });
  });
}
