import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sobra_app/models/expense_entry.dart';
import 'package:sobra_app/models/pay_schedule.dart';
import 'package:sobra_app/models/xp_event.dart';
import 'package:sobra_app/state/sobra_store.dart';

void main() {
  final anchor = DateTime(2026, 9, 4);
  final schedule = PaySchedule.biweekly(anchor: anchor);

  group('a fortnight', () {
    test('opens on the anchor and runs fourteen days', () {
      final bounds = schedule.boundsFor(anchor);
      expect(bounds.start, DateTime(2026, 9, 4));
      expect(bounds.end, DateTime(2026, 9, 17));
      expect(bounds.lengthInDays, 14);
    });

    test('is the same window all the way to its last day', () {
      for (var day = 4; day <= 17; day++) {
        final bounds = schedule.boundsFor(DateTime(2026, 9, day));
        expect(bounds.start, DateTime(2026, 9, 4), reason: 'Sep $day');
      }
      expect(
        schedule.boundsFor(DateTime(2026, 9, 18)).start,
        DateTime(2026, 9, 18),
        reason: 'the fifteenth day opens the next one',
      );
    });

    // This is what makes it not a quincena: a fortnight does not reset with
    // the month, it walks through it.
    test('walks across month and year boundaries', () {
      expect(
        schedule.boundsFor(DateTime(2026, 10, 3)).start,
        DateTime(2026, 10, 2),
      );
      expect(
        schedule.boundsFor(DateTime(2026, 10, 3)).end,
        DateTime(2026, 10, 15),
      );
      final newYear = schedule.boundsFor(DateTime(2027, 1, 1));
      expect(newYear.lengthInDays, 14);
      expect(newYear.contains(DateTime(2027, 1, 1)), isTrue);
    });

    // A user picks "my last payday", then edits something from before it.
    test('still places a day earlier than the anchor', () {
      final before = schedule.boundsFor(DateTime(2026, 8, 25));
      expect(before.start, DateTime(2026, 8, 21));
      expect(before.end, DateTime(2026, 9, 3));
      expect(before.lengthInDays, 14);
      expect(before.contains(DateTime(2026, 8, 25)), isTrue);
    });

    test('leaves no gap and no overlap between neighbours', () {
      var cursor = DateTime(2026, 7, 1);
      CycleBounds? previous;
      while (cursor.isBefore(DateTime(2027, 1, 1))) {
        final bounds = schedule.boundsFor(cursor);
        if (previous != null && bounds.start != previous.start) {
          expect(
            bounds.start,
            previous.end.add(const Duration(days: 1)),
            reason: 'a cycle must start the day after the last one ended',
          );
        }
        previous = bounds;
        cursor = cursor.add(const Duration(days: 1));
      }
    });

    // Twenty-six a year, against the quincena's twenty-four. Keeping both is
    // the whole point: the habit and the paycheque disagree.
    test('is a different schedule from the quincena', () {
      const quincena = PaySchedule.semiMonthly(firstPayDay: 15);
      final quincenaBounds = quincena.boundsFor(DateTime(2026, 9, 20));
      expect(quincenaBounds.start, DateTime(2026, 9, 15));
      expect(quincenaBounds.lengthInDays, isNot(14));

      expect(
        schedule.boundsFor(DateTime(2026, 9, 20)).start,
        isNot(quincenaBounds.start),
      );
    });

    test('falls back to today when no anchor was saved', () {
      const orphan = PaySchedule(type: PayCycleType.biweekly);
      final bounds = orphan.boundsFor(DateTime(2026, 9, 20));
      expect(bounds.start, DateTime(2026, 9, 20));
      expect(bounds.lengthInDays, 14);
    });
  });

  group('an irregular horizon', () {
    // Both now run on the same anchored-block maths, so the existing
    // behaviour has to be unchanged by the refactor.
    test('still repeats from its own start', () {
      final weekly = PaySchedule.irregular(
        planningHorizonDays: 7,
        irregularCycleStart: DateTime(2026, 9, 1),
      );
      expect(weekly.boundsFor(DateTime(2026, 9, 1)).end, DateTime(2026, 9, 7));
      expect(
        weekly.boundsFor(DateTime(2026, 9, 8)).start,
        DateTime(2026, 9, 8),
      );
      expect(
        weekly.boundsFor(DateTime(2026, 8, 30)).start,
        DateTime(2026, 8, 25),
      );
    });

    test('refuses a horizon of no days', () {
      final broken = PaySchedule.irregular(
        planningHorizonDays: 0,
        irregularCycleStart: DateTime(2026, 9, 1),
      );
      expect(() => broken.boundsFor(DateTime(2026, 9, 2)), throwsStateError);
    });
  });

  group('saving it', () {
    test('round-trips the anchor', () {
      final restored = PaySchedule.fromJson(
        jsonDecode(jsonEncode(schedule.toJson())) as Map<String, dynamic>,
      );
      expect(restored.type, PayCycleType.biweekly);
      expect(restored.biweeklyAnchor, anchor);
      expect(restored.boundsFor(anchor).end, DateTime(2026, 9, 17));
    });

    // Adding an enum value has to leave data written before it readable, and
    // the dropdown order must not be what decides that.
    test('reads a schedule saved before this type existed', () {
      final old = PaySchedule.fromJson({
        'type': 'semiMonthly',
        'firstPayDay': 15,
        'secondPayDay': 0,
        'monthlyPayDay': 30,
        'weeklyPayDay': DateTime.friday,
        'planningHorizonDays': 7,
        'irregularCycleStart': null,
      });
      expect(old.type, PayCycleType.semiMonthly);
      expect(old.biweeklyAnchor, isNull);
    });
  });

  group('the store', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('settles fortnights and scales their XP to fourteen days', () async {
      var now = DateTime(2026, 9, 4, 9);
      final store = await SobraStore.load(now: () => now);
      await store.configureOnboarding(
        budgetCentavos: 700000,
        schedule: PaySchedule.biweekly(anchor: DateTime(2026, 9, 4)),
      );
      await store.completeOnboarding();
      expect(store.cycleStart, DateTime(2026, 9, 4));
      expect(store.cycleEnd, DateTime(2026, 9, 17));

      await store.addExpense(
        amountCentavos: 1000,
        category: ExpenseCategory.food,
        note: '',
        occurredAt: now,
        paymentMethod: PaymentMethod.cash,
      );

      now = DateTime(2026, 9, 19, 9);
      await store.settleCycles();

      final closed = store.xpEvents.where(
        (event) => event.kind == XpEventKind.cycleInGreen,
      );
      expect(closed, isNotEmpty);
      final event = closed.first;
      expect(event.cycleType, PayCycleType.biweekly);
      expect(
        event.cycleEnd!.difference(event.cycleStart!).inDays + 1,
        14,
        reason: 'the reward is scaled to the length it actually ran',
      );
      // 14 days against the 15-day reference: 14 * 100 / 15, rounded to 5.
      expect(event.xp, 95);
    });

    test('keeps a fortnight that spans a month change in one cycle', () async {
      final now = DateTime(2026, 10, 1, 9);
      final store = await SobraStore.load(now: () => now);
      await store.configureOnboarding(
        budgetCentavos: 700000,
        schedule: PaySchedule.biweekly(anchor: DateTime(2026, 9, 18)),
      );
      await store.completeOnboarding();

      expect(store.cycleStart, DateTime(2026, 9, 18));
      expect(store.cycleEnd, DateTime(2026, 10, 1));
      expect(store.daysRemaining, 1);
    });
  });
}
