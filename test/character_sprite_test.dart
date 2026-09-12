import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sobra_app/widgets/cat_sprite.dart';

import 'support/localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('all Michi roles follow the normalized sprite contract', () async {
    expect(CharacterMotionRole.values, hasLength(6));

    for (final role in CharacterMotionRole.values) {
      final asset = CharacterCatalog.michi.assetFor(role);
      final motion = CharacterCatalog.michi.motionFor(role);
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

      if (role == CharacterMotionRole.activity ||
          role == CharacterMotionRole.processing ||
          role == CharacterMotionRole.positive) {
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
      () => CharacterCatalog.require('poodle'),
      throwsA(
        isA<FlutterError>().having(
          (error) => error.message,
          'message',
          contains('poodle'),
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
