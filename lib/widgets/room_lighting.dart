import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../models/room_time_of_day.dart';

/// The empty-room art contains no baked sunlight. Rays share the same cover
/// rectangle as the background, so they stay aligned when the stage crops.
class RoomSunbeams extends CustomPainter {
  const RoomSunbeams({required this.background, required this.phase});

  final Rect background;
  final RoomTimeOfDay phase;

  @override
  void paint(Canvas canvas, Size size) {
    if (phase == RoomTimeOfDay.night) return;
    final color = switch (phase) {
      RoomTimeOfDay.day => const Color(0x49FFF8DA),
      RoomTimeOfDay.dawn => const Color(0x30FFE3BD),
      RoomTimeOfDay.sunset => const Color(0x22F8B478),
      RoomTimeOfDay.night => Colors.transparent,
    };
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.translate(background.left, background.top);
    canvas.scale(background.width / 1024, background.height / 1536);
    // The architectural window is already painted. Sunlight belongs on the
    // wall and floor behind it, never on the curtains or frame.
    canvas.clipPath(
      Path()
        ..fillType = PathFillType.evenOdd
        ..addRect(const Rect.fromLTWH(0, 0, 1024, 1536))
        ..addRect(const Rect.fromLTRB(334, 105, 765, 537)),
    );
    final paint = Paint()..color = color;
    canvas.drawPath(
      Path()
        ..moveTo(0, 70)
        ..lineTo(0, 145)
        ..lineTo(555, 751)
        ..lineTo(650, 751)
        ..close(),
      paint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(755, 310)
        ..lineTo(1024, 610)
        ..lineTo(1024, 720)
        ..lineTo(720, 390)
        ..close(),
      paint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(0, 782)
        ..lineTo(135, 782)
        ..lineTo(805, 1536)
        ..lineTo(595, 1536)
        ..close(),
      paint,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(RoomSunbeams oldDelegate) =>
      oldDelegate.background != background || oldDelegate.phase != phase;
}

/// Multiplied over the wall and floor. Multiplying darkens without the grey
/// wash a translucent overlay gives, so outlines keep their contrast.
Color? roomShade(RoomTimeOfDay phase) => switch (phase) {
  RoomTimeOfDay.dawn => const Color(0xFFFFF9F6),
  RoomTimeOfDay.day => null,
  RoomTimeOfDay.sunset => const Color(0xFFFEF8F6),
  RoomTimeOfDay.night => const Color(0xFF8590BE),
};

/// Furniture and the character take a lighter night than the room, so a
/// face and a sofa's outline still read without a lamp.
Color? roomSubjectShade(RoomTimeOfDay phase) => switch (phase) {
  RoomTimeOfDay.night => const Color(0xFFBCC3E4),
  _ => roomShade(phase),
};

/// What a lamp's light multiplies a nearby subject by.
const _lampWarmth = Color(0xFFFFE2B0);

/// The window opening on the shared stage, in portrait background pixels.
/// The sky behind it already shows the time of day.
const _windowGlass = Rect.fromLTRB(424, 168, 673, 490);

/// Where a placed lamp's light comes from: its shade, not its frame's centre.
Offset roomLampLight(Rect frame, {required bool floorLamp}) =>
    Offset(frame.center.dx, frame.top + frame.height * (floorLamp ? .19 : .23));

/// The hanging lantern sits to the right of its bronze stem. These fractions
/// are measured on the transparent sprite, including the canvas margin.
Offset roomBronzeLampLight(Rect frame) => Offset(
  frame.center.dx + frame.height * .046,
  frame.top + frame.height * .188,
);

/// Laid over the background, under furniture and the character.
class RoomAmbientTint extends CustomPainter {
  const RoomAmbientTint({required this.phase, required this.background});

  final RoomTimeOfDay phase;
  final Rect background;

  @override
  void paint(Canvas canvas, Size size) {
    final color = roomShade(phase);
    if (color == null) return;
    final sx = background.width / 1024;
    final sy = background.height / 1536;
    final glass = Rect.fromLTRB(
      background.left + _windowGlass.left * sx,
      background.top + _windowGlass.top * sy,
      background.left + _windowGlass.right * sx,
      background.top + _windowGlass.bottom * sy,
    );
    canvas.drawPath(
      Path()
        ..fillType = PathFillType.evenOdd
        ..addRect(Offset.zero & size)
        ..addRect(glass),
      Paint()
        ..color = color
        ..blendMode = BlendMode.multiply,
    );
  }

  @override
  bool shouldRepaint(RoomAmbientTint oldDelegate) =>
      oldDelegate.phase != phase || oldDelegate.background != background;
}

/// Lights one piece of furniture or the character for [phase].
///
/// At night a placed lamp warms whatever stands near it, strongest on the
/// side facing the lamp — the near arm of a sofa, not the whole sofa.
/// [frame], [lamps] and [reach] share the scene's coordinates.
class RoomSubjectLight extends StatelessWidget {
  const RoomSubjectLight({
    super.key,
    required this.phase,
    required this.frame,
    required this.lamps,
    required this.reach,
    required this.child,
  });

  final RoomTimeOfDay phase;
  final Rect frame;
  final List<Offset> lamps;
  final double reach;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final shade = roomSubjectShade(phase);
    if (shade == null) return child;
    if (phase != RoomTimeOfDay.night || lamps.isEmpty) {
      return ColorFiltered(
        colorFilter: ColorFilter.mode(shade, BlendMode.modulate),
        child: child,
      );
    }
    final lamp = lamps.reduce(
      (a, b) =>
          (a - frame.center).distance <= (b - frame.center).distance ? a : b,
    );
    final local = lamp - frame.topLeft;
    return ShaderMask(
      blendMode: BlendMode.modulate,
      shaderCallback: (bounds) => ui.Gradient.radial(
        bounds.topLeft + local,
        reach,
        [_lampWarmth, shade],
      ),
      child: child,
    );
  }
}

/// Soft, irregularly sized pools of amber on the wall and floor. A single
/// gradient per surface avoids the concentric rings in the first mockup.
class RoomLampGlow extends CustomPainter {
  const RoomLampGlow({
    required this.background,
    required this.floorLamps,
    required this.tableLamps,
    this.bronzeLamps = const [],
  });

