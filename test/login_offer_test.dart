import 'dart:convert';

import 'package:flutter/widgets.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sobra_app/main.dart';
import 'package:sobra_app/models/pay_schedule.dart';
import 'package:sobra_app/screens/login_screen.dart';
import 'package:sobra_app/screens/onboarding_screen.dart';
import 'package:sobra_app/screens/recovery_screen.dart';
import 'package:sobra_app/state/sobra_store.dart';

import 'support/localizations.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<SobraStore> loadStore() => SobraStore.load();

  Future<void> pumpApp(WidgetTester tester, SobraStore store) async {
    useSpanishDevice(tester);
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await store.setReducedMotion(true);
    await tester.pumpWidget(SobraApp(store: store));
    await tester.pump(const Duration(milliseconds: 100));
  }

  test('the answer outlives the process that gave it', () async {
    final store = await loadStore();
    expect(store.hasAnsweredLoginOffer, isFalse);

    await store.answerLoginOffer();

    // The whole point. It used to be a bool in a widget's State, so declining
    // lasted exactly as long as the app stayed alive.
    expect((await loadStore()).hasAnsweredLoginOffer, isTrue);
  });

  test('finishing onboarding counts as having answered', () async {
    final store = await loadStore();

    await store.configureOnboarding(
      budgetCentavos: 600000,
      schedule: const PaySchedule.semiMonthly(),
    );
    await store.completeOnboarding();

    // Onboarding sits behind the offer, so reaching its end proves the
    // question was answered; the two must never disagree.
    expect(store.hasAnsweredLoginOffer, isTrue);
  });

  test('an install from before the offer existed is not asked', () async {
    final established = await loadStore();
    await established.configureOnboarding(
      budgetCentavos: 600000,
      schedule: const PaySchedule.semiMonthly(),
    );
    await established.completeOnboarding();
    final preferences = await SharedPreferences.getInstance();
    final saved =
        jsonDecode(preferences.getString('sobra_state_v2')!)
            as Map<String, dynamic>;
    saved.remove('hasAnsweredLoginOffer');
    await preferences.setString('sobra_state_v2', jsonEncode(saved));

    final reopened = await loadStore();

    // Somebody mid-way through using Sobra must not be stopped by a question
    // the update invented.
    expect(reopened.hasAnsweredLoginOffer, isTrue);
  });

  testWidgets('a new install is offered the account once', (tester) async {
    final store = await loadStore();

    await pumpApp(tester, store);

    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('answering it moves on, and a cold start does not ask again', (
    tester,
  ) async {
    final store = await loadStore();
    await pumpApp(tester, store);

    await tester.tap(find.text('Empezar sin cuenta'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.byType(LoginScreen), findsNothing);
    expect(find.byType(OnboardingScreen), findsOneWidget);

    // The cold start the old build failed: same data, a brand new process.
    final restarted = await loadStore();
    await tester.pumpWidget(SobraApp(store: restarted));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(LoginScreen), findsNothing);
    expect(find.byType(OnboardingScreen), findsOneWidget);
  });

  testWidgets('unreadable data is handled before the account question', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'sobra_state_v2': 'not json'});
    final store = await loadStore();
    expect(store.hasStorageError, isTrue);

    await pumpApp(tester, store);

    // A ledger that will not open outranks a question about backups.
    expect(find.byType(RecoveryScreen), findsOneWidget);
    expect(find.byType(LoginScreen), findsNothing);
  });
}
