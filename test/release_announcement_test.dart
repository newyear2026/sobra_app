import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sobra_app/data/release_notes.dart';
import 'package:sobra_app/l10n/generated/app_localizations.dart';
import 'package:sobra_app/screens/release_notes_screen.dart';
import 'package:sobra_app/services/app_version_service.dart';
import 'package:sobra_app/services/release_announcement_service.dart';
import 'package:sobra_app/theme/app_theme.dart';
import 'package:sobra_app/widgets/release_announcement.dart';

import 'support/localizations.dart';

/// Notes of its own rather than the shipped list, so these tests keep saying
/// what they mean after a release is added and the oldest one drops off.
final _notes = <ReleaseNote>[
  ReleaseNote(
    version: '1.1.0',
    releasedOn: DateTime(2026, 10, 2),
    lines: [(l10n) => l10n.releaseNote100Launch],
  ),
  ReleaseNote(
    version: '1.0.0',
    releasedOn: DateTime(2026, 9, 11),
    lines: [(l10n) => l10n.releaseNote100Launch],
  ),
];

AppVersionLoader _reports(String? version, {String build = '1'}) => () async =>
    version == null
    ? null
    : AppVersion(version: version, buildNumber: build);

Future<SharedPreferences> _preferences([
  Map<String, Object> initial = const {},
]) async {
  SharedPreferences.setMockInitialValues(Map<String, Object>.from(initial));
  return SharedPreferences.getInstance();
}

Future<ReleaseAnnouncements> _started({
  required SharedPreferences preferences,
  String? version = '1.0.0',
  String build = '1',
}) async {
  final announcements = ReleaseAnnouncements(
    preferences: preferences,
    versionLoader: _reports(version, build: build),
    notes: _notes,
  );
  await announcements.start();
  return announcements;
}

Future<void> _loadFonts() async {
  final pixelify = FontLoader('PixelifySans')
    ..addFont(rootBundle.load('assets/fonts/PixelifySans.ttf'));
  final icons = FontLoader('MaterialIcons')
    ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
  await Future.wait([pixelify.load(), icons.load()]);
}

Widget _harness(Widget child) => MaterialApp(
  locale: const Locale('es'),
  theme: buildSobraTheme(),
  localizationsDelegates: sobraLocalizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: child),
);

