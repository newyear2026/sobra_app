import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sobra_app/l10n/generated/app_localizations.dart';
import 'package:sobra_app/models/expense_entry.dart';
import 'package:sobra_app/models/income_entry.dart';
import 'package:sobra_app/models/pay_schedule.dart';
import 'package:sobra_app/screens/app_shell.dart';
import 'package:sobra_app/screens/savings_goal_screen.dart';
import 'package:sobra_app/state/sobra_store.dart';
import 'package:sobra_app/theme/app_theme.dart';

import 'support/localizations.dart';

class _Clock {
  DateTime now = DateTime(2026, 11, 2, 10);
}

Future<SobraStore> _fixture(
  _Clock clock, {
  bool closed = false,
  bool goal = true,
  int target = 100000,
  int starting = 10000,
  bool keepCycleXp = false,
  bool keepGift = false,
}) async {
  final store = await SobraStore.load(now: () => clock.now);
  await store.configureOnboarding(
    budgetCentavos: 100000,
    schedule: const PaySchedule.weekly(weeklyPayDay: DateTime.monday),
    cashCentavos: 100000,
  );
  await store.completeOnboarding();
  await store.grantCatalogEntries({'michi', 'poodle'});
  await store.setReducedMotion(true);
  await store.claimSeasonalCostumes();
  if (!keepGift) await store.takeLaunchGiftNotice();
  await store.takeStarterArrival();
  if (goal) {
    await store.saveSavingsGoal(
      name: 'Emergency fund',
      targetCentavos: target,
      startingCentavos: starting,
    );
  }
  if (closed) {
    await store.addExpense(
      amountCentavos: 80000,
      category: ExpenseCategory.food,
      note: '',
      occurredAt: clock.now,
      paymentMethod: PaymentMethod.cash,
    );
    clock.now = DateTime(2026, 11, 9, 10);
    await store.settleCycles();
    expect(store.cycleRecords.single.resultCentavos, 20000);
  }
  if (!keepCycleXp) store.takePendingXpNotice();
  return store;
}

