import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sobra_app/l10n/generated/app_localizations.dart';
import 'package:sobra_app/l10n/labels.dart';

/// Every locale carries every key.
///
/// gen-l10n does not fail on a missing translation — the generated subclass
/// simply inherits the template's string, so a key added to `app_es.arb` and
/// forgotten in `app_ko.arb` ships Spanish to Korean readers and no tool says
/// a word. Reading the files is the only place that shows up.
///
/// This matters more now that release notes are a standing screen: every
/// shipped version adds keys to every file, and the one that gets
/// forgotten is always the last one in the list.
Map<String, String> _messages(String locale) {
  final file = File('lib/l10n/app_$locale.arb');
  expect(file.existsSync(), isTrue, reason: '${file.path} is missing');
  final decoded = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  return {
    for (final entry in decoded.entries)
      // `@key` entries are metadata for the translator, and `@@locale` names
      // the file. Neither is a string the app can render.
      if (!entry.key.startsWith('@')) entry.key: entry.value as String,
  };
}

void main() {
  // Spanish is the template `l10n.yaml` names, so it defines the set.
  const template = 'es';
  const translations = ['en', 'ko', 'pt', 'de', 'fr', 'ja'];

  test('every locale defines the same keys as the template', () {
    final expected = _messages(template).keys.toSet();

    for (final locale in translations) {
      final actual = _messages(locale).keys.toSet();
      expect(
        expected.difference(actual),
        isEmpty,
        reason: 'app_$locale.arb is missing keys that app_$template.arb has',
      );
      expect(
        actual.difference(expected),
        isEmpty,
        reason: 'app_$locale.arb has keys app_$template.arb does not — a '
            'typo, or a string the template lost',
      );
    }
  });

  // French and Portuguese file 0 under the singular, so a `=1` branch that
  // spells out "1" instead of using the count told a brand-new user they had
  // one movement. Portuguese also carries an explicit `=0` so zero stays
  // plural, which is how Brazil writes it.
  test('a count of zero never reads as one', () {
    for (final locale in [template, ...translations]) {
      final l10n = lookupAppLocalizations(Locale(locale));
      // Korean puts the figure after the noun, so look for it anywhere.
      expect(
        l10n.settingsProfileStats(0, 1),
        contains('0'),
        reason: 'settingsProfileStats in $locale',
      );
      expect(l10n.daysCount(0), contains('0'), reason: 'daysCount in $locale');
    }
    final pt = lookupAppLocalizations(const Locale('pt'));
    expect(
      lookupAppLocalizations(const Locale('ja')).settingsProfileStats(0, 1),
      '記録0件 · Sobritaと1日目',
    );
    expect(pt.settingsProfileStats(0, 1), startsWith('0 registros'));
    expect(pt.settingsProfileStats(1, 1), startsWith('1 registro ·'));
  });

  // Day-then-month was hardcoded once, which put Korean at "28 9월". The
  // order now comes from each locale's `dateShort` / `dateFull`.
  test('dates are written in each locale\'s own order', () {
    final date = DateTime(2026, 9, 28);
    String short(String locale) =>
        shortCycleDate(lookupAppLocalizations(Locale(locale)), date);
    expect(short('es'), '28 sep');
    expect(short('de'), '28. Sep');
    expect(short('ko'), '9월 28일');
    expect(short('ja'), '9月28日');
    expect(
      fullDate(lookupAppLocalizations(const Locale('ja')), date),
      '2026年9月28日',
    );
  });

  test('no locale leaves a message blank', () {
    for (final locale in [template, ...translations]) {
      _messages(locale).forEach((key, value) {
        expect(value.trim(), isNotEmpty, reason: '$key is blank in $locale');
      });
    }
  });
}
