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
  testWidgets('green lamp on each supported shelf in the beach room', (
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

    for (final (support, lampSlot, otherSlot, fileName)
        in <(String, RoomSlot, RoomSlot?, String)>[
          (
            RoomDecorAssets.lowCabinetId,
            RoomSlot.cabinetTopRight,
            null,
            'sobra-green-lamp-on-low-cabinet.png',
          ),
          (
            RoomDecorAssets.lowCabinetId,
            RoomSlot.cabinetTopRight,
            RoomSlot.cabinetTop,
            'sobra-green-lamp-with-books-on-low-cabinet.png',
          ),
          (
            RoomDecorAssets.slimBookcaseId,
            RoomSlot.cabinetTopRight,
            null,
            'sobra-green-lamp-on-bookcase.png',
          ),
          (
            RoomDecorAssets.slimBookcaseId,
            RoomSlot.cabinetTopRight,
            RoomSlot.cabinetTop,
            'sobra-green-lamp-with-books-on-bookcase.png',
          ),
          (
            RoomDecorAssets.slimBookcaseId,
            RoomSlot.cabinetTop,
            RoomSlot.cabinetTopRight,
            'sobra-green-lamp-in-bookcase-with-books-on-top.png',
          ),
          (
            RoomDecorAssets.wallShelfId,
            RoomSlot.wallShelfTopLeft,
            null,
            'sobra-green-lamp-on-wall-shelf.png',
          ),
          (
            RoomDecorAssets.wallShelfId,
            RoomSlot.wallShelfTopLeft,
            RoomSlot.wallShelfTopRight,
            'sobra-green-lamp-with-books-on-wall-shelf.png',
          ),
        ]) {
      final isWallShelf = support == RoomDecorAssets.wallShelfId;
      final placements = <RoomSlot, String>{
        RoomSlot.rug: RoomDecorAssets.defaultRugId,
        isWallShelf ? RoomSlot.wallLeft : RoomSlot.floorCabinet: support,
        lampSlot: 'item-01',
        ?otherSlot: RoomDecorAssets.shelfBooksId,
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
      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('../design/rooms/$fileName'),
      );
      Rect frame(String asset) => tester.getRect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Image &&
              widget.image is AssetImage &&
              (widget.image as AssetImage).assetName == asset,
        ),
      );
      Rect body(
        Rect frame,
        double left,
        double top,
        double right,
        double bottom,
      ) => Rect.fromLTRB(
        frame.center.dx + frame.height * left,
        frame.top + frame.height * top,
        frame.center.dx + frame.height * right,
        frame.top + frame.height * bottom,
      );
      final supportFrame = frame(RoomDecorAssets.assetFor(support)!);
      var focus = switch (support) {
        RoomDecorAssets.slimBookcaseId => body(
          supportFrame,
          -.183,
          .0938,
          .183,
          .9193,
        ),
        RoomDecorAssets.lowCabinetId => body(
          supportFrame,
          -.551,
          .3135,
          .552,
          .9375,
        ),
        _ => body(supportFrame, -.643, .465, .643, .718),
      };
      focus = focus.expandToInclude(
        body(frame(RoomDecorAssets.lamp), -.254, .175, .32, .861),
      );
      if (otherSlot != null) {
        focus = focus.expandToInclude(
          body(frame(RoomDecorAssets.shelfBooks), -.238, .199, .215, .835),
        );
      }
      focus = focus.inflate(10);
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
          '../design/rooms/${fileName.replaceAll('.png', '-detail.png')}',
        ),
      );
      detail.dispose();
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });
}
