import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sobra_app/l10n/generated/app_localizations.dart';
import 'package:sobra_app/models/expense_entry.dart';
import 'package:sobra_app/models/pay_schedule.dart';
import 'package:sobra_app/screens/cycle_settings_screen.dart';
import 'package:sobra_app/state/sobra_store.dart';
import 'package:sobra_app/theme/app_theme.dart';

/// A quincena running Sep 30 – Oct 14 switches to Friday paydays. The first
/// Friday after it is Oct 16, so the new schedule opens with Thursday Oct 15
/// alone: one day of a seven-day week.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late DateTime now;
  late SobraStore store;
  const friday = PaySchedule.weekly(weeklyPayDay: DateTime.friday);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    now = DateTime(2026, 9, 30, 12);
    store = await SobraStore.load(now: () => now);
    await store.configureOnboarding(
      budgetCentavos: 700000,
      schedule: const PaySchedule.semiMonthly(),
    );
    await store.completeOnboarding();
  });

  Future<SobraStore> reopenOn(DateTime day) {
    now = DateTime(day.year, day.month, day.day, 12);
    return SobraStore.load(now: () => now);
  }

  group('the short first cycle after a change', () {
    test('plans with its share of the budget by days', () async {
      await store.queuePayScheduleChange(friday);
      final stub = await reopenOn(DateTime(2026, 10, 15));
      expect(stub.cycleStart, DateTime(2026, 10, 15));
      expect(stub.cycleEnd, DateTime(2026, 10, 15));
      expect(stub.baseBudgetCentavos, 700000);
      expect(stub.totalBudgetCentavos, 100000);
      expect(stub.dailyAllowanceCentavos, 100000);

      final week = await reopenOn(DateTime(2026, 10, 16));
      expect(week.cycleBounds.lengthInDays, 7);
      expect(week.totalBudgetCentavos, 700000);
    });

    test('closes against that share', () async {
      await store.queuePayScheduleChange(friday);
      final stub = await reopenOn(DateTime(2026, 10, 15));
      await stub.addExpense(
        amountCentavos: 150000,
        category: ExpenseCategory.food,
        note: '',
        occurredAt: now,
        paymentMethod: PaymentMethod.card,
      );
      final later = await reopenOn(DateTime(2026, 10, 20));
      final record = later.cycleRecords.firstWhere(
        (r) => r.start == DateTime(2026, 10, 15),
      );
      expect(record.budgetCentavos, 100000);
      expect(record.spentCentavos, 150000);
    });

    test('reads an edited total as that cycle\'s total', () async {
      await store.queuePayScheduleChange(friday);
      final stub = await reopenOn(DateTime(2026, 10, 15));
      await stub.setTotalBudget(200000);
      expect(stub.totalBudgetCentavos, 200000);
      expect(stub.baseBudgetCentavos, 1400000);
    });

    test('is a whole cycle when the change lands on a payday', () async {
      // Oct 15 is a Thursday, so Thursday paydays start on it exactly.
      await store.queuePayScheduleChange(
        const PaySchedule.weekly(weeklyPayDay: DateTime.thursday),
      );
      final week = await reopenOn(DateTime(2026, 10, 15));
      expect(week.cycleBounds.lengthInDays, 7);
      expect(week.totalBudgetCentavos, 700000);
    });
  });

  group('a budget converted for the new cycle length', () {
    test('is offered when the length changes, rounded', () {
      // 700000 × 7 / (365.25 / 24) = 321971.
      expect(store.suggestedBudgetFor(friday), 322000);
      expect(store.suggestedBudgetFor(const PaySchedule.monthly()), 1400000);
    });

    test('is not offered for a similar length', () {
      expect(
        store.suggestedBudgetFor(
          PaySchedule.biweekly(anchor: DateTime(2026, 10, 15)),
        ),
        isNull,
      );
      expect(
        store.suggestedBudgetFor(
          const PaySchedule.semiMonthly(firstPayDay: 10),
        ),
        isNull,
      );
    });

    test('starts with the new schedule, not before', () async {
      await store.queuePayScheduleChange(friday, baseBudgetCentavos: 322000);
      expect(store.totalBudgetCentavos, 700000);
      expect(store.pendingBaseBudgetCentavos, 322000);

      final week = await reopenOn(DateTime(2026, 10, 16));
      expect(week.baseBudgetCentavos, 322000);
      expect(week.totalBudgetCentavos, 322000);
      expect(week.pendingBaseBudgetCentavos, isNull);
      expect(
        week.categoryLimits.values.fold<int>(0, (sum, v) => sum + v),
        322000,
      );
      // The quincena it replaced closed with the budget it ran on.
      final quincena = week.cycleRecords.firstWhere(
        (r) => r.start == DateTime(2026, 9, 30),
      );
      expect(quincena.budgetCentavos, 700000);
    });

    test('is dropped when the change is saved again without it', () async {
      await store.queuePayScheduleChange(friday, baseBudgetCentavos: 322000);
      await store.queuePayScheduleChange(friday);
      expect(store.pendingBaseBudgetCentavos, isNull);
    });

    test('travels in a backup and is checked there', () async {
      await store.queuePayScheduleChange(friday, baseBudgetCentavos: 322000);
      final backup = store.exportJson();
      await store.queuePayScheduleChange(friday);
      await store.importBackup(backup);
      expect(store.pendingBaseBudgetCentavos, 322000);

      final orphan = jsonDecode(backup) as Map<String, dynamic>
        ..['pendingPaySchedule'] = null
        ..['pendingPayScheduleEffectiveAt'] = null;
      expect(
        () => store.inspectBackup(jsonEncode(orphan)),
        throwsFormatException,
      );
    });
  });

  group('the cycle screen', () {
    Future<void> pumpScreen(WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        SobraScope(
          store: store,
          child: MaterialApp(
            locale: const Locale('es'),
            theme: buildSobraTheme(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const CycleSettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Quincenal'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Semanal').last);
      await tester.pumpAndSettle();
    }

    Future<void> save(WidgetTester tester) async {
      await tester.ensureVisible(find.text('Guardar cambio'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Guardar cambio'));
      await tester.pumpAndSettle();
    }

    testWidgets('says the first cycle is short', (tester) async {
      await pumpScreen(tester);
      expect(find.textContaining('dura solo 1 día'), findsOneWidget);
    });

    testWidgets('saves the converted budget when it is taken', (tester) async {
      await pumpScreen(tester);
      await save(tester);
      expect(find.text('Tu presupuesto es por ciclo'), findsOneWidget);
      await tester.tap(find.textContaining('Usar'));
      await tester.pumpAndSettle();
      expect(store.pendingPaySchedule?.type, PayCycleType.weekly);
      expect(store.pendingBaseBudgetCentavos, 322000);
    });

    testWidgets('keeps the budget when asked to', (tester) async {
      await pumpScreen(tester);
      await save(tester);
      await tester.tap(find.textContaining('Mantener'));
      await tester.pumpAndSettle();
      expect(store.pendingPaySchedule?.type, PayCycleType.weekly);
      expect(store.pendingBaseBudgetCentavos, isNull);
    });

    testWidgets('saves nothing when the question is dismissed', (tester) async {
      await pumpScreen(tester);
      await save(tester);
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(store.pendingPaySchedule, isNull);
      expect(find.text('Guardar cambio'), findsOneWidget);
    });
  });
}
