import 'package:flutter/material.dart';

import '../state/sobra_store.dart';
import '../theme/app_theme.dart';
import 'character_room.dart';
import 'pixel_ui.dart';

/// The room as the prologue shows it: the weather over the art, and whoever
/// happens to be standing in it.
///
/// Deliberately not [CharacterRoom]. That one is the home screen's scene — one
/// character with speech stacked above it, sized to a fixed 2:1 card. The
/// prologue needs two of them at once, no bubble, a height that varies page to
/// page, and rain.
///
/// The rain is painted rather than drawn: a second room asset would have to be
/// redrawn every time the room art changes, and there is one room today and a
/// shop full of them planned.
class PrologueScene extends StatefulWidget {
  const PrologueScene({
    super.key,
    required this.height,
    this.raining = false,
    this.actors = const <Widget>[],
  });

  final double height;

  /// Tints the room cold and lays rain over it.
  final bool raining;

  /// Drawn along the floor, evenly spaced. Empty is a room nobody is in yet.
  final List<Widget> actors;

  static const rainKey = ValueKey('prologue-rain');

  @override
  State<PrologueScene> createState() => _PrologueSceneState();
}

class _PrologueSceneState extends State<PrologueScene>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rainController;
  bool? _reducedMotion;

  @override
  void initState() {
    super.initState();
    _rainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 720),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncRain();
  }

  @override
  void didUpdateWidget(covariant PrologueScene oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.raining != widget.raining) _syncRain(force: true);
  }

  void _syncRain({bool force = false}) {
    final reducedMotion = reducedMotionOf(context);
    if (!force && _reducedMotion == reducedMotion) return;
    _reducedMotion = reducedMotion;
    if (!widget.raining || reducedMotion) {
      _rainController.stop();
      _rainController.value = 0;
    } else {
      _rainController.repeat();
    }
  }

  @override
  void dispose() {
    _rainController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PixelCard(
    padding: EdgeInsets.zero,
    color: AppColors.paperLight,
    child: SizedBox(
      height: widget.height,
      width: double.infinity,
      child: ClipRect(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image(
              image: CharacterRoom.backgroundProvider(context),
              fit: BoxFit.cover,
              alignment: const Alignment(0, 0.25),
              excludeFromSemantics: true,
              // The room is decoration. A missing asset must not blank the
              // page the story is being told on.
              errorBuilder: (context, error, stack) =>
                  const ColoredBox(color: AppColors.paperLight),
            ),
            if (widget.raining) ...[
              const ColoredBox(color: Color(0x423A5484)),
              RepaintBoundary(
                child: AnimatedBuilder(
                  animation: _rainController,
                  builder: (context, _) => CustomPaint(
                    key: PrologueScene.rainKey,
                    painter: _RainPainter(phase: _rainController.value),
                  ),
                ),
              ),
            ],
            if (widget.actors.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  mainAxisAlignment: widget.actors.length == 1
                      ? MainAxisAlignment.center
                      : MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: widget.actors,
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

/// Brings an actor into its assigned place, then swaps its movement loop for
/// the pose that belongs to the story beat.
///
/// The travel happens outside the character sheet, so every future character
/// pack inherits the same blocking without needing an onboarding-only asset.
class PrologueArrival extends StatefulWidget {
  const PrologueArrival({
    super.key,
    required this.moving,
    required this.arrived,
    required this.animate,
    this.distance = 72,
    this.duration = const Duration(milliseconds: 2200),
    this.delayFraction = 0,
  }) : assert(distance >= 0),
       assert(delayFraction >= 0 && delayFraction < 0.7);

  final Widget moving;
  final Widget arrived;
  final bool animate;
  final double distance;
  final Duration duration;

  /// A fraction of [duration], useful when two companions enter together.
  final double delayFraction;

  static const movingKey = ValueKey('prologue-arrival-moving');
  static const arrivedKey = ValueKey('prologue-arrival-arrived');

  @override
  State<PrologueArrival> createState() => _PrologueArrivalState();
}

class _PrologueArrivalState extends State<PrologueArrival>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _syncAnimation(restart: true);
  }

  @override
  void didUpdateWidget(covariant PrologueArrival oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration;
    }
    if (oldWidget.animate != widget.animate ||
        oldWidget.delayFraction != widget.delayFraction) {
      _syncAnimation(restart: true);
    }
  }

  void _syncAnimation({required bool restart}) {
    if (!widget.animate) {
      _controller.stop();
      _controller.value = 1;
      return;
    }
    if (restart) _controller.value = 0;
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    builder: (context, _) {
      const arrivalPoint = 0.72;
      final progress = _controller.value;
      if (!widget.animate || progress >= arrivalPoint) {
        return KeyedSubtree(
          key: PrologueArrival.arrivedKey,
          child: widget.arrived,
        );
      }

      final travel = Interval(
        widget.delayFraction,
        arrivalPoint,
        curve: Curves.easeOutCubic,
      ).transform(progress);
      return KeyedSubtree(
        key: PrologueArrival.movingKey,
        child: Opacity(
          opacity: (0.45 + travel * 0.55).clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(-widget.distance * (1 - travel), 0),
            child: widget.moving,
          ),
        ),
      );
    },
  );
}

/// Slanted rain dashes drifting by one dash-and-gap cycle.
class _RainPainter extends CustomPainter {
  const _RainPainter({required this.phase});

  final double phase;

  static const _slope = 0.3;
  static const _spacing = 15.0;
  static const _dash = 13.0;
  static const _gap = 11.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x7ACBE0F2)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.square;
    final drift = size.height * _slope;
    final step = Offset(_slope, 1) / Offset(_slope, 1).distance;

    for (var x = -drift; x < size.width + drift; x += _spacing) {
      final start = Offset(x, 0);
      final length = (size.height * size.height + drift * drift) / size.height;
      final cycle = _dash + _gap;
      for (var along = -cycle + phase * cycle; along < length; along += cycle) {
        final from = start + step * along;
        final to = start + step * (along + _dash);
        canvas.drawLine(from, to, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RainPainter oldDelegate) =>
      oldDelegate.phase != phase;
}
