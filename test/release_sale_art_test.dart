import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sobra_app/data/release_notes.dart';
import 'package:sobra_app/l10n/generated/app_localizations.dart';
import 'package:sobra_app/models/pay_schedule.dart';
import 'package:sobra_app/services/app_version_service.dart';
import 'package:sobra_app/services/release_announcement_service.dart';
import 'package:sobra_app/state/sobra_store.dart';
import 'package:sobra_app/theme/app_theme.dart';
import 'package:sobra_app/widgets/release_announcement.dart';

import 'support/localizations.dart';

const _art = ValueKey('release-announcement-sale-art');

/// The shipped note that carries the Buen Fin / Black Friday picture.
ReleaseNote get _saleNote =>
    releaseNotes.firstWhere((note) => note.art == ReleaseNoteArt.saleNight);

Future<void> _loadFonts() async {
  Future<void> load(String family, List<String> files) {
    final loader = FontLoader(family);
    for (final file in files) {
      loader.addFont(rootBundle.load(file));
    }
    return loader.load();
  }

  await Future.wait([
    load('PixelifySans', ['assets/fonts/PixelifySans.ttf']),
    load('SobraHangul', [
      'assets/fonts/SobraHangul.ttf',
      'assets/fonts/SobraHangul-Bold.ttf',
    ]),
    load('MaterialIcons', ['fonts/MaterialIcons-Regular.otf']),
  ]);
}

/// Opens the card the first launch after updating to the sale release shows,
/// with the store's clock at [now].
Future<void> _open(
  WidgetTester tester,
  DateTime now, {
  Locale locale = const Locale('es'),
}) async {
  SharedPreferences.setMockInitialValues({
    'sobra_notes_announced_version': '1.0.18',
    'sobra_notes_read_version': '1.0.18',
  });
  final preferences = await SharedPreferences.getInstance();
  final store = await SobraStore.load(now: () => now);
  await store.configureOnboarding(
    budgetCentavos: 300000,
    schedule: const PaySchedule.weekly(),
  );
  await store.completeOnboarding();
  final announcements = ReleaseAnnouncements(
    preferences: preferences,
    versionLoader: () async =>
        AppVersion(version: _saleNote.version, buildNumber: '31'),
  );
  await announcements.start();
  await tester.pumpWidget(
    SobraScope(
      store: store,
      child: MaterialApp(
        locale: locale,
        theme: buildSobraTheme(),
        localizationsDelegates: sobraLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: SizedBox.shrink()),
      ),
    ),
  );
  unawaited(
    showReleaseAnnouncement(
      tester.element(find.byType(SizedBox).first),
      announcements: announcements,
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('the picture runs from release through Cyber Monday only', () {
    final note = _saleNote;
    expect(note.showsArtOn(DateTime(2026, 11, 13, 8)), isTrue);
    expect(note.showsArtOn(DateTime(2026, 11, 30, 23, 59)), isTrue);
    expect(note.showsArtOn(DateTime(2026, 12, 1)), isFalse);
  });

  testWidgets('the update card wears the sale picture during the season', (
    tester,
  ) async {
    useSpanishDevice(tester);
    await _open(tester, DateTime(2026, 11, 13, 9));
    expect(find.byKey(_art), findsOneWidget);
    expect(find.text('v${_saleNote.version}'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a card opened after the season goes plain', (tester) async {
    useSpanishDevice(tester);
    await _open(tester, DateTime(2027, 1, 8, 9));
    expect(find.text('v${_saleNote.version}'), findsOneWidget);
    expect(find.byKey(_art), findsNothing);
  });

  testWidgets('the sale card looks the way the design says it does', (
    tester,
  ) async {
    useSpanishDevice(tester);
    tester.view.physicalSize = const Size(420, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _loadFonts();
    await _open(tester, DateTime(2026, 11, 13, 9));
    // Asset images decode outside fake time, so load the art for real.
    await tester.runAsync(
      () => precacheImage(
        const AssetImage('assets/events/sale-night-2026.webp'),
        tester.element(find.byKey(_art)),
      ),
    );
    await tester.pump();
    await expectLater(
      find.byType(Dialog),
      matchesGoldenFile('../design/update/sobra-update-sale-1.0.19.png'),
    );
  });
}
