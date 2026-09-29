import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sobra_app/l10n/generated/app_localizations.dart';
import 'package:sobra_app/l10n/labels.dart';
import 'package:sobra_app/main.dart';
import 'package:sobra_app/models/expense_entry.dart';
import 'package:sobra_app/models/pay_schedule.dart';
import 'package:sobra_app/state/sobra_store.dart';

import 'support/localizations.dart';

/// The cat animations never stop, so `pumpAndSettle` would time out here.
/// Pump a run of real frames instead: the crash this file guards against only
/// shows up while the dialog route is animating out, which a single long pump
/// would skip straight past.
Future<void> frames(WidgetTester tester, [int count = 40]) async {
  for (var i = 0; i < count; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

Future<SobraStore> _openBudgetTab(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  final now = DateTime(2026, 9, 4, 10);
  final store = await SobraStore.load(now: () => now);
  await store.configureOnboarding(
    budgetCentavos: 600000,
    schedule: const PaySchedule.semiMonthly(),
  );
  await store.completeOnboarding();

  await tester.pumpWidget(SobraApp(store: store));
  await frames(tester);
  await tester.tap(find.text('Presup.'));
  await frames(tester);
  expect(find.text('Total del ciclo'), findsOneWidget);
  return store;
}

void main() {
  testWidgets('editing the cycle total survives the dialog closing', (
    tester,
  ) async {
    useSpanishDevice(tester);
    final store = await _openBudgetTab(tester);

    await tester.tap(find.byIcon(Icons.edit).first);
    await frames(tester);
    expect(find.text('Presupuesto total'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '8000');
    await frames(tester, 5);
    await tester.tap(find.text('Guardar'));
    await frames(tester);

    expect(find.text('Cambiaste tu presupuesto'), findsOneWidget);
    await tester.tap(find.text('Ajustarlos proporcionalmente'));
    await frames(tester);

    expect(store.totalBudgetCentavos, 800000);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeping the category limits leaves them untouched', (
    tester,
  ) async {
    useSpanishDevice(tester);
    final store = await _openBudgetTab(tester);
    final before = Map.of(store.categoryLimits);

    await tester.tap(find.byIcon(Icons.edit).first);
    await frames(tester);
    await tester.enterText(find.byType(TextField), '7000');
    await frames(tester, 5);
    await tester.tap(find.text('Guardar'));
    await frames(tester);
    await tester.tap(find.text('Conservarlos'));
    await frames(tester);

    expect(store.totalBudgetCentavos, 700000);
    expect(store.categoryLimits, before);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cancelling the amount dialog changes nothing', (tester) async {
    useSpanishDevice(tester);
    final store = await _openBudgetTab(tester);

    await tester.tap(find.byIcon(Icons.edit).first);
    await frames(tester);
    await tester.enterText(find.byType(TextField), '9999');
    await frames(tester, 5);
    await tester.tap(find.text('Cancelar'));
    await frames(tester);

    expect(find.text('Cambiaste tu presupuesto'), findsNothing);
    expect(store.totalBudgetCentavos, 600000);
    expect(tester.takeException(), isNull);
  });

  testWidgets('editing a category limit survives the dialog closing', (
    tester,
  ) async {
    useSpanishDevice(tester);
    final store = await _openBudgetTab(tester);

    // The first edit icon is the cycle total; the next one is Comida, which
    // sits below the fixed-expense section and has to be scrolled to.
    await tester.ensureVisible(find.byIcon(Icons.edit).at(1));
    await frames(tester);
    await tester.tap(find.byIcon(Icons.edit).at(1));
    await frames(tester);
    expect(
      find.text(
        'Límite de '
        '${ExpenseCategory.food.label(lookupAppLocalizations(const Locale('es')))}',
      ),
      findsOneWidget,
    );

    await tester.enterText(find.byType(TextField), '2500');
    await frames(tester, 5);
    await tester.tap(find.text('Guardar'));
    await frames(tester);

    expect(store.categoryLimits[ExpenseCategory.food], 250000);
    expect(tester.takeException(), isNull);
  });
}
