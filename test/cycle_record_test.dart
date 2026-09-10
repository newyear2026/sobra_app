import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sobra_app/models/currency.dart';
import 'package:sobra_app/models/cycle_record.dart';
import 'package:sobra_app/models/expense_entry.dart';
import 'package:sobra_app/models/pay_schedule.dart';
import 'package:sobra_app/state/sobra_store.dart';

void main() {
  late DateTime now;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    now = DateTime(2026, 9, 1, 9);
  });

  Future<SobraStore> newUser({
    PaySchedule schedule = const PaySchedule.weekly(),
    int budget = 700000,
  }) async {
    final store = await SobraStore.load(now: () => now);
    await store.configureOnboarding(budgetCentavos: budget, schedule: schedule);
    await store.completeOnboarding();
    return store;
  }

  /// Moves the clock to [on] first: the store refuses a movement dated in the
  /// future, which is exactly what a test spending "later this cycle" is.
  Future<void> spend(SobraStore store, int amount, DateTime on) async {
    now = on;
    await store.addExpense(
      amountCentavos: amount,
      category: ExpenseCategory.food,
      note: '',
      occurredAt: on,
      paymentMethod: PaymentMethod.cash,
    );
  }

  group('closing a cycle', () {
    test('writes down what it came to', () async {
      final store = await newUser();
      await spend(store, 120000, DateTime(2026, 9, 7, 12));

      now = DateTime(2026, 9, 12, 9);
      await store.settleCycles();

      expect(store.cycleRecords, hasLength(1));
      final record = store.cycleRecords.single;
      expect(record.start, DateTime(2026, 9, 4));
      expect(record.end, DateTime(2026, 9, 10));
      expect(record.budgetCentavos, 700000);
      expect(record.spentCentavos, 120000);
      expect(record.resultCentavos, 580000);
      expect(record.successful, isTrue);
      expect(record.cycleType, PayCycleType.weekly);
      expect(record.lengthInDays, 7);
    });

    // The reason this exists at all: a history made only of good cycles would
    // show a trend that never happened.
    test('keeps a cycle that went over, which XP does not', () async {
      final store = await newUser(budget: 100000);
      await spend(store, 260000, DateTime(2026, 9, 7, 12));

      now = DateTime(2026, 9, 12, 9);
      await store.settleCycles();

      final overspent = store.cycleRecords.where((r) => !r.successful);
      expect(overspent, isNotEmpty);
      expect(overspent.first.spentCentavos, 260000);
      expect(overspent.first.resultCentavos, lessThan(0));
      expect(
        store.xpEvents.where((e) => e.kind.name == 'cycleInGreen'),
        isEmpty,
        reason: 'the cycle earned no XP, but it still happened',
      );
    });

    test('files each closed cycle once, however often we settle', () async {
      final store = await newUser();
      now = DateTime(2026, 9, 25, 9);
      await store.settleCycles();
      final first = store.cycleRecords.length;
      expect(first, greaterThan(1));

      await store.settleCycles();
      await store.settleCycles();
      expect(store.cycleRecords, hasLength(first));

      final starts = store.cycleRecords.map((r) => r.start).toList();
      expect(starts.toSet(), hasLength(starts.length));
    });

    test('hands them back newest first', () async {
      final store = await newUser();
      now = DateTime(2026, 9, 25, 9);
      await store.settleCycles();

      final records = store.cycleRecords;
      for (var i = 1; i < records.length; i++) {
        expect(records[i - 1].start.isAfter(records[i].start), isTrue);
      }
    });

    // A cycle the user only tracked half of would record a flatteringly small
    // spend, so it is left out rather than written down wrong.
    test(
      'skips a cycle that was already running when tracking began',
      () async {
        now = DateTime(2026, 9, 3, 9);
        final store = await newUser();
        now = DateTime(2026, 9, 12, 9);
        await store.settleCycles();

        for (final record in store.cycleRecords) {
          expect(
            record.start.isBefore(DateTime(2026, 9, 3)),
            isFalse,
            reason: 'no record may start before tracking did',
          );
        }
      },
    );
  });

  group('what a record protects', () {
    // The whole point: today's budget and today's schedule must not rewrite
    // what a cycle was when it closed.
    test('survives the budget changing afterwards', () async {
      final store = await newUser(budget: 700000);
      await spend(store, 120000, DateTime(2026, 9, 7, 12));
      now = DateTime(2026, 9, 12, 9);
      await store.settleCycles();

      await store.setTotalBudget(1500000);

      expect(store.cycleRecords.single.budgetCentavos, 700000);
    });

    test('survives the pay schedule changing afterwards', () async {
      final store = await newUser();
      now = DateTime(2026, 9, 12, 9);
      await store.settleCycles();
      final before = store.cycleRecords.map((r) => r.start).toList();

      await store.queuePayScheduleChange(
        PaySchedule.biweekly(anchor: DateTime(2026, 9, 14)),
      );
      now = DateTime(2026, 10, 20, 9);
      await store.settleCycles();

      final after = store.cycleRecords.map((r) => r.start).toList();
      expect(
        after.toSet().containsAll(before),
        isTrue,
        reason: 'the old windows must still be the windows that were lived',
      );
      expect(
        store.cycleRecords.any((r) => r.cycleType == PayCycleType.weekly),
        isTrue,
      );
    });

    // Currency is deliberately not stored: switching relabels the whole
    // ledger, so a record remembering pesos would be the odd one out.
    test(
      'is relabelled with everything else when the currency changes',
      () async {
        final store = await newUser();
        await spend(store, 120000, DateTime(2026, 9, 2, 12));
        now = DateTime(2026, 9, 12, 9);
        await store.settleCycles();
        final spent = store.cycleRecords.last.spentCentavos;

        await store.setCurrency(Currency.usd);

        expect(store.cycleRecords.last.spentCentavos, spent);
      },
    );
  });

  group('storing them', () {
    test('survives a reload', () async {
      final store = await newUser();
      await spend(store, 120000, DateTime(2026, 9, 7, 12));
      now = DateTime(2026, 9, 12, 9);
      await store.settleCycles();
      final expected = store.cycleRecords.length;

      final restored = await SobraStore.load(now: () => now);
      expect(restored.cycleRecords, hasLength(expected));
      expect(restored.cycleRecords.single.spentCentavos, 120000);
    });

    test('round-trips one record exactly', () {
      final record = CycleRecord(
        start: DateTime(2026, 9, 1),
        end: DateTime(2026, 9, 14),
        budgetCentavos: 600000,
        spentCentavos: 631000,
        cycleType: PayCycleType.biweekly,
      );
      final back = CycleRecord.fromJson(
        jsonDecode(jsonEncode(record.toJson())) as Map<String, dynamic>,
      );
      expect(back.start, record.start);
      expect(back.end, record.end);
      expect(back.budgetCentavos, 600000);
      expect(back.spentCentavos, 631000);
      expect(back.cycleType, PayCycleType.biweekly);
      expect(back.successful, isFalse);
    });

    test('reads data written before records existed', () async {
      final store = await newUser();
      final json = jsonDecode(store.exportJson()) as Map<String, dynamic>;
      json.remove('cycleRecords');
      SharedPreferences.setMockInitialValues({
        'sobra_state_v2': jsonEncode(json),
      });

      final restored = await SobraStore.load(now: () => now);
      expect(restored.cycleRecords, isEmpty);
    });
  });
}
