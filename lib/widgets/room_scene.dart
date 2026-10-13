import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/room_design.dart';
import '../models/room_time_of_day.dart';
import '../state/sobra_store.dart';
import '../theme/app_theme.dart';
import 'cat_sprite.dart';
import 'character_headroom.dart';
import 'room_lighting.dart';

enum RoomSceneVariant { preview, immersive }

/// Composes a hybrid room from a theme, the places it offers and the
/// character layer. Nothing about a slot is tied to Casa clara's pixels, so a
/// later theme can supply a new background and anchor map without changing
/// the saved decoration choices.
class RoomScene extends StatelessWidget {
  const RoomScene({
    super.key,
    required this.variant,
    required this.placements,
    required this.message,
    this.roomId = RoomThemes.casaClaraId,
    this.backgroundAsset,
    this.timeOfDay,
    this.showSlots = false,
    this.animateItems = true,
    this.selectedItemId,
    this.onSlotTap,
    this.onCatTap,
    this.onReactionComplete,
    this.reacting = false,
    this.catMotion,
    this.catLoop,
    this.characterId,
  });

  final RoomSceneVariant variant;
  final Map<RoomSlot, String> placements;
  final String message;
  final String roomId;
  final String? backgroundAsset;

  /// Lights the room for this time of day; null keeps the plain art.
  final RoomTimeOfDay? timeOfDay;

  /// Lights the places [selectedItemId] can go, and only those.
  ///
  /// With nothing selected no place is lit: an empty outline everywhere read
  /// as "anything goes anywhere", and a lamp offered a spot on the wall.
  final bool showSlots;
  final bool animateItems;
  final String? selectedItemId;
  final ValueChanged<RoomSlot>? onSlotTap;
  final VoidCallback? onCatTap;
  final VoidCallback? onReactionComplete;
  final bool reacting;
  final CatMotion? catMotion;
  final bool? catLoop;

  /// Overrides the character the scope names; see [CatSprite.characterId].
  final String? characterId;

  RoomTheme get _room => RoomThemes.byId(roomId);

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final room = _room;
          // Home, Decorate and the full room share the portrait stage. A
          // short viewport scales the whole room down; it never squeezes or
          // moves individual furniture. Tall views reveal more wall/floor.
          final width = math.min(constraints.maxWidth, constraints.maxHeight);
          final size = Size(
            width,
            math.min(
              constraints.maxHeight,
              width / room.portraitSize.aspectRatio,
            ),
          );
          // These scenes paint their own full-width window light. The shared
          // small-window rays and mask would cross their glass and frames.
          final usesPaintedLight =
              room.id == RoomThemes.casaTorreId ||
              room.id == RoomThemes.casaMontanaId ||
              room.id == RoomThemes.casaInvernaderoId;
          final isPanoramic = usesPaintedLight;
          final roomPhase = timeOfDay;
          final sceneAsset = backgroundAsset ?? room.sceneAssetFor(roomPhase);
          final layout = _RoomSceneLayout.of(room.id);
          final selected = selectedItemId;
          final selectedAsset = selected == null
              ? null
              : RoomDecorAssets.assetFor(selected);
          final targets = showSlots && selected != null
              ? room.slotsForItem(selected, placements: placements)
              : const <RoomSlot>[];
          final stageScale = size.width / room.portraitSize.width;
          final backgroundHeight = room.portraitSize.height * stageScale;
          // A stage exactly as tall as the art can come out a rounding error
          // taller, which put the lower bound above zero and made clamp throw
          // — the whole room then failed to build. Never let it pass zero.
          final background = Rect.fromLTWH(
            0,
            ((size.height - size.width) / 2 - 96 * stageScale).clamp(
              math.min(size.height - backgroundHeight, 0.0),
              0.0,
            ),
            size.width,
            backgroundHeight,
          );
          final catAspect =
              CharacterAnimationStandard.frameHeight /
              CharacterAnimationStandard.frameWidth;
          final catWidth = background.width * .26;
          final catHeight = catWidth * catAspect;
          final catFrame = Rect.fromLTWH(
            (size.width - catWidth) / 2,
            background.top + background.height * .49,
            catWidth,
            catHeight,
          );
          final catPaws = catFrame.top + catFrame.height * 344 / 360;
          late Rect Function(RoomSlot, String) itemFrame;
          Rect slotFrame(RoomSlot slot) {
            if (slot == RoomSlot.cabinetTop ||
                slot == RoomSlot.cabinetTopRight) {
              final supportId =
                  placements[RoomSlot.floorCabinet] ==
                      RoomDecorAssets.slimBookcaseId
                  ? RoomDecorAssets.slimBookcaseId
                  : RoomDecorAssets.lowCabinetId;
              final cabinet = itemFrame(RoomSlot.floorCabinet, supportId);
              final height = cabinet.height;
              if (supportId == RoomDecorAssets.slimBookcaseId) {
                // The left spot is the open middle cubby, whose shelf floor
                // is at .598; the right one is the top board. Both are
                // separate movable sprites.
                final bottom =
                    cabinet.top +
                    height * (slot == RoomSlot.cabinetTop ? .61 : .20);
                return Rect.fromLTWH(
                  cabinet.center.dx - height * .20,
                  bottom - height * .16,
                  height * .40,
                  height * .16,
                );
              }
              // Both small props follow the cabinet top as it moves and
              // scales between the Home card and the portrait room.
              return Rect.fromLTWH(
                cabinet.center.dx +
                    height * (slot == RoomSlot.cabinetTop ? -.52 : .06),
                // Both sprites have transparent pixels below their visible
                // bases; overlap the wood slightly so neither looks afloat.
                cabinet.top + height * .04,
                height * .5,
                height * .4,
              );
            }
            if (slot == RoomSlot.sideTableTop) {
              final table = itemFrame(
                RoomSlot.floorRight,
                RoomDecorAssets.roundSideTableId,
              );
              final height = table.height;
              // The tabletop begins at .2144, but props stand toward the
              // middle of its ellipse rather than on the back rim.
              final tableTop = table.top + height * .33;
              return Rect.fromLTWH(
                table.center.dx - height * .28,
                tableTop - height * .18,
                height * .56,
                height * .18,
              );
            }
            if (slot == RoomSlot.wallShelfTopLeft ||
                slot == RoomSlot.wallShelfTopRight) {
              final shelfSlot =
                  placements[RoomSlot.wallLeft] == RoomDecorAssets.wallShelfId
                  ? RoomSlot.wallLeft
                  : RoomSlot.wallCenter;
              final shelf = itemFrame(shelfSlot, RoomDecorAssets.wallShelfId);
              final x =
                  shelf.center.dx +
                  shelf.height *
                      (slot == RoomSlot.wallShelfTopLeft ? -.28 : .28);
              // The opaque wood starts 46.5% down the shelf sprite. Targets
              // and prop bases meet that line, regardless of the room theme.
              final shelfTop = shelf.top + shelf.height * .465;
              return Rect.fromLTWH(
                x - shelf.height * .19,
                shelfTop - shelf.height * .18,
                shelf.height * .38,
                shelf.height * .18,
              );
            }
            final rect = layout.slotRects[slot]!;
            final frame = background;
            return Rect.fromLTWH(
              frame.left + rect.left * frame.width,
              frame.top + rect.top * frame.height,
              rect.width * frame.width,
              rect.height * frame.height,
            );
          }

