import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sobra_app/l10n/generated/app_localizations.dart';
import 'package:sobra_app/services/app_update_service.dart';
import 'package:sobra_app/theme/app_theme.dart';
import 'package:sobra_app/widgets/update_prompt.dart';

import 'support/localizations.dart';

/// Stands in for Play, which cannot be reached from a test at all.
class _FakePort implements AppUpdatePort {
  _FakePort({this.available, this.storeOpens = true});

  PendingUpdate? available;
  bool storeOpens;
  int checks = 0;
  int opens = 0;

  @override
  Future<PendingUpdate?> check() async {
    checks++;
    return available;
  }

  @override
  Future<bool> openStore() async {
    opens++;
    return storeOpens;
  }
}

Future<SharedPreferences> _preferences([
  Map<String, Object> initial = const {},
]) async {
  SharedPreferences.setMockInitialValues(Map<String, Object>.from(initial));
  return SharedPreferences.getInstance();
}

Future<Widget> _harness(Widget child) async => MaterialApp(
  locale: const Locale('es'),
  theme: buildSobraTheme(),
  localizationsDelegates: sobraLocalizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: child),
);

void main() {
  const v7 = PendingUpdate(versionCode: 7);
  const v8 = PendingUpdate(versionCode: 8);

  group('when the store is asked', () {
    test('once a day, and not again until the day turns', () async {
      var today = DateTime(2026, 9, 17, 9);
      final port = _FakePort(available: v7);
      final updates = AppUpdates(
        port: port,
        preferences: await _preferences(),
        now: () => today,
      );

      await updates.refresh();
      await updates.refresh();
      expect(port.checks, 1, reason: 'a second cold start on the same day');

      today = DateTime(2026, 9, 18, 9);
      await updates.refresh();
      expect(port.checks, 2);
    });

    test('the daily budget is remembered across launches', () async {
      final port = _FakePort(available: v7);
      final preferences = await _preferences();
      final now = DateTime(2026, 9, 17);

      await AppUpdates(
        port: port,
        preferences: preferences,
        now: () => now,
      ).refresh();
      await AppUpdates(
        port: port,
        preferences: preferences,
        now: () => now,
      ).refresh();

      expect(port.checks, 1);
    });

    test('a forced check ignores the budget', () async {
      final port = _FakePort(available: v7);
      final now = DateTime(2026, 9, 17);
      final updates = AppUpdates(
        port: port,
        preferences: await _preferences(),
        now: () => now,
      );

      await updates.refresh();
      await updates.refresh(force: true);
      expect(port.checks, 2);
    });

    test('nothing is offered when nothing is waiting', () async {
      final updates = AppUpdates(
        port: _FakePort(),
        preferences: await _preferences(),
      );

      expect(await updates.refresh(), isNull);
      expect(updates.shouldPrompt, isFalse);
      expect(updates.showBanner, isFalse);
    });

    test('a port that cannot reach Play is simply quiet', () async {
      final updates = AppUpdates(
        port: const UnavailableUpdatePort(),
        preferences: await _preferences(),
      );

      await updates.refresh();
      expect(updates.shouldPrompt, isFalse);
      expect(updates.showBanner, isFalse);
      expect(await updates.openStore(), isFalse);
    });
  });

  group('how insistent the offer is', () {
    test('the dialog comes first and the banner takes over', () async {
      final updates = AppUpdates(
        port: _FakePort(available: v7),
        preferences: await _preferences(),
      );
      await updates.refresh();

      expect(updates.shouldPrompt, isTrue);
      expect(
        updates.showBanner,
        isFalse,
        reason: 'the banner would be a second copy of the open dialog',
      );

      updates.markPromptShown();
      expect(updates.shouldPrompt, isFalse);
      expect(
        updates.showBanner,
        isFalse,
        reason: 'the dialog is open — the banner would draw behind the scrim',
      );

      updates.markPromptClosed();
      expect(updates.showBanner, isTrue);
    });

    test('the banner waits for the dialog to close, not to open', () async {
      // Caught on a device: the banner was legible over the dim behind an
      // open dialog, because "has been offered" was doing double duty as
      // "is on screen".
      final updates = AppUpdates(
        port: _FakePort(available: v7),
        preferences: await _preferences(),
      );
      await updates.refresh();

      updates.markPromptShown();
      expect(updates.showBanner, isFalse);
      await updates.dismiss();
      expect(
        updates.showBanner,
        isFalse,
        reason: 'dismiss runs while the dialog is still on screen',
      );
      updates.markPromptClosed();
      expect(updates.showBanner, isTrue);
    });

    test('closing the banner lasts the session, not for good', () async {
      final port = _FakePort(available: v7);
      final preferences = await _preferences();
      final today = DateTime(2026, 9, 17);

      final first = AppUpdates(
        port: port,
        preferences: preferences,
        now: () => today,
      );
      await first.refresh();
      await first.dismiss();
      expect(first.showBanner, isTrue);
      first.hideBanner();
      expect(first.showBanner, isFalse);

      // The next launch, still the same day and the same dismissed update.
      final next = AppUpdates(
        port: port,
        preferences: preferences,
        now: () => DateTime(2026, 9, 18),
      );
      await next.refresh();
      expect(next.shouldPrompt, isFalse, reason: 'already answered "later"');
      expect(next.showBanner, isTrue, reason: 'the line comes back');
    });

    test('a dismissed update never interrupts again', () async {
      final port = _FakePort(available: v7);
      final preferences = await _preferences();

      final first = AppUpdates(
        port: port,
        preferences: preferences,
        now: () => DateTime(2026, 9, 17),
      );
      await first.refresh();
      await first.dismiss();

      final next = AppUpdates(
        port: port,
        preferences: preferences,
        now: () => DateTime(2026, 9, 20),
      );
      await next.refresh();
      expect(next.shouldPrompt, isFalse);
    });

    test('but the update after it does', () async {
      final port = _FakePort(available: v7);
      final preferences = await _preferences();

      final first = AppUpdates(
        port: port,
        preferences: preferences,
        now: () => DateTime(2026, 9, 17),
      );
      await first.refresh();
      await first.dismiss();

      // This is the whole reason the dismissal is keyed on the version code
      // rather than on a flag: one "later" must not silence every release
      // that follows it.
      port.available = v8;
      final next = AppUpdates(
        port: port,
        preferences: preferences,
        now: () => DateTime(2026, 9, 20),
      );
      await next.refresh();
      expect(next.shouldPrompt, isTrue);
    });

    test('a forced check takes back an earlier "later"', () async {
      final port = _FakePort(available: v7);
      final now = DateTime(2026, 9, 17);
      final updates = AppUpdates(
        port: port,
        preferences: await _preferences(),
        now: () => now,
      );

      await updates.refresh();
      await updates.dismiss();
      expect(updates.shouldPrompt, isFalse);

      await updates.refresh(force: true);
      expect(updates.shouldPrompt, isTrue);
    });
  });

  group('the dialog', () {
    testWidgets('offers the store and remembers "later"', (tester) async {
      final port = _FakePort(available: v7);
      final updates = AppUpdates(
        port: port,
        preferences: await _preferences(),
      );
      await updates.refresh();

      await tester.pumpWidget(await _harness(const SizedBox.shrink()));
      final context = tester.element(find.byType(SizedBox));
      unawaited(
        showUpdatePrompt(context, updates: updates, currentVersion: '1.1.0'),
      );
      await tester.pumpAndSettle();

      expect(find.text('Hay una versión nueva'), findsOneWidget);
      expect(find.text('Tu versión: v1.1.0'), findsOneWidget);

      await tester.tap(find.text('Ahora no'));
      await tester.pumpAndSettle();

      expect(port.opens, 0);
      expect(updates.shouldPrompt, isFalse);
      expect(updates.showBanner, isTrue);
    });

    testWidgets('hands over to the store on Actualizar', (tester) async {
      final port = _FakePort(available: v7);
      final updates = AppUpdates(
        port: port,
        preferences: await _preferences(),
      );
      await updates.refresh();

      await tester.pumpWidget(await _harness(const SizedBox.shrink()));
      final context = tester.element(find.byType(SizedBox));
      unawaited(showUpdatePrompt(context, updates: updates));
      await tester.pumpAndSettle();

      // No version row: the platform said nothing, so the dialog claims
      // nothing rather than showing a dash.
      expect(find.textContaining('Tu versión'), findsNothing);

      await tester.tap(find.text('Actualizar'));
      await tester.pumpAndSettle();

      expect(port.opens, 1);
    });

    testWidgets('says so when no store would open', (tester) async {
      final port = _FakePort(available: v7, storeOpens: false);
      final updates = AppUpdates(
        port: port,
        preferences: await _preferences(),
      );
      await updates.refresh();

      await tester.pumpWidget(await _harness(const SizedBox.shrink()));
      final context = tester.element(find.byType(SizedBox));
      unawaited(showUpdatePrompt(context, updates: updates));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Actualizar'));
      await tester.pumpAndSettle();

      expect(find.text('No se pudo abrir Google Play.'), findsOneWidget);
    });
  });

  group('the banner', () {
    testWidgets('carries both the offer and a way out', (tester) async {
      var updated = 0;
      var dismissed = 0;

      await tester.pumpWidget(
        await _harness(
          UpdateBanner(
            onUpdate: () => updated++,
            onDismiss: () => dismissed++,
          ),
        ),
      );

      expect(find.text('Versión nueva disponible'), findsOneWidget);

      await tester.tap(find.text('Actualizar'));
      await tester.pump();
      expect(updated, 1);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();
      expect(dismissed, 1);
    });
  });
}
