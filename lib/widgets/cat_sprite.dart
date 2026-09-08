import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Stable, character-independent roles used by every Sobra character pack.
enum CharacterMotionRole {
  idle,
  activity,
  processing,
  positive,
  success,
  warning,
}

abstract final class CharacterAnimationStandard {
  static const int frameCount = 8;
  static const double frameWidth = 320;
  static const double frameHeight = 360;
  static const Size frameSize = Size(frameWidth, frameHeight);
}

@immutable
class CharacterFrameRange {
  const CharacterFrameRange(this.start, this.end)
    : assert(start >= 0),
      assert(end >= start),
      assert(end < CharacterAnimationStandard.frameCount);

  final int start;
  final int end;

  int get length => end - start + 1;

  int frameAt(double progress) {
    final normalized = progress.clamp(0.0, 1.0);
    final offset = (normalized * length).floor().clamp(0, length - 1);
    return start + offset.toInt();
  }
}

@immutable
class CharacterPlaybackSpec {
  const CharacterPlaybackSpec({
    required this.playRange,
    required this.posterFrame,
    this.holdFrame,
  }) : assert(posterFrame >= 0),
       assert(posterFrame < CharacterAnimationStandard.frameCount),
       assert(holdFrame == null || holdFrame >= 0),
       assert(
         holdFrame == null || holdFrame < CharacterAnimationStandard.frameCount,
       );

  final CharacterFrameRange playRange;

  /// Representative frame used when animation is disabled or reduced.
  final int posterFrame;

  /// Compatibility override for legacy loop-authored one-shot sheets.
  ///
  /// New once-hold sheets should end on a pose that can be held and omit this.
  final int? holdFrame;

  int get completionFrame => holdFrame ?? playRange.end;

  int resolveFrame({
    required double progress,
    required bool animate,
    required bool completed,
  }) {
    if (!animate) return posterFrame;
    if (completed) return completionFrame;
    return playRange.frameAt(progress);
  }
}

@immutable
class CharacterMotionSpec {
  const CharacterMotionSpec({
    required this.assetFileName,
    required this.duration,
    required this.defaultLoop,
    required this.playbackSpec,
  });

  final String assetFileName;
  final Duration duration;
  final bool defaultLoop;
  final CharacterPlaybackSpec playbackSpec;
}

@immutable
class CharacterDefinition {
  const CharacterDefinition({
    required this.id,
    required this.displayName,
    required this.motions,
  }) : assert(id != ''),
       assert(displayName != '');

  final String id;
  final String displayName;
  final Map<CharacterMotionRole, CharacterMotionSpec> motions;

  CharacterMotionSpec motionFor(CharacterMotionRole role) {
    final motion = motions[role];
    if (motion == null) {
      throw FlutterError('$displayName does not define the ${role.name} role.');
    }
    return motion;
  }

  String assetFor(CharacterMotionRole role) =>
      'assets/characters/$id/${motionFor(role).assetFileName}';
}

abstract final class CharacterCatalog {
  static const michi = CharacterDefinition(
    id: 'michi',
    displayName: 'Michi',
    motions: {
      CharacterMotionRole.idle: CharacterMotionSpec(
        assetFileName: 'idle-8.png',
        duration: Duration(milliseconds: 2800),
        defaultLoop: true,
        playbackSpec: CharacterPlaybackSpec(
          playRange: CharacterFrameRange(0, 7),
          posterFrame: 0,
        ),
      ),
      CharacterMotionRole.activity: CharacterMotionSpec(
        assetFileName: 'activity-8.png',
        duration: Duration(milliseconds: 800),
        defaultLoop: true,
        playbackSpec: CharacterPlaybackSpec(
          playRange: CharacterFrameRange(0, 7),
          posterFrame: 0,
        ),
      ),
      CharacterMotionRole.processing: CharacterMotionSpec(
        assetFileName: 'processing-8.png',
        duration: Duration(milliseconds: 2200),
        defaultLoop: true,
        playbackSpec: CharacterPlaybackSpec(
          playRange: CharacterFrameRange(0, 7),
          posterFrame: 4,
        ),
      ),
      CharacterMotionRole.positive: CharacterMotionSpec(
        assetFileName: 'positive-8.png',
        duration: Duration(milliseconds: 2400),
        defaultLoop: true,
        playbackSpec: CharacterPlaybackSpec(
          playRange: CharacterFrameRange(0, 6),
          posterFrame: 6,
        ),
      ),
      CharacterMotionRole.success: CharacterMotionSpec(
        assetFileName: 'success-8.png',
        duration: Duration(milliseconds: 1250),
        defaultLoop: false,
        playbackSpec: CharacterPlaybackSpec(
          playRange: CharacterFrameRange(0, 7),
          posterFrame: 5,
          holdFrame: 0,
        ),
      ),
      CharacterMotionRole.warning: CharacterMotionSpec(
        assetFileName: 'warning-8.png',
        duration: Duration(milliseconds: 1600),
        defaultLoop: false,
        playbackSpec: CharacterPlaybackSpec(
          playRange: CharacterFrameRange(0, 7),
          posterFrame: 7,
        ),
      ),
    },
  );