          // Furniture shares a back row; secondary seats and low tables
          // move forward when that row is occupied. Depth is measured from
          // the floor line so Home and the portrait retain the same grouping.
          Rect itemSpot(RoomSlot slot, String itemId) {
            final spot = slotFrame(slot);
            if (itemId == 'item-01' &&
                slot == RoomSlot.cabinetTopRight &&
                placements[RoomSlot.floorCabinet] ==
                    RoomDecorAssets.lowCabinetId &&
                (placements[RoomSlot.cabinetTop] == null ||
                    placements[RoomSlot.cabinetTop] ==
                        RoomDecorAssets.clearedId)) {
              // A single lamp belongs near the middle of the wide cabinet.
              // The right-hand spot resumes when another prop uses the left.
              final cabinet = itemFrame(
                RoomSlot.floorCabinet,
                RoomDecorAssets.lowCabinetId,
              );
              return spot.shift(Offset(cabinet.center.dx - spot.center.dx, 0));
            }
            if (itemId == 'item-01' &&
                (slot == RoomSlot.wallShelfTopLeft ||
                    slot == RoomSlot.wallShelfTopRight)) {
              final otherSlot = slot == RoomSlot.wallShelfTopLeft
                  ? RoomSlot.wallShelfTopRight
                  : RoomSlot.wallShelfTopLeft;
              final otherItem = placements[otherSlot];
              if (otherItem == null || otherItem == RoomDecorAssets.clearedId) {
                final shelfSlot =
                    placements[RoomSlot.wallLeft] == RoomDecorAssets.wallShelfId
                    ? RoomSlot.wallLeft
                    : RoomSlot.wallCenter;
                final shelf = itemFrame(shelfSlot, RoomDecorAssets.wallShelfId);
                return spot.shift(Offset(shelf.center.dx - spot.center.dx, 0));
              }
            }
            Rect at(double x, double depth) {
              final bottom = _stageFloorLine + depth * .434;
              return Rect.fromLTWH(
                background.left + (x - .08) * background.width,
                background.top + bottom * background.height - spot.height,
                background.width * .16,
                spot.height,
              );
            }

            if (slot == RoomSlot.rug) {
              // The rug shares the character's stage coordinates, including
              // its foreground depth, in every viewport.
              final height = catWidth * 2.15 / 3;
              final top = catPaws - height * .53;
              return Rect.fromLTWH(
                catFrame.center.dx - height * 1.5,
                top,
                height * 3,
                height,
              );
            }
            final cabinetId = placements[RoomSlot.floorCabinet];
            final hasCabinet =
                cabinetId != null && cabinetId != RoomDecorAssets.clearedId;
            final hasSofa = RoomDecorAssets.isSofa(
              placements[RoomSlot.floorSofa],
            );
            final hasLeftChair =
                placements[RoomSlot.floorLeft] == RoomDecorAssets.rattanChairId;
            // The bookcase pushes the chair out to .32, where a table or pouf
            // tucked beside it would stand right behind it; they keep their
            // own place on the right instead.
            final besideChair =
                hasLeftChair &&
                !hasSofa &&
                cabinetId != RoomDecorAssets.slimBookcaseId;
            if (itemId == RoomDecorAssets.petBedId) {
              // Beside the cat on the left. A cabinet brings the chair forward
              // (depth .36), where it hid the bed; then the bed takes the cat's
              // right when nothing stands there, or comes forward onto the rug
              // in front of the chair.
              final rightItem = placements[RoomSlot.floorRight];
              final rightFree =
                  rightItem == null ||
                  rightItem == RoomDecorAssets.clearedId ||
                  (besideChair &&
                      (rightItem == RoomDecorAssets.roundSideTableId ||
                          rightItem == RoomDecorAssets.terracottaPoufId));
              final chairInFront = hasLeftChair && hasCabinet;
              final side = chairInFront && rightFree ? 1 : -1;
              final forward = chairInFront && !rightFree ? catWidth * .30 : 0;
              return Rect.fromLTWH(
                catFrame.center.dx + side * catWidth * .85 - spot.width / 2,
                catPaws - catWidth * .15 + forward - spot.height,
                spot.width,
                spot.height,
              );
            }
            if (slot == RoomSlot.wallCenter &&
                itemId == RoomDecorAssets.wallShelfId) {
              // A shelf is far wider than a clock or frame; centred on the
              // slot its left end ran into the window's right curtain.
              return spot.shift(Offset(background.width * .03, 0));
            }
            if (slot == RoomSlot.floorCabinet &&
                itemId == RoomDecorAssets.slimBookcaseId) {
              // A floor lamp keeps the wall end; the bookcase steps right of
              // it. Side by side at the usual spot, the shade sank behind the
              // bookcase and only half of it showed.
              if (RoomDecorAssets.isFloorLamp(placements[RoomSlot.floorLeft])) {
                return at(isPanoramic ? .23 : .26, .09);
              }
              return at(isPanoramic ? .15 : .18, .09);
            }
            if (slot == RoomSlot.floorLeft && hasCabinet) {
              final bookcase = cabinetId == RoomDecorAssets.slimBookcaseId;
              if (RoomDecorAssets.isFloorLamp(itemId)) {
                return at(.06, .09);
              }
              if (itemId == RoomDecorAssets.rattanChairId) {
                return at(bookcase ? .32 : .13, .36);
              }
            }
            if (slot == RoomSlot.floorRight) {
              if (hasSofa) {
                return switch (itemId) {
                  RoomDecorAssets.rattanChairId => at(.84, .34),
                  RoomDecorAssets.roundSideTableId => at(.69, .30),
                  RoomDecorAssets.terracottaPoufId => at(.82, .30),
                  RoomDecorAssets.floorLampId ||
                  RoomDecorAssets.bronzeLanternLampId => at(.94, .09),
                  _ => spot,
                };
              }
              if (besideChair) {
                final nearChair = hasCabinet ? .31 : .38;
                if (itemId == RoomDecorAssets.roundSideTableId) {
                  return at(nearChair, hasCabinet ? .28 : .10);
                }
                if (itemId == RoomDecorAssets.terracottaPoufId) {
                  return at(nearChair, .28);
                }
              }
            }
            return spot;
          }

