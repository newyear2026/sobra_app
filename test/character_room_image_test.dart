import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sobra_app/main.dart';
import 'package:sobra_app/models/pay_schedule.dart';
import 'package:sobra_app/models/room_design.dart';
import 'package:sobra_app/screens/app_shell.dart';
import 'package:sobra_app/state/sobra_store.dart';
import 'package:sobra_app/theme/app_theme.dart';
import 'package:sobra_app/widgets/character_room.dart';
import 'package:sobra_app/widgets/room_scene.dart';

import 'support/localizations.dart';

/// Decoding the room whole costs this much, and it is what the widget must
/// never spend: the card paints into 1,440 px at the very widest.
const int fullDecodeBytes = 1536 * 1024 * 4;

Widget _roomHarness({String? asset}) => MaterialApp(
  theme: buildSobraTheme(),
  home: Scaffold(
    body: Center(
      child: SizedBox(
        width: 320,
        child: CharacterRoom(
          message: 'Vas muy bien',
          characterBuilder: (_) => const SizedBox.shrink(),
          backgroundAsset: asset ?? CharacterRoom.casaClaraBackgroundAsset,
        ),
      ),
    ),
  ),
);

void main() {
  setUp(() => PaintingBinding.instance.imageCache.clear());

  group('background decode size', () {
    testWidgets('is sized to the screen, not to the art', (tester) async {
      useSpanishDevice(tester);
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_roomHarness());
      await tester.runAsync(
        () => precacheImage(
          CharacterRoom.backgroundProvider(
            tester.element(find.byType(CharacterRoom)),
          ),
          tester.element(find.byType(CharacterRoom)),
        ),
      );
      await tester.pump();

      // 360dp screen at 3x, so min(360, 480) * 3 = 1080 px wide, and the art
      // is 3:2, so the 1080 px decode is 720 px tall.
      expect(
        PaintingBinding.instance.imageCache.currentSizeBytes,
        1080 * 720 * 4,
      );
      expect(
        PaintingBinding.instance.imageCache.currentSizeBytes,
        lessThan(fullDecodeBytes),
      );
    });

    testWidgets('the widget itself asks for that same decode', (tester) async {
      useSpanishDevice(tester);
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // Nothing precached here, so whatever lands in the cache is what the
      // room itself asked for.
      await tester.runAsync(() async {
        await tester.pumpWidget(_roomHarness());
        await tester.pump();
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pump();

      expect(
        PaintingBinding.instance.imageCache.currentSizeBytes,
        1080 * 720 * 4,
      );
    });
  });

  group('backgroundProvider', () {
    Future<int?> widthFor(
      WidgetTester tester, {
      required double logicalWidth,
      required double dpr,
    }) async {
      tester.view.physicalSize = Size(logicalWidth * dpr, 800 * dpr);
      tester.view.devicePixelRatio = dpr;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(_roomHarness());
      final provider = CharacterRoom.backgroundProvider(
        tester.element(find.byType(CharacterRoom)),
      );
      return provider is ResizeImage ? provider.width : null;
    }

    testWidgets('follows the device pixel ratio', (tester) async {
      useSpanishDevice(tester);
      expect(await widthFor(tester, logicalWidth: 360, dpr: 3), 1080);
      expect(await widthFor(tester, logicalWidth: 360, dpr: 2), 720);
    });

    testWidgets('stops growing once the shell caps the layout', (tester) async {
      useSpanishDevice(tester);
      // The shell never lays the room out wider than 480, so a tablet must
      // not pay for a bigger decode than a large phone.
      expect(await widthFor(tester, logicalWidth: 430, dpr: 3), 1290);
      expect(await widthFor(tester, logicalWidth: 520, dpr: 3), 1440);
      expect(await widthFor(tester, logicalWidth: 1000, dpr: 3), 1440);
    });

    testWidgets('never asks for more pixels than the art has', (tester) async {
      useSpanishDevice(tester);
      expect(
        await widthFor(tester, logicalWidth: 800, dpr: 4),
        CharacterRoom.backgroundNativeWidth,
      );
    });
  });

  testWidgets('the background keeps the default mipmapped filter', (
    tester,
  ) async {
    useSpanishDevice(tester);
    await tester.pumpWidget(_roomHarness());
    await tester.pump();

    final image = tester.widget<Image>(find.byKey(CharacterRoom.backgroundKey));
    // `low` is a plain bilinear that aliases below half scale, and the room
    // is drawn at 0.54x to 0.81x. Only the default carries mipmaps.
    expect(image.filterQuality, FilterQuality.medium);
  });

  testWidgets('a missing background leaves the scene standing', (tester) async {
    useSpanishDevice(tester);
    await tester.pumpWidget(_roomHarness(asset: 'assets/rooms/nope.webp'));
    await tester.pump();
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(CharacterRoom), findsOneWidget);
    expect(find.text('Vas muy bien'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(CharacterRoom.backgroundKey),
        matching: find.byType(ColoredBox),
      ),
      findsOneWidget,
    );
  });

  testWidgets('the shell warms the hybrid room layers', (tester) async {
    useSpanishDevice(tester);
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({});
    final store = await SobraStore.load(now: () => DateTime(2026, 9, 8, 10));
    await store.configureOnboarding(
      budgetCentavos: 600000,
      schedule: const PaySchedule.semiMonthly(),
    );
    await store.completeOnboarding();

    await tester.runAsync(() async {
      await tester.pumpWidget(SobraApp(store: store));
      await tester.pump();
      // Let the shell's warm-up land.
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pump();

    expect(find.byType(RoomScene), findsOneWidget);

    final context = tester.element(find.byType(AppShell));
    const provider = AssetImage(RoomThemes.casaClaraPreviewAsset);
    final key = await provider.obtainKey(
      createLocalImageConfiguration(context),
    );
    expect(PaintingBinding.instance.imageCache.containsKey(key), isTrue);
  });
}
