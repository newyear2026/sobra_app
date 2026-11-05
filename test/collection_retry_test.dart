import 'dart:io';
import 'dart:ui' as ui;

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sobra_app/data/catalog_preview_data.dart';
import 'package:sobra_app/l10n/catalog_labels.dart';
import 'package:sobra_app/l10n/generated/app_localizations.dart';
import 'package:sobra_app/screens/collection_screen.dart';
import 'package:sobra_app/services/app_telemetry.dart';
import 'package:sobra_app/services/rewarded_ad_service.dart';
import 'package:sobra_app/state/sobra_store.dart';
import 'package:sobra_app/theme/app_theme.dart';
import 'package:sobra_app/widgets/cat_sprite.dart';

import 'support/fake_rewarded_ad.dart';
import 'support/localizations.dart';

const _sceneKey = ValueKey('retry-scene');

Future<void> _capture(WidgetTester tester, String name) async {
  final directory = Platform.environment['SOBRITA_RETRY_EVIDENCE_DIR'];
  if (directory == null) return;
  final context = tester.element(find.byType(CollectionScreen));
  final providers = <ImageProvider>{
    for (final image in tester.widgetList<Image>(find.byType(Image)))
      image.image,
    for (final sprite in tester.widgetList<CharacterSprite>(
      find.byType(CharacterSprite),
    ))
      AssetImage(sprite.asset),
  };
  await tester.runAsync(
    () => Future.wait([
      for (final provider in providers) precacheImage(provider, context),
    ]),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_sceneKey),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage();
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      await Directory(directory).create(recursive: true);
      await File('$directory/$name.png').writeAsBytes(
        data!.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      );
    } finally {
      image.dispose();
    }
  });
}

Future<void> _pumpCollection(
  WidgetTester tester,
  SobraStore store,
  RewardedAds ads, {
  required String language,
  required String entryId,
  double scale = 1,
}) async {
  tester.view.physicalSize = const Size(320, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await store.setReducedMotion(true);
  await tester.pumpWidget(
    RepaintBoundary(
      key: _sceneKey,
      child: SobraScope(
        store: store,
        child: RewardedAdScope(
          ads: ads,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            locale: Locale(language),
            localizationsDelegates: sobraLocalizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: buildSobraTheme(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: CollectionScreen(
              origin: CollectionOrigin.settings,
              initialEntryId: entryId,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    await Future.wait([
      (FontLoader(
        'PixelifySans',
      )..addFont(rootBundle.load('assets/fonts/PixelifySans.ttf'))).load(),
      (FontLoader(
        'MaterialIcons',
      )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load(),
    ]);
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AppTelemetry.instance = AppTelemetry();
    addTearDown(() => AppTelemetry.instance = AppTelemetry());
  });

  for (final (language, retry, unavailable) in [
    ('es', 'REINTENTAR', 'SIN ANUNCIOS'),
    ('pt', 'TENTAR DE NOVO', 'SEM ANÚNCIOS'),
  ]) {
    testWidgets('$language retry preserves failure notice and grants once', (
      tester,
    ) async {
      final events = <(String, Map<String, Object>)>[];
      AppTelemetry.instance = AppTelemetry(
        sendEvent: (name, parameters) async => events.add((name, parameters)),
      );
      final store = await SobraStore.load(
        now: () => DateTime(2026, 10, 30, 12),
      );
      final entry = CatalogPreviewData.all.firstWhere(
        (entry) => entry.id == 'decor-shelf-books',
      );
      final port = FakeRewardedAdPort()..fills = false;
      final ads = RewardedAds(port: port, store: store);
      addTearDown(ads.dispose);
      final l10n = lookupAppLocalizations(Locale(language));
      final title = catalogEntryDisplayName(l10n, entry);
      await _pumpCollection(
        tester,
        store,
        ads,
        language: language,
        entryId: entry.id,
      );

      Finder action() => find.widgetWithText(FilledButton, retry);
      expect(action(), findsOneWidget);
      expect(tester.widget<FilledButton>(action()).onPressed, isNotNull);
      expect(store.ownsCatalogEntry(entry), isFalse);
      await tester.tap(action());
      await tester.pumpAndSettle();
      expect(find.widgetWithText(SnackBar, unavailable), findsOneWidget);
      expect(port.shows, 0);
      expect(store.rewardedAdsWatchedToday, 0);
      expect(store.ownsCatalogEntry(entry), isFalse);

      // Recover only after the unavailable result. This exercises the actual
      // card -> detail -> retry route, not a direct call to the ad service.
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text(title),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(find.text(title));
      await tester.pumpAndSettle();
      await tester.tap(find.text(title));
      await tester.pumpAndSettle();
      expect(action(), findsOneWidget);
      port.fills = true;
      await tester.tap(action());
      await tester.pumpAndSettle();

      expect(port.shows, 1);
      expect(store.rewardedAdsWatchedToday, 1);
      expect(store.ownsCatalogEntry(entry), isTrue);
      expect(
        events
            .where((event) => event.$1 == 'rewarded_ad_result')
            .map((event) => event.$2['result']),
        ['unavailable', 'counted'],
      );
      expect(
        events.where((event) => event.$1 == 'item_unlocked'),
        hasLength(1),
      );
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      // Reopening the now-owned item cannot pay again or start another ad.
      await tester.ensureVisible(find.text(title));
      await tester.pumpAndSettle();
      await tester.tap(find.text(title));
      await tester.pumpAndSettle();
      final owned = find.widgetWithText(FilledButton, l10n.collectionOwned);
      expect(tester.widget<FilledButton>(owned).onPressed, isNull);
      expect(port.shows, 1);
      expect(store.rewardedAdsWatchedToday, 1);
      expect(Firebase.apps, isEmpty);
      expect(tester.takeException(), isNull);
    });

    for (final scale in [1.0, 2.0]) {
      testWidgets('$language retry fits 320px with text scale $scale', (
        tester,
      ) async {
        final store = await SobraStore.load(
          now: () => DateTime(2026, 10, 30, 12),
        );
        final port = FakeRewardedAdPort()..fills = false;
        final ads = RewardedAds(port: port, store: store);
        addTearDown(ads.dispose);
        await _pumpCollection(
          tester,
          store,
          ads,
          language: language,
          entryId: 'quokka',
          scale: scale,
        );
        final action = find.widgetWithText(FilledButton, retry);
        final label = find.descendant(of: action, matching: find.text(retry));
        final buttonRect = tester.getRect(action);
        final labelRect = tester.getRect(label);
        expect(buttonRect.contains(labelRect.topLeft), isTrue);
        expect(buttonRect.contains(labelRect.bottomRight), isTrue);
        expect(buttonRect.left, greaterThanOrEqualTo(0));
        expect(buttonRect.right, lessThanOrEqualTo(320));
        expect(buttonRect.bottom, lessThanOrEqualTo(800));
        expect(action.hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
        await _capture(tester, '$language-320-scale${scale.toInt()}-detail');

        await tester.tap(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.byIcon(Icons.close),
          ),
        );
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.text('Quokka'),
          150,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        expect(find.text(retry).hitTestable(), findsWidgets);
        expect(port.shows, 0);
        expect(tester.takeException(), isNull);
        await _capture(tester, '$language-320-scale${scale.toInt()}-cards');
      });
    }
  }
}
