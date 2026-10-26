import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../models/costume_motion.dart';

/// Plays genuine sequential poses. All translation/registration is authored
/// per frame in the metadata; there is no whole-body sway or squash animation.
class CostumeMotionPainter extends CustomPainter {
  const CostumeMotionPainter({
    required this.image,
    required this.atlas,
    required this.frame,
    required this.idleAtlas,
    this.landingImage,
  });

  final ui.Image? image;
  final ui.Image? landingImage;
  final CostumeMotionAtlas atlas;
  final CostumeMotionAtlas idleAtlas;
  final int frame;

  bool get isLanding =>
      atlas.landingFrameStart != null && frame >= atlas.landingFrameStart!;

  @override
  void paint(Canvas canvas, Size size) {
    final usesLanding = isLanding && landingImage != null;
    final texture = usesLanding ? landingImage : image;
    if (texture == null) return;
    final layout = usesLanding ? idleAtlas : atlas;
    final index = usesLanding ? 0 : frame.clamp(0, atlas.frameCount - 1);
    final source = layout.sources[index];
    final target = layout.targets[index];
    canvas.drawImageRect(
      texture,
      Rect.fromLTWH(
        source.left * texture.width,
        source.top * texture.height,
        source.width * texture.width,
        source.height * texture.height,
      ),
      Rect.fromLTWH(
        target.left * size.width / 320,
        target.top * size.height / 360,
        target.width * size.width / 320,
        target.height * size.height / 360,
      ),
      Paint()
        ..isAntiAlias = false
        ..filterQuality = FilterQuality.none,
    );
  }

  @override
  bool shouldRepaint(covariant CostumeMotionPainter oldDelegate) =>
      oldDelegate.image != image ||
      oldDelegate.landingImage != landingImage ||
      oldDelegate.atlas != atlas ||
      oldDelegate.idleAtlas != idleAtlas ||
      oldDelegate.frame != frame;
}