void main() {
  group('the first launch', () {
    test('announces nothing, because nothing changed for this user', () async {
      final announcements = await _started(
        preferences: await _preferences(),
      );

      expect(announcements.shouldAnnounce, isFalse);
      expect(
        announcements.hasUnreadNotes,
        isFalse,
        reason: 'a brand-new install has no backlog to catch up on',
      );
    });

    test('records where it started, so the next release is a change', () async {
      final preferences = await _preferences();
      await _started(preferences: preferences);

      final afterUpdate = await _started(
        preferences: preferences,
        version: '1.1.0',
      );
      expect(afterUpdate.shouldAnnounce, isTrue);
    });
  });

  group('after an update', () {
    test('the card comes up once and then stops', () async {
      final preferences = await _preferences({
        'sobra_notes_announced_version': '1.0.0',
        'sobra_notes_read_version': '1.0.0',
      });

      final first = await _started(preferences: preferences, version: '1.1.0');
      expect(first.shouldAnnounce, isTrue);
      await first.markAnnounced();
      expect(first.shouldAnnounce, isFalse);

      final relaunch = await _started(
        preferences: preferences,
        version: '1.1.0',
      );
      expect(relaunch.shouldAnnounce, isFalse);
    });

    test('a new build of the same version is not a new release', () async {
      final preferences = await _preferences({
        'sobra_notes_announced_version': '1.1.0',
        'sobra_notes_read_version': '1.1.0',
      });

      // The build number is what a support question needs and what a release
      // note has to ignore, or every hotfix would interrupt.
      final announcements = await _started(
        preferences: preferences,
        version: '1.1.0',
        build: '9',
      );
      expect(announcements.shouldAnnounce, isFalse);
    });

    test('a version that shipped without a note says nothing', () async {
      final announcements = await _started(
        preferences: await _preferences({
          'sobra_notes_announced_version': '1.0.0',
          'sobra_notes_read_version': '1.0.0',
        }),
        version: '1.2.0',
      );

      expect(announcements.currentNote, isNull);
      expect(announcements.shouldAnnounce, isFalse);
      expect(announcements.hasUnreadNotes, isFalse);
    });

    test('a platform that will not name the build says nothing', () async {
      final announcements = await _started(
        preferences: await _preferences({
          'sobra_notes_announced_version': '1.0.0',
          'sobra_notes_read_version': '1.0.0',
        }),
        version: null,
      );

      expect(announcements.shouldAnnounce, isFalse);
      expect(announcements.hasUnreadNotes, isFalse);
    });
  });

  group('the dot on the Ajustes row', () {
    test('outlives the card, and clears only on reading', () async {
      final preferences = await _preferences({
        'sobra_notes_announced_version': '1.0.0',
        'sobra_notes_read_version': '1.0.0',
      });
      final announcements = await _started(
        preferences: preferences,
        version: '1.1.0',
      );

      await announcements.markAnnounced();
      expect(
        announcements.hasUnreadNotes,
        isTrue,
        reason: 'being told is not the same as having read it',
      );

      await announcements.markRead();
      expect(announcements.hasUnreadNotes, isFalse);

      final relaunch = await _started(
        preferences: preferences,
        version: '1.1.0',
      );
      expect(relaunch.hasUnreadNotes, isFalse);
    });

    test('reading covers being told, for somebody who went looking', () async {
      final preferences = await _preferences({
        'sobra_notes_announced_version': '1.0.0',
        'sobra_notes_read_version': '1.0.0',
      });
      final announcements = await _started(
        preferences: preferences,
        version: '1.1.0',
      );

      // Opened Ajustes before the card had its turn: the card has nothing
      // left to say.
      await announcements.markRead();
      expect(announcements.shouldAnnounce, isFalse);
    });
  });

  group('the card', () {
    setUpAll(_loadFonts);

    testWidgets('carries the note itself', (tester) async {
      final announcements = await _started(
        preferences: await _preferences({
          'sobra_notes_announced_version': '1.0.0',
          'sobra_notes_read_version': '1.0.0',
        }),
        version: '1.1.0',
      );

      await tester.pumpWidget(_harness(const SizedBox.shrink()));
      final context = tester.element(find.byType(SizedBox));
      unawaited(
        showReleaseAnnouncement(context, announcements: announcements),
      );
      await tester.pumpAndSettle();

      expect(find.text('Novedades'), findsOneWidget);
      expect(find.text('v1.1.0'), findsOneWidget);
      expect(find.text('Primera versión de Sobrita.'), findsOneWidget);

      await tester.tap(find.text('Listo'));
      await tester.pumpAndSettle();

      expect(find.byType(ReleaseNotesScreen), findsNothing);
      expect(announcements.hasUnreadNotes, isTrue);
    });

    testWidgets('Ver todo opens the full list and marks it read', (
      tester,
    ) async {
      final announcements = await _started(
        preferences: await _preferences({
          'sobra_notes_announced_version': '1.0.0',
          'sobra_notes_read_version': '1.0.0',
        }),
        version: '1.1.0',
      );

      await tester.pumpWidget(_harness(const SizedBox.shrink()));
      final context = tester.element(find.byType(SizedBox));
      unawaited(
        showReleaseAnnouncement(context, announcements: announcements),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ver todo'));
      await tester.pumpAndSettle();

      expect(find.byType(ReleaseNotesScreen), findsOneWidget);
      expect(announcements.hasUnreadNotes, isFalse);
    });
  });
}
