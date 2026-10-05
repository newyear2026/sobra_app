import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sobra_app/models/room_design.dart';
import 'package:sobra_app/screens/room_decorate_screen.dart';
import 'package:sobra_app/screens/room_screen.dart';
import 'package:sobra_app/state/sobra_store.dart';
import 'package:sobra_app/theme/app_theme.dart';
import 'package:sobra_app/widgets/room_scene.dart';

import 'support/decorations.dart';
import 'support/localizations.dart';

void main() {
  testWidgets('bookcase and side table hold movable props at room depth', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(426, 919);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await (FontLoader(
      'PixelifySans',
    )..addFont(rootBundle.load('assets/fonts/PixelifySans.ttf'))).load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    useSpanishDevice(tester);

    final store = await SobraStore.load(now: () => DateTime(2026, 9, 14, 10));
    await store.setReducedMotion(true);
    await ownAllDecorations(store);
    // The jar is the one prop either piece takes while the table plant is
    // withheld, so it moves between them.
    Future<void> place({required bool jarOnBookcase}) async {
      await store.saveRoomSelection(
        roomId: RoomThemes.casaJardinId,
        placementsByRoom: {
          RoomThemes.casaJardinId: {
            RoomSlot.floorCabinet: RoomDecorAssets.slimBookcaseId,
            RoomSlot.floorRight: RoomDecorAssets.roundSideTableId,
            jarOnBookcase ? RoomSlot.cabinetTop : RoomSlot.sideTableTop:
                RoomDecorAssets.savingsJarId,
          },
        },
      );
    }

    await place(jarOnBookcase: true);
    await tester.pumpWidget(
      SobraScope(
        store: store,
        child: MaterialApp(
          localizationsDelegates: sobraLocalizationsDelegates,
          supportedLocales: sobraSupportedLocales,
          theme: buildSobraTheme(),
          home: const RoomScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.runAsync(
      () => Future.wait([
        for (final asset in [
          RoomThemes.casaJardin.portraitAsset,
          RoomDecorAssets.slimBookcase,
          RoomDecorAssets.roundSideTable,
          RoomDecorAssets.savingsJar,
        ])
          precacheImage(
            AssetImage(asset),
            tester.element(find.byType(RoomScreen)),
          ),
      ]),
    );
    await tester.pump();
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('../design/rooms/sobra-room-bookcase-side-table.png'),
    );

    await place(jarOnBookcase: false);
    await tester.pump();
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile(
        '../design/rooms/sobra-room-bookcase-side-table-swapped.png',
      ),
    );

    tester.view.physicalSize = const Size(426, 220);
    await tester.pumpWidget(
      SobraScope(
        store: store,
        child: MaterialApp(
          localizationsDelegates: sobraLocalizationsDelegates,
          supportedLocales: sobraSupportedLocales,
          home: Scaffold(
            body: RoomScene(
              variant: RoomSceneVariant.preview,
              roomId: RoomThemes.casaJardinId,
              placements: store.roomDecorationsFor(),
              message: 'Vas muy bien',
            ),
          ),
        ),
      ),
    );
    await tester.runAsync(
      () => precacheImage(
        AssetImage(RoomThemes.casaJardin.previewAsset),
        tester.element(find.byType(RoomScene)),
      ),
    );
    await tester.pump();
    await expectLater(
      find.byType(RoomScene),
      matchesGoldenFile('../design/rooms/sobra-home-bookcase-side-table.png'),
    );
  });

  testWidgets('six decorations keep their intended scale and depth', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(426, 919);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await (FontLoader(
      'PixelifySans',
    )..addFont(rootBundle.load('assets/fonts/PixelifySans.ttf'))).load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    useSpanishDevice(tester);

    final store = await SobraStore.load(now: () => DateTime(2026, 9, 14, 10));
    await store.setReducedMotion(true);
    await ownAllDecorations(store);
    await store.saveRoomSelection(
      roomId: RoomThemes.casaJardinId,
      placementsByRoom: {
        RoomThemes.casaJardinId: {
          RoomSlot.floorCabinet: RoomDecorAssets.lowCabinetId,
          RoomSlot.floorCenter: RoomDecorAssets.petBedId,
          RoomSlot.cabinetTop: RoomDecorAssets.savingsJarId,
          RoomSlot.wallLeft: RoomDecorAssets.wallShelfId,
          RoomSlot.floorRight: RoomDecorAssets.terracottaPoufId,
          RoomSlot.rug: RoomDecorAssets.blueCreamRugId,
        },
      },
    );

    await tester.pumpWidget(
      SobraScope(
        store: store,
        child: MaterialApp(
          localizationsDelegates: sobraLocalizationsDelegates,
          supportedLocales: sobraSupportedLocales,
          theme: buildSobraTheme(),
          home: const RoomScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.runAsync(
      () => Future.wait([
        for (final asset in [
          RoomThemes.casaJardin.portraitAsset,
          'assets/rooms/casa_jardin/background_portrait_unlit.png',
          RoomDecorAssets.rattanChair,
          RoomDecorAssets.floorLamp,
          RoomDecorAssets.lowCabinet,
          RoomDecorAssets.petBed,
          RoomDecorAssets.savingsJar,
          RoomDecorAssets.wallShelf,
          RoomDecorAssets.terracottaPouf,
          RoomDecorAssets.blueCreamRug,
        ])
          precacheImage(
            AssetImage(asset),
            tester.element(find.byType(RoomScreen)),
          ),
      ]),
    );
    await tester.pump();

    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('../design/rooms/sobra-room-six-items-garden.png'),
    );
  });

  testWidgets('decorator shows six items at the smaller room viewport', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(520, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await (FontLoader(
      'PixelifySans',
    )..addFont(rootBundle.load('assets/fonts/PixelifySans.ttf'))).load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    useSpanishDevice(tester);

    final store = await SobraStore.load(now: () => DateTime(2026, 9, 14, 10));
    await store.setReducedMotion(true);
    await ownAllDecorations(store);
    await store.saveRoomSelection(
      roomId: RoomThemes.casaJardinId,
      placementsByRoom: {
        RoomThemes.casaJardinId: {
          RoomSlot.floorCabinet: RoomDecorAssets.lowCabinetId,
          RoomSlot.floorCenter: RoomDecorAssets.petBedId,
          RoomSlot.cabinetTop: RoomDecorAssets.savingsJarId,
          RoomSlot.wallLeft: RoomDecorAssets.wallShelfId,
          RoomSlot.floorRight: RoomDecorAssets.terracottaPoufId,
          RoomSlot.rug: RoomDecorAssets.blueCreamRugId,
        },
      },
    );
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
    await tester.pump();
    await tester.runAsync(
      () => Future.wait([
        for (final asset in [
          RoomThemes.casaJardin.portraitAsset,
          'assets/rooms/casa_jardin/background_portrait_unlit.png',
          RoomDecorAssets.rattanChair,
          RoomDecorAssets.floorLamp,
          RoomDecorAssets.lowCabinet,
          RoomDecorAssets.petBed,
          RoomDecorAssets.savingsJar,
          RoomDecorAssets.wallShelf,
          RoomDecorAssets.terracottaPouf,
          RoomDecorAssets.blueCreamRug,
        ])
          precacheImage(
            AssetImage(asset),
            tester.element(find.byType(RoomDecorateScreen)),
          ),
      ]),
    );
    await tester.pump();
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('../design/rooms/sobra-decorator-six-items-garden.png'),
    );
  });

  testWidgets('selected savings jar on the low cabinet', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(520, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await (FontLoader(
      'PixelifySans',
    )..addFont(rootBundle.load('assets/fonts/PixelifySans.ttf'))).load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    useSpanishDevice(tester);

    final store = await SobraStore.load(now: () => DateTime(2026, 9, 14, 10));
    await store.setReducedMotion(true);
    await ownAllDecorations(store);
    await store.saveRoomSelection(
      roomId: RoomThemes.casaJardinId,
      placementsByRoom: {
        RoomThemes.casaJardinId: {
          RoomSlot.floorCabinet: RoomDecorAssets.lowCabinetId,
        },
      },
    );
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
    await tester.tap(find.text('Adornos'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Frasco de ahorros'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Aparador bajo, lugar 1'));
    await tester.pumpAndSettle();
    await tester.runAsync(
      () => Future.wait([
        for (final asset in [
          RoomThemes.casaJardin.portraitAsset,
          RoomDecorAssets.lowCabinet,
          RoomDecorAssets.savingsJar,
        ])
          precacheImage(
            AssetImage(asset),
            tester.element(find.byType(RoomDecorateScreen)),
          ),
      ]),
    );
    await tester.pump();

    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile(
        '../design/rooms/sobra-decorator-jar-selected-on-cabinet.png',
      ),
    );

    // The same placed jar without the active placement outline.
    await tester.tap(find.text('Adornos'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Aparador bajo, lugar 1'), findsNothing);
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('../design/rooms/sobra-decorator-jar-on-cabinet.png'),
    );
  });
}
