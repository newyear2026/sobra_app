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
          final background = _coverRect(size, imageSize.aspectRatio);
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
            final height = stageHeight * stageScale;
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
              Image.asset(
                _asset,
                fit: BoxFit.cover,
                excludeFromSemantics: true,
                errorBuilder: (_, _, _) =>
                    const ColoredBox(color: AppColors.paperLight),
              ),
              for (final item in placed)
                Positioned.fromRect(
                  rect: item.frame,
                  child: _RoomItemImage(asset: item.asset, slot: item.slot),
                ),
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
            ],
          );
        },
      ),
    );
  }
}

/// Where a [BoxFit.cover] image of [aspectRatio] lands in [size], centred.
///
/// Slots are placed on this rather than on the widget, so a decoration stays
/// on its patch of wall however the screen's shape crops the background.
Rect _coverRect(Size size, double aspectRatio) {
  if (size.width / size.height > aspectRatio) {
    final height = size.width / aspectRatio;
    return Rect.fromLTWH(0, (size.height - height) / 2, size.width, height);
  }
  final width = size.height * aspectRatio;
  return Rect.fromLTWH((size.width - width) / 2, 0, width, size.height);
}

class _RoomSceneLayout {
  const _RoomSceneLayout({
    required this.slotRects,
    required this.speechRect,
    required this.catTop,
    required this.catWidth,
  });

  /// Fractions of the background image, not of the widget — except the
  /// rug's, which is the character's mat and follows the character, whose
  /// place is a fraction of the widget.
  final Map<RoomSlot, Rect> slotRects;

  /// The speech bubble and character are fractions of the widget.
  final Rect speechRect;
  final double catTop;
  final double catWidth;

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
    },
    speechRect: Rect.fromLTWH(.31, .17, .38, .26),
    catTop: .47,
    catWidth: .22,
  );

  // The new 3:2 preview art is cover-cropped into the same 2:1 Home card.
  // Convert Casa clara's visible slot positions into the taller source image
  // so the rug and decorations still land on the same part of the stage.
  static const _emptyThemePreview = _RoomSceneLayout(
    slotRects: {
      RoomSlot.rug: Rect.fromLTWH(.20, .73, .62, .24),
      RoomSlot.wallLeft: Rect.fromLTWH(.19, .2225, .11, .18),
      RoomSlot.wallCenter: Rect.fromLTWH(.32, .2075, .13, .21),
      RoomSlot.floorLeft: Rect.fromLTWH(.03, .575, .12, .27),
      RoomSlot.floorRight: Rect.fromLTWH(.69, .4925, .15, .315),
    },
    speechRect: Rect.fromLTWH(.31, .17, .38, .26),
    catTop: .47,
    catWidth: .22,
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
    },
    speechRect: Rect.fromLTWH(.25, .48, .50, .14),
    catTop: .56,
    catWidth: .30,
  );

  static const _byRoom = {
    RoomThemes.casaClaraId: (
      preview: _casaClaraPreview,
      immersive: _casaClaraImmersive,
    ),
    RoomThemes.casaJardinId: (
      preview: _emptyThemePreview,
      immersive: _casaClaraImmersive,
    ),
    RoomThemes.casaDePlayaId: (
      preview: _emptyThemePreview,
      immersive: _casaClaraImmersive,
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
