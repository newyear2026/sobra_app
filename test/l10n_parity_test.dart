import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Every locale carries every key.
///
/// gen-l10n does not fail on a missing translation — the generated subclass
/// simply inherits the template's string, so a key added to `app_es.arb` and
/// forgotten in `app_ko.arb` ships Spanish to Korean readers and no tool says
/// a word. Reading the files is the only place that shows up.
///
/// This matters more now that release notes are a standing screen: every
/// shipped version adds keys to all three files, and the one that gets
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
  const translations = ['en', 'ko'];

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

  test('no locale leaves a message blank', () {
    for (final locale in [template, ...translations]) {
      _messages(locale).forEach((key, value) {
        expect(value.trim(), isNotEmpty, reason: '$key is blank in $locale');
      });
    }
  });
}
