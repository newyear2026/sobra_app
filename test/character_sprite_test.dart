import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sobra_app/widgets/cat_sprite.dart';

import 'support/localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final id in [
    'michi',
    'poodle',
    'schnauzer',
    'guinea-pig',
    'capybara',
    'alpaca',
    'platypus',
  ]) {
    testWidgets('$id dialog reserves the full enlarged motion bounds', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: sobraLocalizationsDelegates,
          supportedLocales: sobraSupportedLocales,
          home: Center(
            child: CatSprite(
              characterId: id,
              motion: CatMotion.celebrate,
              width: 142,
              animate: false,
              reserveMotionSpace: true,
            ),
          ),
        ),
      );
      final wrapper = tester.renderObject<RenderBox>(find.byType(CatSprite));
      final painterFinder = find.descendant(
        of: find.byType(CharacterSprite),
        matching: find.byType(CustomPaint),
      );
      final painter = tester.renderObject<RenderBox>(painterFinder);
      final motion = CharacterCatalog.require(
        id,
      ).motionFor(CharacterMotionRole.success);
      for (var i = 0; i < motion.frameCount; i++) {
        final offset = motion.frameOffsets.isEmpty
            ? 0.0
            : motion.frameOffsets[i];
        final bounds = MatrixUtils.transformRect(
          painter.getTransformTo(wrapper),
          Rect.fromLTWH(
            0,
            offset * 142 / 320,
            painter.size.width,
            painter.size.height,
          ),
        );
        expect(bounds.left, greaterThanOrEqualTo(-0.001));
        expect(bounds.top, greaterThanOrEqualTo(-0.001));
        expect(bounds.right, lessThanOrEqualTo(wrapper.size.width + 0.001));
        expect(bounds.bottom, lessThanOrEqualTo(wrapper.size.height + 0.001));
      }
    });
  }

  test('settled celebration matches idle height for every companion', () async {
    for (final character in CharacterCatalog.all.values) {
      final heights = <double>[];
      for (final role in [
        CharacterMotionRole.idle,
        CharacterMotionRole.success,
      ]) {
        final motion = character.motionFor(role);
        final index = role == CharacterMotionRole.idle
            ? motion.playbackSpec.posterFrame
            : motion.playbackSpec.completionFrame;
        final bytes = await rootBundle.load(character.assetFor(role));
        final codec = await ui.instantiateImageCodec(
          bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
        );
        final frame = await codec.getNextFrame();
        final pixels = (await frame.image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        ))!;
        var top = 360;
        var bottom = 0;
        for (var y = 0; y < 360; y++) {
          for (var x = 0; x < 320; x++) {
            if (pixels.getUint8(
                  (y * frame.image.width + index * 320 + x) * 4 + 3,
                ) <
                96) {
              continue;
            }
            if (y < top) top = y;
            bottom = y + 1;
          }
        }
        heights.add((bottom - top) * motion.displayScale);
        frame.image.dispose();
        codec.dispose();
      }
      expect(heights[1] / heights[0], closeTo(1, 0.02), reason: character.id);
    }
  });

  test('all character roles follow the normalized sprite contract', () async {
    expect(CharacterMotionRole.values, hasLength(6));

    for (final character in CharacterCatalog.all.values) {
      for (final role in CharacterMotionRole.values) {
        final asset = character.assetFor(role);
        final motion = character.motionFor(role);
        final bytes = await rootBundle.load(asset);
        final codec = await ui.instantiateImageCodec(
          bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
        );
        final frame = await codec.getNextFrame();

        expect(
          frame.image.width,
          CharacterAnimationStandard.frameWidth.toInt() * motion.frameCount,
          reason: asset,
        );
        expect(
          frame.image.height,
          CharacterAnimationStandard.frameHeight.toInt(),
          reason: asset,
        );

        if ((role == CharacterMotionRole.activity ||
                role == CharacterMotionRole.processing ||
                role == CharacterMotionRole.positive) &&
            motion.frameOffsets.isNotEmpty) {
          expect(motion.frameOffsets, hasLength(motion.frameCount));
          final pixels = (await frame.image.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          ))!;
          for (var index = 0; index < motion.frameCount; index++) {
            var bottom = 0;
            for (var y = 0; y < 360; y++) {
              var opaque = 0;
              for (var x = 0; x < 320; x++) {
                final offset = (y * frame.image.width + index * 320 + x) * 4;
                if (pixels.getUint8(offset + 3) > 192) opaque++;
              }
              if (opaque >= 8) bottom = y + 1;
            }
            expect(
              bottom + motion.frameOffsets[index],
              344,
              reason: '$asset frame $index must remain grounded',
            );
          }
        }

        frame.image.dispose();
        codec.dispose();
      }
    }
  });

  test('legacy cat motions map one-to-one to semantic roles', () {
    expect(CatMotion.values, hasLength(CharacterMotionRole.values.length));
    expect(CatMotion.idle.role, CharacterMotionRole.idle);
    expect(CatMotion.walk.role, CharacterMotionRole.activity);
    expect(CatMotion.calculate.role, CharacterMotionRole.processing);
    expect(CatMotion.saving.role, CharacterMotionRole.positive);
    expect(CatMotion.celebrate.role, CharacterMotionRole.success);
    expect(CatMotion.concern.role, CharacterMotionRole.warning);
  });

  test('Michi owns a complete character-specific motion definition', () {
    expect(CharacterCatalog.all, containsPair('michi', CharacterCatalog.michi));
    expect(
      CharacterCatalog.michi.motions.keys.toSet(),
      CharacterMotionRole.values.toSet(),
    );
    expect(
      CharacterCatalog.michi.motionFor(CharacterMotionRole.success).defaultLoop,
      isFalse,
    );
    expect(
      CharacterCatalog.michi
          .motionFor(CharacterMotionRole.success)
          .playbackSpec
          .holdFrame,
      11,
    );
    expect(
      CharacterCatalog.michi.motions.values
          .where((motion) => motion.frameCount == 12)
          .length,
      4,
    );
  });

  test('Poodle owns the same six-role motion definition', () {
    expect(
      CharacterCatalog.all,
      containsPair('poodle', CharacterCatalog.poodle),
    );
    expect(
      CharacterCatalog.poodle.motions.keys.toSet(),
      CharacterMotionRole.values.toSet(),
    );
    expect(
      CharacterCatalog.poodle
          .motionFor(CharacterMotionRole.success)
          .defaultLoop,
      isFalse,
    );
    expect(
      CharacterCatalog.poodle
          .motionFor(CharacterMotionRole.success)
          .displayScale,
      1.45,
    );
    expect(
      CharacterCatalog.poodle
          .motionFor(CharacterMotionRole.activity)
          .displayScale,
      1,
    );
  });

  test('Schnauzer owns six motions with a stable final celebration pose', () {
    expect(
      CharacterCatalog.schnauzer.motions.keys.toSet(),
      CharacterMotionRole.values.toSet(),
    );
    for (final role in CharacterMotionRole.values) {
      final expectedFrames = switch (role) {
        CharacterMotionRole.idle || CharacterMotionRole.warning => 8,
        _ => 12,
      };
      expect(
        CharacterCatalog.schnauzer.motionFor(role).frameCount,
        expectedFrames,
        reason: role.name,
      );
    }
    final success = CharacterCatalog.schnauzer.motionFor(
      CharacterMotionRole.success,
    );
    expect(success.defaultLoop, isFalse);
    expect(success.playbackSpec.completionFrame, 11);
    expect(success.displayScale, 1);
  });

  test('Guinea Pig owns all six normalized motions', () {
    expect(
      CharacterCatalog.all,
      containsPair('guinea-pig', CharacterCatalog.guineaPig),
    );
    expect(
      CharacterCatalog.guineaPig.motions.keys.toSet(),
      CharacterMotionRole.values.toSet(),
    );
    for (final role in CharacterMotionRole.values) {
      expect(
        CharacterCatalog.guineaPig.motionFor(role).frameCount,
        role == CharacterMotionRole.idle || role == CharacterMotionRole.warning
            ? 8
            : 12,
        reason: role.name,
      );
    }
    expect(
      CharacterCatalog.guineaPig
          .motionFor(CharacterMotionRole.success)
          .playbackSpec
          .completionFrame,
      11,
    );
  });

  test('Capybara owns all six normalized motions', () {
    expect(
      CharacterCatalog.all,
      containsPair('capybara', CharacterCatalog.capybara),
    );
    expect(
      CharacterCatalog.capybara.motions.keys.toSet(),
      CharacterMotionRole.values.toSet(),
    );
    for (final role in CharacterMotionRole.values) {
      expect(
        CharacterCatalog.capybara.motionFor(role).frameCount,
        role == CharacterMotionRole.idle || role == CharacterMotionRole.warning
            ? 8
            : 12,
        reason: role.name,
      );
    }
    expect(
      CharacterCatalog.capybara
          .motionFor(CharacterMotionRole.success)
          .playbackSpec
          .completionFrame,
      11,
    );
  });

  test('Platypus owns the complete eight- and twelve-frame motion pack', () {
    expect(
      CharacterCatalog.all,
      containsPair('platypus', CharacterCatalog.platypus),
    );
    expect(
      CharacterCatalog.platypus.motions.keys.toSet(),
      CharacterMotionRole.values.toSet(),
    );
    for (final role in CharacterMotionRole.values) {
      expect(
        CharacterCatalog.platypus.motionFor(role).frameCount,
        role == CharacterMotionRole.idle || role == CharacterMotionRole.warning
            ? 8
            : 12,
        reason: role.name,
      );
    }
    expect(
      CharacterCatalog.platypus
          .motionFor(CharacterMotionRole.success)
          .playbackSpec
          .completionFrame,
      11,
    );
  });

  testWidgets('Poodle success art scales from the grounded feet', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: sobraLocalizationsDelegates,
        supportedLocales: sobraSupportedLocales,
        home: CharacterSprite(
          characterId: 'poodle',
          role: CharacterMotionRole.success,
          animate: false,
        ),
      ),
    );

    final transform = tester.widget<Transform>(
      find.descendant(
        of: find.byType(CharacterSprite),
        matching: find.byType(Transform),
      ),
    );
    expect(transform.alignment, const Alignment(0, 2 * 344 / 360 - 1));
    expect(transform.transform.getMaxScaleOnAxis(), closeTo(1.45, 0.001));
  });

  test('CharacterSprite resolves assets and playback from its character', () {
    const sprite = CharacterSprite(
      characterId: 'michi',
      role: CharacterMotionRole.processing,
    );

    expect(
      sprite.motionSpec,
      same(CharacterCatalog.michi.motionFor(CharacterMotionRole.processing)),
    );
    expect(sprite.asset, endsWith('/michi/processing-12.png'));
    expect(sprite.motionSpec.frameCount, 12);
    expect(sprite.effectiveLoop, isTrue);
  });

  test('unregistered character ids fail with a clear error', () {
    expect(
      () => CharacterCatalog.require('unknown-character'),
      throwsA(
        isA<FlutterError>().having(
          (error) => error.message,
          'message',
          contains('unknown-character'),
        ),
      ),
    );
  });

  test('reduced motion resolves to each role poster frame', () {
    final motions = CharacterCatalog.michi;
    expect(
      motions
          .motionFor(CharacterMotionRole.processing)
          .playbackSpec
          .resolveFrame(progress: 0, animate: false, completed: false),
      7,
    );
    expect(
      motions
          .motionFor(CharacterMotionRole.positive)
          .playbackSpec
          .resolveFrame(progress: 0, animate: false, completed: false),
      8,
    );
    expect(
      motions
          .motionFor(CharacterMotionRole.success)
          .playbackSpec
          .resolveFrame(progress: 0, animate: false, completed: false),
      5,
    );
  });

  test('normal playback stays inside the configured frame range', () {
    final positive = CharacterCatalog.michi
        .motionFor(CharacterMotionRole.positive)
        .playbackSpec;

    expect(
      positive.resolveFrame(progress: 0, animate: true, completed: false),
      0,
    );
    expect(
      positive.resolveFrame(progress: 0.999, animate: true, completed: false),
      11,
    );
    expect(
      positive.resolveFrame(progress: 1, animate: true, completed: false),
      11,
    );
  });

  test('success holds its settled frame after one-shot completion', () {
    final success = CharacterCatalog.michi
        .motionFor(CharacterMotionRole.success)
        .playbackSpec;

    expect(
      success.resolveFrame(progress: 0.999, animate: true, completed: false),
      11,
    );
    expect(
      success.resolveFrame(progress: 1, animate: true, completed: true),
      11,
    );
  });

  testWidgets('legacy wrapper inherits role loop defaults', (tester) async {
    var completions = 0;

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: sobraLocalizationsDelegates,
        supportedLocales: sobraSupportedLocales,
        home: CatSprite(
          motion: CatMotion.celebrate,
          onComplete: () => completions += 1,
        ),
      ),
    );

    final success = tester.widget<CharacterSprite>(
      find.byType(CharacterSprite),
    );
    expect(success.loop, isNull);
    expect(success.effectiveLoop, isFalse);

    // Establish the ticker's start time before advancing the full duration.
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump(
      CharacterCatalog.michi.motionFor(CharacterMotionRole.success).duration,
    );
    expect(completions, 1);
    await tester.pump(const Duration(seconds: 1));
    expect(completions, 1);

    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: sobraLocalizationsDelegates,
        supportedLocales: sobraSupportedLocales,
        home: CatSprite(motion: CatMotion.idle),
      ),
    );
    final idle = tester.widget<CharacterSprite>(find.byType(CharacterSprite));
    expect(idle.loop, isNull);
    expect(idle.effectiveLoop, isTrue);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
