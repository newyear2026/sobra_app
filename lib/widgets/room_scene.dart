import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/room_design.dart';
import '../state/sobra_store.dart';
import '../theme/app_theme.dart';
import 'cat_sprite.dart';

enum RoomSceneVariant { preview, immersive }

/// Composes a hybrid room from a fixed theme, four replaceable slots and the
/// character layer. Nothing about a slot is tied to Casa clara's pixels, so a
/// later theme can supply a new background and anchor map without changing
/// the saved decoration choices.
class RoomScene extends StatelessWidget {
  const RoomScene({
    super.key,
    required this.variant,
    required this.placements,
    required this.message,
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
  final String? backgroundAsset;
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

  String get _asset =>
      backgroundAsset ??
      (variant == RoomSceneVariant.preview
          ? RoomThemes.casaClaraPreviewAsset
          : RoomThemes.casaClaraPortraitAsset);

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.biggest;
          final layout = _RoomSceneLayout.forVariant(variant);
          final selectedSlot = selectedItemId == null
              ? null
              : RoomDecorAssets.slotForItemId(selectedItemId!);
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
              for (final slot in RoomSlot.values)
                if (placements[slot] case final itemId?)
                  if (RoomDecorAssets.assetFor(itemId) case final asset?)
                    _RelativePositioned(
                      rect: layout.slotRects[slot]!,
                      size: size,
                      child: Image.asset(
                        asset,
                        fit: BoxFit.contain,
                        excludeFromSemantics: true,
                      ),
                    ),
              if (showSlots)
                for (final slot in RoomSlot.values)
                  _RoomSlotTarget(
                    slot: slot,
                    rect: layout.slotRects[slot]!,
                    size: size,
                    occupied: placements.containsKey(slot),
                    selected: selectedSlot == slot,
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

class _RoomSceneLayout {
  const _RoomSceneLayout({
    required this.slotRects,
    required this.speechRect,
    required this.catTop,
    required this.catWidth,
  });

  final Map<RoomSlot, Rect> slotRects;
  final Rect speechRect;
  final double catTop;
  final double catWidth;

  static const preview = _RoomSceneLayout(
    slotRects: {
      RoomSlot.rug: Rect.fromLTWH(.20, .73, .62, .24),
      RoomSlot.floorRight: Rect.fromLTWH(.69, .49, .15, .42),
      RoomSlot.wallCenter: Rect.fromLTWH(.32, .11, .13, .28),
      RoomSlot.tabletop: Rect.fromLTWH(.18, .49, .08, .20),
    },
    speechRect: Rect.fromLTWH(.31, .17, .38, .26),
    catTop: .47,
    catWidth: .22,
  );

  static const immersive = _RoomSceneLayout(
    slotRects: {
      RoomSlot.rug: Rect.fromLTWH(.05, .67, .90, .14),
      RoomSlot.floorRight: Rect.fromLTWH(.69, .54, .20, .25),
      RoomSlot.wallCenter: Rect.fromLTWH(.74, .20, .15, .16),
      RoomSlot.tabletop: Rect.fromLTWH(.27, .37, .12, .13),
    },
    speechRect: Rect.fromLTWH(.25, .48, .50, .14),
    catTop: .56,
    catWidth: .30,
  );

  static _RoomSceneLayout forVariant(RoomSceneVariant variant) =>
      variant == RoomSceneVariant.preview ? preview : immersive;
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

class _RoomSlotTarget extends StatelessWidget {
  const _RoomSlotTarget({
    required this.slot,
    required this.rect,
    required this.size,
    required this.occupied,
    required this.selected,
    required this.onTap,
  });

  final RoomSlot slot;
  final Rect rect;
  final Size size;
  final bool occupied;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final label = switch (slot) {
      RoomSlot.rug => l10n.roomDefaultRug,
      RoomSlot.floorRight => l10n.roomFloorLamp,
      RoomSlot.wallCenter => l10n.roomWallFrame,
      RoomSlot.tabletop => l10n.roomTablePlant,
    };
    return _RelativePositioned(
      rect: rect,
      size: size,
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.tealSoft.withValues(alpha: .58)
                  : Colors.transparent,
              border: occupied && !selected
                  ? null
                  : Border.all(
                      color: selected ? AppColors.teal : AppColors.muted,
                      width: selected ? 3 : 2,
                    ),
            ),
            child: !occupied
                ? Center(
                    child: Icon(
                      Icons.add,
                      color: selected ? AppColors.tealInk : AppColors.muted,
                      size: math.min(rect.width * size.width * .55, 30),
                    ),
                  )
                : null,
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
