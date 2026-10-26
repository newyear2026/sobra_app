// Render the exact production painter at the app's playback timings.
// flutter test tool/render_costume_motion_previews_test.dart --no-pub
// Then encode the PNG sequences using tool/encode_costume_motion_previews.sh.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sobra_app/data/costume_motion_atlases.dart';
import 'package:sobra_app/models/character_costume.dart';
import 'package:sobra_app/widgets/costume_motion_painter.dart';

const root = 'design/seasonal/2026-halloween-dia-de-muertos/motion-v2/previews';
const roles = [
  'idle',
  'activity',
  'processing',
  'positive',
  'success',
  'warning',
];

Future<ui.Image> texture(String asset) async {
  final data = await rootBundle.load(asset);
  final codec = await ui.instantiateImageCodec(
    data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
  );
  final image = (await codec.getNextFrame()).image;
  codec.dispose();
  return image;
}

void label(
  ui.Canvas canvas,
  String text,
  ui.Offset offset, {
  double size = 14,
}) {
  final builder =
      ui.ParagraphBuilder(
          ui.ParagraphStyle(fontFamily: 'PixelifySans', fontSize: size),
        )
        ..pushStyle(ui.TextStyle(color: const ui.Color(0xff202844)))
        ..addText(text);
  final paragraph = builder.build()
    ..layout(const ui.ParagraphConstraints(width: 640));
  canvas.drawParagraph(paragraph, offset);
  paragraph.dispose();
}

Future<void> saveFrame(
  ui.PictureRecorder recorder,
  int width,
  int height,
  String path,
) async {
  final picture = recorder.endRecording();
  final image = await picture.toImage(width, height);
  final data = (await image.toByteData(format: ui.ImageByteFormat.png))!;
  await File(path).writeAsBytes(
    data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
  );
  image.dispose();
  picture.dispose();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader(
      'PixelifySans',
    )..addFont(rootBundle.load('assets/fonts/PixelifySans.ttf'))).load();
  });
  test(
    'render twelve six-role previews and an idle gallery',
    () async {
      await Directory('$root/gallery-frames').create(recursive: true);
      final idleTextures = <String, ui.Image>{};
      for (final costume in CharacterCostumes.all) {
        final id = costume.characterId;
        final atlases = costumeMotionAtlases[id]!;
        final images = <String, ui.Image>{};
        for (final role in roles) {
          images[role] = await texture(atlases[role]!.asset);
        }
        idleTextures[id] = images['idle']!;
        final dir = Directory('$root/$id-frames');
        await dir.create(recursive: true);
        for (var tick = 0; tick < 48; tick++) {
          final recorder = ui.PictureRecorder();
          final canvas = ui.Canvas(recorder);
          canvas.drawColor(const ui.Color(0xfffffaf2), ui.BlendMode.src);
          label(
            canvas,
            '${id.toUpperCase()} / AUTUMN COSTUME',
            const ui.Offset(12, 8),
            size: 18,
          );
          for (var slot = 0; slot < roles.length; slot++) {
            final role = roles[slot], atlas = atlases[role]!;
            final elapsed = tick * 100;
            final progress = atlas.loop
                ? (elapsed % atlas.durationMs) / atlas.durationMs
                : (elapsed / atlas.durationMs).clamp(0.0, 1.0);
            final frame = (progress * atlas.frameCount).floor().clamp(
              0,
              atlas.frameCount - 1,
            );
            final x = slot % 3 * 192.0, y = 36.0 + slot ~/ 3 * 240;
            label(
              canvas,
              '${role.toUpperCase()} ${atlas.durationMs / 1000}s',
              ui.Offset(x + 10, y),
            );
            canvas.save();
            canvas.translate(x, y + 20);
            CostumeMotionPainter(
              image: images[role],
              landingImage: images['idle'],
              atlas: atlas,
              idleAtlas: atlases['idle']!,
              frame: frame,
            ).paint(canvas, const ui.Size(192, 216));
            canvas.restore();
          }
          await saveFrame(
            recorder,
            576,
            516,
            '${dir.path}/${tick.toString().padLeft(3, '0')}.png',
          );
        }
        for (final entry in images.entries) {
          if (entry.key != 'idle') entry.value.dispose();
        }
        // ignore: avoid_print
        print('Rendered all six roles for $id');
      }
      for (var tick = 0; tick < 28; tick++) {
        final recorder = ui.PictureRecorder();
        final canvas = ui.Canvas(recorder);
        canvas.drawColor(const ui.Color(0xfffffaf2), ui.BlendMode.src);
        label(
          canvas,
          'AUTUMN COSTUMES / DRAWN IDLE ANIMATIONS',
          const ui.Offset(12, 8),
          size: 18,
        );
        for (var slot = 0; slot < CharacterCostumes.all.length; slot++) {
          final id = CharacterCostumes.all[slot].characterId;
          final atlas = costumeMotionAtlases[id]!['idle']!;
          final frame =
              ((tick * 100 % atlas.durationMs) /
                      atlas.durationMs *
                      atlas.frameCount)
                  .floor();
          final x = slot % 4 * 160.0, y = 36.0 + slot ~/ 4 * 204;
          label(canvas, id.toUpperCase(), ui.Offset(x + 10, y));
          canvas.save();
          canvas.translate(x, y + 20);
          CostumeMotionPainter(
            image: idleTextures[id],
            atlas: atlas,
            idleAtlas: atlas,
            frame: frame,
          ).paint(canvas, const ui.Size(160, 180));
          canvas.restore();
        }
        await saveFrame(
          recorder,
          640,
          648,
          '$root/gallery-frames/${tick.toString().padLeft(3, '0')}.png',
        );
      }
      for (final image in idleTextures.values) {
        image.dispose();
      }
    },
    timeout: const Timeout(Duration(minutes: 8)),
  );
}
