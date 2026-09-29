import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sobra_app/l10n/generated/app_localizations.dart';
import 'package:sobra_app/l10n/labels.dart';
import 'package:sobra_app/main.dart';
import 'package:sobra_app/models/language.dart';
import 'package:sobra_app/models/pay_schedule.dart';
import 'package:sobra_app/state/sobra_store.dart';

import 'support/localizations.dart';

Future<SobraStore> _onboardedStore() async {
  SharedPreferences.setMockInitialValues({});
  final store = await SobraStore.load(now: () => DateTime(2026, 9, 5, 12));
  await store.configureOnboarding(
    budgetCentavos: 600000,
    schedule: const PaySchedule.semiMonthly(),
  );
  await store.completeOnboarding();
  return store;
}

void main() {
  group('the language setting', () {
    test('starts out following the phone', () async {
      final store = await _onboardedStore();
      expect(store.languageCode, isNull);
      expect(
        SobraLanguage.fromCode(store.languageCode),
        SobraLanguage.automatic,
      );
    });

    test('survives a reload', () async {
      final store = await _onboardedStore();
      await store.setLanguageCode('en');

      final restored = await SobraStore.load(now: () => DateTime(2026, 9, 5));
      expect(restored.languageCode, 'en');
    });

    // An unknown code in saved data must not crash the picker: an older or
    // newer build could have written one.
    test('reads an unknown code as following the phone', () {
      expect(SobraLanguage.fromCode('it'), SobraLanguage.automatic);
      expect(SobraLanguage.fromCode(null), SobraLanguage.automatic);
      expect(SobraLanguage.fromCode('es'), SobraLanguage.spanish);
    });

    test('is part of the exported backup', () async {
      final store = await _onboardedStore();
      await store.setLanguageCode('en');
      final json = jsonDecode(store.exportJson()) as Map<String, dynamic>;
      expect(json['languageCode'], 'en');
    });

    // Languages are named in themselves so a reader can find their own, which
    // means these two never change with the surrounding locale.
    // A language that is not in this build must not be offerable, and a code
    // saved by a build that had it must not leave the picker out of step.
    test('only offers what this build can show', () {
      expect(SobraLanguage.available, contains(SobraLanguage.spanish));
      expect(SobraLanguage.available, contains(SobraLanguage.english));
      expect(
        SobraLanguage.supportedLocales.first,
        const Locale('en'),
        reason: 'English leads, so it is what an unmatched phone falls back to',
      );
      for (final language in SobraLanguage.available) {
        expect(SobraLanguage.fromCode(language.code), language);
      }
      // Korean ships now: it was held back for want of a Hangul pixel face,
      // never for want of a translation, and `AppType.fallback` carries one.
      expect(SobraLanguage.korean.shipped, isTrue);
      expect(SobraLanguage.supportedLocales, contains(const Locale('ko')));
      expect(SobraLanguage.supportedLocales, contains(const Locale('pt')));
      expect(SobraLanguage.supportedLocales, contains(const Locale('de')));
      expect(SobraLanguage.supportedLocales, contains(const Locale('fr')));
      expect(SobraLanguage.supportedLocales, contains(const Locale('ja')));
    });

    test('drops a stored code this build cannot show', () async {
      final store = await _onboardedStore();
      await store.setLanguageCode('it');

      final restored = await SobraStore.load(now: () => DateTime(2026, 9, 5));
      expect(
        restored.languageCode,
        isNull,
        reason: 'an unshowable choice reads back as following the phone',
      );
    });

    test('names each language in its own words', () {
      for (final l10n in [
        lookupAppLocalizations(const Locale('es')),
        lookupAppLocalizations(const Locale('en')),
      ]) {
        expect(SobraLanguage.spanish.label(l10n), 'Español');
        expect(SobraLanguage.english.label(l10n), 'English');
        expect(SobraLanguage.korean.label(l10n), '한국어');
        expect(SobraLanguage.portuguese.label(l10n), 'Português');
        expect(SobraLanguage.german.label(l10n), 'Deutsch');
        expect(SobraLanguage.french.label(l10n), 'Français');
        expect(SobraLanguage.japanese.label(l10n), '日本語');
      }
      expect(
        SobraLanguage.automatic.label(
          lookupAppLocalizations(const Locale('es')),
        ),
        'Automático',
      );
      expect(
        SobraLanguage.automatic.label(
          lookupAppLocalizations(const Locale('en')),
        ),
        'Automatic',
      );
    });
  });

  group('the running app', () {
    testWidgets('follows an English phone when no language was picked', (
      tester,
    ) async {
      tester.platformDispatcher
        ..localeTestValue = const Locale('en', 'US')
        ..localesTestValue = const <Locale>[Locale('en', 'US')];
      addTearDown(tester.platformDispatcher.clearLocaleTestValue);
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);

      final store = await _onboardedStore();
      await tester.pumpWidget(SobraApp(store: store));
      await tester.pump();

      expect(find.text('Home'), findsWidgets);
      expect(find.text('Inicio'), findsNothing);
    });

    // English leads the supported list, so a phone set to none of the
    // languages — somebody spending yuan, or euros in Italy or the
    // Netherlands — lands on English.
    for (final phone in const [
      Locale('zh', 'CN'),
      Locale('it', 'IT'),
      Locale('nl', 'NL'),
    ]) {
      testWidgets('falls back to English on a $phone phone', (tester) async {
        tester.platformDispatcher
          ..localeTestValue = phone
          ..localesTestValue = <Locale>[phone];
        addTearDown(tester.platformDispatcher.clearLocaleTestValue);
        addTearDown(tester.platformDispatcher.clearLocalesTestValue);

        final store = await _onboardedStore();
        await tester.pumpWidget(SobraApp(store: store));
        await tester.pump();

        expect(find.text('Home'), findsWidgets);
        expect(find.text('Inicio'), findsNothing);
      });
    }

    // The fallback must not cost Latin America its Spanish: any Spanish phone
    // matches `es`, and so does one that lists Spanish behind a language
    // Sobra does not have.
    for (final phones in const [
      [Locale('es', 'CO')],
      [Locale('es', 'AR')],
      [Locale('it', 'IT'), Locale('es', 'ES')],
    ]) {
      testWidgets('stays in Spanish on a $phones phone', (tester) async {
        tester.platformDispatcher
          ..localeTestValue = phones.first
          ..localesTestValue = phones;
        addTearDown(tester.platformDispatcher.clearLocaleTestValue);
        addTearDown(tester.platformDispatcher.clearLocalesTestValue);

        final store = await _onboardedStore();
        await tester.pumpWidget(SobraApp(store: store));
        await tester.pump();

        expect(find.text('Inicio'), findsWidgets);
        expect(find.text('Home'), findsNothing);
      });
    }

    // A Brazilian or Portuguese phone reads Portuguese, any German-speaking
    // one reads German and any French-speaking one French, without anybody
    // opening the picker.
    for (final (phone, home) in const [
      (Locale('pt', 'BR'), 'Início'),
      (Locale('pt', 'PT'), 'Início'),
      (Locale('de', 'DE'), 'Start'),
      (Locale('de', 'AT'), 'Start'),
      (Locale('fr', 'FR'), 'Accueil'),
      (Locale('fr', 'CA'), 'Accueil'),
      (Locale('ja', 'JP'), 'ホーム'),
    ]) {
      testWidgets('follows a $phone phone', (tester) async {
        tester.platformDispatcher
          ..localeTestValue = phone
          ..localesTestValue = <Locale>[phone];
        addTearDown(tester.platformDispatcher.clearLocaleTestValue);
        addTearDown(tester.platformDispatcher.clearLocalesTestValue);

        final store = await _onboardedStore();
        await tester.pumpWidget(SobraApp(store: store));
        await tester.pump();

        expect(find.text(home), findsWidgets);
        expect(find.text('Home'), findsNothing);
      });
    }

    // Korean ships only in debug builds, and tests are one.
    testWidgets('follows a Korean phone in a debug build', (tester) async {
      tester.platformDispatcher
        ..localeTestValue = const Locale('ko', 'KR')
        ..localesTestValue = const <Locale>[Locale('ko', 'KR')];
      addTearDown(tester.platformDispatcher.clearLocaleTestValue);
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);

      final store = await _onboardedStore();
      await tester.pumpWidget(SobraApp(store: store));
      await tester.pump();

      expect(find.text('홈'), findsWidgets);
      expect(find.text('Inicio'), findsNothing);
    });

    testWidgets('a picked language overrides the phone', (tester) async {
      useSpanishDevice(tester);
      final store = await _onboardedStore();
      await store.setLanguageCode('en');

      await tester.pumpWidget(SobraApp(store: store));
      await tester.pump();

      expect(find.text('Home'), findsWidgets);
    });

    // The MaterialApp sits above the scope that would notify it, so this is
    // the wiring that could silently stop working.
    testWidgets('switches language without a restart', (tester) async {
      useSpanishDevice(tester);
      final store = await _onboardedStore();
      await tester.pumpWidget(SobraApp(store: store));
      await tester.pump();
      expect(find.text('Inicio'), findsWidgets);

      await store.setLanguageCode('en');
      await tester.pump();

      expect(find.text('Home'), findsWidgets);
      expect(find.text('Inicio'), findsNothing);

      await store.setLanguageCode(null);
      await tester.pump();

      expect(find.text('Inicio'), findsWidgets);
    });
  });
}
