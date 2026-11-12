import 'dart:ui';

/// Registration of individually drawn animation frames within an RGBA atlas.
/// Sources use normalized texture coordinates; targets use the shared 320x360
/// character canvas, with grounded feet at y=344. No procedural body motion.
class CostumeMotionAtlas {
  const CostumeMotionAtlas({
    required this.asset,
    required this.sources,
    required this.targets,
    required this.durationMs,
    required this.posterFrame,
    required this.loop,
    this.landingFrameStart,
  });

  final String asset;
  final List<Rect> sources;
  final List<Rect> targets;
  final int durationMs;
  final int posterFrame;
  final bool loop;

  /// Success finishes on the exact idle artwork, avoiding a pop back to idle.
  final int? landingFrameStart;
  int get frameCount => sources.length;
}
