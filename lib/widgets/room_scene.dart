import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/room_design.dart';
import '../models/room_time_of_day.dart';
import '../state/sobra_store.dart';
import '../theme/app_theme.dart';
import 'cat_sprite.dart';
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

  /// Time-of-day art is available in the immersive version of every room.
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

  String get _asset =>
      backgroundAsset ??
      (variant == RoomSceneVariant.preview
          ? _room.previewAsset
          : _room.portraitAsset);

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.biggest;
          final room = _room;
          // These scenes paint their own full-width window light. The shared
          // small-window rays and mask would cross their glass and frames.
          final usesPaintedLight =
              room.id == RoomThemes.casaTorreId ||
              room.id == RoomThemes.casaMontanaId ||
              room.id == RoomThemes.casaInvernaderoId;
          final isPanoramic = usesPaintedLight;
          final roomPhase = variant == RoomSceneVariant.immersive
              ? timeOfDay
              : null;
          final assetDirectory = room.portraitAsset.substring(
            0,
            room.portraitAsset.lastIndexOf('/'),
          );
          final sceneAsset =
              backgroundAsset ??
              switch (roomPhase) {
                RoomTimeOfDay.dawn || RoomTimeOfDay.sunset =>
                  '$assetDirectory/background_portrait_sunset_unlit.png',
                RoomTimeOfDay.night =>
                  '$assetDirectory/background_portrait_night_unlit.png',
                RoomTimeOfDay.day =>
                  '$assetDirectory/background_portrait_unlit.png',
                null => _asset,
              };
          final layout = _RoomSceneLayout.of(room.id, variant);
          final selected = selectedItemId;
          final selectedAsset = selected == null
              ? null
              : RoomDecorAssets.assetFor(selected);
          final targets = showSlots && selected != null
              ? room.slotsForItem(selected, placements: placements)
              : const <RoomSlot>[];
          final imageSize = variant == RoomSceneVariant.preview
              ? room.previewSize
              : room.portraitSize;
          final background = _coverRect(
            size,
            imageSize.aspectRatio,
            floorFocus: layout.floorFocus == null
                ? null
                : math.min(
                    layout.floorFocus!,
                    .52 + .1 * size.height / size.width,
                  ),
          );
          final stageScale = background.height / imageSize.height;
          final catAspect =
              CharacterAnimationStandard.frameHeight /
              CharacterAnimationStandard.frameWidth;
          final catWidth = math.min(
            size.width * layout.catWidth,
            size.height * (.96 - layout.catTop) / catAspect,
          );
          final catHeight = catWidth * catAspect;
          final catFrame = Rect.fromLTWH(
            (size.width - catWidth) / 2,
            size.height * layout.catTop,
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
                // The jar rests inside the open middle shelf; the plant
                // stands on the top board. Both are separate movable sprites.
                final bottom =
                    cabinet.top +
                    height * (slot == RoomSlot.cabinetTop ? .69 : .20);
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
              return Rect.fromLTWH(
                table.center.dx - height * .28,
                table.top + height * .29,
                height * .56,
                height * .18,
              );
            }
            final rect = layout.slotRects[slot]!;
            final frame = slot.surface == RoomSurface.rug
                ? Offset.zero & size
                : background;
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
            final preview = variant == RoomSceneVariant.preview;
            final wallSpan = preview ? .535 : .434;
            Rect at(double x, double depth) {
              final bottom = layout.floorLine + depth * wallSpan;
              return Rect.fromLTWH(
                background.left + (x - .08) * background.width,
                background.top + bottom * background.height - spot.height,
                background.width * .16,
                spot.height,
              );
            }

            if (slot == RoomSlot.rug) {
              // The rug follows the paws in every crop, including the short
              // decorator, instead of staying behind the character.
              final height = catWidth * 2.15 / 3;
              final bodyBottom = itemId == RoomDecorAssets.blueCreamRugId
                  ? 592 / 724
                  : 511 / 724;
              final top = math.min(
                catPaws - height * .53,
                size.height - 4 - height * bodyBottom,
              );
              return Rect.fromLTWH(
                catFrame.center.dx - height * 1.5,
                top,
                height * 3,
                height,
              );
            }
            if (itemId == RoomDecorAssets.petBedId) {
              return Rect.fromLTWH(
                catFrame.center.dx - catWidth * .85 - spot.width / 2,
                catPaws - catWidth * .15 - spot.height,
                spot.width,
                spot.height,
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
            if (slot == RoomSlot.floorCabinet &&
                itemId == RoomDecorAssets.slimBookcaseId) {
              return at(isPanoramic ? .15 : .18, .09);
            }
            if (slot == RoomSlot.floorLeft && hasCabinet) {
              final bookcase = cabinetId == RoomDecorAssets.slimBookcaseId;
              if (RoomDecorAssets.isFloorLamp(itemId)) {
                return at(bookcase ? .33 : .06, .09);
              }
              if (itemId == RoomDecorAssets.rattanChairId) {
                return at(bookcase ? .32 : .13, .36);
              }
            }
            if (slot == RoomSlot.floorRight) {
              if (hasSofa) {
                return switch (itemId) {
                  RoomDecorAssets.rattanChairId => at(.84, .34),
                  RoomDecorAssets.roundSideTableId => at(.82, .28),
                  RoomDecorAssets.terracottaPoufId => at(.82, .30),
                  RoomDecorAssets.floorLampId ||
                  RoomDecorAssets.bronzeLanternLampId => at(.94, .09),
                  _ => spot,
                };
              }
              if (hasLeftChair) {
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
            // the viewer. Wall and tabletop decorations keep a fixed scale.
            final depth = slot.surface == RoomSurface.floor
                ? ((spot.bottom - background.top) / background.height -
                          layout.floorLine)
                      .clamp(0.0, .45)
                : 0.0;
            var height =
                stageHeight * stageScale * layout.itemScale * (1 + depth * .6);
            final body = _floorSpriteBody(itemId);
            if (slot.surface == RoomSurface.floor && body != null) {
              final padding = size.width * .025;
              height = math.min(
                height,
                (size.height - padding * 2) / body.height,
              );
              height = math.min(
                height,
                (size.width - padding * 2) / body.width,
              );
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
              final dy = visible.bottom > size.height - padding
                  ? size.height - padding - visible.bottom
                  : visible.top < padding
                  ? padding - visible.top
                  : 0.0;
              frame = frame.shift(Offset(dx, dy));
              return frame;
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
                    a.slot == RoomSlot.sideTableTop;
                final atopB =
                    b.slot == RoomSlot.cabinetTop ||
                    b.slot == RoomSlot.cabinetTopRight ||
                    b.slot == RoomSlot.sideTableTop;
                if (atopA != atopB) return atopA ? 1 : -1;
                return a.frame.bottom.compareTo(b.frame.bottom);
              });

          final sceneCharacterId =
              characterId ??
              SobraScope.maybeOf(context)?.characterId ??
              CharacterCatalog.defaultId;
          final roomDisplayScale = CharacterCatalog.resolve(
            sceneCharacterId,
          ).roomDisplayScale;

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

          return Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fromRect(
                rect: background,
                child: Image.asset(
                  sceneAsset,
                  fit: BoxFit.fill,
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
                                (ModalRoute.isCurrentOf(context) ?? true) &&
                                !reducedMotionOf(context),
                          )
                        : _RoomItemImage(asset: item.asset, slot: item.slot),
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
                          motion: reacting
                              ? CatMotion.celebrate
                              : catMotion ?? CatMotion.idle,
                          characterId: sceneCharacterId,
                          width: catWidth,
                          animate: !reducedMotionOf(context),
                          loop: reacting ? false : catLoop,
                          onComplete: reacting ? onReactionComplete : null,
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
              _RelativePositioned(
                rect: layout.speechRect,
                size: size,
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
                    _ => null,
                  },
                  frame: targetFrame(slot, selected!),
                  ghostFrame: itemFrame(slot, selected),
                  holdsSelection: placements[slot] == selected,
                  ghostAsset: selectedAsset,
                  onTap: onSlotTap == null ? null : () => onSlotTap!(slot),
                ),
            ],
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

/// Where a [BoxFit.cover] image of [aspectRatio] lands in [size].
///
/// Slots are placed on this rather than on the widget, so a decoration stays
/// on its patch of wall however the screen's shape crops the background.
///
/// Centred, unless [floorFocus] names where the stage's floor line should
/// sit, as a fraction of [size]'s height, when the image is cropped top and
/// bottom. Decorate is wide and short: centred, it cut the wall off above the
/// window sill, and a clock hung where Mi casa shows it low on the wall was
/// pushed against the top edge.
Rect _coverRect(Size size, double aspectRatio, {double? floorFocus}) {
  if (size.width / size.height > aspectRatio) {
    final height = size.width / aspectRatio;
    final top = floorFocus == null
        ? (size.height - height) / 2
        : (floorFocus * size.height - _stageFloorLine * height).clamp(
            size.height - height,
            0.0,
          );
    return Rect.fromLTWH(0, top, size.width, height);
  }
  final width = size.height * aspectRatio;
  return Rect.fromLTWH((size.width - width) / 2, 0, width, size.height);
}

/// Where the floor meets the wall on the shared stage, as a fraction of the
/// portrait image's height; see `docs/hybrid-room-theme-guide.md`.
const _stageFloorLine = 782 / 1536;

/// Decorate keeps the floor line two thirds of the way down: the wall up to
/// about 1.7 m stays in view, and the character still has floor to sit on.
const _immersiveFloorFocus = .66;

class _RoomSceneLayout {
  const _RoomSceneLayout({
    required this.slotRects,
    required this.speechRect,
    required this.catTop,
    required this.catWidth,
    required this.floorLine,
    this.itemScale = 1,
    this.floorFocus,
  });

  /// Fractions of the background image, not of the widget — except the
  /// rug's, which is the character's mat and follows the character, whose
  /// place is a fraction of the widget.
  final Map<RoomSlot, Rect> slotRects;

  /// The speech bubble and character are fractions of the widget.
  final Rect speechRect;
  final double catTop;
  final double catWidth;
  final double floorLine;

  /// The wide empty-room paintings compress the wall vertically compared
  /// with their portrait paintings. Keep decor the same size relative to
  /// the window and baseboard in both views.
  final double itemScale;

  /// See [_coverRect]; null centres the background.
  final double? floorFocus;

  // The 3:2 preview art is cropped into a 2:1 Home card. Its window and
  // baseboard are closer together than in the portrait art. Place items by
  // those landmarks so they retain their height on the wall and their depth
  // on the floor when the user opens the same room. The aligned preview art
  // also puts the window at the portrait's horizontal position.
  static const _emptyThemePreviewSlots = <RoomSlot, Rect>{
    RoomSlot.rug: Rect.fromLTWH(.20, .73, .62, .24),
    RoomSlot.wallLeft: Rect.fromLTWH(.17, .275, .10, .08),
    RoomSlot.wallCenter: Rect.fromLTWH(.78, .275, .10, .08),
    RoomSlot.floorLeft: Rect.fromLTWH(.11, .55, .16, .17),
    RoomSlot.floorRight: Rect.fromLTWH(.74, .55, .14, .17),
    // The Home card has much less visible floor than the portrait scene.
    // Keep the pet bed behind the character's feet in this crop.
    RoomSlot.floorCenter: Rect.fromLTWH(.255, .57, .25, .20),
    RoomSlot.floorAccent: Rect.fromLTWH(.64, .65, .08, .136),
    RoomSlot.floorCabinet: Rect.fromLTWH(.17, .505, .18, .22),
    RoomSlot.floorSofa: Rect.fromLTWH(.56, .505, .36, .22),
  };

  static const _emptyThemePreview = _RoomSceneLayout(
    slotRects: _emptyThemePreviewSlots,
    speechRect: Rect.fromLTWH(.21, .27, .38, .26),
    catTop: .47,
    catWidth: .22,
    floorLine: .675,
    itemScale: .82,
  );

  // An empty room has nothing painted in to step around, so furniture stands
  // back against the wall. Wall slots hang clear of a floor lamp's shade.
  static const _emptyThemeImmersiveSlots = <RoomSlot, Rect>{
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

  static const _emptyThemeImmersive = _RoomSceneLayout(
    slotRects: _emptyThemeImmersiveSlots,
    speechRect: Rect.fromLTWH(.25, .48, .50, .14),
    catTop: .56,
    catWidth: .30,
    floorLine: _stageFloorLine,
    floorFocus: _immersiveFloorFocus,
  );

  // Casa clara now uses the same empty-room anchors. Its legacy tabletop
  // decoration remains placeable on the architectural window sill, so a saved
  // desk lamp or plant never floats where the painted side table used to be.
  static const _casaClaraPreview = _RoomSceneLayout(
    slotRects: {
      ..._emptyThemePreviewSlots,
      RoomSlot.tabletop: Rect.fromLTWH(.55, .42, .08, .04),
    },
    speechRect: Rect.fromLTWH(.21, .27, .38, .26),
    catTop: .47,
    catWidth: .22,
    floorLine: .675,
    itemScale: .82,
  );

  static const _casaClaraImmersive = _RoomSceneLayout(
    slotRects: {
      ..._emptyThemeImmersiveSlots,
      RoomSlot.tabletop: Rect.fromLTWH(.57, .29, .08, .04),
    },
    speechRect: Rect.fromLTWH(.25, .48, .50, .14),
    catTop: .56,
    catWidth: .30,
    floorLine: _stageFloorLine,
    floorFocus: _immersiveFloorFocus,
  );

  static const _byRoom = {
    RoomThemes.casaClaraId: (
      preview: _casaClaraPreview,
      immersive: _casaClaraImmersive,
    ),
    RoomThemes.casaJardinId: (
      preview: _emptyThemePreview,
      immersive: _emptyThemeImmersive,
    ),
    RoomThemes.casaDePlayaId: (
      preview: _emptyThemePreview,
      immersive: _emptyThemeImmersive,
    ),
    RoomThemes.casaTorreId: (
      preview: _emptyThemePreview,
      immersive: _emptyThemeImmersive,
    ),
    RoomThemes.casaMontanaId: (
      preview: _emptyThemePreview,
      immersive: _emptyThemeImmersive,
    ),
    RoomThemes.casaInvernaderoId: (
      preview: _emptyThemePreview,
      immersive: _emptyThemeImmersive,
    ),
  };

  static _RoomSceneLayout of(String roomId, RoomSceneVariant variant) {
    final layouts = _byRoom[roomId] ?? _byRoom[RoomThemes.casaClaraId]!;
    return variant == RoomSceneVariant.preview
        ? layouts.preview
        : layouts.immersive;
  }
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
  Widget build(BuildContext context) => Image.asset(
    asset,
    fit: BoxFit.contain,
    filterQuality: FilterQuality.none,
    alignment: switch (slot.surface) {
      RoomSurface.floor || RoomSurface.tabletop => Alignment.bottomCenter,
      RoomSurface.wall || RoomSurface.rug => Alignment.center,
    },
    excludeFromSemantics: true,
  );
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

class _RelativePositioned extends StatelessWidget {
  const _RelativePositioned({
    required this.rect,
    required this.size,
    required this.child,
  });

  final Rect rect;
  final Size size;
  final Widget child;

  @override
  Widget build(BuildContext context) => Positioned(
    left: rect.left * size.width,
    top: rect.top * size.height,
    width: rect.width * size.width,
    height: rect.height * size.height,
    child: child,
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
