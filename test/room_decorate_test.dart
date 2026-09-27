import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sobra_app/screens/collection_screen.dart';
import 'package:sobra_app/screens/room_decorate_screen.dart';
import 'package:sobra_app/models/room_design.dart';
import 'package:sobra_app/state/sobra_store.dart';
import 'package:sobra_app/theme/app_theme.dart';
import 'package:sobra_app/widgets/room_scene.dart';

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

    // Owned from the start, because Casa clara places it.
    expect(find.text('Planta de mesa'), findsOneWidget);
    // item-03 is the same plant behind a rewarded ad, and item-08 a clock
    // behind another. Neither is owned here.
    expect(find.text('VER ANUNCIO'), findsNothing);
    expect(find.text('COMPRAR'), findsNothing);
    expect(find.text('Ver más en la colección'), findsOneWidget);
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

    await tester.ensureVisible(find.text('Ver más en la colección'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ver más en la colección'));
    await tester.pumpAndSettle();

    expect(find.byType(CollectionScreen), findsOneWidget);
  });

  testWidgets('room themes preview, undo, and persist after Done', (
    tester,
  ) async {
    final store = await loadStore();
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
    expect(
      store.roomDecorationsFor()[RoomSlot.floorLeft],
      RoomDecorAssets.defaultTablePlantId,
    );
  });

  testWidgets('three starter items can be placed and saved', (tester) async {
    final store = await loadStore();
    await pump(tester, store);

    await tester.tap(find.text('Sillón de ratán'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Piso, lugar 1'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Lámpara de pie'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Piso, lugar 2'));
    await tester.pumpAndSettle();

    await openCategory(tester, 'Pared y piso');
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

  group('characters', () {
    testWidgets('the category lists only what is owned', (tester) async {
      final store = await loadStore();
      await store.grantCatalogEntry('character-07');
      await pump(tester, store);

      await openCategory(tester, 'Personajes');

      expect(find.text('Michi'), findsOneWidget);
      expect(find.text('Poodle'), findsOneWidget);
      expect(find.text('Schnauzer'), findsNothing);
      expect(find.text('Personaje 7'), findsOneWidget);
      // Owned by nobody in this store, and so not a choice to make here.
      expect(find.text('Personaje 9'), findsNothing);
    });

    // The screen promises Undo and Done. A character that changed on the tap
    // would sit outside both, and Undo would put the lamp back while leaving
    // the cat swapped.
    testWidgets('choosing one is staged until Done', (tester) async {
      final store = await loadStore();
      await store.grantCatalogEntry('character-07');
      await pump(tester, store);

      await openCategory(tester, 'Personajes');
      await tester.drag(find.byType(GridView), const Offset(0, -180));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Personaje 7'));
      await tester.pumpAndSettle();

      expect(store.characterId, 'michi');

      await tester.tap(find.text('Listo'));
      await tester.pumpAndSettle();

      expect(store.characterId, 'character-07');
      expect((await loadStore()).characterId, 'character-07');
    });

    testWidgets('Undo puts the character back', (tester) async {
      final store = await loadStore();
      await store.grantCatalogEntry('character-07');
      await pump(tester, store);

      await openCategory(tester, 'Personajes');
      await tester.drag(find.byType(GridView), const Offset(0, -180));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Personaje 7'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Deshacer'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Listo'));
      await tester.pumpAndSettle();

      expect(store.characterId, 'michi');
    });
  });
}
