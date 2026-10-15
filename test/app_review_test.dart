import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sobra_app/main.dart';
import 'package:sobra_app/models/expense_entry.dart';
import 'package:sobra_app/models/pay_schedule.dart';
import 'package:sobra_app/services/app_review_service.dart';
import 'package:sobra_app/state/sobra_store.dart';

import 'support/localizations.dart';

/// Stands in for Play, which cannot be reached from a test at all.
class _FakePort implements AppReviewPort {
  _FakePort({this.storeOpens = true, this.requestThrows = false});

  bool storeOpens;
  bool requestThrows;
  int requests = 0;
  int opens = 0;

  @override
  Future<void> requestReview() async {
    requests++;
    if (requestThrows) throw StateError('no Play services');
  }

  @override
  Future<bool> openStore() async {
    opens++;
    return storeOpens;
  }
}

Future<SharedPreferences> _preferences([
  Map<String, Object> initial = const {},
]) async {
  SharedPreferences.setMockInitialValues(Map<String, Object>.from(initial));
  return SharedPreferences.getInstance();
}

void main() {
  final firstDay = DateTime(2026, 10, 14);

  group('after a day of use', () {
    test('asks on a later day once something was recorded', () async {
      final port = _FakePort();
      final reviews = AppReviews(
        port: port,
        preferences: await _preferences(),
        now: () => DateTime(2026, 10, 15, 8),
      );

      await reviews.askAfterFirstDay(firstOpenedOn: firstDay, recordedDays: 1);

      expect(port.requests, 1);
    });

    test('stays quiet on the first day, however much was recorded', () async {
      final port = _FakePort();
      final reviews = AppReviews(
        port: port,
        preferences: await _preferences(),
        now: () => DateTime(2026, 10, 14, 23, 59),
      );

      await reviews.askAfterFirstDay(firstOpenedOn: firstDay, recordedDays: 1);

      expect(port.requests, 0);
    });

    test('stays quiet for somebody who never recorded anything', () async {
      final port = _FakePort();
      final reviews = AppReviews(
        port: port,
        preferences: await _preferences(),
        now: () => DateTime(2026, 10, 20),
      );

      await reviews.askAfterFirstDay(firstOpenedOn: firstDay, recordedDays: 0);
      await reviews.askAfterFirstDay(firstOpenedOn: null, recordedDays: 3);

      expect(port.requests, 0);
    });

    test('asks once, ever, across restarts', () async {
      final port = _FakePort();
      final preferences = await _preferences();
      var now = DateTime(2026, 10, 15, 8);
      await AppReviews(
        port: port,
        preferences: preferences,
        now: () => now,
      ).askAfterFirstDay(firstOpenedOn: firstDay, recordedDays: 1);

      now = DateTime(2027, 6, 1);
      final restarted = AppReviews(
        port: port,
        preferences: preferences,
        now: () => now,
      );
      await restarted.askAfterFirstDay(
        firstOpenedOn: firstDay,
        recordedDays: 40,
      );

      expect(port.requests, 1);
    });

    // Installs that were asked under the old after-settlement rule wrote the
    // same key, so they count as asked already.
    test('an earlier ask under the old rule counts', () async {
      final port = _FakePort();
      final reviews = AppReviews(
        port: port,
        preferences: await _preferences({
          'sobra_review_asked_at': DateTime(2026, 9, 30).millisecondsSinceEpoch,
        }),
        now: () => DateTime(2026, 10, 15),
      );

      await reviews.askAfterFirstDay(firstOpenedOn: firstDay, recordedDays: 1);

      expect(port.requests, 0);
    });

    test('never asks once the user opened the listing', () async {
      final port = _FakePort();
      final preferences = await _preferences();
      await AppReviews(port: port, preferences: preferences).openStore();

      await AppReviews(
        port: port,
        preferences: preferences,
        now: () => DateTime(2026, 10, 15),
      ).askAfterFirstDay(firstOpenedOn: firstDay, recordedDays: 1);

      expect(port.requests, 0);
    });

    test('a listing that failed to open does not count as a visit', () async {
      final port = _FakePort(storeOpens: false);
      final reviews = AppReviews(
        port: port,
        preferences: await _preferences(),
        now: () => DateTime(2026, 10, 15),
      );

      expect(await reviews.openStore(), isFalse);
      await reviews.askAfterFirstDay(firstOpenedOn: firstDay, recordedDays: 1);

      expect(port.requests, 1);
    });

    test('a plugin failure is swallowed and still spends the turn', () async {
      final port = _FakePort(requestThrows: true);
      final reviews = AppReviews(
        port: port,
        preferences: await _preferences(),
        now: () => DateTime(2026, 10, 15),
      );

      await reviews.askAfterFirstDay(firstOpenedOn: firstDay, recordedDays: 1);
      await reviews.askAfterFirstDay(firstOpenedOn: firstDay, recordedDays: 1);

      expect(port.requests, 1);
    });
  });

  group('on Inicio', () {
    Future<(SobraStore, void Function(DateTime), DateTime Function())>
    usedYesterday() async {
      SharedPreferences.setMockInitialValues({});
      var now = DateTime(2026, 10, 14, 9);
      final store = await SobraStore.load(now: () => now);
      await store.configureOnboarding(
        budgetCentavos: 600000,
        schedule: const PaySchedule.semiMonthly(),
        cashCentavos: 124000,
      );
      await store.completeOnboarding();
      await store.takeLaunchGiftNotice();
      await store.addExpense(
        amountCentavos: 4500,
        category: ExpenseCategory.food,
        note: '',
        occurredAt: now,
        paymentMethod: PaymentMethod.cash,
      );
      store.takePendingXpNotice();
      await store.setReducedMotion(true);
      return (store, (DateTime next) => now = next, () => now);
    }

    Future<void> pumpApp(WidgetTester tester, SobraApp app) async {
      useSpanishDevice(tester);
      tester.view.physicalSize = const Size(520, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(app);
      await tester.pump();
    }

    testWidgets('the sheet comes the next day, after a quiet moment', (
      tester,
    ) async {
      final (store, setNow, clock) = await usedYesterday();
      setNow(DateTime(2026, 10, 15, 8));
      final port = _FakePort();

      await pumpApp(
        tester,
        SobraApp(
          store: store,
          reviews: AppReviews(port: port, now: clock),
        ),
      );
      expect(port.requests, 0, reason: 'not the instant Inicio draws');

      await tester.pump(const Duration(seconds: 3));
      expect(port.requests, 1);
      expect(tester.takeException(), isNull);
    });

    testWidgets('nothing is asked on the first day', (tester) async {
      final (store, _, clock) = await usedYesterday();
      final port = _FakePort();

      await pumpApp(
        tester,
        SobraApp(
          store: store,
          reviews: AppReviews(port: port, now: clock),
        ),
      );
      await tester.pump(const Duration(seconds: 3));

      expect(port.requests, 0);
    });

    testWidgets('another tab is left alone', (tester) async {
      final (store, setNow, clock) = await usedYesterday();
      setNow(DateTime(2026, 10, 15, 8));
      final port = _FakePort();

      await pumpApp(
        tester,
        SobraApp(
          store: store,
          reviews: AppReviews(port: port, now: clock),
        ),
      );
      await tester.tap(find.text('Mi Sobrita'));
      await tester.pump(const Duration(seconds: 3));
      expect(port.requests, 0);

      await tester.tap(find.text('Inicio'));
      await tester.pump(const Duration(seconds: 3));
      expect(port.requests, 1);
    });
  });

  group('the Ajustes row', () {
    Future<SobraStore> onboardedStore() async {
      SharedPreferences.setMockInitialValues({});
      final store = await SobraStore.load(now: () => DateTime(2026, 9, 3, 10));
      await store.configureOnboarding(
        budgetCentavos: 600000,
        schedule: const PaySchedule.semiMonthly(),
        cashCentavos: 124000,
      );
      await store.completeOnboarding();
      store.takePendingXpNotice();
      return store;
    }

    Future<void> openSettings(WidgetTester tester, SobraApp app) async {
      useSpanishDevice(tester);
      tester.view.physicalSize = const Size(520, 1360);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(app);
      await tester.pump();
      await tester.tap(find.text('Mi Sobrita'));
      await tester.pump(const Duration(milliseconds: 100));
    }

    testWidgets('is absent where there is no store to be rated in', (
      tester,
    ) async {
      final store = await onboardedStore();
      await openSettings(tester, SobraApp(store: store));

      await tester.scrollUntilVisible(find.text('ACERCA DE'), 200);
      expect(find.text('Calificar Sobrita'), findsNothing);
    });

    testWidgets('opens the listing, and says so when it cannot', (
      tester,
    ) async {
      final store = await onboardedStore();
      final port = _FakePort(storeOpens: false);
      final reviews = AppReviews(port: port);
      await openSettings(tester, SobraApp(store: store, reviews: reviews));

      final row = find.text('Calificar Sobrita');
      await tester.scrollUntilVisible(row, 200);
      await tester.tap(row);
      await tester.pump();

      expect(port.opens, 1);
      expect(port.requests, 0, reason: 'the row never asks for the sheet');
      expect(find.text('No se pudo abrir Google Play.'), findsOneWidget);

      port.storeOpens = true;
      await tester.tap(row);
      await tester.pump();
      expect(port.opens, 2);
    });
  });
}