Future<void> _pumpShell(WidgetTester tester, SobraStore store) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  await tester.pumpWidget(
    SobraScope(
      store: store,
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: sobraLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildSobraTheme(),
        home: const AppShell(),
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

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final pixel = FontLoader('PixelifySans')
      ..addFont(rootBundle.load('assets/fonts/PixelifySans.ttf'));
    await pixel.load();
  });
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(SharedPreferences.resetStatic);

  testWidgets('cycle popup is automatic once across rebuild and reload', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final clock = _Clock();
    final store = await _fixture(clock, closed: true);
    await _pumpShell(tester, store);
    expect(
      find.byKey(const ValueKey('goal-allocation-dialog')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('goal-allocation-confirm')),
      findsOneWidget,
    );
    expect(find.byType(Dialog), findsOneWidget);
    await _tap(tester, 'goal-allocation-later');
    expect(store.pendingSavingsGoalCycle, isNull);
    await store.setLanguageCode('en');
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    final reloaded = await SobraStore.load(now: () => clock.now);
    await _pumpShell(tester, reloaded);
    expect(find.byType(Dialog), findsNothing);
    expect(reloaded.pendingSavingsGoalCycle, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('no-goal cycle popup offers setup without creating money', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final clock = _Clock();
    final store = await _fixture(clock, closed: true, goal: false);
    await _pumpShell(tester, store);
    expect(
      find.byKey(const ValueKey('goal-allocation-create')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('goal-allocation-confirm')), findsNothing);
    await _tap(tester, 'goal-allocation-create');
    expect(find.byType(SavingsGoalScreen), findsOneWidget);
    expect(find.byType(Dialog), findsNothing);
    expect(store.activeSavingsGoal, isNull);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(store.activeSavingsGoal, isNull);
    expect(store.savingsGoalProgressCentavos, 0);
    expect(find.byKey(const ValueKey('savings-goal-empty')), findsOneWidget);
    expect(find.byType(Dialog), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('allocation reaching target presents one completion over home', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final clock = _Clock();
    final store = await _fixture(clock, closed: true, target: 30000);
    await _pumpShell(tester, store);
    await _tap(tester, 'goal-allocation-confirm');
    expect(find.byKey(const ValueKey('goal-allocation-dialog')), findsNothing);
    expect(
      find.byKey(const ValueKey('goal-completion-dialog')),
      findsOneWidget,
    );
    expect(find.byType(Dialog), findsOneWidget);
    expect(store.savingsGoalProgressCentavos, 30000);
    expect(store.pendingSavingsGoalCompletionId, isNull);
    await _tap(tester, 'goal-completion-confirm');
    expect(find.byType(Dialog), findsNothing);
    expect(
      find.byKey(const ValueKey('savings-goal-complete-icon')),
      findsOneWidget,
    );
    await store.setLanguageCode('en');
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    final reloaded = await SobraStore.load(now: () => clock.now);
    await _pumpShell(tester, reloaded);
    expect(find.byType(Dialog), findsNothing);
    expect(reloaded.savingsGoalProgressCentavos, 30000);
    expect(tester.takeException(), isNull);
  });

  testWidgets('savings income reaching target is celebrated once on home', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final clock = _Clock();
    final store = await _fixture(clock, target: 30000);
    await _pumpShell(tester, store);
    await store.addIncome(
      amountCentavos: 20000,
      kind: IncomeKind.extra,
      note: '',
      occurredAt: clock.now,
      destination: PaymentMethod.card,
      allocation: IncomeAllocation.savings,
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('goal-completion-dialog')),
      findsOneWidget,
    );
    expect(find.byType(Dialog), findsOneWidget);
    await _tap(tester, 'goal-completion-confirm');
    await store.setLanguageCode('en');
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('creating a reached goal waits for editor return to home', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final clock = _Clock();
    final store = await _fixture(clock, goal: false);
    await _pumpShell(tester, store);
    await _tap(tester, 'savings-goal-empty');
    await _tap(tester, 'goal-type-amount');
    for (final (key, value) in [
      ('goal-name', 'Finished fund'),
      ('goal-target', '100'),
      ('goal-starting', '100'),
    ]) {
      final finder = find.byKey(ValueKey(key));
      await tester.ensureVisible(finder);
      await tester.enterText(finder, value);
      await tester.pump();
    }
    await _tap(tester, 'goal-save');
    expect(find.byType(SavingsGoalScreen), findsNothing);
    expect(
      find.byKey(const ValueKey('goal-completion-dialog')),
      findsOneWidget,
    );
    expect(find.byType(Dialog), findsOneWidget);
    await _tap(tester, 'goal-completion-confirm');
    expect(find.byType(Dialog), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cycle XP path and gift queue never stack goal dialogs', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final clock = _Clock();
    final store = await _fixture(
      clock,
      closed: true,
      keepCycleXp: true,
      keepGift: true,
    );
    await _pumpShell(tester, store);
    expect(
      find.byKey(const ValueKey('goal-allocation-dialog')),
      findsOneWidget,
    );
    expect(find.byType(Dialog), findsOneWidget);
    final l10n = AppLocalizations.of(tester.element(find.byType(AppShell)));
    expect(find.text(l10n.launchGiftTitle), findsNothing);
    await _tap(tester, 'goal-allocation-later');
    expect(find.byKey(const ValueKey('goal-allocation-dialog')), findsNothing);
    expect(find.text(l10n.launchGiftTitle), findsOneWidget);
    expect(find.byType(Dialog), findsOneWidget);
    await tester.tap(find.text(l10n.launchGiftLater));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);
    expect(store.launchGiftNoticePending, isFalse);
    expect(tester.takeException(), isNull);
  });
}
