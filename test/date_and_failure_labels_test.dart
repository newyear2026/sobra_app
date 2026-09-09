import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sobra_app/l10n/generated/app_localizations.dart';
import 'package:sobra_app/l10n/labels.dart';
import 'package:sobra_app/models/store_failure.dart';
import 'package:sobra_app/widgets/cat_sprite.dart';

final l10n = lookupAppLocalizations(const Locale('es'));

void main() {
  group('a date', () {
    // The app deliberately has no numeric date anywhere: "05/09" reads as
    // 5 September to one reader and 9 May to another, and spelling the month
    // is what lets the day-first order stay put in every locale.
    test('spells its month rather than numbering it', () {
      expect(fullDate(l10n, DateTime(2026, 9, 15)), '15 sep 2026');
      expect(shortCycleDate(l10n, DateTime(2026, 5, 9)), '9 may');
      expect(
        cycleDateRange(l10n, DateTime(2026, 9, 15), DateTime(2026, 9, 29)),
        '15 sep–29 sep',
      );
    });

    test('names all twelve months', () {
      final names = <String>{
        for (var month = 1; month <= 12; month++)
          monthAbbreviation(l10n, month),
      };
      expect(names, hasLength(12), reason: 'every month needs its own name');
      expect(monthAbbreviation(l10n, 1), 'ene');
      expect(monthAbbreviation(l10n, 12), 'dic');
    });

    test('names all seven weekdays, long and short', () {
      final long = <String>{
        for (var day = DateTime.monday; day <= DateTime.sunday; day++)
          weekdayName(l10n, day),
      };
      final short = <String>{
        for (var day = DateTime.monday; day <= DateTime.sunday; day++)
          weekdayShortName(l10n, day),
      };
      expect(long, hasLength(7));
      expect(short, hasLength(7));
      expect(weekdayName(l10n, DateTime.monday), 'Lunes');
      expect(weekdayShortName(l10n, DateTime.sunday), 'Dom');
    });
  });

  group('a failed write', () {
    test('has its own sentence for every reason the store can give', () {
      final messages = <String>{
        for (final failure in StoreFailure.values)
          describeStoreFailure(l10n, SobraStoreException(failure)),
      };
      expect(
        messages,
        hasLength(StoreFailure.values.length),
        reason: 'two reasons sharing a sentence hides one of them',
      );
      expect(
        messages,
        isNot(contains(l10n.storeFailureGeneric)),
        reason: 'a typed refusal must never fall through to the plain line',
      );
    });
  });

  group('a motion', () {
    test('describes itself for a screen reader', () {
      final catLabels = <String>{
        for (final motion in CatMotion.values) motion.semanticLabel(l10n),
      };
      expect(catLabels, hasLength(CatMotion.values.length));

      final roleLabels = <String>{
        for (final role in CharacterMotionRole.values)
          role.genericSemanticLabel(l10n),
      };
      expect(roleLabels, hasLength(CharacterMotionRole.values.length));
    });
  });

  group('a counted sentence', () {
    // Spanish needs the singular; Korean has no plural at all. Both are the
    // message's problem now, not the caller's.
    test('agrees with its number', () {
      expect(l10n.daysCount(1), '1 día');
      expect(l10n.daysCount(14), '14 días');
      expect(l10n.xpNoticeCyclesClosedTitle(1), 'Ciclo cerrado');
      expect(l10n.xpNoticeCyclesClosedTitle(2), '2 ciclos cerrados');
      expect(l10n.xpRuleDaysUnderDailyLimit(1), '1 día × 5 XP');
      expect(l10n.xpRuleDaysUnderDailyLimit(6), '6 días × 5 XP');
    });
  });
}
