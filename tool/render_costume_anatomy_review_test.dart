// Render enlarged 12-frame reviews and an animated gallery of repaired roles.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sobra_app/data/costume_motion_atlases.dart';
import 'package:sobra_app/widgets/costume_motion_painter.dart';

import 'render_costume_motion_previews_test.dart' as preview;

const reviewRoot =
    'design/seasonal/2026-halloween-dia-de-muertos/motion-v3-anatomy';
const repairedRoles = [
  ('capybara', 'positive'),
  ('rabbit', 'positive'),
  ('raccoon', 'success'),
  ('alpaca', 'positive'),
  ('maltese', 'positive'),
  ('poodle', 'positive'),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'render repaired limb anatomy at enlarged scale and in motion',
    () async {
      await (FontLoader(
        'PixelifySans',
      )..addFont(rootBundle.load('assets/fonts/PixelifySans.ttf'))).load();
      await Directory('$reviewRoot/frames').create(recursive: true);
      final textures = <String, ui.Image>{};
      for (final (id, role) in repairedRoles) {
        final atlas = costumeMotionAtlases[id]![role]!;
        textures[id] = await preview.texture(atlas.asset);
        final recorder = ui.PictureRecorder();
        final canvas = ui.Canvas(recorder);
        canvas.drawColor(const ui.Color(0xfffffaf2), ui.BlendMode.src);
        preview.label(
          canvas,
          '${id.toUpperCase()} / ${role.toUpperCase()} / ANATOMY REVIEW',
          const ui.Offset(12, 6),
          size: 20,
        );
        for (var frame = 0; frame < atlas.frameCount; frame++) {
          final x = frame % 4 * 256.0, y = 34.0 + frame ~/ 4 * 310;
          preview.label(canvas, 'FRAME ${frame + 1}', ui.Offset(x + 10, y));
          canvas.save();
          canvas.translate(x, y + 20);
          CostumeMotionPainter(
            image: textures[id],
            atlas: atlas,
            idleAtlas: costumeMotionAtlases[id]!['idle']!,
            frame: frame,
          ).paint(canvas, const ui.Size(256, 288));
          canvas.restore();
        }
        await preview.saveFrame(
          recorder,
          1024,
          964,
          '$reviewRoot/$id-$role.png',
        );
      }
      for (var tick = 0; tick < 48; tick++) {
        final recorder = ui.PictureRecorder();
        final canvas = ui.Canvas(recorder);
        canvas.drawColor(const ui.Color(0xfffffaf2), ui.BlendMode.src);
        preview.label(
          canvas,
          'REPAIRED COSTUME ANATOMY / ACTUAL APP RENDERER',
          const ui.Offset(12, 8),
          size: 20,
        );
        for (var slot = 0; slot < repairedRoles.length; slot++) {
          final (id, role) = repairedRoles[slot];
          final atlas = costumeMotionAtlases[id]![role]!;
          final elapsed = tick * 100;
          final progress = atlas.loop
              ? (elapsed % atlas.durationMs) / atlas.durationMs
              : (elapsed / atlas.durationMs).clamp(0.0, 1.0);
          final frame = (progress * atlas.frameCount).floor().clamp(
            0,
            atlas.frameCount - 1,
          );
          final x = slot % 3 * 280.0, y = 40.0 + slot ~/ 3 * 340;
          preview.label(
            canvas,
            '${id.toUpperCase()} / ${role.toUpperCase()}',
            ui.Offset(x + 10, y),
          );
          canvas.save();
          canvas.translate(x, y + 20);
          CostumeMotionPainter(
            image: textures[id],
            atlas: atlas,
            idleAtlas: costumeMotionAtlases[id]!['idle']!,
            frame: frame,
          ).paint(canvas, const ui.Size(280, 315));
          canvas.restore();
        }
        await preview.saveFrame(
          recorder,
          840,
          720,
          '$reviewRoot/frames/${tick.toString().padLeft(3, '0')}.png',
        );
      }
      for (final texture in textures.values) {
        texture.dispose();
      }
    },
    timeout: const Timeout(Duration(minutes: 4)),
  );
}
