import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sobra_app/data/catalog_preview_data.dart';
import 'package:sobra_app/main.dart';
import 'package:sobra_app/models/pay_schedule.dart';
import 'package:sobra_app/services/native_ad_service.dart';
import 'package:sobra_app/state/sobra_store.dart';

import 'support/localizations.dart';

void main() {
  late DateTime now;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    now = DateTime(2026, 9, 15, 10);
  });

  Future<SobraStore> loadStore() => SobraStore.load(now: () => now);

  test('native ads wait through the configured install grace period', () async {
    final store = await loadStore();
    final ads = NativeAds(store: store, graceDays: 7)..setSdkReady(true);

    ads.startVisit();
    expect(ads.canOffer, isFalse);

    now = DateTime(2026, 9, 21, 10);
    expect(ads.canOffer, isFalse);

    now = DateTime(2026, 9, 22, 10);
    expect(ads.canOffer, isTrue);
  });

  test('one impression per visit and two per local day', () async {
    final store = await loadStore();
    final ads = NativeAds(store: store, graceDays: 0)..setSdkReady(true);

    ads.startVisit();
    expect(ads.canOffer, isTrue);
    ads.recordImpression();
    await Future<void>.delayed(Duration.zero);
    expect(store.nativeAdImpressionsToday, 1);
    expect(ads.canOffer, isFalse);
    expect(ads.shouldPlace, isTrue);

    ads.endVisit();
    ads.startVisit();
    expect(ads.canOffer, isTrue);
    ads.recordImpression();
    await Future<void>.delayed(Duration.zero);
    expect(store.nativeAdImpressionsToday, 2);

    ads.endVisit();
    ads.startVisit();
    expect(ads.canOffer, isFalse);

    now = DateTime(2026, 9, 16, 10);
    expect(store.nativeAdImpressionsToday, 0);
    expect(ads.canOffer, isTrue);
  });

  test('the no-ads entitlement removes native placements', () async {
    final store = await loadStore();
    final ads = NativeAds(store: store, graceDays: 0)..setSdkReady(true);
    ads.startVisit();
    expect(ads.canOffer, isTrue);

    await store.grantCatalogEntry(CatalogPreviewData.noAdsEntitlement);

    expect(ads.canOffer, isFalse);
    expect(ads.shouldPlace, isFalse);
  });

  test('only a real recorded impression spends the persisted cap', () async {
    final store = await loadStore();
    expect(store.nativeAdImpressionsToday, 0);

    expect(await store.recordNativeAdImpression(), isTrue);
    expect((await loadStore()).nativeAdImpressionsToday, 1);
  });

  testWidgets('only a real transition into transactions starts a visit', (
    tester,
  ) async {
    useSpanishDevice(tester);
    final store = await loadStore();
    await store.configureOnboarding(
      budgetCentavos: 600000,
      schedule: const PaySchedule.semiMonthly(),
      cashCentavos: 100000,
    );
    await store.completeOnboarding();
    await store.setReducedMotion(true);
    final ads = NativeAds(store: store, graceDays: 0)..setSdkReady(true);

    await tester.pumpWidget(SobraApp(store: store, nativeAds: ads));
    await tester.tap(find.text('Movim.'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(ads.visitId, 1);

    await tester.tap(find.text('Movim.'));
    await tester.pump();
    expect(ads.visitId, 1);

    await tester.tap(find.text('Inicio'));
    await tester.pump();
    await tester.tap(find.text('Movim.'));
    await tester.pump();
    expect(ads.visitId, 2);
  });

  // The ad becomes visible exactly as the user taps another tab. Google has
  // billed the impression either way; dropping it locally is what lets the
  // next visit serve past the daily limit.
  test('an impression arriving after the visit ends is still counted',
      () async {
    final store = await loadStore();
    final ads = NativeAds(store: store, graceDays: 0)..setSdkReady(true);

    ads.startVisit();
    expect(ads.canOffer, isTrue);
    ads.endVisit();
    ads.recordImpression();
    await pumpEventQueue();

    expect(store.nativeAdImpressionsToday, 1);

    // And the day's second slot is the last one, not the third.
    ads.startVisit();
    ads.recordImpression();
    await pumpEventQueue();
    expect(store.nativeAdImpressionsToday, 2);

    ads.startVisit();
    expect(ads.canOffer, isFalse);
  });

  test('a second callback for the same visit counts once', () async {
    final store = await loadStore();
    final ads = NativeAds(store: store, graceDays: 0)..setSdkReady(true);

    ads.startVisit();
    ads.recordImpression();
    ads.recordImpression();
    await pumpEventQueue();

    expect(store.nativeAdImpressionsToday, 1);
  });

  // Asked from inside a build, so it must answer rather than throw. A state
  // written by a future version, or half-written, must not take the ledger
  // down every time it lays out.
  test('a stored install day that will not parse holds the grace', () async {
    SharedPreferences.setMockInitialValues({});
    final seed = await loadStore();
    final preferences = await SharedPreferences.getInstance();
    final saved =
        jsonDecode(preferences.getString('sobra_state_v2')!)
            as Map<String, dynamic>;
    saved['nativeAdInstallDay'] = 'not-a-date';
    await preferences.setString('sobra_state_v2', jsonEncode(saved));
    expect(seed, isNotNull);

    final store = await loadStore();

    expect(store.nativeAdGraceComplete(7), isFalse);
    // Repaired on the way in, so the grace actually ends rather than holding
    // forever on a value nothing can read.
    now = DateTime(2026, 9, 30, 10);
    expect((await loadStore()).nativeAdGraceComplete(7), isTrue);
  });

  // Runs on the first launch after ads shipped, for every existing install.
  test('a launch whose migration cannot be written still opens', () async {
    SharedPreferences.setMockInitialValues({});
    await loadStore();
    final preferences = await SharedPreferences.getInstance();
    final saved =
        jsonDecode(preferences.getString('sobra_state_v2')!)
            as Map<String, dynamic>;
    saved.remove('nativeAdInstallDay');
    await preferences.setString('sobra_state_v2', jsonEncode(saved));
    SharedPreferencesStorePlatform.instance = _ReadOnlyStore(
      Map<String, Object>.from({
        'flutter.sobra_state_v2': preferences.getString('sobra_state_v2')!,
      }),
    );

    final store = await loadStore();

    expect(store.hasStorageError, isFalse);
    expect(store.nativeAdGraceComplete(7), isFalse);
  });
}

/// A preferences store that refuses every write, the way a full disk does.
class _ReadOnlyStore extends InMemorySharedPreferencesStore {
  _ReadOnlyStore(super.values) : super.withData();

  @override
  Future<bool> setValue(String valueType, String key, Object value) async =>
      false;
}
