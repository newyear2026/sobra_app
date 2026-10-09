import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sobra_app/models/room_design.dart';
import 'package:sobra_app/screens/room_screen.dart';
import 'package:sobra_app/state/sobra_store.dart';
import 'package:sobra_app/theme/app_theme.dart';
import 'package:sobra_app/widgets/cat_sprite.dart';

import 'support/localizations.dart';

void main() {
  testWidgets('green lamp sits on the side table in the beach room', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(852, 1838);
    tester.view.devicePixelRatio = 2;
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
    final store = await SobraStore.load(now: () => DateTime(2026, 10, 9, 10));
    await store.setReducedMotion(true);
    final placements = <RoomSlot, String>{
      RoomSlot.rug: RoomDecorAssets.defaultRugId,
      RoomSlot.floorCabinet: RoomDecorAssets.lowCabinetId,
      RoomSlot.wallLeft: RoomDecorAssets.wallShelfId,
      RoomSlot.wallShelfTopLeft: RoomDecorAssets.shelfBooksId,
      RoomSlot.wallShelfTopRight: RoomDecorAssets.trailingPlantId,
      RoomSlot.floorRight: RoomDecorAssets.roundSideTableId,
      RoomSlot.sideTableTop: 'item-01',
    };
    await store.saveRoomSelection(
      roomId: RoomThemes.casaDePlayaId,
      placementsByRoom: {RoomThemes.casaDePlayaId: placements},
    );

    final sceneKey = GlobalKey();
    await tester.pumpWidget(
      SobraScope(
        store: store,
        child: MaterialApp(
          localizationsDelegates: sobraLocalizationsDelegates,
          supportedLocales: sobraSupportedLocales,
          theme: buildSobraTheme(),
          home: RepaintBoundary(key: sceneKey, child: const RoomScreen()),
        ),
      ),
    );
    await tester.pump();
    await tester.runAsync(
      () => Future.wait([
        for (final asset in [
          RoomThemes.casaDePlaya.portraitAsset,
          'assets/rooms/casa_de_playa/background_portrait_unlit.png',
          CatMotion.idle.asset,
          for (final id in placements.values) RoomDecorAssets.assetFor(id)!,
        ])
          precacheImage(
            AssetImage(asset),
            tester.element(find.byType(RoomScreen)),
          ),
      ]),
    );
    await tester.pumpAndSettle();
    Rect imageFrame(String asset) => tester.getRect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName == asset,
      ),
    );
    final table = imageFrame(RoomDecorAssets.roundSideTable);
    final lamp = imageFrame(RoomDecorAssets.lamp);
    final lampFoot = lamp.top + lamp.height * .86;
    // The ellipse's usable top lies between its rear rim and front lip.
    expect(lampFoot, greaterThan(table.top + table.height * .27));
    expect(lampFoot, lessThan(table.top + table.height * .38));
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('../design/rooms/sobra-green-lamp-on-side-table.png'),
    );
    final focus = Rect.fromLTRB(
      table.center.dx - table.height * .37,
      lamp.top + lamp.height * .175,
      table.center.dx + table.height * .37,
      table.top + table.height * .8474,
    ).inflate(10);
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(sceneKey),
    );
    final detail = await (boundary.debugLayer! as OffsetLayer).toImage(
      focus,
      pixelRatio: 4,
    );
    await expectLater(
      detail,
      matchesGoldenFile(
        '../design/rooms/sobra-green-lamp-on-side-table-detail.png',
      ),
    );
    detail.dispose();
  });
}
