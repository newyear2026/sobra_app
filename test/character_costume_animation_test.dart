import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sobra_app/data/costume_motion_atlases.dart';
import 'package:sobra_app/models/character_costume.dart';
import 'package:sobra_app/widgets/cat_sprite.dart';
import 'package:sobra_app/widgets/costume_motion_painter.dart';

import 'support/localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'all twelve costumes have six genuine sequential animation atlases',
    () async {
      final native =
          jsonDecode(
                await rootBundle.loadString(
                  'assets/costumes/autumn_2026/motion_v2/layout.json',
                ),
              )
              as Map<String, dynamic>;
      expect(
        CharacterCostumes.all.map((costume) => costume.characterId).toSet(),
        CharacterCatalog.all.keys.toSet(),
      );
      expect(
        costumeMotionAtlases.keys.toSet(),
        CharacterCatalog.all.keys.toSet(),
      );
      var totalFrames = 0;
      for (final costume in CharacterCostumes.all) {
        final motions = costumeMotionAtlases[costume.characterId]!;
        expect(
          motions.keys.toSet(),
          CharacterMotionRole.values.map((role) => role.name).toSet(),
        );
        for (final role in CharacterMotionRole.values) {
          final atlas = motions[role.name]!;
          final data =
              native[costume.characterId][role.name] as Map<String, dynamic>;
          final expectedCount =
              role == CharacterMotionRole.idle ||
                  role == CharacterMotionRole.warning
              ? 8
              : 12;
          expect(
            atlas.frameCount,
            expectedCount,
            reason: '${costume.id}/${role.name}',
          );
          expect(atlas.asset, costume.motionAsset(role.name));
          expect(atlas.posterFrame, inInclusiveRange(0, expectedCount - 1));
          expect(
            atlas.loop,
            role != CharacterMotionRole.success &&
                role != CharacterMotionRole.warning,
          );
          expect(
            data['validation']['uniqueGeneratedFrames'],
            greaterThanOrEqualTo(expectedCount ~/ 2),
          );
          expect(data['validation']['requiresVisualReview'], isFalse);
          final bytes = await rootBundle.load(atlas.asset);
          final codec = await ui.instantiateImageCodec(
            bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
          );
          final image = (await codec.getNextFrame()).image;
          expect([image.width, image.height], data['size']);
          final pixels = (await image.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          ))!;
          var clearPixels = 0;
          for (var offset = 3; offset < pixels.lengthInBytes; offset += 4) {
            if (pixels.getUint8(offset) == 0) clearPixels++;
          }
          expect(clearPixels / (image.width * image.height), greaterThan(.12));
          for (var index = 0; index < expectedCount; index++) {
            final source = atlas.sources[index];
            final target = atlas.targets[index];
            expect(source.left, greaterThanOrEqualTo(0));
            expect(source.top, greaterThanOrEqualTo(0));
            expect(source.right, lessThanOrEqualTo(1.000001));
            expect(source.bottom, lessThanOrEqualTo(1.000001));
            expect(target.left, greaterThanOrEqualTo(15.99));
            expect(target.top, greaterThanOrEqualTo(15.99));
            expect(target.right, lessThanOrEqualTo(304.01));
            expect(target.bottom, lessThanOrEqualTo(344.01));
            for (final pair in [
              (
                [source.left, source.top, source.width, source.height],
                data['sources'][index],
              ),
              (
                [target.left, target.top, target.width, target.height],
                data['targets'][index],
              ),
            ]) {
              for (var axis = 0; axis < 4; axis++) {
                expect(
                  pair.$1[axis],
                  closeTo((pair.$2 as List<dynamic>)[axis] as num, 1e-7),
                );
              }
            }
            // Each source must actually contain the character, not a blank cell.
            final centerX = ((source.left + source.width / 2) * image.width)
                .floor();
            final centerY = ((source.top + source.height / 2) * image.height)
                .floor();
            var opaque = 0;
            for (var dy = -12; dy <= 12; dy++) {
              for (var dx = -12; dx <= 12; dx++) {
                final offset =
                    ((centerY + dy) * image.width + centerX + dx) * 4 + 3;
                if (pixels.getUint8(offset) > 96) opaque++;
              }
            }
            expect(
              opaque,
              greaterThan(50),
              reason: '${costume.id}/${role.name}/$index',
            );
          }
          if (atlas.loop) {
            expect(atlas.sources.last, atlas.sources.first);
            expect(atlas.targets.last, atlas.targets.first);
          }
          if (role == CharacterMotionRole.success) {
            expect(
              atlas.landingFrameStart,
              costume.characterId == 'raccoon' ? isNull : 10,
            );
            expect(
              atlas.targets[5].bottom,
              lessThan(atlas.targets.first.bottom - 15),
            );
          }
          totalFrames += expectedCount;
          image.dispose();
          codec.dispose();
        }
      }
      expect(totalFrames, 768);
    },
  );

  Widget preview({
    required CharacterMotionRole role,
    bool animate = true,
    int token = 0,
    VoidCallback? onComplete,
  }) => MaterialApp(
    localizationsDelegates: sobraLocalizationsDelegates,
    supportedLocales: sobraSupportedLocales,
    home: Center(
      child: CharacterSprite(
        characterId: 'michi',
        costumeId: 'autumn-2026-michi',
        role: role,
        animate: animate,
        playToken: token,
        onComplete: onComplete,
      ),
    ),
  );

  CostumeMotionPainter painter(WidgetTester tester) =>
      tester
              .widget<CustomPaint>(
                find.descendant(
                  of: find.byType(CharacterSprite),
                  matching: find.byType(CustomPaint),
                ),
              )
              .painter!
          as CostumeMotionPainter;

  testWidgets(
    'drawn frames advance and celebration lands on exact idle only once',
    (tester) async {
      await tester.pumpWidget(preview(role: CharacterMotionRole.idle));
      await tester.pump();
      final first = painter(tester).frame;
      await tester.pump(const Duration(milliseconds: 450));
      expect(painter(tester).frame, isNot(first));
      var completions = 0;
      await tester.pumpWidget(
        preview(
          role: CharacterMotionRole.success,
          onComplete: () => completions++,
        ),
      );
      await tester.pump(const Duration(seconds: 3));
      expect(completions, 1);
      expect(painter(tester).frame, 11);
      expect(painter(tester).isLanding, isTrue);
      expect(
        painter(tester).idleAtlas,
        same(costumeMotionAtlases['michi']!['idle']),
      );
      await tester.pump(const Duration(seconds: 3));
      expect(completions, 1);
      await tester.pumpWidget(
        preview(
          role: CharacterMotionRole.success,
          token: 1,
          onComplete: () => completions++,
        ),
      );
      expect(painter(tester).frame, 0);
      await tester.pump(const Duration(seconds: 3));
      expect(completions, 2);
    },
  );

  testWidgets('repaired raccoon holds its own reviewed landing frame', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: sobraLocalizationsDelegates,
        supportedLocales: sobraSupportedLocales,
        home: const Center(
          child: CharacterSprite(
            characterId: 'raccoon',
            costumeId: 'autumn-2026-raccoon',
            role: CharacterMotionRole.success,
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 3));
    expect(painter(tester).frame, 11);
    expect(painter(tester).isLanding, isFalse);
    expect(
      painter(tester).atlas,
      same(costumeMotionAtlases['raccoon']!['success']),
    );
  });

  testWidgets(
    'reduced motion freezes the proper worried representative frame',
    (tester) async {
      await tester.pumpWidget(
        preview(role: CharacterMotionRole.warning, animate: false),
      );
      final frame = painter(tester).frame;
      expect(frame, costumeMotionAtlases['michi']!['warning']!.posterFrame);
      await tester.pump(const Duration(seconds: 3));
      expect(painter(tester).frame, frame);
    },
  );

  test(
    'all costumes use independent role textures with the same playback contract',
    () {
      for (final costume in CharacterCostumes.all) {
        final assets = <String>{};
        for (final role in CharacterMotionRole.values) {
          final sprite = CharacterSprite(
            characterId: costume.characterId,
            costumeId: costume.id,
            role: role,
          );
          assets.add(sprite.asset);
          expect(
            sprite.motionSpec.frameCount,
            sprite.costumeMotion!.frameCount,
          );
          expect(
            sprite.motionSpec.playbackSpec.playRange.end,
            sprite.costumeMotion!.frameCount - 1,
          );
          expect(sprite.effectiveLoop, sprite.costumeMotion!.loop);
        }
        expect(assets, hasLength(6));
      }
      const foreign = CharacterSprite(
        characterId: 'michi',
        costumeId: 'autumn-2026-poodle',
        role: CharacterMotionRole.idle,
      );
      expect(foreign.costume, isNull);
      expect(foreign.asset, 'assets/characters/michi/idle-8.webp');
    },
  );

  test('costume atlases stay within the shipping size budget', () async {
    // Lossless sheets were 129 MB and would push the app past Play's download
    // cap. tool/package_costume_motion_assets.py ships q90 at about 32 MB.
    var totalBytes = 0;
    for (final motions in costumeMotionAtlases.values) {
      for (final atlas in motions.values) {
        totalBytes += (await rootBundle.load(atlas.asset)).lengthInBytes;
      }
    }
    expect(totalBytes, lessThan(40 * 1000 * 1000));
  });
}
