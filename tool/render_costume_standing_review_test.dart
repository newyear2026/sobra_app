// Review the upright rabbit/raccoon using the production costume painter.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sobra_app/data/costume_motion_atlases.dart';
import 'package:sobra_app/widgets/costume_motion_painter.dart';

import 'render_costume_motion_previews_test.dart' as preview;

const handReview = bool.fromEnvironment('COSTUME_HAND_REVIEW');
const reviewRoot = String.fromEnvironment(
  'COSTUME_REVIEW_ROOT',
  defaultValue: handReview
      ? 'design/seasonal/2026-halloween-dia-de-muertos/motion-v5-rabbit-limbs/review'
      : 'design/seasonal/2026-halloween-dia-de-muertos/motion-v4-standing',
);
const characters = handReview ? ['rabbit'] : ['raccoon', 'rabbit'];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'render upright anatomy and actual playback for both costumes',
    () async {
      await (FontLoader(
        'PixelifySans',
      )..addFont(rootBundle.load('assets/fonts/PixelifySans.ttf'))).load();
      await Directory('$reviewRoot/frames').create(recursive: true);
      final textures = <String, Map<String, ui.Image>>{};
      for (final id in characters) {
        textures[id] = {};
        for (final role in preview.roles) {
          final atlas = costumeMotionAtlases[id]![role]!;
          textures[id]![role] = await preview.texture(atlas.asset);
          final recorder = ui.PictureRecorder();
          final canvas = ui.Canvas(recorder);
          canvas.drawColor(const ui.Color(0xfffffaf2), ui.BlendMode.src);
          preview.label(
            canvas,
            '${id.toUpperCase()} / ${role.toUpperCase()} / SOURCE FRAMES',
            const ui.Offset(12, 6),
            size: 20,
          );
          for (var frame = 0; frame < atlas.frameCount; frame++) {
            final x = frame % 4 * 256.0, y = 34.0 + frame ~/ 4 * 310;
            preview.label(canvas, 'FRAME ${frame + 1}', ui.Offset(x + 10, y));
            canvas.save();
            canvas.translate(x, y + 20);
            // Leave landingImage unset here to expose every generated source pose.
            CostumeMotionPainter(
              image: textures[id]![role],
              atlas: atlas,
              idleAtlas: costumeMotionAtlases[id]!['idle']!,
              frame: frame,
            ).paint(canvas, const ui.Size(256, 288));
            canvas.restore();
          }
          await preview.saveFrame(
            recorder,
            1024,
            34 + (atlas.frameCount ~/ 4) * 310,
            '$reviewRoot/$id-$role.png',
          );
        }
      }

      // Show the exact reported actions so rejected candidates are never used
      // as the user's preview of the final bundled artwork.
      const actions = handReview
          ? [('rabbit', 'activity'), ('rabbit', 'processing')]
          : [('raccoon', 'success'), ('rabbit', 'positive')];
      for (var tick = 0; tick < 48; tick++) {
        final recorder = ui.PictureRecorder();
        final canvas = ui.Canvas(recorder);
        canvas.drawColor(const ui.Color(0xfffffaf2), ui.BlendMode.src);
        preview.label(
          canvas,
          handReview
              ? 'RABBIT / FINAL BUNDLED WALKING AND CALCULATOR'
              : 'UPRIGHT COSTUMES / ACTUAL APP PLAYBACK',
          const ui.Offset(12, 8),
          size: 20,
        );
        for (var slot = 0; slot < actions.length; slot++) {
          final (id, role) = actions[slot];
          final atlas = costumeMotionAtlases[id]![role]!;
          final elapsed = tick * 100;
          final progress = atlas.loop
              ? (elapsed % atlas.durationMs) / atlas.durationMs
              : (elapsed / atlas.durationMs).clamp(0.0, 1.0);
          final frame = (progress * atlas.frameCount).floor().clamp(
            0,
            atlas.frameCount - 1,
          );
          final x = slot * 320.0;
          preview.label(
            canvas,
            '${id.toUpperCase()} / ${role.toUpperCase()}',
            ui.Offset(x + 12, 40),
            size: 18,
          );
          canvas.save();
          canvas.translate(x, 60);
          CostumeMotionPainter(
            image: textures[id]![role],
            landingImage: textures[id]!['idle'],
            atlas: atlas,
            idleAtlas: costumeMotionAtlases[id]!['idle']!,
            frame: frame,
          ).paint(canvas, const ui.Size(320, 360));
          canvas.restore();
        }
        await preview.saveFrame(
          recorder,
          640,
          420,
          '$reviewRoot/frames/${tick.toString().padLeft(3, '0')}.png',
        );
      }

      if (handReview) {
        final recorder = ui.PictureRecorder();
        final canvas = ui.Canvas(recorder);
        canvas.drawColor(const ui.Color(0xfffffaf2), ui.BlendMode.src);
        const frames = [4, 5, 6];
        const labels = [
          'RIGHT PAW / TAP',
          'SAME RIGHT PAW / CHIN',
          'RIGHT PAW / RETURN',
        ];
        final atlas = costumeMotionAtlases['rabbit']!['processing']!;
        for (var slot = 0; slot < frames.length; slot++) {
          final x = slot * 320.0;
          preview.label(canvas, labels[slot], ui.Offset(x + 12, 12), size: 18);
          canvas.save();
          canvas.translate(x, 40);
          CostumeMotionPainter(
            image: textures['rabbit']!['processing'],
            atlas: atlas,
            idleAtlas: costumeMotionAtlases['rabbit']!['idle']!,
            frame: frames[slot],
          ).paint(canvas, const ui.Size(320, 360));
          canvas.restore();
        }
        await preview.saveFrame(
          recorder,
          960,
          400,
          '$reviewRoot/right-arm-path.png',
        );
      }

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      canvas.drawColor(const ui.Color(0xfffffaf2), ui.BlendMode.src);
      for (var slot = 0; slot < characters.length; slot++) {
        final id = characters[slot], atlas = costumeMotionAtlases[id]!['idle']!;
        final x = slot * 320.0;
        preview.label(
          canvas,
          '${id.toUpperCase()} / STANDING IDLE',
          ui.Offset(x + 12, 12),
          size: 18,
        );
        canvas.save();
        canvas.translate(x, 40);
        CostumeMotionPainter(
          image: textures[id]!['idle'],
          atlas: atlas,
          idleAtlas: atlas,
          frame: 0,
        ).paint(canvas, const ui.Size(320, 360));
        canvas.restore();
      }
      await preview.saveFrame(
        recorder,
        characters.length * 320,
        400,
        '$reviewRoot/standing-poses.png',
      );
      for (final roles in textures.values) {
        for (final image in roles.values) {
          image.dispose();
        }
      }
    },
    timeout: const Timeout(Duration(minutes: 4)),
  );
}
