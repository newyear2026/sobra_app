import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sobra_app/models/room_design.dart';
import 'package:sobra_app/state/sobra_store.dart';
import 'package:sobra_app/widgets/cat_sprite.dart';
import 'package:sobra_app/widgets/room_scene.dart';

import 'support/localizations.dart';

void main() {
  testWidgets(
    'Home and room decor align to the same wall and floor landmarks',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});
      final store = await SobraStore.load(now: () => DateTime(2026, 9, 14, 10));
      await store.setReducedMotion(true);

      const placements = {
        RoomSlot.wallLeft: RoomDecorAssets.wallClockId,
        RoomSlot.wallCenter: RoomDecorAssets.wallShelfId,
        RoomSlot.floorLeft: RoomDecorAssets.rattanChairId,
        RoomSlot.floorCabinet: RoomDecorAssets.lowCabinetId,
        RoomSlot.cabinetTop: RoomDecorAssets.savingsJarId,
        RoomSlot.cabinetTopRight: RoomDecorAssets.defaultTablePlantId,
        RoomSlot.floorAccent: RoomDecorAssets.floorLampId,
        RoomSlot.floorRight: RoomDecorAssets.terracottaPoufId,
        RoomSlot.floorCenter: RoomDecorAssets.petBedId,
      };

      Future<Map<String, Rect>> measure(RoomSceneVariant variant) async {
        await tester.pumpWidget(
          SobraScope(
            store: store,
            child: MaterialApp(
              localizationsDelegates: sobraLocalizationsDelegates,
              supportedLocales: sobraSupportedLocales,
              home: Center(
                child: SizedBox(
                  width: 1000,
                  height: variant == RoomSceneVariant.preview ? 500 : 1400,
                  child: RoomScene(
                    variant: variant,
                    roomId: RoomThemes.casaDePlayaId,
                    placements: placements,
                    message: '',
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        Rect imageRect(String asset) => tester.getRect(
          find.byWidgetPredicate(
            (widget) =>
                widget is Image &&
                widget.image is AssetImage &&
                (widget.image as AssetImage).assetName == asset,
          ),
        );

        return {
          'cat': tester.getRect(find.byType(CatSprite)),
          'background': imageRect(
            variant == RoomSceneVariant.preview
                ? RoomThemes.casaDePlaya.previewAsset
                : RoomThemes.casaDePlaya.portraitAsset,
          ),
          'clock': imageRect(RoomDecorAssets.wallClock),
          'shelf': imageRect(RoomDecorAssets.wallShelf),
          'chair': imageRect(RoomDecorAssets.rattanChair),
          'cabinet': imageRect(RoomDecorAssets.lowCabinet),
          'jar': imageRect(RoomDecorAssets.savingsJar),
          'plant': imageRect(RoomDecorAssets.tablePlant),
          'lamp': imageRect(RoomDecorAssets.floorLamp),
          'pouf': imageRect(RoomDecorAssets.terracottaPouf),
          'bed': imageRect(RoomDecorAssets.petBed),
        };
      }

      final preview = await measure(RoomSceneVariant.preview);
      final portrait = await measure(RoomSceneVariant.immersive);

      // The jar follows the cabinet rather than a coordinate on the room
      // background, including in the shorter Home preview.
      for (final scene in [preview, portrait]) {
        final cabinet = scene['cabinet']!;
        final jar = scene['jar']!;
        final plant = scene['plant']!;
        expect(jar.center.dx, lessThan(cabinet.center.dx));
        expect(plant.center.dx, greaterThan(cabinet.center.dx));
        expect(jar.bottom, greaterThan(cabinet.top));
        expect(jar.bottom, lessThan(cabinet.top + cabinet.height * .45));
        // The jar image has clear pixels below the glass. Check its visible
        // base against the wooden top, rather than the image widget's edge.
        final visibleJarBottom = jar.top + jar.height * (1052 / 1287);
        expect(
          visibleJarBottom,
          greaterThan(cabinet.top + cabinet.height * .32),
        );
        final visiblePlantBottom = plant.top + plant.height * (971 / 1191);
        expect(
          visiblePlantBottom,
          greaterThan(cabinet.top + cabinet.height * .32),
        );
      }
      final previewJarOffset =
          (preview['jar']!.bottom - preview['cabinet']!.top) /
          preview['cabinet']!.height;
      final portraitJarOffset =
          (portrait['jar']!.bottom - portrait['cabinet']!.top) /
          portrait['cabinet']!.height;
      expect((previewJarOffset - portraitJarOffset).abs(), lessThan(.01));

      // Coordinates measured on the two background illustrations. The window
      // starts above the wall decor and the baseboard is the floor reference.
      double relativeY(
        Map<String, Rect> frames,
        String item, {
        required double windowTop,
        required double baseboard,
        bool wall = false,
      }) {
        final background = frames['background']!;
        final y = wall ? frames[item]!.center.dy : frames[item]!.bottom;
        final sourceY = (y - background.top) / background.height;
        return (sourceY - (wall ? windowTop : baseboard)) /
            (baseboard - windowTop);
      }

      const previewWindow = 143 / 1024;
      const previewBaseboard = 690 / 1024;
      const portraitWindow = 115 / 1536;
      const portraitBaseboard = 782 / 1536;

      for (final item in [
        'clock',
        'shelf',
        'chair',
        'cabinet',
        'lamp',
        'pouf',
        'bed',
      ]) {
        final wall = item == 'clock' || item == 'shelf';
        final previewDepth = relativeY(
          preview,
          item,
          windowTop: previewWindow,
          baseboard: previewBaseboard,
          wall: wall,
        );
        final portraitDepth = relativeY(
          portrait,
          item,
          windowTop: portraitWindow,
          baseboard: portraitBaseboard,
          wall: wall,
        );
        if (item != 'bed') {
          expect(
            (previewDepth - portraitDepth).abs(),
            lessThan(.04),
            reason: item,
          );
        }

        // The edited wide backgrounds now center the window like the
        // portrait art, so objects should keep the same horizontal relation
        // to it even though the Home card shows more wall on both sides.
        final previewX =
            (preview[item]!.center.dx - preview['background']!.left) /
                preview['background']!.width -
            810 / 1536;
        final portraitX =
            (portrait[item]!.center.dx - portrait['background']!.left) /
                portrait['background']!.width -
            550 / 1024;
        if (item != 'bed') {
          expect(
            (previewX - portraitX).abs(),
            lessThan(.025),
            reason: '$item x',
          );
        }

        final previewHeight =
            preview[item]!.height /
            preview['background']!.height /
            (previewBaseboard - previewWindow);
        final portraitHeight =
            portrait[item]!.height /
            portrait['background']!.height /
            (portraitBaseboard - portraitWindow);
        expect(
          (previewHeight - portraitHeight).abs(),
          lessThan(.02),
          reason: '$item height',
        );
      }

      // The short Home card needs a shallower floor position than the room
      // view. Its pet bed must finish above the character's feet and tuck
      // partly behind the character, instead of reading as a foreground prop.
      for (final scene in [preview, portrait]) {
        final cat = scene['cat']!;
        final bed = scene['bed']!;
        expect(bed.bottom, lessThan(cat.bottom - cat.height * .15));
        expect(cat.center.dx - bed.center.dx, lessThan(cat.width * .65));
      }
    },
  );

  testWidgets('bookcase and side table props follow both room viewports', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final store = await SobraStore.load(now: () => DateTime(2026, 9, 14, 10));
    await store.setReducedMotion(true);
    const placements = {
      RoomSlot.floorCabinet: RoomDecorAssets.slimBookcaseId,
      RoomSlot.floorRight: RoomDecorAssets.roundSideTableId,
      RoomSlot.cabinetTop: RoomDecorAssets.savingsJarId,
      RoomSlot.sideTableTop: RoomDecorAssets.defaultTablePlantId,
    };

    Future<Map<String, Rect>> measure(RoomSceneVariant variant) async {
      await tester.pumpWidget(
        SobraScope(
          store: store,
          child: MaterialApp(
            localizationsDelegates: sobraLocalizationsDelegates,
            supportedLocales: sobraSupportedLocales,
            home: Center(
              child: SizedBox(
                width: 1000,
                height: variant == RoomSceneVariant.preview ? 500 : 1400,
                child: RoomScene(
                  variant: variant,
                  roomId: RoomThemes.casaJardinId,
                  placements: placements,
                  message: '',
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      Rect imageRect(String asset) => tester.getRect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Image &&
              widget.image is AssetImage &&
              (widget.image as AssetImage).assetName == asset,
        ),
      );
      return {
        'bookcase': imageRect(RoomDecorAssets.slimBookcase),
        'table': imageRect(RoomDecorAssets.roundSideTable),
        'jar': imageRect(RoomDecorAssets.savingsJar),
        'plant': imageRect(RoomDecorAssets.tablePlant),
      };
    }

    final preview = await measure(RoomSceneVariant.preview);
    final portrait = await measure(RoomSceneVariant.immersive);
    for (final scene in [preview, portrait]) {
      final bookcase = scene['bookcase']!;
      final table = scene['table']!;
      final jar = scene['jar']!;
      final plant = scene['plant']!;
      expect((jar.center.dx - bookcase.center.dx).abs(), lessThan(1));
      expect((plant.center.dx - table.center.dx).abs(), lessThan(1));
      final jarBase = jar.top + jar.height * (1052 / 1287);
      final plantBase = plant.top + plant.height * (971 / 1191);
      expect(
        (jarBase - bookcase.top) / bookcase.height,
        inInclusiveRange(.63, .67),
      );
      expect(
        (plantBase - table.top) / table.height,
        inInclusiveRange(.32, .42),
      );
    }
    final previewShelfDepth =
        (preview['jar']!.bottom - preview['bookcase']!.top) /
        preview['bookcase']!.height;
    final portraitShelfDepth =
        (portrait['jar']!.bottom - portrait['bookcase']!.top) /
        portrait['bookcase']!.height;
    expect((previewShelfDepth - portraitShelfDepth).abs(), lessThan(.01));
  });
}
