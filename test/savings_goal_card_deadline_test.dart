import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sobra_app/l10n/generated/app_localizations.dart';
import 'package:sobra_app/models/pay_schedule.dart';
import 'package:sobra_app/models/savings_goal.dart';
import 'package:sobra_app/state/sobra_store.dart';
import 'package:sobra_app/theme/app_theme.dart';
import 'package:sobra_app/widgets/savings_goal_card.dart';

import 'support/localizations.dart';

const _deadline = ValueKey('savings-goal-deadline');

/// A $8,999 goal with $6,500 already saved, so $2,499 is missing.
Future<(SobraStore, void Function(DateTime))> _store({
  DateTime? targetDate,
  int starting = 650000,
}) async {
  SharedPreferences.setMockInitialValues({});
  var now = DateTime(2026, 11, 9, 10);
  final store = await SobraStore.load(now: () => now);
  await store.configureOnboarding(
    budgetCentavos: 300000,
    schedule: const PaySchedule.weekly(weeklyPayDay: DateTime.monday),
    cashCentavos: 0,
  );
  await store.completeOnboarding();
  await store.saveSavingsGoal(
    kind: SavingsGoalKind.amount,
    name: 'TV',
    targetCentavos: 899900,
    startingCentavos: starting,
    targetDate: targetDate,
  );
  return (store, (DateTime value) => now = value);
}

Future<void> _pump(
  WidgetTester tester,
  SobraStore store, {
  Locale locale = const Locale('ko'),
  double textScale = 1,
  Size size = const Size(390, 844),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    SobraScope(
      store: store,
      child: MaterialApp(
        locale: locale,
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

void main() {
  testWidgets('a dated goal shows days left and the missing amount', (
    tester,
  ) async {
    final (store, _) = await _store(targetDate: DateTime(2026, 11, 13));
    await _pump(tester, store);
    expect(find.byKey(_deadline), findsOneWidget);
    expect(find.text('D-4'), findsOneWidget);
    expect(find.text('11월 13일까지 \$2,499 더'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Spanish uses the template wording', (tester) async {
    final (store, _) = await _store(targetDate: DateTime(2026, 11, 13));
    await _pump(tester, store, locale: const Locale('es'));
    expect(find.text('4 días'), findsOneWidget);
    expect(find.textContaining('faltan \$2,499'), findsOneWidget);
  });

  testWidgets('the goal date itself counts as today', (tester) async {
    final (store, setNow) = await _store(targetDate: DateTime(2026, 11, 13));
    setNow(DateTime(2026, 11, 13, 23, 30));
    await _pump(tester, store);
    expect(find.text('D-DAY'), findsOneWidget);
  });

  testWidgets('a passed date drops the countdown but keeps the amount', (
    tester,
  ) async {
    final (store, setNow) = await _store(targetDate: DateTime(2026, 11, 13));
    setNow(DateTime(2026, 11, 14, 8));
    await _pump(tester, store);
    expect(find.byKey(_deadline), findsOneWidget);
    expect(find.textContaining('D-'), findsNothing);
    expect(find.text('11월 13일 지났어요 · \$2,499 더'), findsOneWidget);
  });

  testWidgets('an undated goal shows only the missing amount', (tester) async {
    final (store, _) = await _store();
    await _pump(tester, store);
    expect(find.byKey(_deadline), findsOneWidget);
    expect(find.text('\$2,499 더 모으면 돼요'), findsOneWidget);
    expect(find.textContaining('D-'), findsNothing);
  });

  testWidgets('a month away still counts down', (tester) async {
    // 31 days from Monday 9 Nov.
    final (store, _) = await _store(targetDate: DateTime(2026, 12, 10));
    await _pump(tester, store);
    expect(find.text('D-31'), findsOneWidget);
    expect(find.text('12월 10일까지 \$2,499 더'), findsOneWidget);
  });

  testWidgets('past a month the line turns into a per-cycle plan', (
    tester,
  ) async {
    // 32 days: weekly cycles from 9 Nov through the week of 7 Dec are 5.
    // $2,499 / 5 = $499.80, rounded up to a whole $500.
    final (store, _) = await _store(targetDate: DateTime(2026, 12, 11));
    await _pump(tester, store);
    expect(find.textContaining('D-'), findsNothing);
    expect(find.text('12월 11일까지 주기마다 \$500'), findsOneWidget);
  });

  testWidgets('a date next year shows its year and a small weekly share', (
    tester,
  ) async {
    // 53 weekly cycles through the week of 8 Nov 2027: $2,499 / 53 = $47.16.
    final (store, _) = await _store(targetDate: DateTime(2027, 11, 13));
    expect(store.payCyclesThrough(DateTime(2027, 11, 13)), 53);
    await _pump(tester, store);
    expect(find.text('2027년 11월 13일까지 주기마다 \$48'), findsOneWidget);
    await _pump(tester, store, locale: const Locale('es'));
    expect(find.textContaining('por ciclo'), findsOneWidget);
    expect(find.textContaining('2027'), findsOneWidget);
  });

  test('cycle counting is capped for a far-off date', () async {
    final (store, _) = await _store();
    expect(store.payCyclesThrough(DateTime(2026, 11, 15)), 1);
    expect(store.payCyclesThrough(DateTime(2026, 11, 16)), 2);
    expect(store.payCyclesThrough(DateTime(9999, 12, 31)), 600);
  });

  testWidgets('a reached goal shows no deadline', (tester) async {
    final (store, _) = await _store(
      targetDate: DateTime(2026, 11, 13),
      starting: 899900,
    );
    await _pump(tester, store);
    expect(store.isSavingsGoalComplete, isTrue);
    expect(find.byKey(_deadline), findsNothing);
  });

  testWidgets('the line fits a small phone with large text', (tester) async {
    final (store, _) = await _store(targetDate: DateTime(2026, 11, 13));
    for (final locale in AppLocalizations.supportedLocales) {
      // The longest variant: a dated plan with the year in it.
      await store.saveSavingsGoal(
        id: store.activeSavingsGoal!.id,
        name: 'TV',
        targetCentavos: 899900,
        startingCentavos: 650000,
        targetDate: DateTime(2027, 11, 13),
      );
      await _pump(
        tester,
        store,
        locale: locale,
        textScale: 1.3,
        size: const Size(320, 640),
      );
      expect(find.byKey(_deadline), findsOneWidget, reason: '$locale');
      expect(tester.takeException(), isNull, reason: '$locale');
    }
  });
}
