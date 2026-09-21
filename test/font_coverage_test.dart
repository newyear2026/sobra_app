import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sobra_app/models/currency.dart';

/// Every character the bundled font can draw, read out of its `cmap`.
///
/// A missing glyph does not fail: the engine quietly borrows one from a system
/// font, so a ₩ that is not in this file still appears on screen — in another
/// typeface, mid-amount, on the one string Sobra exists to show. That is the
/// failure this reads the table to catch, because no rendering test can see
/// it and no exception is ever thrown.
Set<int> _coverage(ByteData font) {
  final covered = <int>{};
  final tables = font.getUint16(4);
  var cmap = -1;
  for (var i = 0; i < tables; i++) {
    final record = 12 + 16 * i;
    final tag = String.fromCharCodes(
      Uint8List.view(font.buffer, font.offsetInBytes + record, 4),
    );
    if (tag == 'cmap') cmap = font.getUint32(record + 8);
  }
  expect(cmap, isNot(-1), reason: 'the font has no cmap at all');

  final subtables = font.getUint16(cmap + 2);
  for (var i = 0; i < subtables; i++) {
    final record = cmap + 4 + 8 * i;
    final start = cmap + font.getUint32(record + 4);
    switch (font.getUint16(start)) {
      case 4:
        final segments = font.getUint16(start + 6) ~/ 2;
        final startCodes = start + 16 + segments * 2;
        for (var s = 0; s < segments; s++) {
          final last = font.getUint16(start + 14 + s * 2);
          final first = font.getUint16(startCodes + s * 2);
          for (var c = first; c <= last && c != 0xFFFF; c++) {
            covered.add(c);
          }
        }
      case 12:
        final groups = font.getUint32(start + 12);
        for (var g = 0; g < groups; g++) {
          final entry = start + 16 + g * 12;
          final first = font.getUint32(entry);
          final last = font.getUint32(entry + 4);
          // Whole planes would be pointless to walk and no font maps one.
          if (last - first > 0xFFFF) continue;
          for (var c = first; c <= last; c++) {
            covered.add(c);
          }
        }
    }
  }
  return covered;
}

/// Every character the app would ask a font to draw for [locale].
///
/// Read out of the ARB rather than out of a rendered screen: a string only
/// some flow reaches is exactly the one whose missing glyph nobody notices
/// until a user does.
Set<int> _charactersIn(String locale) {
  final file = File('lib/l10n/app_$locale.arb');
  expect(file.existsSync(), isTrue, reason: '${file.path} is missing');
  final decoded = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  return {
    for (final entry in decoded.entries)
      if (!entry.key.startsWith('@')) ...(entry.value as String).runes,
  };
}

void main() {
  late Set<int> covered;
  late Set<int> latin;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    latin = _coverage(await rootBundle.load('assets/fonts/PixelifySans.ttf'));
    covered = {
      ...latin,
      ..._coverage(await rootBundle.load('assets/fonts/SobraHangul.ttf')),
    };
  });

  // The check that would have caught Korean before it shipped: the app had
  // the translation and no face to set it in, and nothing failed — the glyphs
  // came back in whatever the phone had lying around.
  test('between them the bundled fonts draw every word the app ships', () {
    for (final locale in ['es', 'en', 'ko']) {
      final missing = _charactersIn(locale).difference(covered)
        // A line break is not a glyph.
        ..remove(0x0A);
      expect(
        missing,
        isEmpty,
        reason:
            'app_$locale.arb uses '
            '${missing.map((c) => String.fromCharCode(c)).join()} '
            '(${missing.map((c) => 'U+${c.toRadixString(16).toUpperCase()}').join(' ')}) '
            'and neither bundled font draws them. Either cut the character or '
            'bundle a face that has it — see tool/build_hangul_fallback.py.',
      );
    }
  });

  test('Hangul comes from Sobra own face, not the Latin one', () {
    // A syllable, and the compatibility jamo a Korean IME puts on screen
    // while one is still being assembled. Conjoining jamo (U+1100) is not
    // checked: Galmuri does not draw it and Android's IME does not send it.
    expect(covered, containsAll(<int>[0xD55C, 0x3131, 0x314F]));
    expect(
      latin,
      isNot(contains(0xD55C)),
      reason:
          'PixelifySans gained Hangul, which would make the fallback '
          'unreachable and this test meaningless',
    );
  });

  test('the font can draw every currency sign Sobra offers', () {
    for (final currency in Currency.values) {
      for (final rune in currency.symbol.runes) {
        expect(
          latin,
          contains(rune),
          reason:
              '${currency.code} is labelled '
              '"${currency.symbol}" and U+${rune.toRadixString(16).toUpperCase()}'
              ' is not in PixelifySans. Draw it — see tool/patch_pixelify_won.py'
              ' — or the sign renders in whatever font the device falls back to.',
        );
      }
    }
  });

  // The won is the one sign in that list the font did not come with, so it is
  // also the one a re-run of the digit tool, or a fresh copy from upstream,
  // would silently take away again.
  test('the won sign added by hand is still in the font', () {
    expect(latin, contains(0x20A9));
  });

  test('the separators money is written with are in the font', () {
    // formatMoney places these itself, so a figure would lose its grouping
    // rather than fall back if they ever went missing. The Latin face has to
    // be the one carrying them: a figure is set in it, not in the fallback.
    expect(latin, containsAll(<int>[0x2C, 0x2E, 0x2212]));
  });
}
