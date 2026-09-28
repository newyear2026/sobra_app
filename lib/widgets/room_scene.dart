import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/room_design.dart';
import '../state/sobra_store.dart';
import '../theme/app_theme.dart';
import 'cat_sprite.dart';

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
    this.showSlots = false,
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

  /// Lights the places [selectedItemId] can go, and only those.
  ///
  /// With nothing selected no place is lit: an empty outline everywhere read
  /// as "anything goes anywhere", and a lamp offered a spot on the wall.
  final bool showSlots;
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
          final layout = _RoomSceneLayout.of(room.id, variant);
          final selected = selectedItemId;
          final selectedAsset = selected == null
              ? null
              : RoomDecorAssets.assetFor(selected);
          final targets = showSlots && selected != null
              ? room.slotsForItem(selected)
              : const <RoomSlot>[];
          final imageSize = variant == RoomSceneVariant.preview
              ? room.previewSize
              : room.portraitSize;
          final background = _coverRect(
            size,
            imageSize.aspectRatio,
            floorFocus: layout.floorFocus,
          );
          final stageScale = background.height / imageSize.height;
          Rect slotFrame(RoomSlot slot) {
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

          /// Where [itemId] is drawn in [slot]: its own stage height, standing
          /// on the slot's bottom edge or hung on its centre. The box is wider
          /// than any item so the image keeps its own shape inside it.
          Rect itemFrame(RoomSlot slot, String itemId) {
            final spot = slotFrame(slot);
            final stageHeight = RoomDecorAssets.stageHeightFor(itemId);
            if (stageHeight == null) return spot;
            // The same object grows gently as its floor contact moves toward
            // the viewer. Wall and tabletop decorations keep a fixed scale.
            final depth = slot.surface == RoomSurface.floor
                ? (layout.slotRects[slot]!.bottom - layout.floorLine).clamp(
                    0.0,
                    .45,
                  )
                : 0.0;
            final height =
                stageHeight * stageScale * layout.itemScale * (1 + depth * .6);
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
          }

          // The rug lies under everything; the rest overlap by where they
          // stand, so something lower on screen — nearer the viewer — is
          // drawn over what stands behind it.
          final placed =
              [
                for (final slot in room.slots)
                  if (placements[slot] case final itemId?)
                    if (RoomDecorAssets.assetFor(itemId) case final asset?)
                      (
                        slot: slot,
                        asset: asset,
                        frame: itemFrame(slot, itemId),
                      ),
              ]..sort((a, b) {
                if (a.slot.surface == RoomSurface.rug) return -1;
                if (b.slot.surface == RoomSurface.rug) return 1;
                return a.frame.bottom.compareTo(b.frame.bottom);
              });

          final catWidth = size.width * layout.catWidth;
          final catHeight =
              catWidth *
              CharacterAnimationStandard.frameHeight /
              CharacterAnimationStandard.frameWidth;

          return Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fromRect(
                rect: background,
                child: Image.asset(
                  _asset,
                  fit: BoxFit.fill,
                  excludeFromSemantics: true,
                  errorBuilder: (_, _, _) =>
                      const ColoredBox(color: AppColors.paperLight),
                ),
              ),
              for (final item in placed)
                Positioned.fromRect(
                  rect: item.frame,
                  child: _RoomItemImage(asset: item.asset, slot: item.slot),
                ),
              Positioned(
                left: (size.width - catWidth) / 2,
                top: size.height * layout.catTop,
                width: catWidth,
                height: catHeight,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onCatTap,
                  child: Semantics(
                    button: onCatTap != null,
                    child: CatSprite(
                      motion: reacting
                          ? CatMotion.celebrate
                          : catMotion ?? CatMotion.idle,
                      characterId: characterId,
                      width: catWidth,
                      animate: !reducedMotionOf(context),
                      loop: reacting ? false : catLoop,
                      onComplete: reacting ? onReactionComplete : null,
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
                  number: room.slotsFor(slot.surface).indexOf(slot) + 1,
                  frame: slotFrame(slot),
                  ghostFrame: itemFrame(slot, selected!),
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

  // Floor and tabletop rects end where the thing stands: the item is drawn
  // on the rect's bottom edge, so moving a rect's bottom moves the floor line.
  static const _casaClaraPreview = _RoomSceneLayout(
    slotRects: {
      RoomSlot.rug: Rect.fromLTWH(.20, .73, .62, .24),
      RoomSlot.wallLeft: Rect.fromLTWH(.19, .13, .11, .24),
      RoomSlot.wallCenter: Rect.fromLTWH(.32, .11, .13, .28),
      RoomSlot.tabletop: Rect.fromLTWH(.18, .462, .08, .20),
      RoomSlot.floorLeft: Rect.fromLTWH(.03, .60, .12, .36),
      RoomSlot.floorRight: Rect.fromLTWH(.69, .49, .15, .42),
      RoomSlot.floorCenter: Rect.fromLTWH(.22, .67, .25, .20),
      RoomSlot.floorAccent: Rect.fromLTWH(.60, .67, .09, .15),
      RoomSlot.floorCabinet: Rect.fromLTWH(.23, .60, .16, .28),
    },
    speechRect: Rect.fromLTWH(.31, .17, .38, .26),
    catTop: .47,
    catWidth: .22,
    floorLine: .72,
  );

  // The 3:2 preview art is cropped into a 2:1 Home card. Its window and
  // baseboard are closer together than in the portrait art. Place items by
  // those landmarks so they retain their height on the wall and their depth
  // on the floor when the user opens the same room. The aligned preview art
  // also puts the window at the portrait's horizontal position.
  static const _emptyThemePreview = _RoomSceneLayout(
    slotRects: {
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
    },
    speechRect: Rect.fromLTWH(.21, .27, .38, .26),
    catTop: .47,
    catWidth: .22,
    floorLine: .675,
    itemScale: .82,
  );

  // The home card is the preview image's own 2:1 shape, so nothing is
  // cropped and these read the same on the card as on the image. The
  // portrait image is always cropped; its rects were measured on a phone
  // whose room area is 1000x775.
  static const _casaClaraImmersive = _RoomSceneLayout(
    slotRects: {
      RoomSlot.rug: Rect.fromLTWH(.05, .67, .90, .14),
      RoomSlot.wallLeft: Rect.fromLTWH(.146, .273, .146, .083),
      RoomSlot.wallCenter: Rect.fromLTWH(.74, .345, .15, .083),
      RoomSlot.tabletop: Rect.fromLTWH(.27, .433, .12, .067),
      RoomSlot.floorLeft: Rect.fromLTWH(.05, .536, .18, .119),
      RoomSlot.floorRight: Rect.fromLTWH(.69, .521, .20, .129),
      RoomSlot.floorCenter: Rect.fromLTWH(.20, .515, .28, .17),
      RoomSlot.floorAccent: Rect.fromLTWH(.60, .525, .09, .11),
      RoomSlot.floorCabinet: Rect.fromLTWH(.18, .50, .24, .16),
    },
    speechRect: Rect.fromLTWH(.25, .48, .50, .14),
    catTop: .56,
    catWidth: .30,
    floorLine: _stageFloorLine,
    floorFocus: _immersiveFloorFocus,
  );

  // An empty room has nothing painted in to step around, so furniture stands
  // back against the wall, where the stage is about 300 px to the metre and
  // an item drawn at its real size also looks it. On Casa clara's rects it
  // stood mid-floor, nearer the viewer yet smaller than the painted armchair
  // behind it. Wall slots hang at about 1.5 m, above a 1.45 m floor lamp, so
  // nothing on the wall sits on what stands under it.
  static const _emptyThemeImmersive = _RoomSceneLayout(
    slotRects: {
      RoomSlot.rug: Rect.fromLTWH(.05, .67, .90, .14),
      RoomSlot.wallLeft: Rect.fromLTWH(.15, .185, .14, .066),
      RoomSlot.wallCenter: Rect.fromLTWH(.76, .185, .14, .066),
      RoomSlot.floorLeft: Rect.fromLTWH(.07, .40, .24, .147),
      RoomSlot.floorRight: Rect.fromLTWH(.72, .40, .18, .147),
      RoomSlot.floorCenter: Rect.fromLTWH(.20, .50, .28, .18),
      RoomSlot.floorAccent: Rect.fromLTWH(.63, .45, .08, .15),
      RoomSlot.floorCabinet: Rect.fromLTWH(.14, .40, .24, .15),
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
    required this.frame,
    required this.ghostFrame,
    required this.holdsSelection,
    required this.ghostAsset,
    required this.onTap,
  });

  final RoomSlot slot;
  final int number;
  final Rect frame;

  /// Where the item would be drawn, in the scene's coordinates like [frame].
  final Rect ghostFrame;
  final bool holdsSelection;
  final String? ghostAsset;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final surface = switch (slot.surface) {
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
