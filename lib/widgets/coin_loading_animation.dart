import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'coin_loading_timeline.dart';

/// Deposits a coin, pauses proudly, and prepares the next coin without a jump.
class CoinLoadingAnimation extends StatefulWidget {
  const CoinLoadingAnimation({
    super.key,
    this.reducedMotion = false,
    this.startedAt,
  });

  static const asset = CoinLoadingTimeline.asset;
  static const duration = CoinLoadingTimeline.duration;
  static const _frameEnds = CoinLoadingTimeline.frameEnds;

  final bool reducedMotion;
  final DateTime? startedAt;

  static int frameAt(Duration elapsed) {
    final milliseconds = elapsed.isNegative
        ? 0
        : elapsed.inMilliseconds % duration.inMilliseconds;
    for (var i = 0; i < _frameEnds.length; i++) {
      if (milliseconds < _frameEnds[i]) return i;
    }
    return _frameEnds.length - 1;
  }

  @override
  State<CoinLoadingAnimation> createState() => _CoinLoadingAnimationState();
}

class _CoinLoadingAnimationState extends State<CoinLoadingAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: CoinLoadingAnimation.duration,
  );
  ImageStream? _stream;
  ImageInfo? _image;
  bool _still = false;
  late final ImageStreamListener _listener = ImageStreamListener(
    (image, _) {
      if (!mounted) {
        image.dispose();
        return;
      }
      setState(() {
        _image?.dispose();
        _image = image;
      });
      _updateMotion();
    },
    // Decorative art must never prevent the ledger from opening.
    onError: (Object error, StackTrace? stack) {
      debugPrint('Startup illustration unavailable: ${error.runtimeType}');
    },
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateMotion();
    final stream = const AssetImage(
      CoinLoadingAnimation.asset,
    ).resolve(createLocalImageConfiguration(context));
    if (stream.key == _stream?.key) return;
    _stream?.removeListener(_listener);
    _stream = stream..addListener(_listener);
  }

  @override
  void didUpdateWidget(CoinLoadingAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateMotion(synchronize: oldWidget.startedAt != widget.startedAt);
  }

  void _updateMotion({bool synchronize = false}) {
    _still = widget.reducedMotion || MediaQuery.disableAnimationsOf(context);
    if (_still) {
      _controller.stop();
      _controller.value = 0;
    } else if (_image != null && (!_controller.isAnimating || synchronize)) {
      if (widget.startedAt case final startedAt?) {
        final elapsed = DateTime.now().difference(startedAt);
        final period = CoinLoadingAnimation.duration.inMilliseconds;
        _controller.value = elapsed.isNegative
            ? 0
            : (elapsed.inMilliseconds % period) / period;
      }
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _stream?.removeListener(_listener);
    _image?.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => CustomPaint(
          painter: _CoinPainter(
            image: _image?.image,
            frame: CoinLoadingAnimation.frameAt(
              Duration(
                milliseconds:
                    (_controller.value *
                            CoinLoadingAnimation.duration.inMilliseconds)
                        .floor(),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _CoinPainter extends CustomPainter {
  const _CoinPainter({required this.image, required this.frame});

  final ui.Image? image;
  final int frame;

  @override
  void paint(Canvas canvas, Size size) {
    final sprite = image;
    if (sprite == null) return;
    final width = sprite.width / CoinLoadingTimeline.columns;
    final height = sprite.height / CoinLoadingTimeline.rows;
    canvas.drawImageRect(
      sprite,
      Rect.fromLTWH(
        frame % CoinLoadingTimeline.columns * width,
        frame ~/ CoinLoadingTimeline.columns * height,
        width,
        height,
      ),
      Offset.zero & size,
      Paint()..filterQuality = FilterQuality.none,
    );
  }

  @override
  bool shouldRepaint(_CoinPainter oldDelegate) =>
      oldDelegate.image != image || oldDelegate.frame != frame;
}
