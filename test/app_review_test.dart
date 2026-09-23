import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sobra_app/main.dart';
import 'package:sobra_app/models/cycle_record.dart';
import 'package:sobra_app/models/pay_schedule.dart';
import 'package:sobra_app/screens/settlement_screen.dart';
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

CycleRecord _closed({required int spent}) => CycleRecord(
  start: DateTime(2026, 9, 1),
  end: DateTime(2026, 9, 7),
  budgetCentavos: 700000,
  spentCentavos: spent,
  cycleType: PayCycleType.weekly,
);

Future<SharedPreferences> _preferences([
  Map<String, Object> initial = const {},
]) async {
  SharedPreferences.setMockInitialValues(Map<String, Object>.from(initial));
  return SharedPreferences.getInstance();
}

void main() {
  final kept = _closed(spent: 180000);
  final overspent = _closed(spent: 900000);

  group('after a settlement', () {
    test('asks when the cycle closed with money left over', () async {
      final port = _FakePort();
      final reviews = AppReviews(port: port, preferences: await _preferences());

      await reviews.afterSettlement(kept);

      expect(port.requests, 1);
    });

    test('stays quiet after an overspent cycle, or with no record', () async {
      final port = _FakePort();
      final reviews = AppReviews(port: port, preferences: await _preferences());

      await reviews.afterSettlement(overspent);
      await reviews.afterSettlement(null);

      expect(port.requests, 0);
    });

    test('asks at most once per quiet period, across restarts', () async {
      final port = _FakePort();
      final preferences = await _preferences();
      var now = DateTime(2026, 9, 7, 20);
      await AppReviews(
        port: port,
        preferences: preferences,
        now: () => now,
      ).afterSettlement(kept);

      // A new process a week later: the attempt was remembered.
      now = now.add(const Duration(days: 7));
      final restarted = AppReviews(
        port: port,
        preferences: preferences,
        now: () => now,
      );
      await restarted.afterSettlement(kept);
      expect(port.requests, 1);

      now = DateTime(2026, 9, 7, 20).add(AppReviews.quietPeriod);
      await restarted.afterSettlement(kept);
      expect(port.requests, 2);
    });

    test('never asks again once the user opened the listing', () async {
      final port = _FakePort();
      final preferences = await _preferences();
      await AppReviews(port: port, preferences: preferences).openStore();

      await AppReviews(
        port: port,
        preferences: preferences,
      ).afterSettlement(kept);

      expect(port.requests, 0);
    });

    test('a listing that failed to open does not count as a visit', () async {
      final port = _FakePort(storeOpens: false);
      final reviews = AppReviews(port: port, preferences: await _preferences());

      expect(await reviews.openStore(), isFalse);
      await reviews.afterSettlement(kept);

      expect(port.requests, 1);
    });

    test('a plugin failure is swallowed and still spends the turn', () async {
      final port = _FakePort(requestThrows: true);
      final reviews = AppReviews(port: port, preferences: await _preferences());

      await reviews.afterSettlement(kept);
      await reviews.afterSettlement(kept);

      expect(port.requests, 1);
    });
  });

  testWidgets('the sheet waits until the settlement screen has closed', (
    tester,
  ) async {
    useSpanishDevice(tester);
    tester.view.physicalSize = const Size(520, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({});
    final start = DateTime(2026, 9, 2, 10);
    var now = start;
    final store = await SobraStore.load(now: () => now);
    await store.configureOnboarding(
      budgetCentavos: 700000,
      schedule: const PaySchedule.weekly(),
      cashCentavos: 200000,
    );
    await store.completeOnboarding();
    // Two quiet weeks: the first was only partly tracked and files no record,
    // the second closes whole with the entire budget left over.
    now = start.add(const Duration(days: 15));
    await store.settleCycles();
    await store.setReducedMotion(true);
    final port = _FakePort();

    await tester.pumpWidget(
      SobraApp(
        store: store,
        reviews: AppReviews(port: port),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(SettlementScreen), findsOneWidget);
    expect(store.cycleRecords.first.resultCentavos, greaterThan(0));
    expect(port.requests, 0, reason: 'not over the result itself');

    await tester.tap(find.text('Listo'));
    await tester.pumpAndSettle();

    expect(find.byType(SettlementScreen), findsNothing);
    expect(port.requests, 1);
    expect(tester.takeException(), isNull);
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