  final Rect background;
  final List<Rect> floorLamps;
  final List<Rect> tableLamps;
  final List<Rect> bronzeLamps;

  @override
  void paint(Canvas canvas, Size size) {
    final floorY = background.top + background.height * (782 / 1536);
    void paintFloorLamp(Offset shade, Offset feet) {
      canvas.save();
      canvas.clipRect(Rect.fromLTRB(0, 0, size.width, floorY));
      _glow(
        canvas,
        shade,
        background.width * .30,
        background.height * .22,
        const Color(0x9CFFD08A),
      );
      canvas.restore();
      canvas.save();
      canvas.clipRect(Rect.fromLTRB(0, floorY, size.width, size.height));
      _glow(
        canvas,
        feet,
        background.width * .25,
        background.height * .07,
        const Color(0x8CF6B868),
      );
      canvas.restore();
    }

    for (final lamp in floorLamps) {
      paintFloorLamp(
        roomLampLight(lamp, floorLamp: true),
        Offset(lamp.center.dx, lamp.bottom + background.height * .013),
      );
    }
    for (final lamp in bronzeLamps) {
      paintFloorLamp(
        roomBronzeLampLight(lamp),
        Offset(
          lamp.center.dx - lamp.height * .033,
          lamp.top + lamp.height * .954 + background.height * .013,
        ),
      );
    }
    for (final lamp in tableLamps) {
      _glow(
        canvas,
        roomLampLight(lamp, floorLamp: false),
        background.width * .12,
        background.height * .09,
        const Color(0x68FFD69A),
      );
    }
  }

  @override
  bool shouldRepaint(RoomLampGlow oldDelegate) =>
      oldDelegate.background != background ||
      oldDelegate.floorLamps != floorLamps ||
      oldDelegate.tableLamps != tableLamps ||
      oldDelegate.bronzeLamps != bronzeLamps;
}

/// The bright bloom on a floor lamp's shade, drawn over the lamp itself.
class RoomLampShades extends CustomPainter {
  const RoomLampShades({required this.floorLamps, this.bronzeLamps = const []});

  final List<Rect> floorLamps;
  final List<Rect> bronzeLamps;

  @override
  void paint(Canvas canvas, Size size) {
    for (final lamp in floorLamps) {
      _glow(
        canvas,
        roomLampLight(lamp, floorLamp: true),
        lamp.height * .12,
        lamp.height * .075,
        const Color(0xAFFFE6A5),
      );
    }
    for (final lamp in bronzeLamps) {
      _glow(
        canvas,
        roomBronzeLampLight(lamp),
        lamp.height * .055,
        lamp.height * .075,
        const Color(0xAFFFE6A5),
      );
    }
  }

  @override
  bool shouldRepaint(RoomLampShades oldDelegate) =>
      oldDelegate.floorLamps != floorLamps ||
      oldDelegate.bronzeLamps != bronzeLamps;
}

void _glow(
  Canvas canvas,
  Offset center,
  double radiusX,
  double radiusY,
  Color centerColor,
) {
  canvas.save();
  canvas.translate(center.dx, center.dy);
  canvas.scale(radiusX, radiusY);
  canvas.drawCircle(
    Offset.zero,
    1,
    Paint()
      ..shader = RadialGradient(
        colors: [centerColor, centerColor.withValues(alpha: 0)],
        stops: const [0, 1],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: 1)),
  );
  canvas.restore();
}
