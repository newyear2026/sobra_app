import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sobra_app/screens/collection_screen.dart';
import 'package:sobra_app/screens/room_decorate_screen.dart';
import 'package:sobra_app/models/room_design.dart';
import 'package:sobra_app/state/sobra_store.dart';
import 'package:sobra_app/theme/app_theme.dart';
import 'package:sobra_app/widgets/room_scene.dart';
import 'package:sobra_app/widgets/cat_sprite.dart';

import 'support/decorations.dart';
import 'support/localizations.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  /// Reduced motion so the idle sprite stops animating; otherwise
  /// pumpAndSettle waits on a loop that never ends.
  Future<SobraStore> loadStore({bool stillSprite = true}) async {
    final store = await SobraStore.load(now: () => DateTime(2026, 9, 14, 11));
    if (stillSprite) await store.setReducedMotion(true);
    return store;
  }

  Future<void> pump(WidgetTester tester, SobraStore store) async {
    tester.view.physicalSize = const Size(520, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    useSpanishDevice(tester);
    await tester.pumpWidget(
      SobraScope(
        store: store,
        child: MaterialApp(
          localizationsDelegates: sobraLocalizationsDelegates,
          supportedLocales: sobraSupportedLocales,
          theme: buildSobraTheme(),
          home: const RoomDecorateScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// The category row scrolls, so the last tab starts off screen.
  Future<void> openCategory(WidgetTester tester, String label) async {
    await tester.ensureVisible(find.text(label));
    await tester.pumpAndSettle();
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
  }

  // The drawer used to list what the user could not have, labelled with the
  // action that would get it. Neither action exists on this screen: tapping
  // one showed a snackbar repeating the label and stopped there.
  testWidgets('the drawer offers nothing the user does not own', (
    tester,
  ) async {
    final store = await loadStore();
    await pump(tester, store);

    await openCategory(tester, 'Adornos');

    // Owned from the start, like the jar: everybody has the table plant.
    expect(find.text('Planta de mesa'), findsOneWidget);
    expect(find.text('Frasco de ahorros'), findsOneWidget);
    // The books and the trailing plant are behind a rewarded ad each.
    expect(find.text('Libros'), findsNothing);
    expect(find.text('Planta colgante'), findsNothing);
    expect(find.text('VER ANUNCIO'), findsNothing);
    expect(find.text('COMPRAR'), findsNothing);
    expect(find.text('Ver más en la colección'), findsOneWidget);
  });

  testWidgets('the green lamp appears under props, not furniture', (
    tester,
  ) async {
    final store = await loadStore();
    await ownEverything(store);
    await pump(tester, store);

    expect(find.text('Lámpara verde'), findsNothing);
    await openCategory(tester, 'Adornos');
    expect(find.text('Lámpara verde'), findsOneWidget);
  });

  // The lamp stands on a cabinet, side table or wall shelf. Without any of
  // them, the generic count read "Hay 0 lugares en la mesa" over a room with
  // nothing to tap.
  testWidgets('the green lamp asks for a support until there is one', (
    tester,
  ) async {
    final store = await loadStore();
    await ownEverything(store);
    await pump(tester, store);
    await openCategory(tester, 'Adornos');
    await tester.ensureVisible(find.text('Lámpara verde'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lámpara verde'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Pon la lámpara en un aparador, una mesa auxiliar o una repisa de '
        'pared. Añade uno primero si hace falta.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('Hay 0 lugares'), findsNothing);

    await store.saveRoomSelection(
      roomId: RoomThemes.casaClaraId,
      placementsByRoom: {
        RoomThemes.casaClaraId: {
          RoomSlot.rug: RoomDecorAssets.defaultRugId,
          RoomSlot.floorRight: RoomDecorAssets.roundSideTableId,
        },
      },
    );
    await tester.pumpWidget(const SizedBox.shrink());
    await pump(tester, store);
    await openCategory(tester, 'Adornos');
    await tester.ensureVisible(find.text('Lámpara verde'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lámpara verde'));
    await tester.pumpAndSettle();

    expect(
      find.text('Hay un lugar en la mesa. Tócalo para ponerlo.'),
      findsOneWidget,
    );
  });

  // States from before rooms were saved carry only the equipped item. The
  // lamp used to be parked on a side table that was not there: invisible, and
  // every Listo failed with "wrong place".
  testWidgets('a legacy lamp with no side table does not block saving', (
    tester,
  ) async {
    final fresh = await loadStore();
    await fresh.setReducedMotion(true);
    final preferences = await SharedPreferences.getInstance();
    final saved =
        jsonDecode(preferences.getString('sobra_state_v2')!)
            as Map<String, dynamic>;
    saved
      ..remove('roomPlacementsByRoom')
      ..['equippedItemId'] = 'item-01';
    await preferences.setString('sobra_state_v2', jsonEncode(saved));

    final store = await loadStore();
    await ownEverything(store);
    expect(store.roomDecorationsFor().values, isNot(contains('item-01')));

    await pump(tester, store);
    await tester.tap(find.text('Listo'));
    await tester.pumpAndSettle();

    expect(
      find.text('No pudimos guardar el cambio. Vuelve a intentarlo.'),
      findsNothing,
    );
    // Only a successful save closes the screen.
    expect(find.byType(RoomDecorateScreen), findsNothing);
  });

  testWidgets('an unlocked item joins the drawer', (tester) async {
    final store = await loadStore();
    // item-05 is the wall frame, normally behind a rewarded ad.
    await store.grantCatalogEntry('item-05');
    await pump(tester, store);

    await openCategory(tester, 'Pared y piso');

    expect(find.text('Cuadro'), findsOneWidget);
  });

  testWidgets('the last tile opens the collection', (tester) async {
    final store = await loadStore();
    await pump(tester, store);

    await tester.scrollUntilVisible(
      find.text('Ver más en la colección'),
      180,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ver más en la colección'));
    await tester.pumpAndSettle();

    expect(find.byType(CollectionScreen), findsOneWidget);
  });

  testWidgets('the room tab lists owned rooms and leads to the rest', (
    tester,
  ) async {
    final store = await loadStore();
    await pump(tester, store);
    await openCategory(tester, 'Casa');

    expect(find.text('Casa clara'), findsOneWidget);
    expect(find.text('Casa jardín'), findsNothing);
    expect(find.text('Casa torre'), findsNothing);

    await tester.ensureVisible(find.text('Ver más en la colección'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ver más en la colección'));
    await tester.pumpAndSettle();

    // Lands on the rooms tab, where the locked ones say how to get them.
    expect(find.byType(CollectionScreen), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Casa torre'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text(r'MX$ 19'), findsOneWidget);
    expect(find.text('Casa jardín'), findsOneWidget);
  });

  testWidgets('room themes preview, undo, and persist after Done', (
    tester,
  ) async {
    final store = await loadStore();
    await ownEverything(store);
    await pump(tester, store);
    await openCategory(tester, 'Casa');

    expect(find.text('Casa jardín'), findsOneWidget);
    expect(find.text('Casa de playa'), findsOneWidget);

    await tester.tap(find.text('Casa jardín'));
    await tester.pumpAndSettle();
    expect(store.equippedRoomId, RoomThemes.casaClaraId);
    expect(
      tester.widget<RoomScene>(find.byType(RoomScene)).roomId,
      RoomThemes.casaJardinId,
    );

    await tester.tap(find.byTooltip('Deshacer'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<RoomScene>(find.byType(RoomScene)).roomId,
      RoomThemes.casaClaraId,
    );

    await tester.tap(find.text('Casa de playa'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Listo'));
    await tester.pumpAndSettle();

    expect(store.equippedRoomId, RoomThemes.casaDePlayaId);
    expect((await loadStore()).equippedRoomId, RoomThemes.casaDePlayaId);
    expect(store.roomDecorationsFor()[RoomSlot.floorLeft], isNull);
  });

  testWidgets('panoramic room can be selected and saved', (tester) async {
    final store = await loadStore();
    await ownEverything(store);
    await pump(tester, store);
    await openCategory(tester, 'Casa');

    final choice = find.text('Casa torre');
    await tester.scrollUntilVisible(
      choice,
      160,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(choice);
    await tester.pumpAndSettle();
    expect(
      tester.widget<RoomScene>(find.byType(RoomScene)).roomId,
      RoomThemes.casaTorreId,
    );

    await tester.tap(find.text('Listo'));
    await tester.pumpAndSettle();
    expect(store.equippedRoomId, RoomThemes.casaTorreId);
    expect((await loadStore()).equippedRoomId, RoomThemes.casaTorreId);
  });

  for (final (roomId, label) in [
    (RoomThemes.casaMontanaId, 'Casa montaña'),
    (RoomThemes.casaInvernaderoId, 'Casa invernadero'),
  ]) {
    testWidgets('$label can be selected and saved', (tester) async {
      final store = await loadStore();
      await ownEverything(store);
      await pump(tester, store);
      await openCategory(tester, 'Casa');

      final choice = find.text(label);
      await tester.scrollUntilVisible(
        choice,
        160,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pumpAndSettle();
      await tester.tap(choice);
      await tester.pumpAndSettle();
      expect(tester.widget<RoomScene>(find.byType(RoomScene)).roomId, roomId);

      await tester.tap(find.text('Listo'));
      await tester.pumpAndSettle();
      expect(store.equippedRoomId, roomId);
      expect((await loadStore()).equippedRoomId, roomId);
    });
  }

  testWidgets('the chair, the lamp and the clock can be placed and saved', (
    tester,
  ) async {
    final store = await loadStore();
    await ownEverything(store);
    await pump(tester, store);

    await tester.ensureVisible(find.text('Sillón de ratán'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sillón de ratán'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Piso, lugar 1'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Lámpara de pie'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lámpara de pie'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Piso, lugar 2'));
    await tester.pumpAndSettle();

    await openCategory(tester, 'Pared y piso');
    await tester.ensureVisible(find.text('Reloj de pared'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reloj de pared'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Pared, lugar 1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Listo'));
    await tester.pumpAndSettle();

    final saved = (await loadStore()).roomDecorationsFor();
    expect(saved[RoomSlot.floorLeft], RoomDecorAssets.rattanChairId);
    expect(saved[RoomSlot.floorRight], RoomDecorAssets.floorLampId);
    expect(saved[RoomSlot.wallLeft], RoomDecorAssets.wallClockId);
  });

  testWidgets('the jar sits on the cabinet and leaves with it', (tester) async {
    final store = await loadStore();
    await ownEverything(store);
    await pump(tester, store);
    await openCategory(tester, 'Casa');
    await tester.tap(find.text('Casa jardín'));
    await tester.pumpAndSettle();
    await openCategory(tester, 'Muebles');
    await tester.ensureVisible(find.text('Aparador bajo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Aparador bajo'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Piso, lugar 5'));
    await tester.pumpAndSettle();

    await openCategory(tester, 'Adornos');
    await tester.tap(find.text('Planta de mesa'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Aparador bajo, lugar 2'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Aparador bajo, lugar 2'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<RoomScene>(find.byType(RoomScene)).placements,
      containsPair(
        RoomSlot.cabinetTopRight,
        RoomDecorAssets.defaultTablePlantId,
      ),
    );

    await tester.tap(find.text('Frasco de ahorros'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Aparador bajo, lugar 1'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Aparador bajo, lugar 1'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<RoomScene>(find.byType(RoomScene)).placements,
      containsPair(RoomSlot.cabinetTop, RoomDecorAssets.savingsJarId),
    );

    await openCategory(tester, 'Muebles');
    await tester.ensureVisible(find.text('Aparador bajo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Aparador bajo'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Piso, lugar 5'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Listo'));
    await tester.pumpAndSettle();

    final saved = (await loadStore()).roomDecorationsFor(
      RoomThemes.casaJardinId,
    );
    expect(saved[RoomSlot.floorCabinet], isNull);
    expect(saved[RoomSlot.cabinetTop], isNull);
    expect(saved[RoomSlot.cabinetTopRight], isNull);
  });

  testWidgets('books and plant stay placed when cabinet becomes bookcase', (
    tester,
  ) async {
    final store = await loadStore();
    await ownEverything(store);
    await store.saveRoomDecorations({
      RoomSlot.floorCabinet: RoomDecorAssets.lowCabinetId,
    });
    await pump(tester, store);

    await openCategory(tester, 'Adornos');
    await tester.ensureVisible(find.text('Libros'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Libros'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Aparador bajo, lugar 1'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Planta colgante'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Planta colgante'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Aparador bajo, lugar 2'));
    await tester.pumpAndSettle();

    await openCategory(tester, 'Muebles');
    await tester.ensureVisible(find.text('Estantería estrecha'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Estantería estrecha'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Piso, lugar 5'));
    await tester.pumpAndSettle();

    final draft = tester.widget<RoomScene>(find.byType(RoomScene)).placements;
    expect(draft[RoomSlot.floorCabinet], RoomDecorAssets.slimBookcaseId);
    expect(draft[RoomSlot.cabinetTop], RoomDecorAssets.shelfBooksId);
    expect(draft[RoomSlot.cabinetTopRight], RoomDecorAssets.trailingPlantId);
    await tester.tap(find.text('Listo'));
    await tester.pumpAndSettle();
    expect(
      (await loadStore()).roomDecorationsFor()[RoomSlot.cabinetTopRight],
      RoomDecorAssets.trailingPlantId,
    );
  });

  testWidgets('wall shelf props follow the shelf and leave with it', (
    tester,
  ) async {
    final store = await loadStore();
    await ownEverything(store);
    await store.saveRoomDecorations({
      RoomSlot.wallCenter: RoomDecorAssets.wallShelfId,
    });
    await pump(tester, store);

    await openCategory(tester, 'Adornos');
    await tester.ensureVisible(find.text('Libros'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Libros'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Repisa de pared, lugar 1'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<RoomScene>(find.byType(RoomScene))
          .placements[RoomSlot.wallShelfTopLeft],
      RoomDecorAssets.shelfBooksId,
    );
    await tester.ensureVisible(find.text('Planta colgante'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Planta colgante'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Repisa de pared, lugar 2'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<RoomScene>(find.byType(RoomScene))
          .placements[RoomSlot.wallShelfTopRight],
      RoomDecorAssets.trailingPlantId,
    );

    await openCategory(tester, 'Pared y piso');
    await tester.tap(find.text('Repisa de pared'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Pared, lugar 1'));
    await tester.pumpAndSettle();
    var draft = tester.widget<RoomScene>(find.byType(RoomScene)).placements;
    expect(draft[RoomSlot.wallLeft], RoomDecorAssets.wallShelfId);
    expect(draft[RoomSlot.wallShelfTopLeft], RoomDecorAssets.shelfBooksId);
    expect(draft[RoomSlot.wallShelfTopRight], RoomDecorAssets.trailingPlantId);

    await tester.tap(find.bySemanticsLabel('Pared, lugar 1'));
    await tester.pumpAndSettle();
    draft = tester.widget<RoomScene>(find.byType(RoomScene)).placements;
    expect(draft[RoomSlot.wallLeft], isNull);
    expect(draft[RoomSlot.wallShelfTopLeft], isNull);
    expect(draft[RoomSlot.wallShelfTopRight], isNull);
    await tester.tap(find.text('Listo'));
    await tester.pumpAndSettle();
    expect(
      (await loadStore()).roomDecorationsFor()[RoomSlot.wallShelfTopLeft],
      isNull,
    );
  });

  testWidgets('bookcase and side table take props in distinct places', (
    tester,
  ) async {
    final store = await loadStore();
    await ownEverything(store);
    await pump(tester, store);
    await openCategory(tester, 'Casa');
    await tester.tap(find.text('Casa jardín'));
    await tester.pumpAndSettle();
    await openCategory(tester, 'Muebles');

    await tester.scrollUntilVisible(
      find.text('Estantería estrecha'),
      180,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.ensureVisible(find.text('Estantería estrecha'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Estantería estrecha'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Piso, lugar 5'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Mesa auxiliar redonda'),
      180,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.ensureVisible(find.text('Mesa auxiliar redonda'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mesa auxiliar redonda'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Piso, lugar 2'));
    await tester.pumpAndSettle();

    await openCategory(tester, 'Adornos');
    await tester.tap(find.text('Frasco de ahorros'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Estantería estrecha, lugar 1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Planta de mesa'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Mesa auxiliar redonda, lugar 1'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<RoomScene>(find.byType(RoomScene)).placements,
      containsPair(RoomSlot.sideTableTop, RoomDecorAssets.defaultTablePlantId),
    );

    await openCategory(tester, 'Muebles');
    await tester.scrollUntilVisible(
      find.text('Mesa auxiliar redonda'),
      180,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.ensureVisible(find.text('Mesa auxiliar redonda'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mesa auxiliar redonda'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Piso, lugar 2'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Listo'));
    await tester.pumpAndSettle();

    final saved = (await loadStore()).roomDecorationsFor(
      RoomThemes.casaJardinId,
    );
    expect(saved[RoomSlot.floorCabinet], RoomDecorAssets.slimBookcaseId);
    expect(saved[RoomSlot.cabinetTop], RoomDecorAssets.savingsJarId);
    expect(saved[RoomSlot.floorRight], isNull);
    expect(saved[RoomSlot.sideTableTop], isNull);
  });

  group('characters', () {
    testWidgets('room and drawer give the rabbit the same optical scale', (
      tester,
    ) async {
      final store = await loadStore();
      await ownEverything(store);
      await store.grantCatalogEntry('rabbit');
      await pump(tester, store);
      await openCategory(tester, 'Personajes');
      await tester.scrollUntilVisible(
        find.text('Bunny'),
        180,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pumpAndSettle();

      final previewScale = tester.widget<Transform>(
        find.byKey(const ValueKey('decorate-character-scale-rabbit')),
      );
      expect(
        previewScale.transform.entry(0, 0),
        closeTo(CharacterCatalog.rabbit.roomDisplayScale, .001),
      );
      await tester.tap(find.text('Bunny'));
      await tester.pumpAndSettle();
      final sceneScale = tester.widget<Transform>(
        find.byKey(const ValueKey('room-character-scale')),
      );
      expect(sceneScale.transform.entry(0, 0), closeTo(1.38, .001));
    });

    testWidgets('the category lists only what is owned', (tester) async {
      final store = await loadStore();
      await ownEverything(store);
      await store.grantCatalogEntries({'poodle', 'capybara'});
      await pump(tester, store);

      await openCategory(tester, 'Personajes');

      // Michi is the other starter here, still waiting at the door.
      expect(find.text('Michi'), findsNothing);
      expect(find.text('Miru'), findsOneWidget);
      expect(find.text('Yoshi'), findsNothing);
      expect(find.text('Tranqui'), findsOneWidget);
      // Owned by nobody in this store, and so not a choice to make here.
      expect(find.text('Lana'), findsNothing);
    });

    // The screen promises Undo and Done. A character that changed on the tap
    // would sit outside both, and Undo would put the lamp back while leaving
    // the cat swapped.
    testWidgets('choosing one is staged until Done', (tester) async {
      final store = await loadStore();
      await ownEverything(store);
      await store.grantCatalogEntry('capybara');
      await pump(tester, store);

      await openCategory(tester, 'Personajes');
      await tester.drag(find.byType(GridView), const Offset(0, -180));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tranqui'));
      await tester.pumpAndSettle();

      expect(store.characterId, 'michi');

      await tester.tap(find.text('Listo'));
      await tester.pumpAndSettle();

      expect(store.characterId, 'capybara');
      expect((await loadStore()).characterId, 'capybara');
    });

    testWidgets('Undo puts the character back', (tester) async {
      final store = await loadStore();
      await ownEverything(store);
      await store.grantCatalogEntry('capybara');
      await pump(tester, store);

      await openCategory(tester, 'Personajes');
      await tester.drag(find.byType(GridView), const Offset(0, -180));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tranqui'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Deshacer'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Listo'));
      await tester.pumpAndSettle();

      expect(store.characterId, 'michi');
    });
  });
}