  static const Map<String, CharacterDefinition> all = {'michi': michi};

  static CharacterDefinition require(String characterId) {
    final definition = all[characterId];
    if (definition == null) {
      throw FlutterError('Character "$characterId" is not registered.');
    }
    return definition;
  }
}

extension CharacterMotionRoleSpec on CharacterMotionRole {
  String get genericSemanticLabel => switch (this) {
    CharacterMotionRole.idle => 'El personaje descansa tranquilo',
    CharacterMotionRole.activity => 'El personaje está en movimiento',
    CharacterMotionRole.processing => 'El personaje está haciendo cuentas',
    CharacterMotionRole.positive => 'El personaje muestra un cambio positivo',
    CharacterMotionRole.success => 'El personaje celebra un logro',
    CharacterMotionRole.warning => 'El personaje muestra preocupación',
  };
}

/// Generic renderer for any character pack that follows the shared contract.
class CharacterSprite extends StatefulWidget {
  const CharacterSprite({
    super.key,
    required this.characterId,
    required this.role,
    this.width = 112,
    this.animate = true,
    this.loop,
    this.playToken = 0,
    this.semanticLabel,
    this.onComplete,
  }) : assert(characterId != '');

  final String characterId;
  final CharacterMotionRole role;
  final double width;
  final bool animate;
  final bool? loop;
  final int playToken;
  final String? semanticLabel;
  final VoidCallback? onComplete;

  CharacterDefinition get characterDefinition =>
      CharacterCatalog.require(characterId);

  CharacterMotionSpec get motionSpec => characterDefinition.motionFor(role);

  String get asset => characterDefinition.assetFor(role);

  bool get effectiveLoop => loop ?? motionSpec.defaultLoop;

  @override
  State<CharacterSprite> createState() => _CharacterSpriteState();
}

class _CharacterSpriteState extends State<CharacterSprite>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  ImageStream? _stream;
  ImageStreamListener? _listener;
  ui.Image? _image;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && !widget.effectiveLoop) {
          widget.onComplete?.call();
        }
      });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadImage();
    _configureAnimation(restart: true);
  }

  @override
  void didUpdateWidget(covariant CharacterSprite oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.characterId != widget.characterId ||
        oldWidget.role != widget.role) {
      _loadImage();
    }
    if (oldWidget.characterId != widget.characterId ||
        oldWidget.role != widget.role ||
        oldWidget.animate != widget.animate ||
        oldWidget.effectiveLoop != widget.effectiveLoop ||
        oldWidget.playToken != widget.playToken) {
      _configureAnimation(restart: true);
    }
  }

  void _loadImage() {
    _removeImageListener();
    final stream = AssetImage(
      widget.asset,
    ).resolve(createLocalImageConfiguration(context));
    final listener = ImageStreamListener((info, _) {
      if (!mounted) return;
      assert(() {
        final expectedWidth =
            CharacterAnimationStandard.frameWidth.toInt() *
            CharacterAnimationStandard.frameCount;
        final expectedHeight = CharacterAnimationStandard.frameHeight.toInt();
        if (info.image.width != expectedWidth ||
            info.image.height != expectedHeight) {
          throw FlutterError(
            '${widget.asset} must be ${expectedWidth}x$expectedHeight, '
            'but is ${info.image.width}x${info.image.height}.',
          );
        }
        return true;
      }());
      setState(() => _image = info.image);
    });
    _stream = stream;
    _listener = listener;
    stream.addListener(listener);
  }

  void _configureAnimation({required bool restart}) {
    _controller.duration = widget.motionSpec.duration;
    if (!widget.animate) {
      _controller.stop();
      _controller.value = 0;
      return;
    }
    if (restart) _controller.value = 0;
    if (widget.effectiveLoop) {
      _controller.repeat();
    } else {
      _controller.forward();
    }
  }

  void _removeImageListener() {
    final stream = _stream;
    final listener = _listener;
    if (stream != null && listener != null) stream.removeListener(listener);
  }

  @override
  void dispose() {
    _removeImageListener();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final height =
        widget.width *
        CharacterAnimationStandard.frameHeight /
        CharacterAnimationStandard.frameWidth;
    return Semantics(
      image: true,
      label: widget.semanticLabel ?? widget.role.genericSemanticLabel,
      child: SizedBox(
        width: widget.width,
        height: height,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final frame = widget.motionSpec.playbackSpec.resolveFrame(
              progress: _controller.value,
              animate: widget.animate,
              completed:
                  !widget.effectiveLoop &&
                  _controller.status == AnimationStatus.completed,
            );
            return CustomPaint(
              painter: _SpritePainter(image: _image, frame: frame),
            );
          },
        ),
      ),
    );
  }
}

