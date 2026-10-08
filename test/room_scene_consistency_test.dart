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
                  height: variant == RoomSceneVariant.preview ? 1000 : 1400,
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
      final background = frame(RoomThemes.casaMontana.portraitAsset);
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

  testWidgets('all room viewports preserve the exact shared arrangement', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(520, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final store = await SobraStore.load(now: () => DateTime(2026, 10, 6, 12));
    await store.setReducedMotion(true);
    const arrangements = [
      {
        RoomSlot.floorCabinet: RoomDecorAssets.lowCabinetId,
        RoomSlot.floorLeft: RoomDecorAssets.rattanChairId,
        RoomSlot.floorRight: RoomDecorAssets.terracottaPoufId,
        RoomSlot.floorSofa: RoomDecorAssets.ivorySofaId,
        RoomSlot.floorCenter: RoomDecorAssets.petBedId,
        RoomSlot.cabinetTop: RoomDecorAssets.savingsJarId,
        RoomSlot.cabinetTopRight: RoomDecorAssets.defaultTablePlantId,
        RoomSlot.wallLeft: RoomDecorAssets.wallClockId,
        RoomSlot.wallCenter: RoomDecorAssets.wallShelfId,
        RoomSlot.rug: RoomDecorAssets.blueCreamRugId,
      },
      {
        RoomSlot.floorCabinet: RoomDecorAssets.slimBookcaseId,
        RoomSlot.floorLeft: RoomDecorAssets.floorLampId,
        RoomSlot.floorRight: RoomDecorAssets.roundSideTableId,
        RoomSlot.floorSofa: RoomDecorAssets.launchSofaId,
        RoomSlot.cabinetTop: RoomDecorAssets.savingsJarId,
        RoomSlot.sideTableTop: RoomDecorAssets.defaultTablePlantId,
        RoomSlot.rug: RoomDecorAssets.defaultRugId,
      },
      {
        RoomSlot.floorCabinet: RoomDecorAssets.launchTvId,
        RoomSlot.floorLeft: RoomDecorAssets.bronzeLanternLampId,
        RoomSlot.floorRight: RoomDecorAssets.rattanChairId,
        RoomSlot.floorSofa: RoomDecorAssets.ivorySofaId,
        RoomSlot.rug: RoomDecorAssets.defaultRugId,
      },
    ];
    const viewports = [
      (RoomSceneVariant.preview, Size(360, 360)),
      (RoomSceneVariant.immersive, Size(360, 320)),
      (RoomSceneVariant.immersive, Size(426, 430)),
      (RoomSceneVariant.immersive, Size(360, 560)),
      (RoomSceneVariant.immersive, Size(320, 900)),
    ];
    for (final room in RoomThemes.all) {
      for (final arrangement in arrangements) {
        final placements = {
          for (final entry in arrangement.entries)
            if (room.slots.contains(entry.key)) entry.key: entry.value,
        };
        Map<String, Rect>? baseline;
        List<String>? baselinePaintOrder;
        for (final (variant, size) in viewports) {
          await tester.pumpWidget(
            SobraScope(
              store: store,
              child: MaterialApp(
                localizationsDelegates: sobraLocalizationsDelegates,
                supportedLocales: sobraSupportedLocales,
                home: Center(
                  child: SizedBox.fromSize(
                    size: size,
                    child: RoomScene(
                      variant: variant,
                      roomId: room.id,
                      placements: placements,
                      message: '',
                      animateItems: false,
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pump();
          Finder image(String asset) => find.byWidgetPredicate(
            (widget) =>
                widget is Image &&
                widget.image is AssetImage &&
                (widget.image as AssetImage).assetName == asset,
          );
          final background = tester.getRect(image(room.portraitAsset));
          Rect onStage(Rect rect) => Rect.fromLTWH(
            (rect.left - background.left) / background.width,
            (rect.top - background.top) / background.height,
            rect.width / background.width,
            rect.height / background.height,
          );
          final frames = {
            'character': onStage(tester.getRect(find.byType(CatSprite))),
            for (final id in placements.values)
              id: onStage(tester.getRect(image(RoomDecorAssets.assetFor(id)!))),
          };
          final paintOrder = tester
              .widgetList<Image>(find.byType(Image))
              .where((widget) => widget.image is AssetImage)
              .map((widget) => (widget.image as AssetImage).assetName)
              .toList();
          baseline ??= frames;
          baselinePaintOrder ??= paintOrder;
          expect(paintOrder, baselinePaintOrder);
          for (final entry in frames.entries) {
            final expected = baseline[entry.key]!;
            final reason = '${room.id} $variant $size ${entry.key}';
            expect(
              entry.value.left,
              closeTo(expected.left, 1e-6),
              reason: reason,
            );
            expect(
              entry.value.top,
              closeTo(expected.top, 1e-6),
              reason: reason,
            );
            expect(
              entry.value.width,
              closeTo(expected.width, 1e-6),
              reason: reason,
            );
            expect(
              entry.value.height,
              closeTo(expected.height, 1e-6),
              reason: reason,
            );
          }
          expect(tester.takeException(), isNull);
        }
      }
    }
  });

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
                height: variant == RoomSceneVariant.preview ? 1000 : 1400,
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
