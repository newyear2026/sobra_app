import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sobra_app/widgets/cat_sprite.dart';
import 'package:sobra_app/widgets/character_headroom.dart';

void main() {
  testWidgets('top rows match every character sheet', (tester) async {
    await tester.runAsync(() async {
      for (final character in CharacterCatalog.all.values) {
        final rows = characterTopRows[character.id];
        expect(rows, isNotNull, reason: '${character.id} has no top rows');
        for (final MapEntry(key: role, value: motion)
            in character.motions.entries) {
          final data = await rootBundle.load(character.assetFor(role));
          final codec = await ui.instantiateImageCodec(
            data.buffer.asUint8List(),
          );
          final image = (await codec.getNextFrame()).image;
          final pixels = (await image.toByteData())!;
          var top = -1;
          for (var y = 0; y < image.height && top < 0; y++) {
            for (var x = 0; x < image.width; x++) {
              // Same threshold the sprite tooling treats as visible.
              if (pixels.getUint8((y * image.width + x) * 4 + 3) > 16) {
                top = y;
                break;
              }
            }
          }
          image.dispose();
          expect(
            rows![role],
            top,
            reason:
                '${character.id} ${role.name} (${motion.assetFileName}) '
                'now reaches row $top; update characterTopRows',
          );
        }
      }
    });
  });
}