          /// Where [itemId] is drawn in [slot]: its own stage height, standing
          /// on the slot's bottom edge or hung on its centre. The box is wider
          /// than any item so the image keeps its own shape inside it.
          itemFrame = (RoomSlot slot, String itemId) {
            final spot = itemSpot(slot, itemId);
            final stageHeight = RoomDecorAssets.stageHeightFor(itemId);
            if (stageHeight == null) return spot;
            // The same object grows gently as its floor contact moves toward
            // the viewer. Tabletop props inherit their support's scale below.
            final depth = slot.surface == RoomSurface.floor
                ? ((spot.bottom - background.top) / background.height -
                          _stageFloorLine)
                      .clamp(0.0, .45)
                : 0.0;
            var height = stageHeight * stageScale * (1 + depth * .6);
            final body = _floorSpriteBody(itemId);
            if (slot.surface == RoomSurface.floor && body != null) {
              // Keep opaque furniture inside the room's side walls. This
              // uses stage bounds, not the viewport, so the same placement
              // has exactly the same frame on Home and in Decorate.
              final padding = background.width * .025;
              if (itemId == RoomDecorAssets.petBedId) {
                height = math.min(height, catWidth * .85 / body.width);
              }
              var frame = Rect.fromLTWH(
                spot.center.dx - height * 1.5,
                spot.bottom - height * body.bottom,
                height * 3,
                height,
              );
              final visible = _floorSpriteRect(frame, itemId);
              final dx = visible.left < padding
                  ? padding - visible.left
                  : visible.right > size.width - padding
                  ? size.width - padding - visible.right
                  : 0.0;
              frame = frame.shift(Offset(dx, 0));
              return frame;
            }
            if ((slot == RoomSlot.cabinetTop ||
                    slot == RoomSlot.cabinetTopRight ||
                    slot == RoomSlot.sideTableTop ||
                    slot == RoomSlot.wallShelfTopLeft ||
                    slot == RoomSlot.wallShelfTopRight) &&
                (itemId == RoomDecorAssets.shelfBooksId ||
                    itemId == 'item-01' ||
                    // In the bookcase cubby the jar stands on the same
                    // shelf floor as the books; the generic tabletop drop
                    // buried its base in the shelf's front lip.
                    (itemId == RoomDecorAssets.savingsJarId &&
                        slot == RoomSlot.cabinetTop &&
                        placements[RoomSlot.floorCabinet] ==
                            RoomDecorAssets.slimBookcaseId))) {
              late Rect support;
              late String supportId;
              late double contactY;
              var contactX = spot.center.dx;
              if (slot == RoomSlot.cabinetTop ||
                  slot == RoomSlot.cabinetTopRight) {
                final isBookcase =
                    placements[RoomSlot.floorCabinet] ==
                    RoomDecorAssets.slimBookcaseId;
                supportId = isBookcase
                    ? RoomDecorAssets.slimBookcaseId
                    : RoomDecorAssets.lowCabinetId;
                support = itemFrame(RoomSlot.floorCabinet, supportId);
                if (isBookcase) {
                  contactX = support.center.dx;
                  contactY =
                      support.top +
                      support.height *
                          (slot == RoomSlot.cabinetTop ? .598 : .133);
                } else {
                  final alone =
                      itemId == 'item-01' &&
                      slot == RoomSlot.cabinetTopRight &&
                      (placements[RoomSlot.cabinetTop] == null ||
                          placements[RoomSlot.cabinetTop] ==
                              RoomDecorAssets.clearedId);
                  contactX =
                      support.center.dx +
                      support.height *
                          (alone
                              ? 0
                              : slot == RoomSlot.cabinetTop
                              ? -.24
                              : .24);
                  contactY = support.top + support.height * .365;
                }
              } else if (slot == RoomSlot.sideTableTop) {
                supportId = RoomDecorAssets.roundSideTableId;
                support = itemFrame(RoomSlot.floorRight, supportId);
                contactY = support.top + support.height * .33;
              } else {
                supportId = RoomDecorAssets.wallShelfId;
                final shelfSlot = placements[RoomSlot.wallLeft] == supportId
                    ? RoomSlot.wallLeft
                    : RoomSlot.wallCenter;
                support = itemFrame(shelfSlot, supportId);
                contactY = support.top + support.height * .49;
              }
              // Props inherit the supporting furniture's depth scale. Their
              // visible size stays consistent on a cabinet, table or shelf.
              height *=
                  support.height /
                  (RoomDecorAssets.stageHeightFor(supportId)! * stageScale);
              if (supportId == RoomDecorAssets.slimBookcaseId &&
                  slot == RoomSlot.cabinetTop &&
                  itemId == 'item-01') {
                // A lamp tucked into the cubby sits further back and must
                // clear the underside of the shelf above it.
                height = math.min(height, support.height * .25);
              }
              // Contact points are measured on the opaque bases, excluding
              // the canvas margins and the lamp's baked grey shadow.
              final base = switch (itemId) {
                'item-01' => const Offset(-.06, .86),
                RoomDecorAssets.savingsJarId => const Offset(0, .835),
                _ => const Offset(-.012, .835),
              };
              return Rect.fromLTWH(
                contactX - height * base.dx - height * 1.5,
                contactY - height * base.dy,
                height * 3,
                height,
              );
            }
            if (slot == RoomSlot.wallShelfTopLeft ||
                slot == RoomSlot.wallShelfTopRight) {
              // Sprite canvases include transparent margins. Anchor each
              // visible object to the wood; vines alone trail below it.
              final opaqueBase = switch (itemId) {
                RoomDecorAssets.trailingPlantId => .47,
                _ => .82,
              };
              return Rect.fromLTWH(
                spot.center.dx - height * 1.5,
                spot.bottom - height * opaqueBase,
                height * 3,
                height,
              );
            }
            if (slot == RoomSlot.sideTableTop) {
              // These sprites carry transparent pixels below their stands.
              // Put the visible base on the tabletop, accounting for the
              // transparent pixels beneath each sprite's stand.
              final opaqueBase = switch (itemId) {
                RoomDecorAssets.savingsJarId => .819,
                _ => .815,
              };
              return Rect.fromLTWH(
                spot.center.dx - height * 1.5,
                spot.bottom - height * opaqueBase,
                height * 3,
                height,
              );
            }
            if (itemId == RoomDecorAssets.trailingPlantId) {
              final isBookcase =
                  placements[RoomSlot.floorCabinet] ==
                  RoomDecorAssets.slimBookcaseId;
              final cabinet = itemFrame(
                RoomSlot.floorCabinet,
                isBookcase
                    ? RoomDecorAssets.slimBookcaseId
                    : RoomDecorAssets.lowCabinetId,
              );
              // The plant's pot rests at the centre of the top board, or on
              // the cubby's shelf floor (.60) when it takes the bookcase's
              // left spot.
              final supportLine =
                  spot.bottom -
                  cabinet.height *
                      (isBookcase
                          ? (slot == RoomSlot.cabinetTop ? .01 : .09)
                          : .12);
              return Rect.fromLTWH(
                spot.center.dx - height * 1.5,
                supportLine - height * .47,
                height * 3,
                height,
              );
            }
            final width = height * 3;
            return switch (slot.surface) {
              RoomSurface.floor || RoomSurface.tabletop => Rect.fromLTWH(
                spot.center.dx - width / 2,
                spot.bottom - height,
                width,
                height,
              ),
              RoomSurface.wall || RoomSurface.rug => Rect.fromCenter(
                center: spot.center,
                width: width,
                height: height,
              ),
            };
          };

