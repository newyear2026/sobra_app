// flutter test --no-pub tool/render_costume_contacts_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sobra_app/data/costume_motion_atlases.dart';
import 'package:sobra_app/widgets/costume_motion_painter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'render every registered frame for visual QA',
    () async {
      await (FontLoader(
        'PixelifySans',
      )..addFont(rootBundle.load('assets/fonts/PixelifySans.ttf'))).load();
      const roles = [
        'idle',
        'activity',
        'processing',
        'positive',
        'success',
        'warning',
      ];
      final directory = Directory(
        'design/seasonal/2026-halloween-dia-de-muertos/motion-v2/contacts',
      );
      await directory.create(recursive: true);
      for (final entry in costumeMotionAtlases.entries) {
        final atlases = entry.value;
        if (atlases.length != 6) continue;
        final images = <String, ui.Image>{};
        for (final role in roles) {
          final data = await rootBundle.load(atlases[role]!.asset);
          final codec = await ui.instantiateImageCodec(
            data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
          );
          images[role] = (await codec.getNextFrame()).image;
          codec.dispose();
        }
        final recorder = ui.PictureRecorder();
        final canvas = ui.Canvas(recorder);
        canvas.drawColor(const ui.Color(0xfffffaf2), ui.BlendMode.src);
        for (var row = 0; row < roles.length; row++) {
          final role = roles[row], atlas = atlases[role]!;
          final paragraph =
              (ui.ParagraphBuilder(
                      ui.ParagraphStyle(
                        fontFamily: 'PixelifySans',
                        fontSize: 16,
                      ),
                    )
                    ..pushStyle(ui.TextStyle(color: const ui.Color(0xff202844)))
                    ..addText(
                      '${entry.key.toUpperCase()} / ${role.toUpperCase()}',
                    ))
                  .build()
                ..layout(const ui.ParagraphConstraints(width: 1152));
          canvas.drawParagraph(paragraph, ui.Offset(8, row * 128.0 + 2));
          paragraph.dispose();
          for (var frame = 0; frame < atlas.frameCount; frame++) {
            canvas.save();
            canvas.translate(frame * 96.0, row * 128.0 + 20);
            CostumeMotionPainter(
              image: images[role],
              landingImage: images['idle'],
              atlas: atlas,
              idleAtlas: atlases['idle']!,
              frame: frame,
            ).paint(canvas, const ui.Size(96, 108));
            canvas.restore();
          }
        }
        final picture = recorder.endRecording();
        final image = await picture.toImage(1152, 768);
        final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!;
        await File('${directory.path}/${entry.key}.png').writeAsBytes(
          bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
        );
        image.dispose();
        picture.dispose();
        for (final texture in images.values) {
          texture.dispose();
        }
        // ignore: avoid_print
        print('Rendered 64 registered frames for ${entry.key}');
      }
    },
    timeout: const Timeout(Duration(minutes: 4)),
  );
}
