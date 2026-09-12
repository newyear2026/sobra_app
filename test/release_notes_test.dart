import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sobra_app/data/release_notes.dart';
import 'package:sobra_app/l10n/generated/app_localizations.dart';
import 'package:sobra_app/models/language.dart';
import 'package:sobra_app/screens/release_notes_screen.dart';
import 'package:sobra_app/screens/settings_screen.dart';
import 'package:sobra_app/services/app_version_service.dart';
import 'package:sobra_app/state/sobra_store.dart';
import 'package:sobra_app/theme/app_theme.dart';

import 'support/localizations.dart';

Future<void> _loadGoldenFonts() async {
  final pixelify = FontLoader('PixelifySans')
    ..addFont(rootBundle.load('assets/fonts/PixelifySans.ttf'));
  final materialIcons = FontLoader('MaterialIcons')
    ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
  await Future.wait([pixelify.load(), materialIcons.load()]);
}

Future<Widget> _screen(Widget child, {Locale locale = const Locale('es')}) async {
  return MaterialApp(
    locale: locale,
    // The app's theme, not Material's: half of Sobra's type comes through
    // `textTheme`, and a harness without it renders those lines in a font
    // the test bundle never loaded.
    theme: buildSobraTheme(),
    localizationsDelegates: sobraLocalizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  );
}

void main() {
  group('release notes data', () {
    test('keeps no more versions than the retention rule allows', () {
      // The rule exists because every retained version costs ARB strings in
      // every locale. Left to a code review it would quietly stop holding.
      expect(releaseNotes.length, lessThanOrEqualTo(releaseNoteRetention));
    });

    test('is ordered newest first', () {
      for (var i = 1; i < releaseNotes.length; i++) {
        expect(
          releaseNotes[i].releasedOn.isAfter(releaseNotes[i - 1].releasedOn),
          isFalse,
          reason: 'v${releaseNotes[i].version} is newer than the entry above '
              'it; the screen renders this list in order.',
        );
      }
    });

    test('names each version once', () {
      final versions = releaseNotes.map((note) => note.version).toList();
      expect(versions.toSet().length, versions.length);
    });

    test('carries at least one line per version', () {
      for (final note in releaseNotes) {
        expect(note.lines, isNotEmpty, reason: 'v${note.version}');
      }
    });
  });

  testWidgets('reads a line in every language the app ships', (tester) async {
    // Renders, rather than reading the ARB, so a note whose text comes back
    // blank at runtime fails here too. That a key exists in all three files
    // is a separate question, and `l10n_parity_test.dart` asks it — gen-l10n
    // inherits the template silently, so this test alone would not notice.
    for (final language in SobraLanguage.supportedLocales) {
      late AppLocalizations l10n;
      await tester.pumpWidget(
        await _screen(
          Builder(
            builder: (context) {
              l10n = AppLocalizations.of(context);
              return const SizedBox.shrink();
            },
          ),
          locale: language,
        ),
      );

      for (final note in releaseNotes) {
        for (final line in note.lines) {
          expect(
            line(l10n).trim(),
            isNotEmpty,
            reason: 'v${note.version} has an empty line in $language',
          );
        }
      }
    }
  });

  group('release notes screen', () {
    testWidgets('renders a card per version and tags the running build', (
      tester,
    ) async {
      final current = releaseNotes.first;
      await tester.pumpWidget(
        await _screen(
          ReleaseNotesScreen(
            currentVersion: AppVersion(
              version: current.version,
              buildNumber: '7',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      for (final note in releaseNotes) {
        expect(find.text('v${note.version}'), findsOneWidget);
      }
      // Exactly one card claims to be the build in hand.
      expect(find.text('Actual'), findsOneWidget);
    });

    testWidgets('tags nothing when the platform will not name the build', (
      tester,
    ) async {
      await tester.pumpWidget(await _screen(const ReleaseNotesScreen()));
      await tester.pumpAndSettle();

      // Better a list with no current marker than a marker on the wrong row.
      expect(find.text('Actual'), findsNothing);
      expect(find.text('v${releaseNotes.first.version}'), findsOneWidget);
    });

    testWidgets('looks the way the design says it does', (tester) async {
      useSpanishDevice(tester);
      tester.view.physicalSize = const Size(520, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await _loadGoldenFonts();

      await tester.pumpWidget(
        await _screen(
          const ReleaseNotesScreen(
            currentVersion: AppVersion(version: '1.0.0', buildNumber: '1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(Scaffold).first,
        matchesGoldenFile('../design/update/sobra-release-notes-applied.png'),
      );
    });
  });

  group('settings about section', () {
    Future<Widget> settings(AppVersionLoader loader) async {
      SharedPreferences.setMockInitialValues({});
      final store = await SobraStore.load(now: () => DateTime(2026, 9, 11, 10));
      await store.completeOnboarding();
      return await _screen(
        SobraScope(
          store: store,
          child: Scaffold(body: SettingsScreen(versionLoader: loader)),
        ),
      );
    }

    testWidgets('shows the running version once the platform answers', (
      tester,
    ) async {
      await tester.pumpWidget(
        await settings(
          () async =>
              const AppVersion(version: '1.0.0', buildNumber: '1'),
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(find.text('Versión'), 200);
      expect(find.text('1.0.0 (1)'), findsOneWidget);
      expect(find.text('v1.0.0'), findsOneWidget);
    });

    testWidgets('shows a dash rather than a guess when it does not', (
      tester,
    ) async {
      await tester.pumpWidget(await settings(() async => null));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(find.text('Versión'), 200);
      // Two rows fall back: the notes row and the version row.
      expect(find.text('—'), findsNWidgets(2));
    });

    testWidgets('opens the notes from the Novedades row', (tester) async {
      await tester.pumpWidget(
        await settings(
          () async =>
              const AppVersion(version: '1.0.0', buildNumber: '1'),
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(find.text('Novedades'), 200);
      await tester.tap(find.text('Novedades'));
      await tester.pumpAndSettle();

      expect(find.byType(ReleaseNotesScreen), findsOneWidget);
      expect(find.text('Actual'), findsOneWidget);
    });
  });
}
