import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sobra_app/models/room_design.dart';
import 'package:sobra_app/state/sobra_store.dart';
import 'package:sobra_app/widgets/cat_sprite.dart';
import 'package:sobra_app/widgets/room_scene.dart';

import 'support/localizations.dart';

void main() {
  testWidgets('books and green lamp fit their supporting furniture', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(426, 919);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final store = await SobraStore.load(now: () => DateTime(2026, 9, 14, 10));
    await store.setReducedMotion(true);

    Rect frame(String asset) => tester.getRect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName == asset,
      ),
    );
    Future<void> show(
      RoomSceneVariant variant,
      Map<RoomSlot, String> placements,
    ) async {
      await tester.pumpWidget(
        SobraScope(
          store: store,
          child: MaterialApp(
            localizationsDelegates: sobraLocalizationsDelegates,
            supportedLocales: sobraSupportedLocales,
            home: RoomScene(
              variant: variant,
              placements: placements,
              message: '',
            ),
          ),
        ),
      );
      await tester.pump();
    }

    // Bounds measured on the opaque pixels in the assets, independently of
    // the placement anchors. A base must lie within the wooden top face.
    void lampFits(
      Rect lamp,
      Rect support,
      double top,
      double bottom,
      double halfWidth,
    ) {
      final baseY = lamp.top + lamp.height * .86;
      final baseX = lamp.center.dx - lamp.height * .06;
      expect(
        baseY,
        inInclusiveRange(
          support.top + support.height * top,
          support.top + support.height * bottom,
        ),
      );
      expect(
        baseX - lamp.height * .20,
        greaterThan(support.center.dx - support.height * halfWidth),
      );
      expect(
        baseX + lamp.height * .20,
        lessThan(support.center.dx + support.height * halfWidth),
      );
    }

    for (final variant in RoomSceneVariant.values) {
      for (final supportId in [
        RoomDecorAssets.lowCabinetId,
        RoomDecorAssets.slimBookcaseId,
        RoomDecorAssets.wallShelfId,
      ]) {
        final shelf = supportId == RoomDecorAssets.wallShelfId;
        final bookcase = supportId == RoomDecorAssets.slimBookcaseId;
        final supportSlot = shelf ? RoomSlot.wallLeft : RoomSlot.floorCabinet;
        final lampSlot = shelf
            ? RoomSlot.wallShelfTopLeft
            : RoomSlot.cabinetTopRight;
        final bookSlot = shelf
            ? RoomSlot.wallShelfTopRight
            : RoomSlot.cabinetTop;
        final placements = {supportSlot: supportId, lampSlot: 'item-01'};
        await show(variant, placements);
        final support = frame(RoomDecorAssets.assetFor(supportId)!);
        var lamp = frame(RoomDecorAssets.lamp);
        lampFits(
          lamp,
          support,
          shelf
              ? .48
              : bookcase
              ? .117
              : .332,
          shelf
              ? .515
              : bookcase
              ? .156
              : .40,
          shelf
              ? .64
              : bookcase
              ? .15
              : .50,
        );
        final baseX = lamp.center.dx - lamp.height * .06;
        expect(baseX, closeTo(support.center.dx, 1));

        await show(variant, {
          ...placements,
          bookSlot: RoomDecorAssets.shelfBooksId,
        });
        lamp = frame(RoomDecorAssets.lamp);
        final books = frame(RoomDecorAssets.shelfBooks);
        final bookTop = books.top + books.height * .199;
        final bookBottom = books.top + books.height * .835;
        expect(
          bookBottom,
          inInclusiveRange(
            support.top +
                support.height *
                    (shelf
                        ? .48
                        : bookcase
                        ? .56
                        : .332),
            support.top +
                support.height *
                    (shelf
                        ? .515
                        : bookcase
                        ? .61
                        : .40),
          ),
        );
        // Books retain a useful visual size next to the lamp.
        expect(books.height * .636, greaterThan(lamp.height * .685 * .60));
        if (bookcase) {
          expect(bookTop, greaterThan(support.top + support.height * .407));
          expect(
            books.center.dx - books.height * .238,
            greaterThan(support.center.dx - support.height * .145),
          );
          expect(
            books.center.dx + books.height * .215,
            lessThan(support.center.dx + support.height * .145),
          );
        } else {
          final booksLeft = books.center.dx - books.height * .238;
          final booksRight = books.center.dx + books.height * .215;
          final lampLeft = lamp.center.dx - lamp.height * .254;
          final lampRight = lamp.center.dx + lamp.height * .32;
          expect(shelf ? lampRight < booksLeft : booksRight < lampLeft, isTrue);
        }

        // The opposite saved slot order must also sit on the same surfaces.
        await show(variant, {
          supportSlot: supportId,
          bookSlot: 'item-01',
          lampSlot: RoomDecorAssets.shelfBooksId,
        });
        lamp = frame(RoomDecorAssets.lamp);
        lampFits(
          lamp,
          support,
          shelf
              ? .48
              : bookcase
              ? .56
              : .332,
          shelf
              ? .515
              : bookcase
              ? .61
              : .40,
          shelf
              ? .64
              : bookcase
              ? .145
              : .50,
        );
        if (bookcase) {
          expect(
            lamp.top + lamp.height * .175,
            greaterThan(support.top + support.height * .407),
          );
        }
      }
      // A table moving toward the viewer also scales its lamp, preserving
      // the physical proportion and contact in each viewport.
      double? proportion;
      for (final withSofa in [false, true]) {
        await show(variant, {
          RoomSlot.floorRight: RoomDecorAssets.roundSideTableId,
          RoomSlot.sideTableTop: 'item-01',
          if (withSofa) RoomSlot.floorSofa: RoomDecorAssets.ivorySofaId,
        });
        final table = frame(RoomDecorAssets.roundSideTable);
        final lamp = frame(RoomDecorAssets.lamp);
        lampFits(lamp, table, .27, .38, .35);
        final ratio = lamp.height / table.height;
        if (proportion != null) expect(ratio, closeTo(proportion, .001));
        proportion = ratio;
      }
    }
  });

  testWidgets('left lamp keeps its position when cabinet becomes bookcase', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(426, 919);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final store = await SobraStore.load(now: () => DateTime(2026, 9, 14, 10));
    await store.setReducedMotion(true);

    Future<double> lampCenter(String cabinetId, String lampId) async {
      await tester.pumpWidget(
        SobraScope(
          store: store,
          child: MaterialApp(
            localizationsDelegates: sobraLocalizationsDelegates,
            supportedLocales: sobraSupportedLocales,
            home: RoomScene(
              variant: RoomSceneVariant.immersive,
              placements: {
                RoomSlot.floorCabinet: cabinetId,
                RoomSlot.floorLeft: lampId,
              },
              message: '',
            ),
          ),
        ),
      );
      await tester.pump();
      return tester
          .getRect(
            find.byWidgetPredicate(
              (widget) =>
                  widget is Image &&
                  widget.image is AssetImage &&
                  (widget.image as AssetImage).assetName ==
                      RoomDecorAssets.assetFor(lampId),
            ),
          )
          .center
          .dx;
    }

    for (final lampId in [
      RoomDecorAssets.floorLampId,
      RoomDecorAssets.bronzeLanternLampId,
    ]) {
      final besideCabinet = await lampCenter(
        RoomDecorAssets.lowCabinetId,
        lampId,
      );
      final besideBookcase = await lampCenter(
        RoomDecorAssets.slimBookcaseId,
        lampId,
      );
      expect(besideBookcase, closeTo(besideCabinet, .01));
    }
  });

  // The lamp keeps the wall end and the bookcase steps aside. Side by side at
  // the bookcase's usual spot, the shade sank behind it and half of it hid.
  testWidgets('a floor lamp and the bookcase stand apart on the left', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 1500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final store = await SobraStore.load(now: () => DateTime(2026, 9, 14, 10));
    await store.setReducedMotion(true);

    /// The painted part of [asset], which sits bottom-centred and contained
    /// in its frame. [paint] is the opaque box within the sprite's pixels;
    /// the soft halo around the bookcase is left out, as nobody sees it.
    Rect painted(String asset, Size pixels, Rect paint) {
      final frame = tester.getRect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Image &&
              widget.image is AssetImage &&
              (widget.image as AssetImage).assetName == asset,
        ),
      );
      final scale = math.min(
        frame.width / pixels.width,
        frame.height / pixels.height,
      );
      final left = frame.center.dx - pixels.width * scale / 2;
      final top = frame.bottom - pixels.height * scale;
      return Rect.fromLTRB(
        left + paint.left * scale,
        top + paint.top * scale,
        left + paint.right * scale,
        top + paint.bottom * scale,
      );
    }

    const lamps = {
      RoomDecorAssets.floorLampId: (
        RoomDecorAssets.floorLamp,
        Size(407, 1412),
        Rect.fromLTRB(4, 4, 404, 1399),
      ),
      RoomDecorAssets.bronzeLanternLampId: (
        RoomDecorAssets.bronzeLanternLamp,
        Size(754, 2086),
        Rect.fromLTRB(159, 128, 579, 1990),
      ),
    };
    for (final roomId in [
      RoomThemes.casaClaraId,
      RoomThemes.casaInvernaderoId,
    ]) {
      for (final MapEntry(key: lampId, value: (asset, pixels, paint))
          in lamps.entries) {
        await tester.pumpWidget(
          SobraScope(
            store: store,
            child: MaterialApp(
              localizationsDelegates: sobraLocalizationsDelegates,
              supportedLocales: sobraSupportedLocales,
              home: RoomScene(
                variant: RoomSceneVariant.immersive,
                roomId: roomId,
                placements: {
                  RoomSlot.floorCabinet: RoomDecorAssets.slimBookcaseId,
                  RoomSlot.floorLeft: lampId,
                },
                message: '',
              ),
            ),
          ),
        );
        await tester.pump();

        final lamp = painted(asset, pixels, paint);
        final bookcase = painted(
          RoomDecorAssets.slimBookcase,
          const Size(1024, 1536),
          const Rect.fromLTRB(232, 144, 793, 1412),
        );
        expect(
          lamp.right,
          lessThanOrEqualTo(bookcase.left),
          reason: '$lampId beside the bookcase in $roomId',
        );
      }
    }
  });

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
      // On the cubby's shelf floor, beside where the books stand.
      expect(
        (jarBase - bookcase.top) / bookcase.height,
        inInclusiveRange(.58, .61),
      );
      expect(
        (plantBase - table.top) / table.height,
        inInclusiveRange(.32, .34),
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
