import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sobra_app/main.dart';
import 'package:sobra_app/models/pay_schedule.dart';
import 'package:sobra_app/models/room_design.dart';
import 'package:sobra_app/screens/room_decorate_screen.dart';
import 'package:sobra_app/state/sobra_store.dart';
import 'package:sobra_app/theme/app_theme.dart';
import 'package:sobra_app/widgets/cat_sprite.dart';
import 'package:sobra_app/widgets/room_scene.dart';

import 'support/localizations.dart';

void main() {
  testWidgets('square Home card previews the saved decorated room', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(426, 919);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    useSpanishDevice(tester);
    await Future.wait([
      (FontLoader(
        'PixelifySans',
      )..addFont(rootBundle.load('assets/fonts/PixelifySans.ttf'))).load(),
      (FontLoader(
        'MaterialIcons',
      )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load(),
    ]);
    SharedPreferences.setMockInitialValues({});
    final store = await SobraStore.load(now: () => DateTime(2026, 9, 8, 10));
    await store.configureOnboarding(
      budgetCentavos: 600000,
      schedule: const PaySchedule.semiMonthly(),
      cashCentavos: 124000,
    );
    await store.completeOnboarding();
    await store.grantCatalogEntries({
      'michi',
      'poodle',
      RoomDecorAssets.launchTvId,
    });
    await store.chooseCharacter('poodle');
    await store.setReducedMotion(true);
    await store.saveRoomDecorations({
      RoomSlot.floorLeft: RoomDecorAssets.floorLampId,
      RoomSlot.floorCabinet: RoomDecorAssets.launchTvId,
      RoomSlot.floorSofa: RoomDecorAssets.ivorySofaId,
      RoomSlot.rug: RoomDecorAssets.defaultRugId,
    });
    await tester.pumpWidget(SobraApp(store: store));
    await tester.pump();
    await tester.runAsync(
      () => Future.wait([
        for (final asset in [
          RoomThemes.casaClara.portraitAsset,
          'assets/rooms/casa_clara/background_portrait_unlit.png',
          CharacterCatalog.poodle.assetFor(CharacterMotionRole.idle),
          for (final id in store.roomDecorationsFor().values)
            RoomDecorAssets.assetFor(id)!,
        ])
          precacheImage(
            AssetImage(asset),
            tester.element(find.byType(RoomScene)),
          ),
      ]),
    );
    await tester.pumpAndSettle();
    final homeSize = tester.getSize(find.byType(RoomScene));
    expect(homeSize.height, closeTo(homeSize.width, .01));
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byType(Scaffold).first,
      matchesGoldenFile('../design/rooms/shared-stage-home.png'),
    );

    // Same saved furniture, viewed through Decorate's differently sized area.
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
    final drawerImages = tester
        .widgetList<Image>(find.byType(Image))
        .map((image) => image.image)
        .toSet();
    await tester.runAsync(
      () => Future.wait([
        for (final provider in drawerImages)
          precacheImage(provider, tester.element(find.byType(RoomScene))),
      ]),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('../design/rooms/shared-stage-decorate.png'),
    );
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
