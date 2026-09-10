import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sobra_app/models/cash_reconciliation.dart';
import 'package:sobra_app/models/expense_entry.dart';
import 'package:sobra_app/models/pay_schedule.dart';
import 'package:sobra_app/models/xp_event.dart';
import 'package:sobra_app/state/sobra_store.dart';

void main() {
  late DateTime now;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    now = DateTime(2026, 9, 1, 9);
  });

  Future<SobraStore> newUser({
    PaySchedule schedule = const PaySchedule.weekly(),
    int? cashCentavos,
  }) async {
    final store = await SobraStore.load(now: () => now);
    await store.configureOnboarding(
      budgetCentavos: 700000,
      schedule: schedule,
      cashCentavos: cashCentavos,
    );
    await store.completeOnboarding();
    return store;
  }

  // The count week turns over on the day the user picked, which starts as
  // Sunday. Before it was a setting the screen said Sunday while the code
  // counted Monday to Sunday, so the two were a day apart.
  test('a cash count awards XP at most once per count week', () async {
    final store = await newUser(cashCentavos: 200000);
    expect(store.cashCountWeekday, DateTime.sunday);

    now = DateTime(2026, 9, 2, 10);
    await store.reconcileCashCount(
      actualCentavos: 200000,
      resolution: CashResolution.correction,
    );
    expect(store.totalXp, 25);
    expect(store.xpEvents.single.kind, XpEventKind.cashCount);
    expect(store.takePendingXpNotice()?.xp, 25);

    now = DateTime(2026, 9, 5, 10);
    await store.reconcileCashCount(
      actualCentavos: 200000,
      resolution: CashResolution.correction,
    );
    expect(store.totalXp, 25, reason: 'Saturday is still the same count week');
    expect(store.pendingXpNotice, isNull);

    now = DateTime(2026, 9, 6, 10);
    await store.reconcileCashCount(
      actualCentavos: 200000,
      resolution: CashResolution.correction,
    );
    expect(store.totalXp, 50, reason: 'Sunday opens the next one');
    expect(store.xpEvents, hasLength(2));
  });

  test('the count week turns over on the chosen day', () async {
    final store = await newUser(cashCentavos: 200000);
    await store.setCashCountWeekday(DateTime.wednesday);

    // Wednesday 2 September opens a week; Tuesday the 8th still closes it.
    expect(store.cashCountWeekOffset(DateTime(2026, 9, 2)), 0);
    expect(store.cashCountWeekOffset(DateTime(2026, 9, 8)), 6);
    expect(store.cashCountWeekOffset(DateTime(2026, 9, 9)), 0);

    now = DateTime(2026, 9, 3, 10);
    await store.reconcileCashCount(
      actualCentavos: 200000,
      resolution: CashResolution.correction,
    );
    expect(store.totalXp, 25);

    now = DateTime(2026, 9, 8, 10);
    await store.reconcileCashCount(
      actualCentavos: 200000,
      resolution: CashResolution.correction,
    );
    expect(store.totalXp, 25, reason: 'still inside the chosen week');

    now = DateTime(2026, 9, 9, 10);
    await store.reconcileCashCount(
      actualCentavos: 200000,
      resolution: CashResolution.correction,
    );
    expect(store.totalXp, 50);
  });

  test('the chosen count day survives a reload', () async {
    final store = await newUser(cashCentavos: 200000);
    await store.setCashCountWeekday(DateTime.friday);

    final restored = await SobraStore.load(now: () => now);
    expect(restored.cashCountWeekday, DateTime.friday);
  });

  test('a closed weekly cycle settles once and survives a reload', () async {
    final store = await newUser(
      schedule: PaySchedule.irregular(
        planningHorizonDays: 7,
        irregularCycleStart: DateTime(2026, 9, 1),
      ),
    );

    now = DateTime(2026, 9, 8, 8);
    await store.refreshForCurrentDate();

    expect(store.lastSettledCycleEnd, DateTime(2026, 9, 7));
    expect(store.successfulCycles, 1);
    expect(store.totalXp, 130);
    expect(
      store.xpEvents.map((event) => event.kind),
      containsAll({
        XpEventKind.cycleInGreen,
        XpEventKind.daysUnderDailyLimit,
        XpEventKind.firstSuccessfulCycle,
      }),
    );
    expect(
      store.xpEvents
          .singleWhere((event) => event.kind == XpEventKind.cycleInGreen)
          .xp,
      45,
    );
    expect(store.takePendingXpNotice()?.xp, 130);

    await store.settleCycles();
    expect(store.totalXp, 130, reason: 'settling twice must be idempotent');

    final restored = await SobraStore.load(now: () => now);
    expect(restored.totalXp, 130);
    expect(restored.xpEvents, hasLength(3));
    expect(restored.lastSettledCycleEnd, DateTime(2026, 9, 7));
    expect(restored.pendingXpNotice, isNull);
  });

  test(
    'a 15-day successful cycle normalizes its close reward to 100 XP',
    () async {
      final store = await newUser(
        schedule: PaySchedule.irregular(
          planningHorizonDays: 15,
          irregularCycleStart: DateTime(2026, 9, 1),
        ),
      );

      now = DateTime(2026, 9, 16, 8);
      await store.settleCycles();

      final close = store.xpEvents.singleWhere(
        (event) => event.kind == XpEventKind.cycleInGreen,
      );
      expect(close.xp, 100);
      expect(close.budgetCentavos, 700000);
      expect(close.spentCentavos, 0);
      expect(
        store.xpEvents
            .singleWhere(
              (event) => event.kind == XpEventKind.daysUnderDailyLimit,
            )
            .xp,
        75,
      );
    },
  );

  test(
    'an over-budget cycle closes without success or daily-limit XP',
    () async {
      final store = await newUser(
        schedule: PaySchedule.irregular(
          planningHorizonDays: 7,
          irregularCycleStart: DateTime(2026, 9, 1),
        ),
      );
      await store.addExpense(
        amountCentavos: 800000,
        category: ExpenseCategory.food,
        note: 'Gasto grande',
        occurredAt: now,
        paymentMethod: PaymentMethod.card,
      );

      now = DateTime(2026, 9, 8, 8);
      await store.settleCycles();

      expect(
        store.xpEvents.where(
          (event) =>
              event.kind == XpEventKind.cycleInGreen ||
              event.kind == XpEventKind.daysUnderDailyLimit ||
              event.kind == XpEventKind.firstSuccessfulCycle,
        ),
        isEmpty,
      );
      expect(store.successfulCycles, 0);
      expect(store.lastSettledCycleEnd, DateTime(2026, 9, 7));
    },
  );

  test('daily-limit XP reconstructs each start-of-day limit', () async {
    final store = await newUser(
      schedule: PaySchedule.irregular(
        planningHorizonDays: 7,
        irregularCycleStart: DateTime(2026, 9, 1),
      ),
    );
    await store.addExpense(
      amountCentavos: 100000,
      category: ExpenseCategory.food,
      note: 'Día exacto',
      occurredAt: now,
      paymentMethod: PaymentMethod.card,
    );
    now = DateTime(2026, 9, 2, 9);
    await store.addExpense(
      amountCentavos: 101000,
      category: ExpenseCategory.food,
      note: 'Día pasado',
      occurredAt: now,
      paymentMethod: PaymentMethod.card,
    );

    now = DateTime(2026, 9, 8, 8);
    await store.settleCycles();

    final daily = store.xpEvents.singleWhere(
      (event) => event.kind == XpEventKind.daysUnderDailyLimit,
    );
    expect(daily.quantity, 6);
    expect(daily.xp, 30);
  });

  test(
    'a due schedule change settles old and new boundaries in order',
    () async {
      now = DateTime(2026, 3, 10, 9);
      final store = await newUser(schedule: const PaySchedule.semiMonthly());
      await store.queuePayScheduleChange(const PaySchedule.weekly());

      now = DateTime(2026, 3, 20, 9);
      await store.settleCycles();

      expect(store.paySchedule.type, PayCycleType.weekly);
      expect(store.lastSettledCycleEnd, DateTime(2026, 3, 19));
      expect(
        store.xpEvents.any(
          (event) =>
              event.kind == XpEventKind.cycleInGreen &&
              event.cycleType == PayCycleType.weekly &&
              event.cycleStart == DateTime(2026, 3, 15),
        ),
        isTrue,
      );
      final sourceKeys = store.xpEvents.map((event) => event.sourceKey).toSet();
      expect(sourceKeys, hasLength(store.xpEvents.length));
    },
  );

  test('level thresholds are derived from total XP', () {
    expect(XpProgress.fromTotal(0).level, 1);
    expect(XpProgress.fromTotal(149).level, 1);
    expect(XpProgress.fromTotal(150).level, 2);
    expect(XpProgress.fromTotal(450).level, 3);
    expect(XpProgress.fromTotal(895).level, 4);
    expect(XpProgress.fromTotal(895).currentLevelXp, 45);
    expect(XpProgress.fromTotal(1550).isMaxLevel, isTrue);
  });

  test('existing installs start today without retroactive XP', () async {
    final store = await newUser();
    final oldState = jsonDecode(store.exportJson()) as Map<String, dynamic>
      ..remove('xpEvents')
      ..remove('xpTrackingStartedAt')
      ..remove('lastSettledCycleEnd');
    SharedPreferences.setMockInitialValues({
      'sobra_state_v2': jsonEncode(oldState),
    });

    now = DateTime(2026, 9, 20, 10);
    final migrated = await SobraStore.load(now: () => now);

    expect(migrated.xpEvents, isEmpty);
    expect(migrated.totalXp, 0);
    expect(migrated.xpTrackingStartedAt, DateTime(2026, 9, 20));
    expect(migrated.lastSettledCycleEnd, isNull);
  });
}
