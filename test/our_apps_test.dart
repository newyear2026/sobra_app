import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sobra_app/data/our_apps.dart';
import 'package:sobra_app/l10n/generated/app_localizations.dart';
import 'package:sobra_app/main.dart';
import 'package:sobra_app/models/pay_schedule.dart';
import 'package:sobra_app/screens/our_apps_screen.dart';
import 'package:sobra_app/services/app_review_service.dart';
import 'package:sobra_app/state/sobra_store.dart';
import 'package:sobra_app/theme/app_theme.dart';

import 'support/localizations.dart';

/// Only there so the Ajustes rows that need Play are built.
class _PlayPort implements AppReviewPort {
  @override
  Future<void> requestReview() async {}

  @override
  Future<bool> openStore() async => true;
}

Future<void> _loadGoldenFonts() async {
  final pixelify = FontLoader('PixelifySans')
    ..addFont(rootBundle.load('assets/fonts/PixelifySans.ttf'));
  final hangul = FontLoader('SobraHangul')
    ..addFont(rootBundle.load('assets/fonts/SobraHangul.ttf'))
    ..addFont(rootBundle.load('assets/fonts/SobraHangul-Bold.ttf'));
  final materialIcons = FontLoader('MaterialIcons')
    ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
  await Future.wait([pixelify.load(), hangul.load(), materialIcons.load()]);
}

void main() {
  test('every app listed ships its icon and a distinct package', () {
    expect(ourApps, isNotEmpty);
    expect(
      ourApps.map((app) => app.packageName).toSet(),
      hasLength(ourApps.length),
    );
    for (final app in ourApps) {
      expect(File(app.icon).existsSync(), isTrue, reason: app.icon);
      expect(
        app.packageName,
        isNot(startsWith('com.example.')),
        reason: 'an unreleased app has no listing to open',
      );
    }
  });

  group('the screen', () {
    Future<void> pumpScreen(WidgetTester tester, ListingOpener opener) async {
      tester.view.physicalSize = const Size(520, 1100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: sobraLocalizationsDelegates,
          supportedLocales: sobraSupportedLocales,
          home: OurAppsScreen(openListing: opener),
        ),
      );
      await tester.pump();
    }

    testWidgets('gives every app the same card and button', (tester) async {
      await pumpScreen(tester, (_, {referrer}) async => true);

      for (final app in ourApps) {
        expect(find.text(app.name), findsOneWidget);
      }
      expect(find.text('Ver en Google Play'), findsNWidgets(ourApps.length));
      expect(tester.takeException(), isNull);
    });

    testWidgets('opens the listing that was tapped, tagged as from Sobra', (
      tester,
    ) async {
      final opened = <(String, String?)>[];
      await pumpScreen(tester, (packageName, {referrer}) async {
        opened.add((packageName, referrer));
        return true;
      });

      await tester.tap(find.text('Ver en Google Play').last);
      await tester.pump();

      expect(opened, [(ourApps.last.packageName, ourAppsReferrer)]);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('says so when Play cannot be opened', (tester) async {
      await pumpScreen(tester, (_, {referrer}) async => false);

      await tester.tap(find.text('Ver en Google Play').first);
      await tester.pump();

      expect(find.text('No se pudo abrir Google Play.'), findsOneWidget);
    });
  });

  group('the Ajustes row', () {
    Future<void> openSettings(WidgetTester tester, {required bool play}) async {
      SharedPreferences.setMockInitialValues({});
      final store = await SobraStore.load(now: () => DateTime(2026, 9, 3, 10));
      await store.configureOnboarding(
        budgetCentavos: 600000,
        schedule: const PaySchedule.semiMonthly(),
        cashCentavos: 124000,
      );
      await store.completeOnboarding();
      store.takePendingXpNotice();

      useSpanishDevice(tester);
      tester.view.physicalSize = const Size(520, 1360);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        SobraApp(
          store: store,
          reviews: play ? AppReviews(port: _PlayPort()) : null,
        ),
      );
      await tester.pump();
      await tester.tap(find.text('Mi Sobrita'));
      await tester.pump(const Duration(milliseconds: 100));
    }

    testWidgets('is absent where there is no Play to send anyone to', (
      tester,
    ) async {
      await openSettings(tester, play: false);

      await tester.scrollUntilVisible(find.text('ACERCA DE'), 200);
      expect(find.text('Apps recomendadas'), findsNothing);
    });

    testWidgets('leads to the list of apps', (tester) async {
      await openSettings(tester, play: true);

      final row = find.text('Apps recomendadas');
      await tester.scrollUntilVisible(row, 200);
      await tester.tap(row);
      await tester.pumpAndSettle();

      expect(find.byType(OurAppsScreen), findsOneWidget);
      for (final app in ourApps) {
        expect(find.text(app.name), findsOneWidget);
      }
    });
  });

  for (final (locale, name) in [('es', 'es'), ('ko', 'ko')]) {
    testWidgets('looks the way the design says it does ($name)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(420, 820);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await _loadGoldenFonts();

      await tester.pumpWidget(
        MaterialApp(
          locale: Locale(locale),
          theme: buildSobraTheme(),
          localizationsDelegates: sobraLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: OurAppsScreen(openListing: (_, {referrer}) async => true),
        ),
      );
      // The icons are real files, and decoding one is real I/O that the fake
      // clock of a widget test never waits for.
      await tester.runAsync(() async {
        for (final element in find.byType(Image).evaluate()) {
          await precacheImage((element.widget as Image).image, element);
        }
      });
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(Scaffold).first,
        matchesGoldenFile(
          '../design/settings/sobra-our-apps-applied-$name.png',
        ),
      );
    });
  }
}
