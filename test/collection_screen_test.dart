import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sobra_app/data/catalog_preview_data.dart';
import 'package:sobra_app/models/catalog_entry.dart';
import 'package:sobra_app/models/room_design.dart';
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

  /// A store with the daily limit switched on.
  ///
  /// The app ships without one, so this is the only way the "limit reached"
  /// card is reachable. It stays tested because the limit is still a supported
  /// setting, and a card nothing can render is a card that breaks unnoticed.
  Future<SobraStore> loadCappedStore() => SobraStore.load(
    now: () => DateTime(2026, 9, 14, 11),
    rewardedAdsPerDay: 3,
  );

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
    String? initialEntryId,
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
        home: CollectionScreen(
          openedFromDecorate: openedFromDecorate,
          initialEntryId: initialEntryId,
        ),
      ),
    );
    if (ads != null) app = RewardedAdScope(ads: ads, child: app);
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();
  }

  // The header art is a picture of a room, so it has to be the user's room:
  // pinned to Casa clara it went stale the moment another one was equipped.
  testWidgets('the header shows the equipped room', (tester) async {
    final store = await loadStore();
    await store.saveRoomSelection(
      roomId: RoomThemes.casaJardinId,
      placementsByRoom: const {},
    );
    await pump(tester, store);

    final art = tester
        .widgetList<Image>(find.byType(Image))
        .map((image) => (image.image as AssetImage).assetName);
    expect(art, contains(RoomThemes.casaJardin.previewAsset));
    expect(art, isNot(contains(RoomThemes.casaClara.previewAsset)));
  });

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

    await tester.ensureVisible(find.text('Personaje 2'));
    await tester.pumpAndSettle();
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

    await tester.scrollUntilVisible(
      find.text('Personaje 10'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Personaje 10'));
    await tester.pumpAndSettle();

    expect(inDialog('COMPRAR'), findsOneWidget);
    expect(inDialog('EQUIPAR'), findsNothing);
  });

  // Slot 10 has no product in Play until it has a name, so nothing quotes it.
  testWidgets('a paid character with no price cannot be bought', (
    tester,
  ) async {
    final store = await loadStore();
    final unpriced = entryById('character-10');
    expect(store.ownsCatalogEntry(unpriced), isFalse);
    await pump(tester, store, initialEntryId: 'character-10');

    expect(inDialog('Personaje 10'), findsOneWidget);
    expect(inDialog('COMPRAR'), findsOneWidget);
    final buyButton = tester.widget<FilledButton>(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(FilledButton),
      ),
    );
    expect(buyButton.onPressed, isNull);
  });

  testWidgets('Bunny appears in the collection at the single price', (
    tester,
  ) async {
    final store = await loadStore();
    await pump(tester, store, initialEntryId: 'rabbit');

    expect(inDialog('Bunny'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.textContaining(r'MX$ 39'),
      ),
      findsOneWidget,
    );
    final buyButton = tester.widget<FilledButton>(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(FilledButton),
      ),
    );
    expect(buyButton.onPressed, isNotNull);
  });

  testWidgets('Pico appears in the collection at the single price', (
    tester,
  ) async {
    final store = await loadStore();
    await pump(tester, store, initialEntryId: 'platypus');

    expect(inDialog('Pico'), findsOneWidget);
    expect(inDialog('COMPRAR'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.textContaining(r'MX$ 39'),
      ),
      findsOneWidget,
    );
    final buyButton = tester.widget<FilledButton>(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(FilledButton),
      ),
    );
    expect(buyButton.onPressed, isNotNull);
  });

  testWidgets('a stored ad count is what the card counts from', (tester) async {
    final store = await loadStore();
    await store.recordRewardedAdView(entryById('character-03'));

    await pump(tester, store, ads: await readyAds(store));

    // The count is its own line now, so the button says what it does and the
    // line says how far along the run is.
    // The lazy grid builds the visible cards; later entries load on scroll.
    expect(find.text('VER ANUNCIO'), findsAtLeastNWidgets(3));
    expect(find.text('1/2'), findsOneWidget);
    // The lazy grid has not necessarily built every later character card.
    expect(find.text('0/2'), findsAtLeastNWidgets(2));
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

    expect(find.text('SIN ANUNCIOS'), findsAtLeastNWidgets(3));
    // Blocked, but the run is still legible.
    expect(find.text('0/2'), findsAtLeastNWidgets(3));
  });

  // No ad system above the screen at all — the design gallery, and every
  // widget test that does not ask for one.
  testWidgets('with no ad provider the cards are locked, not counting', (
    tester,
  ) async {
    final store = await loadStore();

    await pump(tester, store);

    expect(find.text('SIN ANUNCIOS'), findsAtLeastNWidgets(3));
  });

  testWidgets('a spent daily cap is what every ad card says', (tester) async {
    final store = await loadCappedStore();
    await store.recordRewardedAdView(entryById('item-03'));
    await store.recordRewardedAdView(entryById('item-05'));
    await store.recordRewardedAdView(entryById('item-08'));
    expect(store.rewardedAdsLeftToday, 0);

    await pump(tester, store, ads: await readyAds(store));

    expect(find.text('LÍMITE DE HOY'), findsAtLeastNWidgets(3));
  });

  testWidgets('the special tier says it continues tomorrow', (tester) async {
    final store = await loadStore();
    final special = entryById('character-08');
    await store.recordRewardedAdView(special);

    await pump(tester, store, ads: await readyAds(store));

    await tester.scrollUntilVisible(
      find.text('Personaje 8'),
      200,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text('SIGUE MAÑANA'), findsOneWidget);
    // The count stays on screen through the wait. Seeing 1/3 is the reason to
    // come back tomorrow; a card that only says "later" is a locked card.
    expect(find.text('1/3'), findsOneWidget);
    // The others are untouched: one entry's day does not spend anybody else's.
    expect(find.text('0/2'), findsWidgets);
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
    final port = FakeRewardedAdPort()..script = [RewardedAdResult.dismissed];
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

  // "SIGUE MAÑANA" says an entry is waiting without ever saying why. The card
  // has no room for the rule, so the dialog is where it is written out.
  testWidgets('the dialog explains the once-a-day rule', (tester) async {
    final store = await loadStore();
    final special = entryById('character-08');
    expect(special.rewardedAdOncePerDay, isTrue);
    await store.recordRewardedAdView(special);

    await pump(tester, store, ads: await readyAds(store));
    await tester.scrollUntilVisible(
      find.text('Personaje 8'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Personaje 8'));
    await tester.pumpAndSettle();

    expect(
      inDialog('Mira anuncios de recompensa · 1/3 · uno por día'),
      findsOneWidget,
    );
  });

  testWidgets('an ordinary entry is not told it is once a day', (tester) async {
    final store = await loadStore();

    await pump(tester, store, ads: await readyAds(store));
    await tester.ensureVisible(find.text('Personaje 3'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Personaje 3'));
    await tester.pumpAndSettle();

    expect(inDialog('Mira anuncios de recompensa · 0/2'), findsOneWidget);
    expect(
      inDialog('Mira anuncios de recompensa · 0/2 · uno por día'),
      findsNothing,
    );
  });

  testWidgets('Guinea Pig unlocks in the collection after two ads', (
    tester,
  ) async {
    final store = await loadStore();
    final entry = entryById('guinea-pig');
    await pump(
      tester,
      store,
      ads: await readyAds(store),
      initialEntryId: 'guinea-pig',
    );

    expect(find.text('Cookie'), findsWidgets);
    expect(inDialog('Mira anuncios de recompensa · 0/2'), findsOneWidget);
    expect(inDialog('VER ANUNCIO'), findsOneWidget);
    expect(store.ownsCatalogEntry(entry), isFalse);

    await tester.tap(inDialog('VER ANUNCIO'));
    await tester.pumpAndSettle();
    expect(store.rewardedAdProgressFor(entry.id), 1);
    expect(store.ownsCatalogEntry(entry), isFalse);

    await tester.tap(find.text('Cookie'));
    await tester.pumpAndSettle();
    expect(inDialog('Mira anuncios de recompensa · 1/2'), findsOneWidget);
    await tester.tap(inDialog('VER ANUNCIO'));
    await tester.pumpAndSettle();
    expect(store.ownsCatalogEntry(entry), isTrue);
    expect(find.text('¡Cookie es tuyo!'), findsOneWidget);
  });

  // The fetch in front of the ad is a network round trip. Before the card said
  // so, the only feedback for a tap was an unchanged button.
  testWidgets('the card says it is preparing while an ad is fetched', (
    tester,
  ) async {
    final store = await loadStore();
    final port = _SlowRewardedAdPort();
    final ads = RewardedAds(port: port, store: store);
    await pump(tester, store, ads: ads);

    // Not awaited: the assertion below is about what the screen shows while
    // the run is still in flight.
    final run = ads.watch(entryById('character-03'));
    await tester.pump();

    expect(find.text('PREPARANDO'), findsOneWidget);

    port.finishLoad();
    await run;
    await tester.pumpAndSettle();

    expect(find.text('PREPARANDO'), findsNothing);
    expect(store.rewardedAdProgressFor('character-03'), 1);
  });

  // The dead end found on a device: one empty answer at launch left every
  // rewarded card reading "no ads" for the rest of the process, because the
  // card that would have asked for another ad had stopped accepting taps.
  testWidgets('a no-fill at launch does not disable ads for the session', (
    tester,
  ) async {
    final store = await loadStore();
    final port = FakeRewardedAdPort()..fills = false;
    final ads = RewardedAds(port: port, store: store);
    // The one request the app makes at launch, and it comes back empty.
    await ads.prepare();
    expect(ads.isReady, isFalse);

    await pump(tester, store, ads: ads);
    await tester.tap(find.text('OBJETOS'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Objeto 3'));
    await tester.pumpAndSettle();

    // The network recovers while the user is looking at the screen.
    port.fills = true;
    await tester.tap(find.text('Objeto 3'));
    await tester.pumpAndSettle();
    await tester.tap(inDialog('SIN ANUNCIOS'));
    await tester.pumpAndSettle();

    expect(store.ownsCatalogEntry(entryById('item-03')), isTrue);
  });

  // Opening the screen asks for one, so the common case never reaches the tap.
  testWidgets('opening the collection asks for an ad', (tester) async {
    final store = await loadStore();
    final port = FakeRewardedAdPort();
    final ads = RewardedAds(port: port, store: store);
    expect(port.loads, 0);

    await pump(tester, store, ads: ads);

    expect(port.loads, greaterThan(0));
    expect(ads.isReady, isTrue);
  });

  // The real rules still close the button. Only an empty network stays open.
  testWidgets('a rule-blocked card still refuses the tap', (tester) async {
    final store = await loadCappedStore();
    await store.recordRewardedAdView(entryById('item-03'));
    await store.recordRewardedAdView(entryById('item-05'));
    await store.recordRewardedAdView(entryById('item-08'));
    expect(store.rewardedAdsLeftToday, 0);

    await pump(tester, store, ads: await readyAds(store));
    await tester.ensureVisible(find.text('Personaje 3'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Personaje 3'));
    await tester.pumpAndSettle();

    // Asserted by behaviour rather than by widget type: pressing it must not
    // start a run, whatever the button happens to be made of.
    expect(inDialog('LÍMITE DE HOY'), findsOneWidget);
    await tester.tap(inDialog('LÍMITE DE HOY'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(store.rewardedAdProgressFor('character-03'), 0);
    expect(store.rewardedAdsLeftToday, 0);
  });

  testWidgets('an initial entry opens its detail without playing an ad', (
    tester,
  ) async {
    final store = await loadStore();
    await pump(tester, store, initialEntryId: 'item-03');

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(inDialog('Objeto 3'), findsOneWidget);
    expect(store.rewardedAdProgressFor('item-03'), 0);
  });

  testWidgets('new room items appear in Items with their own art', (
    tester,
  ) async {
    final store = await loadStore();
    await pump(tester, store, initialEntryId: RoomDecorAssets.rattanChairId);

    expect(inDialog('Sillón de ratán'), findsOneWidget);
    expect(inDialog('OBTENIDO'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                RoomDecorAssets.rattanChair,
      ),
      findsWidgets,
    );
    expect(
      CatalogPreviewData.items.map((entry) => entry.id),
      containsAll([
        RoomDecorAssets.rattanChairId,
        RoomDecorAssets.floorLampId,
        RoomDecorAssets.wallClockId,
      ]),
    );
  });
}

/// A network whose fetch can be held open, so a test can look at the screen
/// while the run is still working.
class _SlowRewardedAdPort implements RewardedAdPort {
  final _loaded = Completer<void>();
  bool _ready = false;

  void finishLoad() {
    _ready = true;
    _loaded.complete();
  }

  @override
  bool get isReady => _ready;

  @override
  Future<void> load() => _loaded.future;

  @override
  Future<RewardedAdResult> show() async {
    _ready = false;
    return RewardedAdResult.earned;
  }
}
