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

Future<SobraStore> _store(WidgetTester tester, Size size) async {
  SharedPreferences.setMockInitialValues({});
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  useSpanishDevice(tester);
  await (FontLoader(
    'PixelifySans',
  )..addFont(rootBundle.load('assets/fonts/PixelifySans.ttf'))).load();
  final store = await SobraStore.load(now: () => DateTime(2026, 10, 1, 12));
  await store.setReducedMotion(true);
  return store;
}

Future<void> _precache(
  WidgetTester tester,
  String folder, {
  required bool preview,
}) async {
  await tester.runAsync(
    () => Future.wait([
      for (final asset in [
        if (preview)
          'assets/rooms/$folder/background_portrait_unlit.png'
        else ...[
          'assets/rooms/$folder/background_portrait_unlit.png',
          'assets/rooms/$folder/background_portrait_sunset_unlit.png',
          'assets/rooms/$folder/background_portrait_night_unlit.png',
        ],
        RoomDecorAssets.launchSofa,
        RoomDecorAssets.floorLamp,
        RoomDecorAssets.rug,
        CatMotion.idle.asset,
      ])
        precacheImage(AssetImage(asset), tester.element(find.byType(Scaffold))),
    ]),
  );
  await tester.pump();
}

void main() {
  for (final (roomId, folder, slug) in [
    (RoomThemes.casaMontanaId, 'casa_montana', 'casa-montana'),
    (RoomThemes.casaInvernaderoId, 'casa_invernadero', 'casa-invernadero'),
  ]) {
    testWidgets('$slug shows day, sunset, night and placed lamp', (
      tester,
    ) async {
      final store = await _store(tester, const Size(1600, 640));
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
              body: RepaintBoundary(
                key: const ValueKey('scenic-room-preview'),
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
                                  roomId: roomId,
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
      await _precache(tester, folder, preview: false);
      await expectLater(
        find.byKey(const ValueKey('scenic-room-preview')),
        matchesGoldenFile('../design/rooms/concepts/$slug-app-lighting.png'),
      );
    });

    testWidgets('$slug fills the square home card', (tester) async {
      final store = await _store(tester, const Size(640, 640));
      await tester.pumpWidget(
        SobraScope(
          store: store,
          child: MaterialApp(
            localizationsDelegates: sobraLocalizationsDelegates,
            supportedLocales: sobraSupportedLocales,
            home: Scaffold(
              body: RoomScene(
                variant: RoomSceneVariant.preview,
                roomId: roomId,
                placements: const {
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
      await _precache(tester, folder, preview: true);
      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('../design/rooms/concepts/$slug-home-card.png'),
      );
    });
  }
}
