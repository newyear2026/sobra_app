import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sobra_app/models/room_design.dart';
import 'package:sobra_app/models/room_time_of_day.dart';
import 'package:sobra_app/state/sobra_store.dart';
import 'package:sobra_app/widgets/cat_sprite.dart';
import 'package:sobra_app/widgets/room_scene.dart';

import 'support/localizations.dart';

void main() {
  testWidgets('panoramic room stays readable through day, sunset and night', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1600, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    useSpanishDevice(tester);
    await (FontLoader(
      'PixelifySans',
    )..addFont(rootBundle.load('assets/fonts/PixelifySans.ttf'))).load();
    final store = await SobraStore.load(now: () => DateTime(2026, 10, 1, 12));
    await store.setReducedMotion(true);

    const sofaAndRug = <RoomSlot, String>{
      RoomSlot.floorSofa: RoomDecorAssets.launchSofaId,
      RoomSlot.rug: RoomDecorAssets.defaultRugId,
    };
    const withLamp = <RoomSlot, String>{
      ...sofaAndRug,
      RoomSlot.floorLeft: RoomDecorAssets.floorLampId,
    };
    final panels = [
      (label: 'Día', phase: RoomTimeOfDay.day, items: withLamp),
      (label: 'Atardecer', phase: RoomTimeOfDay.sunset, items: withLamp),
      (
        label: 'Noche · sin lámpara',
        phase: RoomTimeOfDay.night,
        items: sofaAndRug,
      ),
      (
        label: 'Noche · con lámpara',
        phase: RoomTimeOfDay.night,
        items: withLamp,
      ),
    ];

    await tester.pumpWidget(
      SobraScope(
        store: store,
        child: MaterialApp(
          localizationsDelegates: sobraLocalizationsDelegates,
          supportedLocales: sobraSupportedLocales,
          home: Scaffold(
            backgroundColor: const Color(0xFFF8F3EA),
            body: RepaintBoundary(
              key: const ValueKey('casa-torre-preview'),
              child: ColoredBox(
                color: const Color(0xFFF8F3EA),
                child: Row(
                  children: [
                    for (final panel in panels)
                      SizedBox(
                        width: 400,
                        child: Column(
                          children: [
                            SizedBox(
                              height: 30,
                              child: Center(
                                child: Text(
                                  panel.label,
                                  style: const TextStyle(
                                    color: Color(0xFF27303A),
                                    fontFamily: 'PixelifySans',
                                    fontSize: 17,
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: RoomScene(
                                variant: RoomSceneVariant.immersive,
                                roomId: RoomThemes.casaTorreId,
                                placements: panel.items,
                                message: 'Vas muy bien',
                                timeOfDay: panel.phase,
                                animateItems: false,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.runAsync(
      () => Future.wait([
        for (final asset in [
          'assets/rooms/casa_torre/background_portrait_unlit.png',
          'assets/rooms/casa_torre/background_portrait_sunset_unlit.png',
          'assets/rooms/casa_torre/background_portrait_night_unlit.png',
          RoomDecorAssets.launchSofa,
          RoomDecorAssets.floorLamp,
          RoomDecorAssets.rug,
          CatMotion.idle.asset,
        ])
          precacheImage(
            AssetImage(asset),
            tester.element(find.byType(Scaffold)),
          ),
      ]),
    );
    await tester.pump();

    await expectLater(
      find.byKey(const ValueKey('casa-torre-preview')),
      matchesGoldenFile(
        '../design/rooms/casa_torre/casa-torre-app-lighting.png',
      ),
    );
  });

  testWidgets('panoramic room fills the wide home card', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(640, 320);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    useSpanishDevice(tester);
    await (FontLoader(
      'PixelifySans',
    )..addFont(rootBundle.load('assets/fonts/PixelifySans.ttf'))).load();
    final store = await SobraStore.load(now: () => DateTime(2026, 10, 1, 12));
    await store.setReducedMotion(true);

    await tester.pumpWidget(
      SobraScope(
        store: store,
        child: const MaterialApp(
          localizationsDelegates: sobraLocalizationsDelegates,
          supportedLocales: sobraSupportedLocales,
          home: Scaffold(
            body: RoomScene(
              variant: RoomSceneVariant.preview,
              roomId: RoomThemes.casaTorreId,
              placements: {
                RoomSlot.floorSofa: RoomDecorAssets.launchSofaId,
                RoomSlot.floorLeft: RoomDecorAssets.floorLampId,
                RoomSlot.rug: RoomDecorAssets.defaultRugId,
              },
              message: 'Vas muy bien',
              animateItems: false,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.runAsync(
      () => Future.wait([
        for (final asset in [
          'assets/rooms/casa_torre/background_preview.png',
          RoomDecorAssets.launchSofa,
          RoomDecorAssets.floorLamp,
          RoomDecorAssets.rug,
          CatMotion.idle.asset,
        ])
          precacheImage(
            AssetImage(asset),
            tester.element(find.byType(Scaffold)),
          ),
      ]),
    );
    await tester.pump();

    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('../design/rooms/casa_torre/casa-torre-home-card.png'),
    );
  });
}