          Rect targetFrame(RoomSlot slot, String itemId) {
            final spot = itemSpot(slot, itemId);
            if (slot.surface != RoomSurface.floor) return spot;
            final frame = itemFrame(slot, itemId);
            final visible = _floorSpriteRect(frame, itemId);
            return spot.shift(
              Offset(
                frame.center.dx - spot.center.dx,
                visible.bottom - spot.bottom,
              ),
            );
          }

          // The rug lies under everything; the rest overlap by where they
          // stand, so something lower on screen — nearer the viewer — is
          // drawn over what stands behind it.
          bool hasSupport(RoomSlot slot) => switch (slot) {
            RoomSlot.cabinetTop || RoomSlot.cabinetTopRight =>
              placements[RoomSlot.floorCabinet] ==
                      RoomDecorAssets.lowCabinetId ||
                  placements[RoomSlot.floorCabinet] ==
                      RoomDecorAssets.slimBookcaseId,
            RoomSlot.sideTableTop =>
              placements[RoomSlot.floorRight] ==
                  RoomDecorAssets.roundSideTableId,
            RoomSlot.wallShelfTopLeft || RoomSlot.wallShelfTopRight =>
              placements[RoomSlot.wallLeft] == RoomDecorAssets.wallShelfId ||
                  placements[RoomSlot.wallCenter] ==
                      RoomDecorAssets.wallShelfId,
            _ => true,
          };
          final placed =
              [
                for (final slot in room.slots)
                  if (placements[slot] case final itemId?)
                    if (hasSupport(slot))
                      if (RoomDecorAssets.assetFor(itemId) case final asset?)
                        (
                          slot: slot,
                          itemId: itemId,
                          asset: asset,
                          frame: itemFrame(slot, itemId),
                        ),
              ]..sort((a, b) {
                if (a.slot.surface == RoomSurface.rug) return -1;
                if (b.slot.surface == RoomSurface.rug) return 1;
                // The sofa and TV hide the lamp stem where it stands behind
                // them. A pouf belongs in front of the sofa's lower edge.
                if (RoomDecorAssets.isFloorLamp(a.itemId) &&
                    (RoomDecorAssets.isSofa(b.itemId) ||
                        b.itemId == RoomDecorAssets.launchTvId)) {
                  return -1;
                }
                if (RoomDecorAssets.isFloorLamp(b.itemId) &&
                    (RoomDecorAssets.isSofa(a.itemId) ||
                        a.itemId == RoomDecorAssets.launchTvId)) {
                  return 1;
                }
                final atopA =
                    a.slot == RoomSlot.cabinetTop ||
                    a.slot == RoomSlot.cabinetTopRight ||
                    a.slot == RoomSlot.sideTableTop ||
                    a.slot == RoomSlot.wallShelfTopLeft ||
                    a.slot == RoomSlot.wallShelfTopRight;
                final atopB =
                    b.slot == RoomSlot.cabinetTop ||
                    b.slot == RoomSlot.cabinetTopRight ||
                    b.slot == RoomSlot.sideTableTop ||
                    b.slot == RoomSlot.wallShelfTopLeft ||
                    b.slot == RoomSlot.wallShelfTopRight;
                if (atopA != atopB) return atopA ? 1 : -1;
                return a.frame.bottom.compareTo(b.frame.bottom);
              });

