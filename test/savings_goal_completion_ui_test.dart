import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sobra_app/l10n/generated/app_localizations.dart';
import 'package:sobra_app/models/pay_schedule.dart';
import 'package:sobra_app/screens/completed_savings_goals_screen.dart';
import 'package:sobra_app/state/sobra_store.dart';
import 'package:sobra_app/theme/app_theme.dart';
import 'package:sobra_app/widgets/savings_goal_card.dart';

import 'support/localizations.dart';

Future<SobraStore> _store() async {
  final store = await SobraStore.load(now: () => DateTime(2026, 11, 9, 10));
  await store.configureOnboarding(
    budgetCentavos: 600000,
    schedule: const PaySchedule.semiMonthly(),
    cashCentavos: 100000,
  );
  await store.completeOnboarding();
  return store;
}

Future<void> _pump(
  WidgetTester tester,
  SobraStore store, {
  Size size = const Size(390, 844),
  double textScale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    SobraScope(
      store: store,
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: sobraLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildSobraTheme(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: const Scaffold(
          body: SingleChildScrollView(
            padding: EdgeInsets.all(20),
            child: SavingsGoalCard(),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, String key) async {
  final finder = find.byKey(ValueKey(key));
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _enter(WidgetTester tester, String key, String text) async {
  final finder = find.byKey(ValueKey(key));
  await tester.ensureVisible(finder);
  await tester.enterText(finder, text);
  await tester.pump();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(SharedPreferences.resetStatic);

  testWidgets('completed card opens a new goal without discarding on cancel', (
    tester,
  ) async {
    final store = await _store();
    final goal = await store.saveSavingsGoal(
      name: 'Emergency fund',
      targetCentavos: 100000,
      startingCentavos: 120000,
    );
    await _pump(tester, store);
    expect(
      find.byKey(const ValueKey('savings-goal-complete-icon')),
      findsOneWidget,
    );
    expect(find.text('100%'), findsOneWidget);
    await _tap(tester, 'savings-goal-active');
    expect(find.byKey(const ValueKey('goal-completed-status')), findsOneWidget);
    await _tap(tester, 'goal-new');
    expect(find.byKey(const ValueKey('goal-type-amount')), findsOneWidget);
    expect(store.activeSavingsGoal!.id, goal.id);
    expect(store.completedSavingsGoals, isEmpty);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(store.activeSavingsGoal!.id, goal.id);
    expect(store.completedSavingsGoals, isEmpty);
    expect(
      find.byKey(const ValueKey('savings-goal-complete-icon')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'saving the next goal archives the old total and history is reachable',
    (tester) async {
      final store = await _store();
      final old = await store.saveSavingsGoal(
        name: 'Completed fund',
        targetCentavos: 100000,
        startingCentavos: 120000,
      );
      await _pump(tester, store);
      await _tap(tester, 'savings-goal-active');
      await _tap(tester, 'goal-new');
      await _tap(tester, 'goal-type-amount');
      final starting = tester.widget<TextFormField>(
        find.byKey(const ValueKey('goal-starting')),
      );
      expect(starting.controller!.text, '0');
      await _enter(tester, 'goal-name', 'Next trip');
      await _enter(tester, 'goal-target', '5000');
      await _tap(tester, 'goal-save');
      expect(store.activeSavingsGoal!.name, 'Next trip');
      expect(store.savingsGoalProgressCentavos, 0);
      expect(store.completedSavingsGoals.single.goal.id, old.id);
      expect(store.completedSavingsGoals.single.progressCentavos, 120000);
      await _tap(tester, 'savings-goal-active');
      await _tap(tester, 'goal-history');
      expect(find.byType(CompletedSavingsGoalsScreen), findsOneWidget);
      expect(find.text('Completed fund'), findsOneWidget);
      expect(find.byKey(ValueKey('completed-goal-${old.id}')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('completed history remains accessible without an active goal', (
    tester,
  ) async {
    final store = await _store();
    final old = await store.saveSavingsGoal(
      name: 'Old goal',
      targetCentavos: 100000,
      startingCentavos: 100000,
    );
    final next = await store.saveSavingsGoal(
      replacingCompletedGoalId: old.id,
      name: 'Next goal',
      targetCentavos: 200000,
      startingCentavos: 0,
    );
    await store.removeSavingsGoal(next.id);
    await _pump(tester, store);
    await _tap(tester, 'savings-goal-empty');
    await _tap(tester, 'goal-history');
    expect(find.text('Old goal'), findsOneWidget);
    expect(find.byKey(ValueKey('completed-goal-${old.id}')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('completed card fits a small screen with large text', (
    tester,
  ) async {
    final store = await _store();
    await store.saveSavingsGoal(
      name: 'A long completed goal name for a family emergency fund',
      targetCentavos: 10000000000,
      startingCentavos: 10000000000,
    );
    await _pump(tester, store, size: const Size(320, 700), textScale: 1.6);
    expect(find.text('100%'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
