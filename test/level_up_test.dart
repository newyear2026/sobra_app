import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sobra_app/main.dart';
import 'package:sobra_app/models/cash_reconciliation.dart';
import 'package:sobra_app/models/pay_schedule.dart';
import 'package:sobra_app/screens/settlement_screen.dart';
import 'package:sobra_app/state/sobra_store.dart';

import 'support/localizations.dart';

/// A store frozen at [start] whose clock the test can move forward.
Future<(SobraStore, void Function(DateTime))> _storeAt(DateTime start) async {
  SharedPreferences.setMockInitialValues({});
  var now = start;
  final store = await SobraStore.load(now: () => now);
  await store.configureOnboarding(
    budgetCentavos: 700000,
    schedule: const PaySchedule.weekly(),
    cashCentavos: 200000,
  );
  await store.completeOnboarding();
  return (store, (DateTime next) => now = next);
}

void main() {
  test('cash count that crosses a level reports the new level', () async {
    var day = DateTime(2026, 9, 2, 10);
    final (store, setNow) = await _storeAt(day);

    // Five weekly counts at 25 XP each stop just short of level 2 (150 XP).
    for (var week = 0; week < 5; week++) {
      await store.reconcileCashCount(
        actualCentavos: 200000,
        resolution: CashResolution.correction,
      );
      expect(store.takePendingXpNotice()?.newLevel, isNull);
      day = day.add(const Duration(days: 7));
      setNow(day);
    }
    expect(store.totalXp, 125);

    // The sixth count lands exactly on the boundary.
    await store.reconcileCashCount(
      actualCentavos: 200000,
      resolution: CashResolution.correction,
    );
    final notice = store.takePendingXpNotice();
    expect(notice?.xp, 25);
    expect(notice?.newLevel, 2);
    expect(notice?.previousLevel, 1);
    expect(store.xpProgress.level, 2);
  });

  test('settlement that stays within the level leaves newLevel null', () async {
    final start = DateTime(2026, 9, 2, 10);
    final (store, setNow) = await _storeAt(start);

    // One quiet week: the single closed cycle cannot reach 150 XP.
    setNow(start.add(const Duration(days: 8)));
    await store.settleCycles();

    final notice = store.pendingXpNotice;
    expect(notice, isNotNull);
    expect(store.xpProgress.level, 1);
    expect(notice!.newLevel, isNull);
  });

  test('settlement that crosses levels reports the level reached', () async {
    final start = DateTime(2026, 9, 2, 10);
    final (store, setNow) = await _storeAt(start);

    // Ten quiet weeks close at once; the accumulated XP jumps levels.
    setNow(start.add(const Duration(days: 70)));
    await store.settleCycles();

    final notice = store.pendingXpNotice;
    expect(notice, isNotNull);
    expect(store.xpProgress.level, greaterThan(1));
    expect(notice!.newLevel, store.xpProgress.level);
  });

  testWidgets('level-up shows the celebration card once', (tester) async {
    useSpanishDevice(tester);
    tester.view.physicalSize = const Size(520, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final start = DateTime(2026, 9, 2, 10);
    final (store, setNow) = await _storeAt(start);
    setNow(start.add(const Duration(days: 70)));
    await store.settleCycles();
    await store.setReducedMotion(true);
    final level = store.xpProgress.level;
    expect(store.pendingXpNotice?.newLevel, level);

    await tester.pumpWidget(SobraApp(store: store));
    await tester.pumpAndSettle();

    expect(find.text('¡NIVEL $level!'), findsOneWidget);
    expect(find.textContaining('objetos nuevos desbloqueados'), findsOneWidget);
    expect(find.textContaining('Objeto 7'), findsOneWidget);
    expect(find.text('Seguir'), findsOneWidget);
    // The notice is consumed: the card is a one-time moment.
    expect(store.pendingXpNotice, isNull);

    await tester.tap(find.text('Seguir'));
    await tester.pumpAndSettle();
    expect(find.text('¡NIVEL $level!'), findsNothing);
    expect(find.byType(SettlementScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a closed cycle opens the settlement screen, not a snackbar', (
    tester,
  ) async {
    useSpanishDevice(tester);
    tester.view.physicalSize = const Size(520, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final start = DateTime(2026, 9, 2, 10);
    final (store, setNow) = await _storeAt(start);
    setNow(start.add(const Duration(days: 8)));
    await store.settleCycles();
    await store.setReducedMotion(true);
    expect(store.pendingXpNotice, isNotNull);
    expect(store.pendingXpNotice!.newLevel, isNull);

    await tester.pumpWidget(SobraApp(store: store));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(SettlementScreen), findsOneWidget);
    expect(find.text('Cierre de este ciclo'), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
    expect(find.text('Seguir'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a cash count that levels up celebrates on Inicio', (
    tester,
  ) async {
    useSpanishDevice(tester);
    tester.view.physicalSize = const Size(520, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var day = DateTime(2026, 9, 2, 10);
    final (store, setNow) = await _storeAt(day);
    for (var week = 0; week < 5; week++) {
      await store.reconcileCashCount(
        actualCentavos: 200000,
        resolution: CashResolution.correction,
      );
      store.takePendingXpNotice();
      day = day.add(const Duration(days: 7));
      setNow(day);
    }
    await store.setReducedMotion(true);
    expect(store.totalXp, 125);

    await tester.pumpWidget(SobraApp(store: store));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Efectivo estimado'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '2000');
    await tester.pump();
    await tester.tap(find.text('Guardar conteo'));
    await tester.pumpAndSettle();

    expect(find.text('¡NIVEL 2!'), findsOneWidget);
    expect(find.text('¡Nuevo objeto desbloqueado!'), findsOneWidget);
    expect(find.textContaining('Objeto 7'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
