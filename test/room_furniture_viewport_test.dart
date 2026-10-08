import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sobra_app/models/room_design.dart';
import 'package:sobra_app/state/sobra_store.dart';
import 'package:sobra_app/widgets/cat_sprite.dart';
import 'package:sobra_app/widgets/room_scene.dart';

import 'support/localizations.dart';

// Read the artwork itself so this check can catch a changed sprite whose
// transparent canvas no longer matches the placement metadata.
Future<Rect> opaqueBody(String asset) async {
  final data = await rootBundle.load(asset);
  final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
  final frame = await codec.getNextFrame();
  final image = frame.image;
  final pixels = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
  var left = image.width;
  var right = 0;
  var top = image.height;
  var bottom = 0;
  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      if (pixels.getUint8((y * image.width + x) * 4 + 3) <= 128) continue;
      if (x < left) left = x;
      if (x >= right) right = x + 1;
      if (y < top) top = y;
      if (y >= bottom) bottom = y + 1;
    }
  }
  final result = Rect.fromLTRB(
    (left - image.width / 2) / image.height,
    top / image.height,
    (right - image.width / 2) / image.height,
    bottom / image.height,
  );
  image.dispose();
  codec.dispose();
  return result;
}

Rect paintedBody(Rect frame, Rect body) => Rect.fromLTRB(
  frame.center.dx + body.left * frame.height,
  frame.top + body.top * frame.height,
  frame.center.dx + body.right * frame.height,
  frame.top + body.bottom * frame.height,
);

void main() {
  testWidgets(
    'furniture fits all room viewports and rugs stay under the paws',
    (tester) async {
      tester.view.physicalSize = const Size(400, 950);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});
      final store = await SobraStore.load(now: () => DateTime(2026, 10, 2, 12));
      await store.setReducedMotion(true);

      const sets = [
        {
          RoomSlot.floorSofa: RoomDecorAssets.ivorySofaId,
          RoomSlot.floorRight: RoomDecorAssets.rattanChairId,
          RoomSlot.floorLeft: RoomDecorAssets.bronzeLanternLampId,
          RoomSlot.rug: RoomDecorAssets.defaultRugId,
        },
        {
          RoomSlot.floorSofa: RoomDecorAssets.ivorySofaId,
          RoomSlot.floorRight: RoomDecorAssets.bronzeLanternLampId,
          RoomSlot.floorCabinet: RoomDecorAssets.slimBookcaseId,
          RoomSlot.floorLeft: RoomDecorAssets.rattanChairId,
          RoomSlot.rug: RoomDecorAssets.defaultRugId,
        },
        {
          RoomSlot.floorSofa: RoomDecorAssets.launchSofaId,
          RoomSlot.floorRight: RoomDecorAssets.rattanChairId,
          RoomSlot.floorLeft: RoomDecorAssets.floorLampId,
          RoomSlot.floorCenter: RoomDecorAssets.petBedId,
          RoomSlot.rug: RoomDecorAssets.defaultRugId,
        },
        {
          RoomSlot.floorCabinet: RoomDecorAssets.launchTvId,
          RoomSlot.floorLeft: RoomDecorAssets.rattanChairId,
          RoomSlot.floorSofa: RoomDecorAssets.launchSofaId,
          RoomSlot.floorRight: RoomDecorAssets.roundSideTableId,
          RoomSlot.rug: RoomDecorAssets.blueCreamRugId,
        },
        {
          RoomSlot.floorCabinet: RoomDecorAssets.slimBookcaseId,
          RoomSlot.floorLeft: RoomDecorAssets.floorLampId,
          RoomSlot.floorSofa: RoomDecorAssets.launchSofaId,
          RoomSlot.floorRight: RoomDecorAssets.terracottaPoufId,
          RoomSlot.rug: RoomDecorAssets.defaultRugId,
        },
        {
          RoomSlot.floorCabinet: RoomDecorAssets.lowCabinetId,
          RoomSlot.floorLeft: RoomDecorAssets.rattanChairId,
          RoomSlot.floorRight: RoomDecorAssets.floorLampId,
          RoomSlot.rug: RoomDecorAssets.defaultRugId,
        },
      ];
      final bodies = await tester.runAsync(
        () async => {
          for (final asset in {
            for (final set in sets)
              for (final id in set.values) RoomDecorAssets.assetFor(id)!,
          })
            asset: await opaqueBody(asset),
        },
      );

      const viewports = [
        (RoomSceneVariant.immersive, Size(360, 560)),
        (RoomSceneVariant.immersive, Size(360, 320)),
        (RoomSceneVariant.preview, Size(360, 360)),
        (RoomSceneVariant.immersive, Size(320, 900)),
      ];
      for (final room in RoomThemes.all) {
        for (final (variant, size) in viewports) {
          for (final placements in sets) {
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
            final viewport = tester.getRect(find.byType(RoomScene));
            Rect bodyFor(String id) {
              final asset = RoomDecorAssets.assetFor(id)!;
              final imageFrame = tester.getRect(
                find.byWidgetPredicate(
                  (widget) =>
                      widget is Image &&
                      widget.image is AssetImage &&
                      (widget.image as AssetImage).assetName == asset,
                ),
              );
              return paintedBody(imageFrame, bodies![asset]!);
            }

            for (final entry in placements.entries) {
              if (entry.key.surface != RoomSurface.floor) continue;
              final body = bodyFor(entry.value);
              final reason = '${room.id}, $variant $size, ${entry.value}';
              expect(
                body.left,
                greaterThanOrEqualTo(viewport.left - .5),
                reason: reason,
              );
              expect(
                body.right,
                lessThanOrEqualTo(viewport.right + .5),
                reason: reason,
              );
              expect(
                body.top,
                greaterThanOrEqualTo(viewport.top - .5),
                reason: reason,
              );
              expect(
                body.bottom,
                lessThanOrEqualTo(viewport.bottom + .5),
                reason: reason,
              );
            }
            final cat = tester.getRect(find.byType(CatSprite));
            final paws = Offset(
              cat.center.dx,
              cat.top + cat.height * 344 / 360,
            );
            final rug = bodyFor(placements[RoomSlot.rug]!);
            expect(
              rug.contains(paws),
              isTrue,
              reason: '${room.id}, $variant $size',
            );

            if (RoomDecorAssets.isSofa(placements[RoomSlot.floorSofa]) &&
                placements[RoomSlot.floorRight] ==
                    RoomDecorAssets.rattanChairId) {
              expect(
                bodyFor(RoomDecorAssets.rattanChairId).bottom,
                greaterThan(bodyFor(placements[RoomSlot.floorSofa]!).bottom),
              );
            }
          }
        }
      }
    },
  );
}
