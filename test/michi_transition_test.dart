import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sobra_app/widgets/cat_sprite.dart';

Future<List<Uint8List>> _frames(CharacterMotionRole role) async {
  final character = CharacterCatalog.michi;
  final motion = character.motionFor(role);
  final bytes = await rootBundle.load(character.assetFor(role));
  final codec = await ui.instantiateImageCodec(bytes.buffer.asUint8List());
  final image = (await codec.getNextFrame()).image;
  try {
    final pixels = (await image.toByteData(
      format: ui.ImageByteFormat.rawRgba,
    ))!;
    return List.generate(motion.frameCount, (index) {
      final frame = Uint8List(320 * 360 * 4);
      for (var y = 0; y < 360; y++) {
        final row = pixels.buffer.asUint8List(
          pixels.offsetInBytes + (y * image.width + index * 320) * 4,
          320 * 4,
        );
        frame.setRange(y * 320 * 4, (y + 1) * 320 * 4, row);
      }
      return frame;
    });
  } finally {
    image.dispose();
    codec.dispose();
  }
}

int _paintedHeight(Uint8List frame) {
  var top = 360;
  var bottom = 0;
  for (var y = 0; y < 360; y++) {
    for (var x = 0; x < 320; x++) {
      if (frame[(y * 320 + x) * 4 + 3] < 96) continue;
      if (y < top) top = y;
      bottom = y + 1;
    }
  }
  return bottom - top;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Michi celebration opens and lands on the approved idle pose', () async {
    final idle = await _frames(CharacterMotionRole.idle);
    final success = await _frames(CharacterMotionRole.success);
    final idleSpec = CharacterCatalog.michi.motionFor(CharacterMotionRole.idle);
    final successSpec = CharacterCatalog.michi.motionFor(
      CharacterMotionRole.success,
    );
    final approved = idle[idleSpec.playbackSpec.posterFrame];
    expect(
      success[successSpec.playbackSpec.playRange.start],
      orderedEquals(approved),
    );
    expect(
      success[successSpec.playbackSpec.completionFrame],
      orderedEquals(approved),
    );
  });

  test(
    'Michi standing jump poses keep the approved idle body height',
    () async {
      final idle = await _frames(CharacterMotionRole.idle);
      final success = await _frames(CharacterMotionRole.success);
      final idleHeight = _paintedHeight(idle.first);
      // Frame 1 crouches deliberately; later poses stand or jump at full size.
      for (var index = 2; index <= 10; index++) {
        expect(
          _paintedHeight(success[index]) / idleHeight,
          closeTo(1, 0.02),
          reason: 'Michi must not shrink on landing from frame $index',
        );
      }
    },
  );
}