          final sceneCharacterId =
              characterId ??
              SobraScope.maybeOf(context)?.characterId ??
              CharacterCatalog.defaultId;
          final sceneCharacter = CharacterCatalog.resolve(sceneCharacterId);
          final roomDisplayScale = sceneCharacter.roomDisplayScale;
          final shownMotion = reacting
              ? CatMotion.celebrate
              : catMotion ?? CatMotion.idle;
          // How far above the paws, in source pixels, the speech bubble's tip
          // sits. It stays where it always was (.06 of the frame above its
          // top) unless the motion on screen reaches higher once scaled for
          // the room — a jump or tall ears — and then lifts clear of it.
          final headRise =
              (344 -
                  (characterTopRows[sceneCharacter.id]?[shownMotion.role] ??
                      16)) *
              sceneCharacter.motionFor(shownMotion.role).displayScale *
              roomDisplayScale;
          final speechRise = math.max(344 - .06 * 360, headRise + 10);

          final floorLamps = [
            for (final item in placed)
              if (item.asset == RoomDecorAssets.floorLamp) item.frame,
          ];
          final tableLamps = [
            for (final item in placed)
              if (item.asset == RoomDecorAssets.lamp) item.frame,
          ];
          final bronzeLamps = [
            for (final item in placed)
              if (item.itemId == RoomDecorAssets.bronzeLanternLampId)
                item.frame,
          ];
          final lampLights = [
            for (final lamp in floorLamps) roomLampLight(lamp, floorLamp: true),
            for (final lamp in bronzeLamps) roomBronzeLampLight(lamp),
            for (final lamp in tableLamps)
              roomLampLight(lamp, floorLamp: false),
          ];
          Widget lit(Rect frame, Widget child) => roomPhase == null
              ? child
              : RoomSubjectLight(
                  phase: roomPhase,
                  frame: frame,
                  lamps: lampLights,
                  reach: background.width * .75,
                  child: child,
                );