/// Existing cat-facing names remain available while screens migrate to roles.
enum CatMotion { idle, walk, calculate, saving, celebrate, concern }

extension CatMotionAsset on CatMotion {
  CharacterMotionRole get role => switch (this) {
    CatMotion.idle => CharacterMotionRole.idle,
    CatMotion.walk => CharacterMotionRole.activity,
    CatMotion.calculate => CharacterMotionRole.processing,
    CatMotion.saving => CharacterMotionRole.positive,
    CatMotion.celebrate => CharacterMotionRole.success,
    CatMotion.concern => CharacterMotionRole.warning,
  };

  CharacterMotionSpec get motionSpec => CharacterCatalog.michi.motionFor(role);

  String get asset => CharacterCatalog.michi.assetFor(role);

  Size get frameSize => CharacterAnimationStandard.frameSize;

  Duration get duration => motionSpec.duration;

  String get semanticLabel => switch (this) {
    CatMotion.idle => 'El gato descansa tranquilo',
    CatMotion.walk => 'El gato camina',
    CatMotion.calculate => 'El gato hace cuentas',
    CatMotion.saving => 'El gato guarda monedas en la alcancía',
    CatMotion.celebrate => 'El gato celebra contento',
    CatMotion.concern => 'El gato muestra preocupación por el presupuesto',
  };
}

/// Compatibility wrapper for the app's current Michi call sites.
class CatSprite extends StatelessWidget {
  const CatSprite({
    super.key,
    required this.motion,
    this.width = 112,
    this.animate = true,
    this.loop,
    this.playToken = 0,
    this.onComplete,
  });

  final CatMotion motion;
  final double width;
  final bool animate;
  final bool? loop;
  final int playToken;
  final VoidCallback? onComplete;

  @override
  Widget build(BuildContext context) {
    return CharacterSprite(
      characterId: 'michi',
      role: motion.role,
      width: width,
      animate: animate,
      loop: loop,
      playToken: playToken,
      semanticLabel: motion.semanticLabel,
      onComplete: onComplete,
    );
  }
}

class _SpritePainter extends CustomPainter {
  const _SpritePainter({required this.image, required this.frame});

  final ui.Image? image;
  final int frame;

  @override
  void paint(Canvas canvas, Size size) {
    final sprite = image;
    if (sprite == null) return;
    final frameWidth = sprite.width / CharacterAnimationStandard.frameCount;
    final source = Rect.fromLTWH(
      frame * frameWidth,
      0,
      frameWidth,
      sprite.height.toDouble(),
    );
    final destination = Offset.zero & size;
    final paint = Paint()
      ..isAntiAlias = false
      ..filterQuality = FilterQuality.none;
    canvas.drawImageRect(sprite, source, destination, paint);
  }

  @override
  bool shouldRepaint(covariant _SpritePainter oldDelegate) =>
      oldDelegate.image != image || oldDelegate.frame != frame;
}
