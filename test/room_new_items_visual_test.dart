import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sobra_app/models/room_design.dart';
import 'package:sobra_app/screens/room_decorate_screen.dart';
import 'package:sobra_app/screens/room_screen.dart';
import 'package:sobra_app/state/sobra_store.dart';
import 'package:sobra_app/theme/app_theme.dart';

import 'support/localizations.dart';

void main() {
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
    await store.saveRoomSelection(
      roomId: RoomThemes.casaJardinId,
      placementsByRoom: {
        RoomThemes.casaJardinId: {
          RoomSlot.floorCabinet: RoomDecorAssets.lowCabinetId,
          RoomSlot.floorCenter: RoomDecorAssets.petBedId,
          RoomSlot.floorAccent: RoomDecorAssets.savingsJarId,
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
    await store.saveRoomSelection(
      roomId: RoomThemes.casaJardinId,
      placementsByRoom: {
        RoomThemes.casaJardinId: {
          RoomSlot.floorCabinet: RoomDecorAssets.lowCabinetId,
          RoomSlot.floorCenter: RoomDecorAssets.petBedId,
          RoomSlot.floorAccent: RoomDecorAssets.savingsJarId,
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
}
