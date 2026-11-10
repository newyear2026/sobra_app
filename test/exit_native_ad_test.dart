import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:sobra_app/data/catalog_preview_data.dart';
import 'package:sobra_app/l10n/generated/app_localizations.dart';
import 'package:sobra_app/services/admob_consent_service.dart';
import 'package:sobra_app/services/exit_native_ad_service.dart';
import 'package:sobra_app/state/sobra_store.dart';
import 'package:sobra_app/theme/app_theme.dart';
import 'package:sobra_app/widgets/app_exit_guard.dart';
import 'package:sobra_app/widgets/exit_confirmation_dialog.dart';

import 'support/localizations.dart';

class _Creative implements ExitAdCreative {
  _Creative(this.size);
  @override
  final ExitAdSize size;
  int disposals = 0;
  @override
  Widget buildWidget() => const ColoredBox(
    key: ValueKey('loaded-test-creative'),
    color: Colors.blue,
  );
  @override
  void dispose() => disposals++;
}

class _Request {
  _Request(this.size, this.impression);
  final ExitAdSize size;
  final VoidCallback impression;
  final result = Completer<ExitAdCreative?>();
  _Creative fill() {
    final ad = _Creative(size);
    result.complete(ad);
    return ad;
  }
}

class _Loader {
  final requests = <_Request>[];
  Future<ExitAdCreative?> load(ExitAdSize size, VoidCallback impression) {
    final request = _Request(size, impression);
    requests.add(request);
    return request.result.future;
  }
}

class _Consent extends AdMobConsentController {
  bool allowed = true;
  @override
  bool get canRequestAds => allowed;
  void revoke() {
    allowed = false;
    notifyListeners();
  }
}

class _FailingDisk extends InMemorySharedPreferencesStore {
  _FailingDisk() : super.empty();
  bool fail = false;
  int stateWrites = 0;

  @override
  Future<bool> setValue(String type, String key, Object value) {
    if (key == 'flutter.sobra_state_v2') {
      stateWrites++;
      if (fail) return Future.value(false);
    }
    return super.setValue(type, key, value);
  }
}

