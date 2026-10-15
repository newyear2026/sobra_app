import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sobra_app/l10n/generated/app_localizations.dart';
import 'package:sobra_app/main.dart';
import 'package:sobra_app/models/cycle_record.dart';
import 'package:sobra_app/models/pay_schedule.dart';
import 'package:sobra_app/models/xp_event.dart';
import 'package:sobra_app/screens/settlement_screen.dart';
import 'package:sobra_app/services/app_review_service.dart';
import 'package:sobra_app/services/app_share.dart';
import 'package:sobra_app/services/app_telemetry.dart';
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

void main() {
  late List<String> shared;
  late List<(String, Map<String, Object>)> sent;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    shared = [];
    sent = [];
    AppShare.instance = AppShare(
      send: (text) async {
        shared.add(text);
        return ShareResultStatus.success;
      },
    );
    AppTelemetry.instance = AppTelemetry(
      sendEvent: (name, parameters) async => sent.add((name, parameters)),
    );
    addTearDown(() {
      AppShare.instance = AppShare();
      AppTelemetry.instance = AppTelemetry();
    });
  });

  group('the link', () {
    test('opens the release listing, tagged with where it came from', () {
      final link = shareLink(ShareOrigin.settlement);

      expect(link.host, 'play.google.com');
      expect(link.path, '/store/apps/details');
      expect(link.queryParameters['id'], 'com.sobra.app.sobra_app');
      expect(
        link.queryParameters['referrer'],
        'utm_source=sobrita_share&utm_medium=settlement',
      );
      expect(
        shareLink(ShareOrigin.settings).queryParameters['referrer'],
        'utm_source=sobrita_share&utm_medium=settings',
      );
    });

    test('keeps the referrer in one parameter instead of spilling it', () {
      final raw = shareLink(ShareOrigin.settings).toString();

      expect(raw, isNot(contains('&utm_medium')));
      expect(Uri.parse(raw).queryParameters.keys, ['id', 'referrer']);
    });

    test('follows the message on its own line', () async {
      final l10n = await AppLocalizations.delegate.load(const Locale('es'));

      expect(
        shareText(l10n, ShareOrigin.settings),
        '${l10n.shareMessageSettings}\n${shareLink(ShareOrigin.settings)}',
      );
    });
  });

  group('sharing', () {
    test('reports where it was opened and how it ended', () async {
      final l10n = await AppLocalizations.delegate.load(const Locale('es'));

      await AppShare.instance.share(l10n, ShareOrigin.settlement);

      expect(shared, [shareText(l10n, ShareOrigin.settlement)]);
      expect(sent.single.$1, 'share');
      expect(sent.single.$2, {'origin': 'settlement', 'result': 'success'});
    });

    test('a sheet that cannot open is reported, not thrown', () async {
      final l10n = await AppLocalizations.delegate.load(const Locale('es'));
      AppShare.instance = AppShare(send: (_) => throw StateError('no sheet'));

      await AppShare.instance.share(l10n, ShareOrigin.settings);

      expect(sent.single.$1, 'share');
      expect(sent.single.$2, {'origin': 'settings', 'result': 'unavailable'});
    });
  });

  group('the settlement card', () {
    const notice = XpNotice(
      kind: XpNoticeKind.cyclesClosed,
      xp: 130,
      closedCycles: 1,
    );

    CycleRecord closedWith({required int spentCentavos}) => CycleRecord(
      start: DateTime(2026, 9, 1),
      end: DateTime(2026, 9, 7),
      budgetCentavos: 700000,
      spentCentavos: spentCentavos,
      cycleType: PayCycleType.weekly,
    );

    Future<void> pump(WidgetTester tester, CycleRecord record) async {
      final store = await SobraStore.load(now: () => DateTime(2026, 9, 14, 11));
      tester.view.physicalSize = const Size(520, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      useSpanishDevice(tester);
      await tester.pumpWidget(
        SobraScope(
          store: store,
          child: MaterialApp(
            localizationsDelegates: sobraLocalizationsDelegates,
            supportedLocales: sobraSupportedLocales,
            theme: buildSobraTheme(),
            home: SettlementScreen(notice: notice, record: record),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('shares from the settlement when money was left over', (
      tester,
    ) async {
      await pump(tester, closedWith(spentCentavos: 180000));

      await tester.tap(find.text('Presúmele a un amigo'));
      await tester.pumpAndSettle();

      expect(shared, hasLength(1));
      expect(shared.single, contains('utm_medium%3Dsettlement'));
      expect(shared.single, isNot(contains('5,200')));
    });

    testWidgets('is not offered after a cycle that ran over or broke even', (
      tester,
    ) async {
      await pump(tester, closedWith(spentCentavos: 800000));
      expect(find.text('Presúmele a un amigo'), findsNothing);

      await pump(tester, closedWith(spentCentavos: 700000));
      expect(find.text('Presúmele a un amigo'), findsNothing);
    });
  });

  group('the Ajustes row', () {
    Future<void> openSettings(WidgetTester tester, {required bool play}) async {
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

    testWidgets('opens the share sheet tagged as from Ajustes', (tester) async {
      await openSettings(tester, play: true);

      // Scrolled past, so the row clears the tab bar instead of sitting under it.
      await tester.scrollUntilVisible(find.text('Apps recomendadas'), 200);
      await tester.tap(find.text('Recomendar Sobrita a un amigo'));
      await tester.pump();

      expect(shared, hasLength(1));
      expect(shared.single, contains('utm_medium%3Dsettings'));
    });

    testWidgets('is absent where there is no Play listing to send', (
      tester,
    ) async {
      await openSettings(tester, play: false);

      await tester.scrollUntilVisible(find.text('ACERCA DE'), 200);
      expect(find.text('Recomendar Sobrita a un amigo'), findsNothing);
    });
  });
}
