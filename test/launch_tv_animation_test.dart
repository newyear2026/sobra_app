import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sobra_app/models/room_design.dart';
import 'package:sobra_app/state/sobra_store.dart';
import 'package:sobra_app/theme/app_theme.dart';
import 'package:sobra_app/widgets/room_scene.dart';

import 'support/localizations.dart';

void main() {
  testWidgets('TV blinks and changes channel without a tap', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = await SobraStore.load(now: () => DateTime(2026, 9, 14, 10));
    tester.view.physicalSize = const Size(520, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      SobraScope(
        store: store,
        child: MaterialApp(
          localizationsDelegates: sobraLocalizationsDelegates,
          supportedLocales: sobraSupportedLocales,
          theme: buildSobraTheme(),
          home: const Scaffold(
            body: RoomScene(
              variant: RoomSceneVariant.immersive,
              placements: {RoomSlot.floorCabinet: RoomDecorAssets.launchTvId},
              message: '',
            ),
          ),
        ),
      ),
    );

    expect(
      find.image(const AssetImage(RoomDecorAssets.launchTv)),
      findsOneWidget,
    );
    await tester.pump(const Duration(milliseconds: 3500));
    expect(
      find.image(const AssetImage(RoomDecorAssets.launchTvBlink)),
      findsOneWidget,
    );
    await tester.pump(const Duration(milliseconds: 160));
    await tester.pump(const Duration(seconds: 6));
    await tester.pump(const Duration(milliseconds: 160));
    await tester.pump(const Duration(seconds: 12));
    await tester.pump(const Duration(milliseconds: 150));
    expect(
      find.image(const AssetImage(RoomDecorAssets.launchTvSoccer)),
      findsOneWidget,
    );
  });

  testWidgets('reduced motion keeps the TV on a still frame', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = await SobraStore.load(now: () => DateTime(2026, 9, 14, 10));
    await store.setReducedMotion(true);
    tester.view.physicalSize = const Size(520, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      SobraScope(
        store: store,
        child: MaterialApp(
          localizationsDelegates: sobraLocalizationsDelegates,
          supportedLocales: sobraSupportedLocales,
          theme: buildSobraTheme(),
          home: const Scaffold(
            body: RoomScene(
              variant: RoomSceneVariant.immersive,
              placements: {RoomSlot.floorCabinet: RoomDecorAssets.launchTvId},
              message: '',
            ),
          ),
        ),
      ),
    );

    await tester.pump(const Duration(minutes: 1));
    expect(
      find.image(const AssetImage(RoomDecorAssets.launchTv)),
      findsOneWidget,
    );
  });
}
