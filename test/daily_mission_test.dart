import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sobra_app/main.dart';
import 'package:sobra_app/models/daily_mission.dart';
import 'package:sobra_app/models/expense_entry.dart';
import 'package:sobra_app/models/income_entry.dart';
import 'package:sobra_app/models/pay_schedule.dart';
import 'package:sobra_app/models/xp_event.dart';
import 'package:sobra_app/state/sobra_store.dart';

import 'support/localizations.dart';

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
  test('recording today completes record and same-day missions once', () async {
    final start = DateTime(2026, 9, 8, 14, 20);
    final (store, _) = await _storeAt(start);

    await store.addExpense(
      amountCentavos: 4500,
      category: ExpenseCategory.food,
      note: '',
      occurredAt: start,
      paymentMethod: PaymentMethod.cash,
    );

    expect(store.dailyMissions.completedCount, 2);
    expect(store.dailyMissions.earnedXp, 15);
    expect(
      store.xpEvents.map((event) => event.kind),
      containsAll({
        XpEventKind.dailyMissionRecord,
        XpEventKind.dailyMissionSameDay,
      }),
    );
    final notice = store.takePendingXpNotice();
    expect(notice?.kind, XpNoticeKind.missionCompleted);
    expect(notice?.xp, 15);
    expect(notice?.missionCount, 2);

    await store.addExpense(
      amountCentavos: 2000,
      category: ExpenseCategory.transport,
      note: '',
      occurredAt: start,
      paymentMethod: PaymentMethod.card,
    );
    expect(store.dailyMissions.earnedXp, 15);
    expect(store.pendingXpNotice, isNull);
  });

  test('a backdated movement completes only the record mission', () async {
    final start = DateTime(2026, 9, 8, 10);
    final (store, _) = await _storeAt(start);

    await store.addIncome(
      amountCentavos: 10000,
      kind: IncomeKind.extra,
      note: '',
      occurredAt: DateTime(2026, 9, 6, 9),
      destination: PaymentMethod.cash,
      allocation: IncomeAllocation.savings,
    );

    final board = store.dailyMissions;
    expect(
      board.missions
          .singleWhere(
            (mission) => mission.kind == DailyMissionKind.recordMovement,
          )
          .isDone,
      isTrue,
    );
    expect(
      board.missions
          .singleWhere((mission) => mission.kind == DailyMissionKind.sameDay)
          .isDone,
      isFalse,
    );
    expect(store.takePendingXpNotice()?.xp, 10);
  });

  test('editing a past expense to today completes both missions', () async {
    final start = DateTime(2026, 9, 8, 10);
    final (store, _) = await _storeAt(start);
    final entry = await store.addExpense(
      amountCentavos: 4500,
      category: ExpenseCategory.food,
      note: '',
      occurredAt: DateTime(2026, 9, 6, 9),
      paymentMethod: PaymentMethod.cash,
    );
    expect(store.dailyMissions.completedCount, 1);
    store.takePendingXpNotice();

    await store.updateExpense(entry.copyWith(occurredAt: start));
    expect(store.dailyMissions.completedCount, 2);
    expect(store.takePendingXpNotice()?.xp, 5);
  });

  test('missions reset with the calendar day', () async {
    final start = DateTime(2026, 9, 8, 10);
    final (store, setNow) = await _storeAt(start);
    await store.addExpense(
      amountCentavos: 1000,
      category: ExpenseCategory.food,
      note: '',
      occurredAt: start,
      paymentMethod: PaymentMethod.cash,
    );
    expect(store.dailyMissions.completedCount, 2);

    setNow(DateTime(2026, 9, 9, 10));
    expect(store.dailyMissions.completedCount, 0);
    expect(store.dailyMissions.earnedXp, 0);
  });

  test('reviewing the budget awards its mission once', () async {
    final (store, _) = await _storeAt(DateTime(2026, 9, 8, 10));
    await store.noteBudgetReviewed();
    expect(
      store.dailyMissions.missions
          .singleWhere(
            (mission) => mission.kind == DailyMissionKind.reviewBudget,
          )
          .isDone,
      isTrue,
    );
    expect(store.takePendingXpNotice()?.xp, 5);

    await store.noteBudgetReviewed();
    expect(store.pendingXpNotice, isNull);
    expect(store.totalXp, 5);
  });

  testWidgets('home footer opens the mission screen; level opens progress', (
    tester,
  ) async {
    useSpanishDevice(tester);
    tester.view.physicalSize = const Size(520, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final (store, _) = await _storeAt(DateTime(2026, 9, 8, 10));
    await store.setReducedMotion(true);

    await tester.pumpWidget(SobraApp(store: store));
    await tester.pumpAndSettle();

    expect(find.text('Misión de hoy'), findsOneWidget);
    expect(find.text('0 de 3 listas'), findsOneWidget);

    await tester.tap(find.text('Michi curioso'));
    await tester.pumpAndSettle();
    expect(find.text('Tu progreso'), findsOneWidget);
    await tester.tap(find.byTooltip('Volver'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Misión de hoy'));
    await tester.pumpAndSettle();
    expect(find.text('Registra un movimiento hoy'), findsWidgets);
    expect(find.text('Anótalo el mismo día'), findsOneWidget);
    expect(find.text('Revisa tu presupuesto'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('opening Presupuesto completes the budget mission', (
    tester,
  ) async {
    useSpanishDevice(tester);
    tester.view.physicalSize = const Size(520, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final (store, _) = await _storeAt(DateTime(2026, 9, 8, 10));
    await store.setReducedMotion(true);

    await tester.pumpWidget(SobraApp(store: store));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Presup.'));
    await tester.pumpAndSettle();

    expect(
      store.dailyMissions.missions
          .singleWhere(
            (mission) => mission.kind == DailyMissionKind.reviewBudget,
          )
          .isDone,
      isTrue,
    );
    expect(find.text('Misión lista'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