          return Center(
            child: SizedBox.fromSize(
              size: size,
              child: ClipRect(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Positioned.fromRect(
                      rect: background,
                      child: Image.asset(
                        sceneAsset,
                        fit: BoxFit.fill,
                        // When the hour turns, the last light stays up until
                        // the next one has loaded instead of a blank room.
                        gaplessPlayback: true,
                        excludeFromSemantics: true,
                        errorBuilder: (_, _, _) =>
                            const ColoredBox(color: AppColors.paperLight),
                      ),
                    ),
                    if (roomPhase != null) ...[
                      if (!usesPaintedLight) ...[
                        Positioned.fill(
                          child: IgnorePointer(
                            child: CustomPaint(
                              painter: RoomSunbeams(
                                background: background,
                                phase: roomPhase,
                              ),
                            ),
                          ),
                        ),
                        // The room darkens under the furniture and the character,
                        // which take their own, lighter shade below.
                        Positioned.fill(
                          child: IgnorePointer(
                            child: CustomPaint(
                              painter: RoomAmbientTint(
                                phase: roomPhase,
                                background: background,
                              ),
                            ),
                          ),
                        ),
                      ],
                      if (roomPhase == RoomTimeOfDay.night)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: CustomPaint(
                              painter: RoomLampGlow(
                                background: background,
                                floorLamps: floorLamps,
                                tableLamps: tableLamps,
                                bronzeLamps: bronzeLamps,
                              ),
                            ),
                          ),
                        ),
                    ],
                    for (final item in placed)
                      Positioned.fromRect(
                        rect: item.frame,
                        child: lit(
                          item.frame,
                          item.asset == RoomDecorAssets.launchTv
                              ? _AnimatedTvSprite(
                                  animate:
                                      animateItems &&
                                      !showSlots &&
                                      (ModalRoute.isCurrentOf(context) ??
                                          true) &&
                                      !reducedMotionOf(context),
                                )
                              : _RoomItemImage(
                                  asset: item.asset,
                                  slot: item.slot,
                                ),
                        ),
                      ),
                    Positioned.fromRect(
                      rect: catFrame,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: onCatTap,
                        child: Semantics(
                          button: onCatTap != null,
                          child: Transform.scale(
                            key: const ValueKey('room-character-scale'),
                            scale: roomDisplayScale,
                            // Keep the paws on the same floor line as Michi and
                            // Miru while the smaller painted silhouettes grow.
                            alignment: const Alignment(0, 2 * 344 / 360 - 1),
                            child: lit(
                              catFrame,
                              CatSprite(
                                motion: shownMotion,
                                characterId: sceneCharacterId,
                                width: catWidth,
                                animate: !reducedMotionOf(context),
                                loop: reacting ? false : catLoop,
                                onComplete: reacting
                                    ? onReactionComplete
                                    : null,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (roomPhase == RoomTimeOfDay.night &&
                        (floorLamps.isNotEmpty || bronzeLamps.isNotEmpty))
                      Positioned.fill(
                        child: IgnorePointer(
                          child: CustomPaint(
                            painter: RoomLampShades(
                              floorLamps: floorLamps,
                              bronzeLamps: bronzeLamps,
                            ),
                          ),
                        ),
                      ),
                    AnimatedPositioned(
                      duration: reducedMotionOf(context)
                          ? Duration.zero
                          : const Duration(milliseconds: 180),
                      curve: Curves.easeOut,
                      left: catFrame.center.dx - background.width * .25,
                      bottom:
                          size.height - catPaws + catHeight * speechRise / 360,
                      width: background.width * .5,
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: _RoomSpeech(message: message),
                      ),
                    ),
                    // Last, so a place the character or its speech overlaps can
                    // still be tapped: Decorate's crop keeps more wall, and Casa
                    // clara's table now sits beside the bubble.
                    for (final slot in targets)
                      _RoomSlotTarget(
                        slot: slot,
                        number: switch (slot) {
                          RoomSlot.cabinetTop => 1,
                          RoomSlot.cabinetTopRight => 2,
                          RoomSlot.sideTableTop => 1,
                          RoomSlot.wallShelfTopLeft => 1,
                          RoomSlot.wallShelfTopRight => 2,
                          _ => room.slotsFor(slot.surface).indexOf(slot) + 1,
                        },
                        supportLabel: switch (slot) {
                          RoomSlot.cabinetTop || RoomSlot.cabinetTopRight =>
                            placements[RoomSlot.floorCabinet] ==
                                    RoomDecorAssets.slimBookcaseId
                                ? AppLocalizations.of(context).roomSlimBookcase
                                : AppLocalizations.of(context).roomLowCabinet,
                          RoomSlot.sideTableTop => AppLocalizations.of(
                            context,
                          ).roomRoundSideTable,
                          RoomSlot.wallShelfTopLeft ||
                          RoomSlot.wallShelfTopRight => AppLocalizations.of(
                            context,
                          ).roomWallShelf,
                          _ => null,
                        },
                        frame: targetFrame(slot, selected!),
                        ghostFrame: itemFrame(slot, selected),
                        holdsSelection: placements[slot] == selected,
                        ghostAsset: selectedAsset,
                        onTap: onSlotTap == null
                            ? null
                            : () => onSlotTap!(slot),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// Main opaque outlines measured on the sprite canvases. X is relative to
// the canvas centre and every coordinate is in units of canvas height.
// Transparent padding and baked glows must not determine floor contact or
// whether a piece fits inside the viewport.
Rect? _floorSpriteBody(String itemId) => switch (itemId) {
  RoomDecorAssets.ivorySofaId => const Rect.fromLTRB(
    -1.1961,
    .0757,
    1.1961,
    .9433,
  ),
  RoomDecorAssets.bronzeLanternLampId => const Rect.fromLTRB(
    -.1045,
    .0614,
    .0968,
    .9540,
  ),
  RoomDecorAssets.rattanChairId => const Rect.fromLTRB(-.485, .004, .484, .996),
  RoomDecorAssets.floorLampId => const Rect.fromLTRB(
    -.1413,
    .0028,
    .142,
    .9908,
  ),
  RoomDecorAssets.launchSofaId => const Rect.fromLTRB(
    -.9688,
    .0075,
    .9713,
    .9625,
  ),
  RoomDecorAssets.launchTvId => const Rect.fromLTRB(
    -.5505,
    .0086,
    .5527,
    .9892,
  ),
  RoomDecorAssets.lowCabinetId => const Rect.fromLTRB(
    -.5508,
    .3135,
    .5518,
    .9375,
  ),
  RoomDecorAssets.slimBookcaseId => const Rect.fromLTRB(
    -.1823,
    .0938,
    .1829,
    .9193,
  ),
  RoomDecorAssets.roundSideTableId => const Rect.fromLTRB(
    -.3654,
    .2144,
    .3654,
    .8474,
  ),
  RoomDecorAssets.petBedId => const Rect.fromLTRB(-.5947, .1182, .5947, .9209),
  RoomDecorAssets.terracottaPoufId => const Rect.fromLTRB(
    -.4572,
    .2077,
    .4572,
    .8957,
  ),
  _ => null,
};

Rect _floorSpriteRect(Rect frame, String itemId) {
  final body = _floorSpriteBody(itemId);
  if (body == null) return frame;
  return Rect.fromLTRB(
    frame.center.dx + frame.height * body.left,
    frame.top + frame.height * body.top,
    frame.center.dx + frame.height * body.right,
    frame.top + frame.height * body.bottom,
  );
}

/// Floor contact on the shared 1024 × 1536 portrait stage.
const _stageFloorLine = 782 / 1536;

class _RoomSceneLayout {
  const _RoomSceneLayout(this.slotRects);

  /// Every anchor is relative to the portrait background. Preview, full
  /// room and decorator project these same coordinates into their viewport.
  final Map<RoomSlot, Rect> slotRects;

  static const _slots = <RoomSlot, Rect>{
    RoomSlot.rug: Rect.fromLTWH(.05, .67, .90, .14),
    RoomSlot.wallLeft: Rect.fromLTWH(.15, .185, .14, .066),
    RoomSlot.wallCenter: Rect.fromLTWH(.76, .185, .14, .066),
    RoomSlot.floorLeft: Rect.fromLTWH(.07, .40, .24, .147),
    RoomSlot.floorRight: Rect.fromLTWH(.72, .40, .18, .147),
    RoomSlot.floorCenter: Rect.fromLTWH(.20, .50, .28, .18),
    RoomSlot.floorAccent: Rect.fromLTWH(.63, .45, .08, .15),
    RoomSlot.floorCabinet: Rect.fromLTWH(.14, .40, .24, .15),
    RoomSlot.floorSofa: Rect.fromLTWH(.47, .40, .46, .15),
  };

  static const _empty = _RoomSceneLayout(_slots);
  // Preserve the legacy tabletop slot on Casa clara's architectural sill.
  static const _casaClara = _RoomSceneLayout({
    ..._slots,
    RoomSlot.tabletop: Rect.fromLTWH(.57, .29, .08, .04),
  });

  static _RoomSceneLayout of(String roomId) =>
      roomId == RoomThemes.casaClaraId ? _casaClara : _empty;
}

/// A placed decoration, set down the way its surface holds it.
///
/// Things that stand — on the floor or a table — sit on the bottom of their
/// box, so one narrower than its box does not float above the floor line.
/// Things that hang or lie are centred.
class _RoomItemImage extends StatelessWidget {
  const _RoomItemImage({required this.asset, required this.slot});

  final String asset;
  final RoomSlot slot;

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      asset,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.none,
      alignment: switch (slot.surface) {
        RoomSurface.floor || RoomSurface.tabletop => Alignment.bottomCenter,
        RoomSurface.wall || RoomSurface.rug => Alignment.center,
      },
      excludeFromSemantics: true,
    );
    return asset == RoomDecorAssets.lamp
        ? ClipRect(clipper: const _LampBaseClipper(), child: image)
        : image;
  }
}

/// The sprite's grey shadow was painted for a light floor. It looks like a
/// separate plinth on wood, so keep the lamp's navy base outline instead.
class _LampBaseClipper extends CustomClipper<Rect> {
  const _LampBaseClipper();

  @override
  Rect getClip(Size size) =>
      Rect.fromLTWH(0, 0, size.width, size.height * .861);

  @override
  bool shouldReclip(_LampBaseClipper oldClipper) => false;
}

/// A quiet ambient loop. The screen changes by itself while the room is
/// visible; the furniture, placement, and decoration controls never move.
class _AnimatedTvSprite extends StatefulWidget {
  const _AnimatedTvSprite({required this.animate});

  final bool animate;

  @override
  State<_AnimatedTvSprite> createState() => _AnimatedTvSpriteState();
}

class _AnimatedTvSpriteState extends State<_AnimatedTvSprite>
    with WidgetsBindingObserver {
  static const _frames = <(String, Duration)>[
    (RoomDecorAssets.launchTv, Duration(milliseconds: 3500)),
    (RoomDecorAssets.launchTvBlink, Duration(milliseconds: 160)),
    (RoomDecorAssets.launchTv, Duration(seconds: 6)),
    (RoomDecorAssets.launchTvBlink, Duration(milliseconds: 160)),
    (RoomDecorAssets.launchTv, Duration(seconds: 12)),
    (RoomDecorAssets.launchTvBase, Duration(milliseconds: 150)),
    (RoomDecorAssets.launchTvSoccer, Duration(milliseconds: 1500)),
    (RoomDecorAssets.launchTvSoccerAlt, Duration(milliseconds: 1500)),
    (RoomDecorAssets.launchTvSoccer, Duration(milliseconds: 1500)),
    (RoomDecorAssets.launchTvSoccerAlt, Duration(milliseconds: 1500)),
    (RoomDecorAssets.launchTvSoccer, Duration(milliseconds: 1500)),
    (RoomDecorAssets.launchTvSoccerAlt, Duration(milliseconds: 1500)),
    (RoomDecorAssets.launchTvSoccer, Duration(milliseconds: 1500)),
    (RoomDecorAssets.launchTvSoccerAlt, Duration(milliseconds: 1500)),
    (RoomDecorAssets.launchTvSoccer, Duration(milliseconds: 1500)),
    (RoomDecorAssets.launchTvSoccerAlt, Duration(milliseconds: 1500)),
    (RoomDecorAssets.launchTvSoccer, Duration(milliseconds: 1500)),
    (RoomDecorAssets.launchTvSoccerAlt, Duration(milliseconds: 1500)),
    (RoomDecorAssets.launchTvSoccer, Duration(milliseconds: 1500)),
    (RoomDecorAssets.launchTvSoccerAlt, Duration(milliseconds: 1500)),
    (RoomDecorAssets.launchTvBase, Duration(milliseconds: 150)),
  ];

  Timer? _timer;
  int _frame = 0;
  bool _inForeground = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.animate) _schedule();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final foreground = state == AppLifecycleState.resumed;
    if (_inForeground == foreground) return;
    _inForeground = foreground;
    _timer?.cancel();
    if (foreground && widget.animate) {
      setState(() => _frame = 0);
      _schedule();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    for (final (asset, _) in _frames) {
      precacheImage(AssetImage(asset), context);
    }
  }

  @override
  void didUpdateWidget(covariant _AnimatedTvSprite oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animate == widget.animate) return;
    _timer?.cancel();
    _frame = 0;
    if (widget.animate && _inForeground) _schedule();
  }

  void _schedule() {
    _timer = Timer(_frames[_frame].$2, () {
      if (!mounted || !widget.animate || !_inForeground) return;
      setState(() => _frame = (_frame + 1) % _frames.length);
      _schedule();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Image.asset(
    widget.animate ? _frames[_frame].$1 : RoomDecorAssets.launchTv,
    fit: BoxFit.contain,
    filterQuality: FilterQuality.none,
    alignment: Alignment.bottomCenter,
    gaplessPlayback: true,
    excludeFromSemantics: true,
  );
}

/// One place the selected item can go.
///
/// Shows the item there, faint and at its real size, so the choice is between
/// two pictures of the room rather than two empty boxes. The place already
/// holding the item shows the real thing with a remove mark instead: tapping
/// it takes the item out.
class _RoomSlotTarget extends StatelessWidget {
  const _RoomSlotTarget({
    required this.slot,
    required this.number,
    required this.supportLabel,
    required this.frame,
    required this.ghostFrame,
    required this.holdsSelection,
    required this.ghostAsset,
    required this.onTap,
  });

  final RoomSlot slot;
  final int number;
  final String? supportLabel;
  final Rect frame;

  /// Where the item would be drawn, in the scene's coordinates like [frame].
  final Rect ghostFrame;
  final bool holdsSelection;
  final String? ghostAsset;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final surface =
        supportLabel ??
        switch (slot.surface) {
          RoomSurface.wall => l10n.roomSurfaceWall,
          RoomSurface.floor => l10n.roomSurfaceFloor,
          RoomSurface.tabletop => l10n.roomSurfaceTabletop,
          RoomSurface.rug => l10n.roomSurfaceRug,
        };
    final markSize = math.min(frame.width * .3, 22.0);
    return Positioned.fromRect(
      rect: frame,
      child: Semantics(
        button: true,
        selected: holdsSelection,
        label: l10n.roomSlotLabel(surface, number),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Stack(
            fit: StackFit.expand,
            clipBehavior: Clip.none,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: holdsSelection
                      ? Colors.transparent
                      : AppColors.tealSoft.withValues(alpha: .5),
                  border: Border.all(color: AppColors.teal, width: 3),
                ),
              ),
              if (!holdsSelection && ghostAsset != null)
                Positioned.fromRect(
                  rect: ghostFrame.shift(-frame.topLeft),
                  child: Opacity(
                    opacity: .55,
                    child: _RoomItemImage(asset: ghostAsset!, slot: slot),
                  ),
                ),
              if (holdsSelection)
                Positioned(
                  top: -markSize / 2,
                  right: -markSize / 2,
                  width: markSize,
                  height: markSize,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.teal,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.ink, width: 2),
                    ),
                    child: Icon(
                      Icons.close,
                      color: Colors.white,
                      size: markSize * .7,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoomSpeech extends StatelessWidget {
  const _RoomSpeech({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: const _RoomSpeechPainter(),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 13, 22),
      child: Text(
        message,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: pixelText(size: 13, bold: true, height: 1.2),
      ),
    ),
  );
}

class _RoomSpeechPainter extends CustomPainter {
  const _RoomSpeechPainter();

  Path _bubblePath(Size size) {
    const strokeWidth = 2.5;
    const shadowOffset = 3.0;
    const tailHeight = 11.0;
    const tailWidth = 14.0;
    const inset = strokeWidth / 2;
    final right = size.width - shadowOffset - inset;
    final bottom = size.height - tailHeight - shadowOffset - inset;
    final tailCenter = (inset + right) / 2;

    return Path()
      ..moveTo(inset, inset)
      ..lineTo(right, inset)
      ..lineTo(right, bottom)
      ..lineTo(tailCenter + tailWidth / 2, bottom)
      ..lineTo(tailCenter, bottom + tailHeight)
      ..lineTo(tailCenter - tailWidth / 2, bottom)
      ..lineTo(inset, bottom)
      ..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final path = _bubblePath(size);
    const shadowOffset = Offset(3, 3);
    final shadow = Paint()
      ..color = AppColors.ink
      ..style = PaintingStyle.fill
      ..isAntiAlias = false;
    final fill = Paint()
      ..color = AppColors.surface
      ..style = PaintingStyle.fill
      ..isAntiAlias = false;
    final border = Paint()
      ..color = AppColors.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeJoin = StrokeJoin.miter
      ..isAntiAlias = false;
    canvas
      ..drawPath(path.shift(shadowOffset), shadow)
      ..drawPath(path, fill)
      ..drawPath(path, border);
  }

  @override
  bool shouldRepaint(covariant _RoomSpeechPainter oldDelegate) => false;
}
