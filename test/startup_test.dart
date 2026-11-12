import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sobra_app/l10n/generated/app_localizations.dart';
import 'package:sobra_app/main.dart' as application;
import 'package:sobra_app/models/language.dart';
import 'package:sobra_app/screens/startup_screen.dart';
import 'package:sobra_app/screens/welcome_screen.dart';
import 'package:sobra_app/startup.dart';
import 'package:sobra_app/services/startup_launch.dart';
import 'package:sobra_app/theme/app_theme.dart';
import 'package:sobra_app/widgets/coin_loading_animation.dart';
import 'package:sobra_app/widgets/coin_loading_timeline.dart';

import 'support/localizations.dart';

void main() {
  Future<void> warmArt(WidgetTester tester) async {
    await tester.runAsync(
      () => precacheImage(
        const AssetImage(CoinLoadingAnimation.asset),
        tester.element(find.byType(StartupScreen)),
      ),
    );
    await tester.pump();
  }

  void viewport(WidgetTester tester, Size size) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets(
    'the real entry point reaches welcome after local initialization',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      final messenger = tester.binding.defaultBinaryMessenger;
      for (final name in [
        'com.sobra.app/widgets',
        'com.sobra.app/quick_entry',
        'plugins.flutter.io/path_provider',
      ]) {
        final channel = MethodChannel(name);
        messenger.setMockMethodCallHandler(channel, (call) async => null);
        addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
      }
      application.main();
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        if (find.byType(WelcomeScreen).evaluate().isNotEmpty) break;
      }
      expect(
        find.byType(WelcomeScreen),
        findsOneWidget,
        reason: tester
            .widgetList<Text>(find.byType(Text))
            .map((t) => t.data)
            .join(' | '),
      );
      expect(find.byType(StartupScreen), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      debugDefaultTargetPlatformOverride = null;
    },
  );

  testWidgets(
    'shows loading before initialization and never waits for animation',
    (tester) async {
      final ready = Completer<Widget>();
      var attempts = 0;
      await tester.pumpWidget(
        SobraStartup(
          initialize: (_) {
            attempts++;
            return ready.future;
          },
        ),
      );
      expect(find.byType(StartupScreen), findsOneWidget);
      expect(find.bySemanticsLabel('Loading…'), findsOneWidget);
      expect(attempts, 1);
      await warmArt(tester);
      await tester.pump(const Duration(milliseconds: 100));
      ready.complete(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Text('Ready ledger'),
        ),
      );
      await tester.pump();
      expect(find.text('Ready ledger'), findsOneWidget);
      expect(find.byType(StartupScreen), findsNothing);
      await tester.pump(const Duration(seconds: 4));
      expect(attempts, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('a first frame with no window size still hands over cleanly', (
    tester,
  ) async {
    // Android can draw the first frame before the window is laid out, so
    // the loading screen is built at 0×0 and only then at the real size.
    tester.view.physicalSize = Size.zero;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final ready = Completer<Widget>();
    await tester.pumpWidget(SobraStartup(initialize: (_) => ready.future));
    expect(tester.takeException(), isNull);

    tester.view.physicalSize = const Size(392, 785);
    await tester.pump();
    expect(find.byType(StartupScreen), findsOneWidget);
    ready.complete(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Text('Ready ledger'),
      ),
    );
    await tester.pump();
    expect(find.text('Ready ledger'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('saved language and reduced motion apply while still loading', (
    tester,
  ) async {
    late ValueChanged<StartupPreferences> preferences;
    final ready = Completer<Widget>();
    await tester.pumpWidget(
      SobraStartup(
        initialize: (onReady) {
          preferences = onReady;
          return ready.future;
        },
      ),
    );
    preferences((languageCode: 'ko', reducedMotion: true));
    await tester.pump();
    expect(find.bySemanticsLabel('불러오는 중…'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(
      tester
          .widget<CoinLoadingAnimation>(find.byType(CoinLoadingAnimation))
          .reducedMotion,
      isTrue,
    );
    await warmArt(tester);
    await tester.pumpAndSettle();
    expect(tester.binding.hasScheduledFrame, isFalse);
    await tester.pumpWidget(const SizedBox.shrink());
    ready.complete(const SizedBox.shrink());
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('initialization failure has a working retry', (tester) async {
    final first = Completer<Widget>();
    final second = Completer<Widget>();
    var attempts = 0;
    await tester.pumpWidget(
      SobraStartup(
        initialize: (_) => ++attempts == 1 ? first.future : second.future,
      ),
    );
    first.completeError(StateError('unavailable'));
    await tester.pump();
    expect(
      find.text('We couldn’t open Sobrita.\nPlease try again.'),
      findsOneWidget,
    );
    expect(find.byType(LinearProgressIndicator), findsNothing);
    await tester.tap(find.text('Try again'));
    await tester.pump();
    expect(attempts, 2);
    expect(find.bySemanticsLabel('Loading…'), findsOneWidget);
    second.complete(const SizedBox(key: ValueKey('recovered')));
    await tester.pump();
    expect(find.byKey(const ValueKey('recovered')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('coin lands, pauses, retrieves the next coin, then wraps', () {
    expect(CoinLoadingAnimation.frameAt(Duration.zero), 0);
    expect(CoinLoadingAnimation.frameAt(const Duration(milliseconds: 800)), 5);
    expect(CoinLoadingAnimation.frameAt(const Duration(milliseconds: 1500)), 9);
    expect(
      CoinLoadingAnimation.frameAt(const Duration(milliseconds: 2499)),
      11,
    );
    expect(
      CoinLoadingAnimation.frameAt(const Duration(milliseconds: 2500)),
      12,
    );
    expect(
      CoinLoadingAnimation.frameAt(const Duration(milliseconds: 2900)),
      15,
    );
    expect(
      CoinLoadingAnimation.frameAt(const Duration(milliseconds: 3399)),
      19,
    );
    expect(CoinLoadingAnimation.frameAt(CoinLoadingAnimation.duration), 0);
    expect(CoinLoadingAnimation.frameAt(const Duration(milliseconds: 4200)), 5);
    expect(CoinLoadingAnimation.frameAt(const Duration(milliseconds: 8300)), 9);
  });

  testWidgets('last and first atlas poses have identical pixels at the seam', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final data = await rootBundle.load(CoinLoadingAnimation.asset);
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final image = (await codec.getNextFrame()).image;
      try {
        final pixels = (await image.toByteData())!.buffer.asUint8List();
        final width = image.width ~/ CoinLoadingTimeline.columns;
        final height = image.height ~/ CoinLoadingTimeline.rows;
        final last = CoinLoadingTimeline.frameEnds.length - 1;
        for (var y = 0; y < height; y++) {
          final firstOffset = y * image.width * 4;
          final lastOffset =
              ((last ~/ CoinLoadingTimeline.columns * height + y) *
                      image.width +
                  last % CoinLoadingTimeline.columns * width) *
              4;
          expect(
            listEquals(
              pixels.sublist(firstOffset, firstOffset + width * 4),
              pixels.sublist(lastOffset, lastOffset + width * 4),
            ),
            isTrue,
            reason: 'The loop must not visibly jump at row $y.',
          );
        }
      } finally {
        image.dispose();
        codec.dispose();
      }
    });
  });

  testWidgets('pending startup keeps cycling and ready stops it immediately', (
    tester,
  ) async {
    final ready = Completer<Widget>();
    await tester.pumpWidget(SobraStartup(initialize: (_) => ready.future));
    await warmArt(tester);
    CustomPainter pose() => tester
        .widget<CustomPaint>(
          find.descendant(
            of: find.byType(CoinLoadingAnimation),
            matching: find.byType(CustomPaint),
          ),
        )
        .painter!;

    await tester.pump(const Duration(milliseconds: 800));
    final deposited = pose();
    await tester.pump(CoinLoadingAnimation.duration);
    expect(pose().shouldRepaint(deposited), isFalse);
    expect(tester.binding.hasScheduledFrame, isTrue);
    await tester.pump(const Duration(milliseconds: 700));
    final proud = pose();
    expect(proud.shouldRepaint(deposited), isTrue);
    await tester.pump(CoinLoadingAnimation.duration);
    expect(pose().shouldRepaint(proud), isFalse);
    expect(tester.binding.hasScheduledFrame, isTrue);

    ready.complete(const SizedBox(key: ValueKey('ready-after-loops')));
    await tester.pump();
    await tester.pump();
    expect(find.byKey(const ValueKey('ready-after-loops')), findsOneWidget);
    expect(find.byType(CoinLoadingAnimation), findsNothing);
    expect(tester.binding.hasScheduledFrame, isFalse);
    expect(tester.takeException(), isNull);
  });

  for (final fails in [false, true]) {
    testWidgets(
      'native splash releases after the ${fails ? 'error' : 'ready'} frame',
      (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        addTearDown(() => debugDefaultTargetPlatformOverride = null);
        final ready = Completer<Widget>();
        final native = Completer<Map<String, Object?>>();
        var releases = 0;
        final messenger = tester.binding.defaultBinaryMessenger;
        messenger.setMockMethodCallHandler(StartupLaunch.channel, (call) async {
          if (call.method == 'read') return native.future;
          if (call.method == 'release') {
            releases++;
            // The opaque native surface must never cover retry or be removed
            // before the actual destination has been laid out.
            expect(
              fails ? find.text('Try again') : find.text('Ready ledger'),
              findsOneWidget,
            );
          }
          return null;
        });
        addTearDown(
          () => messenger.setMockMethodCallHandler(StartupLaunch.channel, null),
        );
        viewport(tester, const Size(390, 844));
        await tester.pumpWidget(SobraStartup(initialize: (_) => ready.future));
        native.complete({
          'centerX': 195.0,
          'centerY': 410.0,
          'size': 144.0,
          'startedAt': DateTime.now()
              .subtract(const Duration(seconds: 4))
              .millisecondsSinceEpoch,
        });
        await tester.pump();
        await warmArt(tester);
        expect(releases, 0);
        expect(
          tester.getRect(find.byType(CoinLoadingAnimation)),
          const Rect.fromLTWH(123, 338, 144, 144),
        );
        expect(
          tester
              .widget<CoinLoadingAnimation>(find.byType(CoinLoadingAnimation))
              .startedAt,
          isNotNull,
        );
        if (fails) {
          ready.completeError(StateError('unavailable'));
        } else {
          ready.complete(
            const Directionality(
              textDirection: TextDirection.ltr,
              child: Text('Ready ledger'),
            ),
          );
        }
        await tester.pump();
        await tester.pump();
        expect(releases, 1);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        debugDefaultTargetPlatformOverride = null;
      },
    );
  }

  for (final (locale, size, textScale) in [
    ('ko', const Size(390, 844), 1.0),
    ('de', const Size(320, 568), 1.8),
    ('ja', const Size(740, 360), 1.3),
    ('fr', const Size(768, 1024), 1.0),
  ]) {
    testWidgets('$locale loading fits $size at $textScale text scale', (
      tester,
    ) async {
      viewport(tester, size);
      final boundaryKey = GlobalKey();
      if (Platform.environment['CAPTURE_STARTUP'] == '1' && locale == 'ko') {
        for (final (family, asset) in [
          ('PixelifySans', 'assets/fonts/PixelifySans.ttf'),
          ('SobraHangul', 'assets/fonts/SobraHangul-Bold.ttf'),
        ]) {
          await (FontLoader(family)..addFont(rootBundle.load(asset))).load();
        }
      }
      await tester.pumpWidget(
        MaterialApp(
          locale: Locale(locale),
          supportedLocales: SobraLanguage.supportedLocales,
          localizationsDelegates: sobraLocalizationsDelegates,
          theme: buildSobraTheme(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(textScale),
              disableAnimations: true,
            ),
            child: child!,
          ),
          home: RepaintBoundary(key: boundaryKey, child: const StartupScreen()),
        ),
      );
      await warmArt(tester);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(tester.binding.hasScheduledFrame, isFalse);
      expect(find.byType(CoinLoadingAnimation), findsOneWidget);
      final l10n = AppLocalizations.of(
        tester.element(find.byType(StartupScreen)),
      );
      expect(find.bySemanticsLabel(l10n.startupLoading), findsOneWidget);
      expect(
        tester.getSize(find.byType(CoinLoadingAnimation)),
        const Size.square(144),
      );
      expect(
        tester.getCenter(find.byType(CoinLoadingAnimation)),
        Offset(size.width / 2, size.height / 2),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Optional real-widget captures for visual review, not golden assertions.
      if (Platform.environment['CAPTURE_STARTUP'] == '1' && locale == 'ko') {
        await tester.runAsync(() async {
          final boundary =
              boundaryKey.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          final image = await boundary.toImage(pixelRatio: 2);
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          final output = File(
            'output/startup-unified-cat-20261109/flutter-startup.png',
          );
          await output.parent.create(recursive: true);
          await output.writeAsBytes(data!.buffer.asUint8List());
          image.dispose();
        });
      }
    });
  }
}
