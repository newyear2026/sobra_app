import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/room_design.dart';
import '../theme/app_theme.dart';
import 'pixel_ui.dart';

/// A responsive scene that keeps room art, copy and character animation in
/// separate layers.
///
/// Room assets never contain the character or UI text. That lets the same
/// scene host every motion and keeps speech readable at compact widths.
class CharacterRoom extends StatelessWidget {
  const CharacterRoom({
    super.key,
    required this.message,
    required this.characterBuilder,
    this.backgroundAsset = casaClaraBackgroundAsset,
  });

  static const casaClaraBackgroundAsset = RoomThemes.casaClaraPreviewAsset;
  static const backgroundKey = ValueKey('character-room-background');

  /// Widest the room is ever laid out: the shell caps its content at 520 and
  /// Inicio pads 20 a side.
  ///
  /// Decoding is sized from this rather than from the room's own constraints
  /// so the provider can be built — and warmed — before layout has run.
  static const double maxLogicalWidth = 480;

  /// The background's own pixel width. Decoding past it would only upscale.
  static const int backgroundNativeWidth = 1536;

  /// The background sized for this screen.
  ///
  /// The art is far larger than the card ever is, so decoding it whole costs
  /// about 6.3 MB for something that paints into at most 1440 px. Warm it through
  /// this method too: [ResizeImage] keys on the target width, so precaching
  /// the bare [AssetImage] would fill the cache with an entry nothing reads.
  static ImageProvider backgroundProvider(
    BuildContext context, {
    String asset = casaClaraBackgroundAsset,
  }) {
    final width =
        math.min(MediaQuery.sizeOf(context).width, maxLogicalWidth) *
        MediaQuery.devicePixelRatioOf(context);
    return ResizeImage.resizeIfNeeded(
      math.min(width.round(), backgroundNativeWidth),
      null,
      AssetImage(asset),
    );
  }

  final String message;
  final Widget Function(double width) characterBuilder;
  final String backgroundAsset;

  @override
  Widget build(BuildContext context) {
    return PixelCard(
      padding: EdgeInsets.zero,
      color: AppColors.paperLight,
      child: AspectRatio(
        aspectRatio: 2,
        child: ClipRect(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 380;
              final characterWidth = compact ? 84.0 : 112.0;
              // The character stands on the clear floor, and the speech sits directly
              // above rather than beside: stacked, a long message grows upward
              // into empty wall instead of squeezing against the card's edge.
              final bubbleWidth =
                  constraints.maxWidth * (compact ? 0.78 : 0.66);

              return Stack(
                fit: StackFit.expand,
                children: [
                  Image(
                    image: backgroundProvider(context, asset: backgroundAsset),
                    key: backgroundKey,
                    fit: BoxFit.cover,
                    // No filterQuality override: the art is drawn at 0.54x to
                    // 0.81x, and only the default `medium` carries mipmaps.
                    // `low` is a plain bilinear that aliases below half scale,
                    // and `none` would drop pixels out of an anti-aliased
                    // render rather than sharpen it.
                    excludeFromSemantics: true,
                    // The room is decoration. If the asset ever goes missing
                    // the scene should keep its shape and let the character
                    // and the speech carry the card, not blank out in release
                    // or paint an error box in debug.
                    errorBuilder: (context, error, stack) =>
                        const ColoredBox(color: AppColors.paperLight),
                  ),
                  Positioned.fill(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: compact ? 4 : 10),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Flexible so a three-line message shortens itself
                          // rather than pushing the character off the floor.
                          Flexible(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: bubbleWidth,
                              ),
                              child: _RoomSpeech(
                                message: message,
                                compact: compact,
                              ),
                            ),
                          ),
                          SizedBox(height: compact ? 2 : 4),
                          characterBuilder(characterWidth),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _RoomSpeech extends StatelessWidget {
  const _RoomSpeech({required this.message, required this.compact});

  final String message;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final tailWidth = compact ? 12.0 : 16.0;
    final tailHeight = compact ? 10.0 : 14.0;
    const shadowOffset = 3.0;

    return CustomPaint(
      painter: _PixelSpeechBubblePainter(
        tailWidth: tailWidth,
        tailHeight: tailHeight,
        shadowOffset: shadowOffset,
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          compact ? 8 : 12,
          compact ? 7 : 10,
          (compact ? 8 : 12) + shadowOffset,
          (compact ? 7 : 10) + tailHeight + shadowOffset,
        ),
        child: Text(
          message,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: pixelText(size: compact ? 12 : 14, bold: true, height: 1.25),
        ),
      ),
    );
  }
}

class _PixelSpeechBubblePainter extends CustomPainter {
  const _PixelSpeechBubblePainter({
    required this.tailWidth,
    required this.tailHeight,
    required this.shadowOffset,
  });

  final double tailWidth;
  final double tailHeight;
  final double shadowOffset;

  /// A rectangle with a tail hanging straight down from the middle.
  ///
  /// The speaker is centred underneath, so the tail points at them rather than
  /// across at them — and being centred, it stays pointing at the character
  /// whatever the message does to the bubble's width.
  Path _bubblePath(Size size) {
    const strokeWidth = 2.5;
    const inset = strokeWidth / 2;
    final right = size.width - shadowOffset - inset;
    final bottom = size.height - tailHeight - shadowOffset - inset;
    final tailCentre = (inset + right) / 2;

    return Path()
      ..moveTo(inset, inset)
      ..lineTo(right, inset)
      ..lineTo(right, bottom)
      ..lineTo(tailCentre + tailWidth / 2, bottom)
      ..lineTo(tailCentre, bottom + tailHeight)
      ..lineTo(tailCentre - tailWidth / 2, bottom)
      ..lineTo(inset, bottom)
      ..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final path = _bubblePath(size);
    final shadow = Paint()
      ..color = AppColors.ink
      ..style = PaintingStyle.fill
      ..isAntiAlias = false;
    canvas.drawPath(path.shift(Offset(shadowOffset, shadowOffset)), shadow);

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
      ..drawPath(path, fill)
      ..drawPath(path, border);
  }

  @override
  bool shouldRepaint(covariant _PixelSpeechBubblePainter oldDelegate) =>
      oldDelegate.tailWidth != tailWidth ||
      oldDelegate.tailHeight != tailHeight ||
      oldDelegate.shadowOffset != shadowOffset;
}
