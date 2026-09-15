import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sobra_app/data/catalog_preview_data.dart';
import 'package:sobra_app/models/catalog_entry.dart';
import 'package:sobra_app/screens/collection_screen.dart';
import 'package:sobra_app/services/rewarded_ad_service.dart';
import 'package:sobra_app/state/sobra_store.dart';
import 'package:sobra_app/theme/app_theme.dart';

import 'support/fake_rewarded_ad.dart';
import 'support/localizations.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<SobraStore> loadStore() =>
      SobraStore.load(now: () => DateTime(2026, 9, 14, 11));

  CatalogEntry entryById(String id) => [
    ...CatalogPreviewData.characters,
    ...CatalogPreviewData.items,
  ].firstWhere((entry) => entry.id == id);

  /// Text inside the open detail dialog.
  ///
  /// Scoped because the card the dialog was opened from is still mounted
  /// behind it, carrying the very same action label.
  Finder inDialog(String text) =>
      find.descendant(of: find.byType(AlertDialog), matching: find.text(text));

  /// An ad network with one ad loaded and ready.
  Future<RewardedAds> readyAds(SobraStore store) async {
    final port = FakeRewardedAdPort();
    final ads = RewardedAds(port: port, store: store);
    await ads.prepare();
    return ads;
  }

  Future<void> pump(
    WidgetTester tester,
    SobraStore store, {
    RewardedAds? ads,
    bool openedFromDecorate = false,
  }) async {
    tester.view.physicalSize = const Size(520, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    useSpanishDevice(tester);
    Widget app = SobraScope(
      store: store,
      child: MaterialApp(
        localizationsDelegates: sobraLocalizationsDelegates,
        supportedLocales: sobraSupportedLocales,
        theme: buildSobraTheme(),
        home: CollectionScreen(openedFromDecorate: openedFromDecorate),
      ),
    );
    if (ads != null) app = RewardedAdScope(ads: ads, child: app);
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();
  }

  // The screen used to hold ownership in its own State, so what it offered was
  // the same two ids for everybody regardless of what the user had done.
  // Owning it ends the collection's business with it: not for sale any more,
  // and not for wearing either. Wearing belongs to the decorate screen, which
  // is the one that can show the choice landing.
  testWidgets('a granted character is neither for sale nor for equipping', (
    tester,
  ) async {
    final store = await loadStore();
    await store.grantCatalogEntry('character-02');
    await pump(tester, store);

    await tester.tap(find.text('Personaje 2'));
    await tester.pumpAndSettle();

    expect(inDialog('OBTENIDO'), findsOneWidget);
    expect(inDialog('COMPRAR'), findsNothing);
    expect(inDialog('EQUIPAR'), findsNothing);
    expect(store.characterId, 'michi');
  });

  testWidgets('an unowned character still offers only its purchase', (
    tester,
  ) async {
    final store = await loadStore();
    await pump(tester, store);

    await tester.tap(find.text('Personaje 7'));
    await tester.pumpAndSettle();

    expect(inDialog('COMPRAR'), findsOneWidget);
    expect(inDialog('EQUIPAR'), findsNothing);
  });

  testWidgets('a stored ad count is what the card counts from', (tester) async {
    final store = await loadStore();
    await store.recordRewardedAdView(entryById('character-03'));

    await pump(tester, store, ads: await readyAds(store));

    // Three tiers on one screen: an ordinary character at two views, the
    // special one at three.
    expect(find.text('ANUNCIO 1/2'), findsOneWidget);
    expect(find.text('ANUNCIO 0/2'), findsOneWidget);
    expect(find.text('ANUNCIO 0/3'), findsOneWidget);
  });

  testWidgets('an owned item offers nothing to place', (tester) async {
    final store = await loadStore();
    await pump(tester, store);

    await tester.tap(find.text('OBJETOS'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Objeto 1'));
    await tester.pumpAndSettle();

    expect(inDialog('OBTENIDO'), findsOneWidget);
    expect(inDialog('EQUIPAR'), findsNothing);
  });

  // The decoration carries the pack's product id so the store can price the
  // pack. If the card followed that id instead of the unlock method it would
  // offer COMPRAR, and one room object would charge for the whole pack.
  testWidgets('the pack decoration is shown locked, with no price', (
    tester,
  ) async {
    final store = await loadStore();
    await pump(tester, store);

    await tester.tap(find.text('OBJETOS'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Estrella de Michi'),
      200,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text('PAQUETE'), findsOneWidget);
    expect(find.text('COMPRAR'), findsNothing);

    await tester.ensureVisible(find.text('Estrella de Michi'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Estrella de Michi'));
    await tester.pumpAndSettle();

    // Says where it comes from, and offers nothing to tap.
    expect(
      inDialog('Llega con Michi y sus amigos. No se vende por separado.'),
      findsOneWidget,
    );
    expect(inDialog('COMPRAR'), findsNothing);
  });

  // The progress lives on the button, so a blocked run replaces it. The
  // number is still one tap away in the detail dialog, and the button says
  // the more useful thing: there is nothing to watch.
  testWidgets('with no ad loaded the card says so instead of counting', (
    tester,
  ) async {
    final store = await loadStore();
    final port = FakeRewardedAdPort()..fills = false;
    final ads = RewardedAds(port: port, store: store);

    await pump(tester, store, ads: ads);

    expect(find.text('SIN ANUNCIOS'), findsNWidgets(3));
    expect(find.text('ANUNCIO 0/2'), findsNothing);
  });

  // No ad system above the screen at all — the design gallery, and every
  // widget test that does not ask for one.
  testWidgets('with no ad provider the cards are locked, not counting', (
    tester,
  ) async {
    final store = await loadStore();

    await pump(tester, store);

    expect(find.text('SIN ANUNCIOS'), findsNWidgets(3));
  });

  testWidgets('a spent daily cap is what every ad card says', (tester) async {
    final store = await loadStore();
    await store.recordRewardedAdView(entryById('item-03'));
    await store.recordRewardedAdView(entryById('item-05'));
    await store.recordRewardedAdView(entryById('item-08'));
    expect(store.rewardedAdsLeftToday, 0);

    await pump(tester, store, ads: await readyAds(store));

    expect(find.text('LÍMITE DE HOY'), findsNWidgets(3));
  });

  testWidgets('the special tier says it continues tomorrow', (tester) async {
    final store = await loadStore();
    final special = entryById('character-08');
    await store.recordRewardedAdView(special);

    await pump(tester, store, ads: await readyAds(store));

    expect(find.text('SIGUE MAÑANA'), findsOneWidget);
    // The others are untouched: one entry's day does not spend anybody else's.
    expect(find.text('ANUNCIO 0/2'), findsNWidgets(2));
  });

  testWidgets('watching an ad through counts and unlocks', (tester) async {
    final store = await loadStore();
    final item = entryById('item-03');
    expect(item.rewardedAdTarget, 1);

    await pump(tester, store, ads: await readyAds(store));
    await tester.tap(find.text('OBJETOS'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Objeto 3'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Objeto 3'));
    await tester.pumpAndSettle();
    await tester.tap(inDialog('VER ANUNCIO'));
    await tester.pumpAndSettle();

    expect(store.ownsCatalogEntry(item), isTrue);
    expect(store.rewardedAdsWatchedToday, 1);
    expect(find.text('¡Objeto 3 es tuyo!'), findsOneWidget);
  });

  // Acquiring is this screen's work and placing is not, so the unlock hands
  // the user back to the screen that can put the thing somewhere — but only
  // when that screen is the one underneath. Reached from settings there is
  // nothing to go back to, and pushing a decorate screen from inside the
  // collection would stack the two surfaces in the order this split undoes.
  testWidgets('an unlock offers the way back to decorate', (tester) async {
    final store = await loadStore();

    await pump(
      tester,
      store,
      ads: await readyAds(store),
      openedFromDecorate: true,
    );
    await tester.tap(find.text('OBJETOS'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Objeto 3'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Objeto 3'));
    await tester.pumpAndSettle();
    await tester.tap(inDialog('VER ANUNCIO'));
    await tester.pumpAndSettle();

    expect(find.text('Colocarlo'), findsOneWidget);
  });

  testWidgets('reached from anywhere else the unlock offers no way back', (
    tester,
  ) async {
    final store = await loadStore();

    await pump(tester, store, ads: await readyAds(store));
    await tester.tap(find.text('OBJETOS'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Objeto 3'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Objeto 3'));
    await tester.pumpAndSettle();
    await tester.tap(inDialog('VER ANUNCIO'));
    await tester.pumpAndSettle();

    expect(find.text('¡Objeto 3 es tuyo!'), findsOneWidget);
    expect(find.text('Colocarlo'), findsNothing);
  });

  testWidgets('closing an ad early explains why nothing moved', (tester) async {
    final store = await loadStore();
    final port = FakeRewardedAdPort()
      ..script = [RewardedAdResult.dismissed];
    final ads = RewardedAds(port: port, store: store);
    await ads.prepare();

    await pump(tester, store, ads: ads);
    await tester.tap(find.text('OBJETOS'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Objeto 3'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Objeto 3'));
    await tester.pumpAndSettle();
    await tester.tap(inDialog('VER ANUNCIO'));
    await tester.pumpAndSettle();

    expect(store.ownsCatalogEntry(entryById('item-03')), isFalse);
    expect(
      find.text('Mira el anuncio completo para que cuente.'),
      findsOneWidget,
    );
  });
}
