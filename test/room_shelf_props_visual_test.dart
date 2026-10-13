import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sobra_app/models/room_design.dart';
import 'package:sobra_app/screens/room_screen.dart';
import 'package:sobra_app/state/sobra_store.dart';
import 'package:sobra_app/theme/app_theme.dart';
import 'package:sobra_app/widgets/cat_sprite.dart';

import 'support/decorations.dart';
import 'support/localizations.dart';

void main() {
  testWidgets('props on cabinet, bookcase, and wall shelf', (tester) async {
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
    await ownEverything(store);
    await store.setReducedMotion(true);

    for (final (roomId, supportId, leftProp, rightProp, filename)
        in <(String, String?, String, String, String)>[
          (
            RoomThemes.casaClaraId,
            RoomDecorAssets.lowCabinetId,
            RoomDecorAssets.shelfBooksId,
            RoomDecorAssets.trailingPlantId,
            'sobra-props-low-cabinet.png',
          ),
          (
            RoomThemes.casaClaraId,
            RoomDecorAssets.slimBookcaseId,
            RoomDecorAssets.shelfBooksId,
            RoomDecorAssets.trailingPlantId,
            'sobra-props-bookcase.png',
          ),
          (
            RoomThemes.casaClaraId,
            null,
            RoomDecorAssets.shelfBooksId,
            RoomDecorAssets.trailingPlantId,
            'sobra-props-wall-shelf.png',
          ),
          (
            RoomThemes.casaClaraId,
            null,
            RoomDecorAssets.savingsJarId,
            RoomDecorAssets.defaultTablePlantId,
            'sobra-props-wall-shelf-other.png',
          ),
          (
            RoomThemes.casaDePlayaId,
            RoomDecorAssets.lowCabinetId,
            RoomDecorAssets.trailingPlantId,
            RoomDecorAssets.shelfBooksId,
            'sobra-props-beach-low-cabinet.png',
          ),
          (
            RoomThemes.casaDePlayaId,
            null,
            RoomDecorAssets.shelfBooksId,
            RoomDecorAssets.trailingPlantId,
            'sobra-props-beach-wall-shelf.png',
          ),
        ]) {
      final propPlacements = supportId == null
          ? <RoomSlot, String>{
              RoomSlot.wallShelfTopLeft: leftProp,
              RoomSlot.wallShelfTopRight: rightProp,
            }
          : <RoomSlot, String>{
              RoomSlot.floorCabinet: supportId,
              RoomSlot.cabinetTop: leftProp,
              RoomSlot.cabinetTopRight: rightProp,
            };
      final beachWallShelf =
          roomId == RoomThemes.casaDePlayaId && supportId == null;
      final placements = <RoomSlot, String>{
        RoomSlot.rug: RoomDecorAssets.defaultRugId,
        ...propPlacements,
        if (beachWallShelf) RoomSlot.floorCabinet: RoomDecorAssets.lowCabinetId,
        (beachWallShelf ? RoomSlot.wallLeft : RoomSlot.wallCenter):
            RoomDecorAssets.wallShelfId,
      };
      await store.saveRoomSelection(
        roomId: roomId,
        placementsByRoom: {roomId: placements},
      );
      final portraitAsset = RoomThemes.byId(roomId).portraitAsset;
      final unlitAsset =
          '${portraitAsset.substring(0, portraitAsset.lastIndexOf('/'))}/background_portrait_unlit.png';
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
            portraitAsset,
            unlitAsset,
            CatMotion.idle.asset,
            for (final id in store.roomDecorationsFor().values)
              RoomDecorAssets.assetFor(id)!,
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
      if (supportId == RoomDecorAssets.slimBookcaseId) {
        final bookcase = imageFrame(RoomDecorAssets.slimBookcase);
        final books = imageFrame(RoomDecorAssets.shelfBooks);
        // The books clear the cubby's ceiling and stand on its wooden floor.
        expect(
          books.top + books.height * .199,
          greaterThan(bookcase.top + bookcase.height * .407),
        );
        expect(
          books.top + books.height * .835,
          inInclusiveRange(
            bookcase.top + bookcase.height * .56,
            bookcase.top + bookcase.height * .61,
          ),
        );
        expect(
          imageFrame(RoomDecorAssets.trailingPlant).center.dx,
          closeTo(imageFrame(RoomDecorAssets.slimBookcase).center.dx, .01),
        );
      }
      if (roomId == RoomThemes.casaDePlayaId) {
        if (supportId != null) {
          final cabinet = imageFrame(RoomDecorAssets.lowCabinet);
          final books = imageFrame(RoomDecorAssets.shelfBooks);
          // The visible bottom belongs on the top face, between its back
          // outline and front lip, rather than above or inside the cabinet.
          expect(
            books.top + books.height * .835,
            inInclusiveRange(
              cabinet.top + cabinet.height * .332,
              cabinet.top + cabinet.height * .40,
            ),
          );
        } else {
          final shelf = imageFrame(RoomDecorAssets.wallShelf);
          final books = imageFrame(RoomDecorAssets.shelfBooks);
          final plant = imageFrame(RoomDecorAssets.trailingPlant);
          final woodTop = shelf.top + shelf.height * .465;
          final bookBase = books.top + books.height * .835;
          expect(bookBase, greaterThan(shelf.top + shelf.height * .48));
          expect(bookBase, lessThan(shelf.top + shelf.height * .515));
          expect(plant.top + plant.height * .47, closeTo(woodTop, 2));
        }
      }
      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('../design/rooms/$filename'),
      );
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });
}
