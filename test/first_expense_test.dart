import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sobra_app/models/expense_entry.dart';
import 'package:sobra_app/screens/app_shell.dart';
import 'package:sobra_app/screens/first_expense_screen.dart';
import 'package:sobra_app/services/app_telemetry.dart';
import 'package:sobra_app/state/sobra_store.dart';
import 'package:sobra_app/theme/app_theme.dart';

import 'support/localizations.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  /// After the launch-gift campaign, so its dialog does not join the queue.
  final afterLaunch = DateTime(2026, 12, 1, 11);

  /// Onboarding finished the way the onboarding screen finishes it.
  Future<SobraStore> onboarded({DateTime? at}) async {
    final store = await SobraStore.load(now: () => at ?? afterLaunch);
    await store.completeOnboarding(offerFirstExpense: true);
    return store;
  }

  Future<void> addLunch(SobraStore store) => store.addExpense(
    amountCentavos: 4500,
    category: ExpenseCategory.food,
    note: '',
    occurredAt: store.currentMoment,
    paymentMethod: PaymentMethod.cash,
  );

  List<(String, Map<String, Object>)> recordTelemetry() {
    final sent = <(String, Map<String, Object>)>[];
    AppTelemetry.instance = AppTelemetry(
      sendEvent: (name, parameters) async => sent.add((name, parameters)),
    );
    addTearDown(() => AppTelemetry.instance = AppTelemetry());
    return sent;
  }

  group('the store', () {
    test('finishing onboarding owes the guided first expense once', () async {
      final store = await onboarded();

      expect(store.firstExpenseGuidePending, isTrue);
      // The card waits for the guide, so the two never ask at once.
      expect(store.showsFirstExpenseCard, isFalse);

      await store.takeFirstExpenseGuide();

      expect(store.firstExpenseGuidePending, isFalse);
      expect(store.showsFirstExpenseCard, isTrue);
      final reopened = await SobraStore.load(now: () => afterLaunch);
      expect(reopened.firstExpenseGuidePending, isFalse);
      expect(reopened.showsFirstExpenseCard, isTrue);
    });

    test('a ledger that already holds spending is not asked', () async {
      final store = await SobraStore.load(now: () => afterLaunch);
      await addLunch(store);

      await store.completeOnboarding(offerFirstExpense: true);

      expect(store.firstExpenseGuidePending, isFalse);
      expect(store.showsFirstExpenseCard, isFalse);
    });

    test(
      'completing onboarding anywhere but its screen asks nothing',
      () async {
        final store = await SobraStore.load(now: () => afterLaunch);

        await store.completeOnboarding();

        expect(store.firstExpenseGuidePending, isFalse);
        expect(store.showsFirstExpenseCard, isFalse);
      },
    );

    test(
      'an install that finished onboarding earlier is asked nothing',
      () async {
        await onboarded();
        final preferences = await SharedPreferences.getInstance();
        final saved =
            jsonDecode(preferences.getString('sobra_state_v2')!)
                  as Map<String, dynamic>
              ..remove('firstExpenseGuidePending')
              ..remove('firstExpenseGuideOffered')
              ..remove('firstExpenseCardSnoozedDay');
        await preferences.setString('sobra_state_v2', jsonEncode(saved));

        final reopened = await SobraStore.load(now: () => afterLaunch);

        expect(reopened.firstExpenseGuidePending, isFalse);
        expect(reopened.showsFirstExpenseCard, isFalse);
      },
    );

    test('putting the card off lasts until tomorrow', () async {
      var now = afterLaunch;
      final store = await SobraStore.load(now: () => now);
      await store.completeOnboarding(offerFirstExpense: true);
      await store.takeFirstExpenseGuide();

      await store.snoozeFirstExpenseCard();

      expect(store.showsFirstExpenseCard, isFalse);
      expect(
        (await SobraStore.load(now: () => now)).showsFirstExpenseCard,
        isFalse,
      );
      now = afterLaunch.add(const Duration(days: 1));
      expect(store.showsFirstExpenseCard, isTrue);
    });

    test('the first everyday expense retires the card for good', () async {
      final store = await onboarded();
      await store.takeFirstExpenseGuide();

      await addLunch(store);

      expect(store.hasRecordedEverydayExpense, isTrue);
      expect(store.showsFirstExpenseCard, isFalse);
    });
  });

  group('the guided screen', () {
    Future<void> pumpLauncher(WidgetTester tester, SobraStore store) async {
      tester.view.physicalSize = const Size(520, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      useSpanishDevice(tester);
      // The companion loops otherwise, and a screen that never settles cannot
      // be stepped through.
      await store.setReducedMotion(true);
      await tester.pumpWidget(
        SobraScope(
          store: store,
          child: MaterialApp(
            localizationsDelegates: sobraLocalizationsDelegates,
            supportedLocales: sobraSupportedLocales,
            theme: buildSobraTheme(),
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: TextButton(
                    onPressed: () => showFirstExpenseGuide(
                      context,
                      origin: FirstExpenseOrigin.homeCard,
                    ),
                    child: const Text('open'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    testWidgets('records through the store and points at the starter', (
      tester,
    ) async {
      final sent = recordTelemetry();
      final store = await onboarded();
      await store.takeFirstExpenseGuide();
      await pumpLauncher(tester, store);

      expect(find.text('Tu primer gasto · 1 de 2'), findsOneWidget);
      await tester.enterText(find.byType(TextField), '45');
      await tester.pump();
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();

      expect(find.text('Tu primer gasto · 2 de 2'), findsOneWidget);
      await tester.tap(find.text('Transporte'));
      await tester.tap(find.text('Tarjeta'));
      await tester.pump();
      await tester.tap(find.text('Guardar mi gasto'));
      await tester.pumpAndSettle();

      final saved = store.transactions.single;
      expect(saved.amountCentavos, 4500);
      expect(saved.category, ExpenseCategory.transport);
      expect(saved.paymentMethod, PaymentMethod.card);
      expect(find.text('¡Listo!'), findsOneWidget);
      expect(find.text('Tu primer registro'), findsOneWidget);
      // The record that just saved is today's step towards the other starter.
      expect(store.recordedToday, isTrue);
      expect(
        find.text('Hoy ya cuenta. Cada día que anotes, Miru se acerca.'),
        findsOneWidget,
      );
      expect(sent.map((event) => event.$1), contains('expense_recorded'));
      expect(sent.where((event) => event.$1 == 'first_expense').single.$2, {
        'origin': 'homeCard',
        'result': 'saved',
      });

      await tester.tap(find.text('Ir a Inicio'));
      await tester.pumpAndSettle();
      expect(find.text('open'), findsOneWidget);
    });

    testWidgets('"not yet" records nothing and says so', (tester) async {
      final sent = recordTelemetry();
      final store = await onboarded();
      await store.takeFirstExpenseGuide();
      await pumpLauncher(tester, store);

      await tester.tap(find.text('Aún no he gastado'));
      await tester.pumpAndSettle();

      expect(find.text('open'), findsOneWidget);
      expect(store.transactions, isEmpty);
      expect(sent.single.$2, {'origin': 'homeCard', 'result': 'skipped'});
    });

    testWidgets('continuing needs an amount', (tester) async {
      final store = await onboarded();
      await store.takeFirstExpenseGuide();
      await pumpLauncher(tester, store);

      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();

      expect(find.text('Tu primer gasto · 1 de 2'), findsOneWidget);
    });
  });

  group('the shell', () {
    Future<void> pumpShell(WidgetTester tester, SobraStore store) async {
      tester.view.physicalSize = const Size(520, 1100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        SobraScope(
          store: store,
          child: MaterialApp(
            locale: const Locale('es'),
            localizationsDelegates: sobraLocalizationsDelegates,
            supportedLocales: sobraSupportedLocales,
            theme: buildSobraTheme(),
            home: const AppShell(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
    }

    testWidgets('opens the guide right after onboarding, once', (tester) async {
      final sent = recordTelemetry();
      final store = await onboarded();

      await pumpShell(tester, store);

      expect(find.text('Tu primer gasto · 1 de 2'), findsOneWidget);
      expect(store.firstExpenseGuidePending, isFalse);

      await tester.tap(find.text('Aún no he gastado'));
      await tester.pump();
      // A page transition, not a dialog's: it needs the longer wait.
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(FirstExpenseScreen), findsNothing);
      expect(sent.where((event) => event.$1 == 'first_expense').single.$2, {
        'origin': 'onboarding',
        'result': 'skipped',
      });
      // Whoever said "not yet" finds the same question waiting on Inicio.
      expect(find.text('Un gasto, y empezamos.'), findsOneWidget);
    });

    testWidgets('the card on Inicio goes away for the day', (tester) async {
      final store = await onboarded();
      await store.takeFirstExpenseGuide();

      await pumpShell(tester, store);
      expect(find.text('Un gasto, y empezamos.'), findsOneWidget);

      await tester.ensureVisible(find.text('Ahora no'));
      await tester.tap(find.text('Ahora no'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Un gasto, y empezamos.'), findsNothing);
    });
  });
}
