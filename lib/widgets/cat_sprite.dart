import 'dart:ui' as ui;

import 'package:flutter/material.dart';

enum CatMotion { idle, walk, calculate, saving, celebrate }

extension CatMotionAsset on CatMotion {
  String get asset => switch (this) {
    CatMotion.idle => 'assets/cats/cat-idle-8.png',
    CatMotion.walk => 'assets/cats/cat-walk-8.png',
    CatMotion.calculate => 'assets/cats/cat-expense-8.png',
    CatMotion.saving => 'assets/cats/cat-saving-8.png',
    CatMotion.celebrate => 'assets/cats/cat-celebrate-8.png',
  };

  Size get frameSize => switch (this) {
    CatMotion.idle => const Size(229, 241),
    CatMotion.walk => const Size(264, 247),
    CatMotion.calculate => const Size(218, 250),
    CatMotion.saving => const Size(221, 227),
    CatMotion.celebrate => const Size(290, 357),
  };

  Duration get duration => switch (this) {
    CatMotion.idle => const Duration(milliseconds: 2800),
    CatMotion.walk => const Duration(milliseconds: 800),
    CatMotion.calculate => const Duration(milliseconds: 2200),
    CatMotion.saving => const Duration(milliseconds: 2400),
    CatMotion.celebrate => const Duration(milliseconds: 1250),
  };

  // The app runs in es-MX only, so these are what a screen reader actually
  // says out loud.
  String get semanticLabel => switch (this) {
    CatMotion.idle => 'El gato descansa tranquilo',
    CatMotion.walk => 'El gato camina',
    CatMotion.calculate => 'El gato hace cuentas',
    CatMotion.saving => 'El gato guarda monedas en la alcancía',
    CatMotion.celebrate => 'El gato celebra contento',
  };
}

class CatSprite extends StatefulWidget {
  const CatSprite({
    super.key,
    required this.motion,
    this.width = 112,
    this.animate = true,
    this.loop = true,
    this.playToken = 0,
    this.onComplete,
  });

  final CatMotion motion;
  final double width;
  final bool animate;
  final bool loop;
  final int playToken;
  final VoidCallback? onComplete;

  @override
  State<CatSprite> createState() => _CatSpriteState();
}

class _CatSpriteState extends State<CatSprite>
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
        if (status == AnimationStatus.completed && !widget.loop) {
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
  void didUpdateWidget(covariant CatSprite oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.motion != widget.motion) {
      _loadImage();
    }
    if (oldWidget.motion != widget.motion ||
        oldWidget.animate != widget.animate ||
        oldWidget.loop != widget.loop ||
        oldWidget.playToken != widget.playToken) {
      _configureAnimation(restart: true);
    }
  }

  void _loadImage() {
    _removeImageListener();
    final stream = AssetImage(
      widget.motion.asset,
    ).resolve(createLocalImageConfiguration(context));
    final listener = ImageStreamListener((info, _) {
      if (!mounted) return;
      setState(() => _image = info.image);
    });
    _stream = stream;
    _listener = listener;
    stream.addListener(listener);
  }

  void _configureAnimation({required bool restart}) {
    _controller.duration = widget.motion.duration;
    if (!widget.animate) {
      _controller.stop();
      _controller.value = 0;
      return;
    }
    if (restart) _controller.value = 0;
    if (widget.loop) {
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
    final natural = widget.motion.frameSize;
    final height = widget.width * natural.height / natural.width;
    return Semantics(
      image: true,
      label: widget.motion.semanticLabel,
      child: SizedBox(
        width: widget.width,
        height: height,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final rawFrame = widget.animate
                ? (_controller.value * 8).floor()
                : 0;
            final frame = rawFrame.clamp(0, 7);
            return CustomPaint(
              painter: _SpritePainter(image: _image, frame: frame),
            );
          },
        ),
      ),
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
    final frameWidth = sprite.width / 8;
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
