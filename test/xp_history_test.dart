import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sobra_app/main.dart';
import 'package:sobra_app/models/cash_reconciliation.dart';
import 'package:sobra_app/models/pay_schedule.dart';
import 'package:sobra_app/screens/xp_history_screen.dart';
import 'package:sobra_app/state/sobra_store.dart';
import 'package:sobra_app/theme/app_theme.dart';

void main() {
  void usePhoneSize(WidgetTester tester) {
    tester.view.physicalSize = const Size(520, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('XP history shows persisted reasons and totals', (tester) async {
    usePhoneSize(tester);
    var now = DateTime(2026, 9, 2, 10);
    SharedPreferences.setMockInitialValues({});
    final store = await SobraStore.load(now: () => now);
    await store.configureOnboarding(
      budgetCentavos: 700000,
      schedule: const PaySchedule.weekly(),
      cashCentavos: 200000,
    );
    await store.completeOnboarding();
    await store.reconcileCashCount(
      actualCentavos: 200000,
      resolution: CashResolution.correction,
    );
    store.takePendingXpNotice();

    await tester.pumpWidget(
      SobraScope(
        store: store,
        child: MaterialApp(
          theme: buildSobraTheme(),
          home: const XpHistoryScreen(),
        ),
      ),
    );

    expect(find.text('Historial de XP'), findsOneWidget);
    expect(find.text('Michi curioso'), findsOneWidget);
    expect(find.text('25 XP totales'), findsOneWidget);
    expect(find.text('Conteo de efectivo'), findsOneWidget);
    expect(find.text('+25 XP'), findsOneWidget);
    expect(find.text('Ver cálculo'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cycle XP rows expose their calculation', (tester) async {
    usePhoneSize(tester);
    var now = DateTime(2026, 9, 1, 9);
    SharedPreferences.setMockInitialValues({});
    final store = await SobraStore.load(now: () => now);
    await store.configureOnboarding(
      budgetCentavos: 700000,
      schedule: PaySchedule.irregular(
        planningHorizonDays: 7,
        irregularCycleStart: DateTime(2026, 9, 1),
      ),
    );
    await store.completeOnboarding();
    now = DateTime(2026, 9, 8, 8);
    await store.settleCycles();
    store.takePendingXpNotice();

    await tester.pumpWidget(
      SobraScope(
        store: store,
        child: MaterialApp(
          theme: buildSobraTheme(),
          home: const XpHistoryScreen(),
        ),
      ),
    );
    await tester.tap(find.text('Ver cálculo').first);
    await tester.pumpAndSettle();

    expect(find.text('Cómo se calculó'), findsOneWidget);
    expect(find.text('Presupuesto'), findsOneWidget);
    expect(find.text('XP acreditado'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('saving an eligible cash count shows immediate XP feedback', (
    tester,
  ) async {
    usePhoneSize(tester);
    final now = DateTime(2026, 9, 2, 10);
    SharedPreferences.setMockInitialValues({});
    final store = await SobraStore.load(now: () => now);
    await store.configureOnboarding(
      budgetCentavos: 700000,
      schedule: const PaySchedule.weekly(),
      cashCentavos: 200000,
    );
    await store.completeOnboarding();

    await tester.pumpWidget(SobraApp(store: store));
    await tester.tap(find.text('Efectivo estimado'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.enterText(find.byType(TextField).first, '2000');
    await tester.pump();
    await tester.tap(find.text('Guardar conteo'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('Conteo de efectivo guardado'), findsOneWidget);
    expect(find.text('+25 XP'), findsOneWidget);
    expect(store.totalXp, 25);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a settlement completed before startup announces its total XP', (
    tester,
  ) async {
    usePhoneSize(tester);
    var now = DateTime(2026, 9, 1, 9);
    SharedPreferences.setMockInitialValues({});
    final store = await SobraStore.load(now: () => now);
    await store.configureOnboarding(
      budgetCentavos: 700000,
      schedule: PaySchedule.irregular(
        planningHorizonDays: 7,
        irregularCycleStart: DateTime(2026, 9, 1),
      ),
    );
    await store.completeOnboarding();
    now = DateTime(2026, 9, 8, 8);
    await store.settleCycles();

    await tester.pumpWidget(SobraApp(store: store));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Ciclo cerrado'), findsOneWidget);
    expect(find.text('+130 XP'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
