import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sobra_app/l10n/generated/app_localizations.dart';
import 'package:sobra_app/models/expense_entry.dart';
import 'package:sobra_app/models/pay_schedule.dart';
import 'package:sobra_app/screens/app_shell.dart';
import 'package:sobra_app/screens/savings_goal_screen.dart';
import 'package:sobra_app/services/admob_consent_service.dart';
import 'package:sobra_app/services/exit_native_ad_service.dart';
import 'package:sobra_app/state/sobra_store.dart';
import 'package:sobra_app/theme/app_theme.dart';

import 'support/localizations.dart';

class _Consent extends AdMobConsentController {
  @override
  bool get canRequestAds => true;
}

class _Creative implements ExitAdCreative {
  _Creative(this.size);
  @override
  final ExitAdSize size;
  @override
  Widget buildWidget() => const ColoredBox(
    key: ValueKey('exit-integration-creative'),
    color: Colors.blue,
  );
  @override
  void dispose() {}
}

Future<SobraStore> _fixture(String state) async {
  var now = DateTime(2026, 11, 2, 10);
  final store = await SobraStore.load(now: () => now);
  await store.configureOnboarding(
    budgetCentavos: 100000,
    schedule: const PaySchedule.weekly(weeklyPayDay: DateTime.monday),
    cashCentavos: 100000,
  );
  await store.completeOnboarding();
  await store.grantCatalogEntries({'michi', 'poodle'});
  await store.setReducedMotion(true);
  await store.claimSeasonalCostumes();
  await store.takeLaunchGiftNotice();
  await store.takeStarterArrival();
  if (state != 'empty') {
    await store.saveSavingsGoal(
      name: 'Emergency fund',
      targetCentavos: 100000,
      startingCentavos: state == 'completed' ? 100000 : 10000,
    );
  }
  await store.addExpense(
    amountCentavos: 80000,
    category: ExpenseCategory.food,
    note: '',
    occurredAt: now,
    paymentMethod: PaymentMethod.cash,
  );
  now = DateTime(2026, 11, 9, 10);
  await store.settleCycles();
  store.takePendingXpNotice();
  if (state == 'completed') {
    await store.acknowledgeSavingsGoalCyclePrompt(DateTime(2026, 11, 2));
  }
  return store;
}

Future<void> _back(WidgetTester tester) async {
  await tester.binding.handlePopRoute();
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final font = FontLoader('PixelifySans')
      ..addFont(rootBundle.load('assets/fonts/PixelifySans.ttf'));
    await font.load();
  });
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });
  tearDown(() {
    SharedPreferences.resetStatic();
  });

  for (final state in ['active', 'empty', 'completed']) {
    testWidgets('Android back leaves $state goal flow before native exit', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final store = await _fixture(state);
      final initialProgress = store.savingsGoalProgressCentavos;
      final consent = _Consent();
      final ads = ExitNativeAds(
        load: (size, _) async => _Creative(size),
        onImpression: () {},
      );
      addTearDown(consent.dispose);
      addTearDown(ads.dispose);
      await tester.pumpWidget(
        SobraScope(
          store: store,
          child: AdMobConsentScope(
            consent: consent,
            child: MaterialApp(
              locale: const Locale('en'),
              localizationsDelegates: sobraLocalizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              theme: buildSobraTheme(),
              home: AppShell(exitAds: ads),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final popup = state == 'completed'
          ? 'goal-completion-dialog'
          : 'goal-allocation-dialog';
      expect(find.byKey(ValueKey(popup)), findsOneWidget);
      expect(find.byKey(const ValueKey('exit-dialog-frame')), findsNothing);
      expect(
        find.byKey(const ValueKey('exit-integration-creative')),
        findsNothing,
      );

      if (state == 'empty') {
        await tester.tap(find.byKey(const ValueKey('goal-allocation-create')));
        await tester.pumpAndSettle();
        expect(find.byType(SavingsGoalScreen), findsOneWidget);
      }
      await _back(tester);
      expect(find.byKey(ValueKey(popup)), findsNothing);
      expect(find.byType(SavingsGoalScreen), findsNothing);
      expect(find.byKey(const ValueKey('exit-dialog-frame')), findsNothing);
      expect(store.savingsGoalProgressCentavos, initialProgress);

      await _back(tester);
      expect(find.byKey(const ValueKey('exit-dialog-frame')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('exit-integration-creative')),
        findsOneWidget,
      );
      expect(find.byKey(ValueKey(popup)), findsNothing);
      await tester.tap(find.byKey(const ValueKey('exit-cancel')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('exit-dialog-frame')), findsNothing);
      expect(store.savingsGoalProgressCentavos, initialProgress);
      expect(tester.takeException(), isNull);
    });
  }
}
