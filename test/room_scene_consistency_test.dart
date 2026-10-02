import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sobra_app/models/room_design.dart';
import 'package:sobra_app/state/sobra_store.dart';
import 'package:sobra_app/widgets/cat_sprite.dart';
import 'package:sobra_app/widgets/room_scene.dart';

import 'support/localizations.dart';

void main() {
  testWidgets('lamps clear large furniture and the pouf sits in front', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1024, 2048);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final store = await SobraStore.load(now: () => DateTime(2026, 9, 14, 10));
    await store.setReducedMotion(true);

    for (final variant in RoomSceneVariant.values) {
      Future<void> show(Map<RoomSlot, String> placements) async {
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
                    roomId: RoomThemes.casaMontanaId,
                    placements: placements,
                    message: '',
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();
      }

      Rect frame(String asset) => tester.getRect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Image &&
              widget.image is AssetImage &&
              (widget.image as AssetImage).assetName == asset,
        ),
      );

      await show(const {
        RoomSlot.floorCabinet: RoomDecorAssets.launchTvId,
        RoomSlot.floorSofa: RoomDecorAssets.launchSofaId,
        RoomSlot.floorLeft: RoomDecorAssets.floorLampId,
        RoomSlot.floorRight: RoomDecorAssets.terracottaPoufId,
      });
      final background = frame(
        variant == RoomSceneVariant.preview
            ? RoomThemes.casaMontana.previewAsset
            : RoomThemes.casaMontana.portraitAsset,
      );
      final lamp = frame(RoomDecorAssets.floorLamp);
      final tv = frame(RoomDecorAssets.launchTv);
      final sofa = frame(RoomDecorAssets.launchSofa);
      final pouf = frame(RoomDecorAssets.terracottaPouf);
      // The shade can extend horizontally above the TV. Its stem must
      // clear the unit and the shade must finish above the screen.
      final lampStemRight = lamp.center.dx + lamp.height * .025;
      final tvLeft = tv.center.dx - tv.height * (520 / 465) / 2;
      expect(lampStemRight, lessThan(tvLeft));
      expect(lamp.top + lamp.height * .28, lessThan(tv.top));
      expect(pouf.top, greaterThan(sofa.center.dy));
      expect(pouf.bottom, greaterThan(sofa.bottom));

      await show(const {
        RoomSlot.floorCabinet: RoomDecorAssets.launchTvId,
        RoomSlot.floorSofa: RoomDecorAssets.launchSofaId,
        RoomSlot.floorRight: RoomDecorAssets.floorLampId,
      });
      expect(
        frame(RoomDecorAssets.floorLamp).center.dx,
        greaterThan(background.left + background.width * .9),
      );
      final images = tester
          .widgetList<Image>(
            find.descendant(
              of: find.byType(RoomScene),
              matching: find.byType(Image),
            ),
          )
          .where((image) => image.image is AssetImage)
          .map((image) => (image.image as AssetImage).assetName)
          .toList();
      expect(
        images.indexOf(RoomDecorAssets.floorLamp),
        lessThan(images.indexOf(RoomDecorAssets.launchSofa)),
      );
    }
  });

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
        // Foreground seats are pulled into the shorter viewport so their
        // feet remain visible. Back-row furniture and wall decor retain
        // their position relative to the room landmarks.
        if (!const ['chair', 'pouf', 'bed'].contains(item)) {
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
        if (item != 'bed') {
          expect(
            (previewHeight - portraitHeight).abs(),
            lessThan(.02),
            reason: '$item height',
          );
        }
      }

      // The pet bed sits beside the character, with its visible base above
      // the paws and a size that stays readable in the short Home crop.
      for (final scene in [preview, portrait]) {
        final cat = scene['cat']!;
        final bed = scene['bed']!;
        final visibleBottom = bed.top + bed.height * (943 / 1024);
        final visibleWidth = bed.height * (1218 / 1024);
        expect(visibleBottom, lessThan(cat.bottom - cat.height * .12));
        expect(visibleWidth, lessThanOrEqualTo(cat.width * .851));
        expect(cat.center.dx - bed.center.dx, closeTo(cat.width * .85, 1));
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