void main() {
  late _Loader loader;
  late ExitNativeAds ads;
  late DateTime now;
  late int impressions;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    loader = _Loader();
    now = DateTime(2026, 11, 7, 10);
    impressions = 0;
    ads = ExitNativeAds(
      load: loader.load,
      now: () => now,
      onImpression: () => impressions++,
    );
  });
  tearDown(() => ads.dispose());

  test(
    'preloads one template; consumes once; counts real impressions once',
    () async {
      ads.configure(size: ExitAdSize.medium, enabled: true);
      ads.configure(size: ExitAdSize.medium, enabled: true);
      expect(loader.requests, hasLength(1));
      expect(impressions, 0);
      final creative = loader.requests.single.fill();
      await pumpEventQueue();
      expect(ads.beginPresentation(canShow: true), same(creative));
      expect(ads.beginPresentation(canShow: true), isNull);
      loader.requests.single.impression();
      loader.requests.single.impression();
      expect(impressions, 1);
      creative.dispose();
      ads.endPresentation();
      expect(loader.requests, hasLength(2));
    },
  );

  test('stale template responses are disposed after a size change', () async {
    ads.configure(size: ExitAdSize.medium, enabled: true);
    ads.configure(size: ExitAdSize.small, enabled: true);
    final stale = loader.requests.first.fill();
    final small = loader.requests.last.fill();
    await pumpEventQueue();
    expect(stale.disposals, 1);
    expect(ads.beginPresentation(canShow: true), same(small));
    small.dispose();
  });

  test(
    'late results are disposed after consent loss or owner disposal',
    () async {
      ads.configure(size: ExitAdSize.small, enabled: true);
      ads.configure(size: ExitAdSize.small, enabled: false);
      final first = loader.requests.first.fill();
      await pumpEventQueue();
      expect(first.disposals, 1);
      ads.configure(size: ExitAdSize.small, enabled: true);
      ads.dispose();
      final last = loader.requests.last.fill();
      await pumpEventQueue();
      expect(last.disposals, 1);
    },
  );

  test('expired cached ad is never shown, and failure does not loop', () async {
    ads.configure(size: ExitAdSize.small, enabled: true);
    final expired = loader.requests.single.fill();
    await pumpEventQueue();
    now = now.add(const Duration(hours: 1));
    expect(ads.beginPresentation(canShow: true), isNull);
    expect(expired.disposals, 1);
    ads.endPresentation();
    loader.requests.last.result.complete(null);
    await pumpEventQueue();
    ads.configure(size: ExitAdSize.small, enabled: true);
    expect(loader.requests, hasLength(2));
  });

  test(
    'session impression gap follows the shared clock-correction policy',
    () async {
      ads.configure(size: ExitAdSize.small, enabled: true);
      final first = loader.requests.single.fill();
      await pumpEventQueue();
      expect(ads.beginPresentation(canShow: true), same(first));
      loader.requests.single.impression();
      first.dispose();
      ads.endPresentation();
      final next = loader.requests.last.fill();
      await pumpEventQueue();
      expect(ads.beginPresentation(canShow: true), isNull);
      ads.endPresentation();
      now = now.subtract(const Duration(minutes: 1));
      // A clock correction invalidates a cache loaded in the future, but a
      // new creative must not be blocked by the previous impression's date.
      expect(ads.beginPresentation(canShow: true), isNull);
      expect(next.disposals, 1);
      ads.endPresentation();
      final afterCorrection = loader.requests.last.fill();
      await pumpEventQueue();
      expect(ads.beginPresentation(canShow: true), same(afterCorrection));
      afterCorrection.dispose();
    },
  );

  Future<SobraStore> pumpGuard(
    WidgetTester tester, {
    Size size = const Size(390, 844),
    double textScale = 1,
    _Consent? consent,
    bool ownedAds = false,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = await SobraStore.load(now: () => now);
    final permission = consent ?? _Consent();
    addTearDown(permission.dispose);
    await tester.pumpWidget(
      SobraScope(
        store: store,
        child: AdMobConsentScope(
          consent: permission,
          child: MaterialApp(
            theme: buildSobraTheme(),
            locale: const Locale('ko'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: sobraLocalizationsDelegates,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(textScale)),
              child: child!,
            ),
            home: AppExitGuard(
              ads: ownedAds ? null : ads,
              adLoader: ownedAds ? loader.load : null,
              child: Scaffold(
                body: Builder(
                  builder: (context) => TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const Scaffold(body: Text('detail')),
                      ),
                    ),
                    child: const Text('open detail'),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    return store;
  }

  Future<void> back(WidgetTester tester) async {
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
  }

  for (final (size, expected) in [
    (const Size(390, 844), ExitAdSize.medium),
    (const Size(360, 580), ExitAdSize.small),
  ]) {
    testWidgets('auto selects $expected with no clipped exit controls', (
      tester,
    ) async {
      await pumpGuard(tester, size: size);
      expect(loader.requests.single.size, expected);
      final creative = loader.requests.single.fill();
      await tester.pump();
      await back(tester);
      expect(
        tester.getSize(find.byKey(const ValueKey('exit-native-ad-slot'))),
        Size(320, expected.height),
      );
      final confirm = tester.getRect(
        find.byKey(const ValueKey('exit-confirm')),
      );
      expect(confirm.bottom, lessThan(size.height));
      expect(tester.takeException(), isNull);
      await tester.tap(find.byKey(const ValueKey('exit-cancel')));
      await tester.pumpAndSettle();
      expect(creative.disposals, 1);
    });
  }

  testWidgets('late fill never inserts into an already-open ad-free dialog', (
    tester,
  ) async {
    await pumpGuard(tester);
    await back(tester);
    final frame = tester.getRect(
      find.byKey(const ValueKey('exit-dialog-frame')),
    );
    final button = tester.getRect(find.byKey(const ValueKey('exit-confirm')));
    loader.requests.single.fill();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('exit-native-ad-slot')), findsNothing);
    expect(
      tester.getRect(find.byKey(const ValueKey('exit-dialog-frame'))),
      frame,
    );
    expect(tester.getRect(find.byKey(const ValueKey('exit-confirm'))), button);
    await tester.tap(find.byKey(const ValueKey('exit-cancel')));
    await tester.pumpAndSettle();
    await back(tester);
    expect(find.byKey(const ValueKey('exit-native-ad-slot')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('exit-cancel')));
    await tester.pumpAndSettle();
  });

  testWidgets('revocation hides the creative without moving the exit button', (
    tester,
  ) async {
    final consent = _Consent();
    await pumpGuard(tester, consent: consent);
    loader.requests.single.fill();
    await tester.pump();
    await back(tester);
    final before = tester.getRect(find.byKey(const ValueKey('exit-confirm')));
    consent.revoke();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('loaded-test-creative')), findsNothing);
    expect(tester.getRect(find.byKey(const ValueKey('exit-confirm'))), before);
    await tester.tap(find.byKey(const ValueKey('exit-cancel')));
    await tester.pumpAndSettle();
  });

  testWidgets(
    'no-ads entitlement and existing impression interval are respected',
    (tester) async {
      final store = await pumpGuard(tester);
      final creative = loader.requests.single.fill();
      await tester.pump();
      await store.recordNativeAdImpression();
      await back(tester);
      expect(find.byKey(const ValueKey('exit-native-ad-slot')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('exit-cancel')));
      await tester.pumpAndSettle();
      await store.grantCatalogEntry(CatalogPreviewData.noAdsEntitlement);
      expect(creative.disposals, 1);
      now = now.add(const Duration(minutes: 10));
      await back(tester);
      expect(find.byKey(const ValueKey('exit-native-ad-slot')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('exit-cancel')));
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'failed impression save keeps exit usable and preserves the session gap',
    (tester) async {
      final disk = _FailingDisk();
      SharedPreferencesStorePlatform.instance = disk;
      SharedPreferences.resetStatic();
      addTearDown(SharedPreferences.resetStatic);
      final store = await pumpGuard(tester, ownedAds: true);
      final request = loader.requests.single;
      request.fill();
      await tester.pump();
      await back(tester);
      expect(find.byKey(const ValueKey('exit-native-ad-slot')), findsOneWidget);

      final writes = disk.stateWrites;
      disk.fail = true;
      request.impression();
      request.impression();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(disk.stateWrites, writes + 1);
      expect(store.lastNativeAdImpressionAt, isNull);
      await tester.tap(find.byKey(const ValueKey('exit-cancel')));
      await tester.pumpAndSettle();

      final next = loader.requests.last;
      next.fill();
      await tester.pump();
      now = now.add(const Duration(minutes: 4, seconds: 59));
      await back(tester);
      expect(find.byKey(const ValueKey('exit-native-ad-slot')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('exit-cancel')));
      await tester.pumpAndSettle();

      now = now.add(const Duration(seconds: 1));
      await back(tester);
      expect(find.byKey(const ValueKey('exit-native-ad-slot')), findsOneWidget);
      disk.fail = false;
      next.impression();
      next.impression();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(disk.stateWrites, writes + 2);
      expect(store.lastNativeAdImpressionAt, now);
      await tester.tap(find.byKey(const ValueKey('exit-cancel')));
      await tester.pumpAndSettle();
    },
  );

  for (final (size, scale) in [
    (const Size(320, 640), 1.0),
    (const Size(390, 844), 2.0),
  ]) {
    testWidgets(
      'narrow/large-text layout $size $scale remains usable without ad',
      (tester) async {
        await pumpGuard(tester, size: size, textScale: scale);
        expect(loader.requests, isEmpty);
        await back(tester);
        expect(find.byKey(const ValueKey('exit-native-ad-slot')), findsNothing);
        expect(tester.takeException(), isNull);
        expect(
          tester.getRect(find.byKey(const ValueKey('exit-confirm'))).bottom,
          lessThan(size.height),
        );
        await tester.tap(find.byKey(const ValueKey('exit-cancel')));
        await tester.pumpAndSettle();
      },
    );
  }

  testWidgets(
    'pushed screens go back normally; only confirm requests Android exit',
    (tester) async {
      var exits = 0;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'SystemNavigator.pop') exits++;
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await pumpGuard(tester);
      await tester.tap(find.text('open detail'));
      await tester.pumpAndSettle();
      await back(tester);
      expect(find.byType(ExitConfirmationDialog), findsNothing);
      expect(exits, 0);
      await back(tester);
      await back(
        tester,
      ); // System back cancels the dialog, never exits the app.
      expect(find.byType(ExitConfirmationDialog), findsNothing);
      expect(exits, 0);
      await back(tester);
      await tester.tap(find.byKey(const ValueKey('exit-confirm')));
      await tester.pumpAndSettle();
      expect(exits, 1);
    },
  );

  testWidgets('rapid cancel taps never pop the home route', (tester) async {
    await pumpGuard(tester);
    await back(tester);
    final cancel = find.byKey(const ValueKey('exit-cancel'));
    final position = tester.getCenter(cancel);
    await tester.tap(cancel);
    await tester.pump(const Duration(milliseconds: 16));
    // The closing route ignores input; exercise a real second pointer tap.
    await tester.tapAt(position);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('open detail'), findsOneWidget);
    await back(tester);
    expect(find.byType(ExitConfirmationDialog), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('exit-cancel')));
    await tester.pumpAndSettle();
  });

  testWidgets('SDK load errors keep the ad-free dialog usable', (tester) async {
    await pumpGuard(tester);
    await back(tester);
    final frame = tester.getRect(
      find.byKey(const ValueKey('exit-dialog-frame')),
    );
    final exitButton = tester.getRect(
      find.byKey(const ValueKey('exit-confirm')),
    );
    loader.requests.single.result.completeError(StateError('SDK unavailable'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey('exit-native-ad-slot')), findsNothing);
    expect(
      tester.getRect(find.byKey(const ValueKey('exit-dialog-frame'))),
      frame,
    );
    expect(
      tester.getRect(find.byKey(const ValueKey('exit-confirm'))),
      exitButton,
    );
    await tester.tap(find.byKey(const ValueKey('exit-cancel')));
    await tester.pumpAndSettle();
    expect(find.text('open detail'), findsOneWidget);
    await back(tester);
    expect(find.byType(ExitConfirmationDialog), findsOneWidget);
    expect(loader.requests, hasLength(1));
    await tester.tap(find.byKey(const ValueKey('exit-cancel')));
    await tester.pumpAndSettle();
    // This test owns the injected cache, including its retry timer.
    ads.dispose();
  });
}
