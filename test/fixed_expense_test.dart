import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sobra_app/models/cash_reconciliation.dart';
import 'package:sobra_app/models/expense_entry.dart';
import 'package:sobra_app/models/pay_schedule.dart';
import 'package:sobra_app/models/recurring_expense.dart';
import 'package:sobra_app/models/xp_event.dart';
import 'package:sobra_app/state/sobra_store.dart';

RecurringExpense _schedule(
  FixedFrequency frequency,
  DateTime anchor, {
  int amount = 10000,
}) => RecurringExpense(
  id: 'fixed-test',
  name: 'Test',
  amountCentavos: amount,
  category: ExpenseCategory.home,
  paymentMethod: PaymentMethod.card,
  unit: frequency.unit,
  interval: frequency.interval,
  anchorDate: anchor,
);

List<DateTime> _first(RecurringExpense expense, int count) => [
  for (var index = 0; index < count; index++) expense.occurrence(index),
];

void main() {
  group('due dates', () {
    test('a 31st is pulled back in short months and comes back after', () {
      final rent = _schedule(FixedFrequency.monthly, DateTime(2027, 1, 31));

      expect(_first(rent, 5), [
        DateTime(2027, 1, 31),
        DateTime(2027, 2, 28),
        // Counting from February's 28th would have stuck here for good.
        DateTime(2027, 3, 31),
        DateTime(2027, 4, 30),
        DateTime(2027, 5, 31),
      ]);
      expect(
        _schedule(FixedFrequency.monthly, DateTime(2028, 1, 31)).occurrence(1),
        DateTime(2028, 2, 29),
      );
    });

    test('every two months keeps to the months of the first bill', () {
      final cfe = _schedule(FixedFrequency.bimonthly, DateTime(2026, 9, 29));

      expect(_first(cfe, 4), [
        DateTime(2026, 9, 29),
        DateTime(2026, 11, 29),
        DateTime(2027, 1, 29),
        DateTime(2027, 3, 29),
      ]);
    });

    test('twice a month lands on the 15th and the last day', () {
      final abono = _schedule(
        FixedFrequency.semiMonthly,
        DateTime(2026, 9, 15),
      );

      expect(_first(abono, 4), [
        DateTime(2026, 9, 15),
        DateTime(2026, 9, 30),
        DateTime(2026, 10, 15),
        DateTime(2026, 10, 31),
      ]);
      expect(
        abono.occurrencesBetween(DateTime(2027, 2, 1), DateTime(2027, 2, 28)),
        [DateTime(2027, 2, 15), DateTime(2027, 2, 28)],
      );
    });

    test('twice a month can start from the second half', () {
      final abono = _schedule(
        FixedFrequency.semiMonthly,
        DateTime(2026, 9, 30),
      );

      expect(_first(abono, 3), [
        DateTime(2026, 9, 30),
        DateTime(2026, 10, 15),
        DateTime(2026, 10, 31),
      ]);
    });

    test('weekly repeats on the same weekday', () {
      final garrafon = _schedule(FixedFrequency.weekly, DateTime(2026, 9, 4));

      expect(
        garrafon.occurrencesBetween(
          DateTime(2026, 9, 1),
          DateTime(2026, 9, 30),
        ),
        [
          DateTime(2026, 9, 4),
          DateTime(2026, 9, 11),
          DateTime(2026, 9, 18),
          DateTime(2026, 9, 25),
        ],
      );
    });

    test('nothing is due before the first due date', () {
      final abono = _schedule(
        FixedFrequency.semiMonthly,
        DateTime(2026, 9, 15),
      );

      expect(
        abono.occurrencesBetween(DateTime(2026, 8, 1), DateTime(2026, 9, 20)),
        [DateTime(2026, 9, 15)],
      );
      expect(abono.lastOccurrenceOnOrBefore(DateTime(2026, 9, 14)), isNull);
      expect(
        abono.lastOccurrenceOnOrBefore(DateTime(2026, 9, 29)),
        DateTime(2026, 9, 15),
      );
      expect(abono.isOccurrence(DateTime(2026, 9, 30)), isTrue);
      expect(abono.isOccurrence(DateTime(2026, 9, 29)), isFalse);
    });

    test('a range years out still finds the right day', () {
      final rent = _schedule(FixedFrequency.monthly, DateTime(2026, 1, 31));

      expect(
        rent.occurrencesBetween(DateTime(2036, 2, 1), DateTime(2036, 2, 29)),
        [DateTime(2036, 2, 29)],
      );
    });

    test('survives a round trip through JSON', () {
      final cfe = _schedule(
        FixedFrequency.bimonthly,
        DateTime(2026, 9, 29),
      ).copyWith(isVariable: true, reminder: FixedReminder.threeDaysBefore);

      final back = RecurringExpense.fromJson(
        jsonDecode(jsonEncode(cfe.toJson())) as Map<String, dynamic>,
      );

      expect(back.toJson(), cfe.toJson());
      expect(back.frequency, FixedFrequency.bimonthly);
    });
  });

  group('the store', () {
    late DateTime now;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      // Sep 28 2026 falls in the Sep 16 – 30 quincena, three days from its end.
      now = DateTime(2026, 9, 28, 9);
    });

    Future<SobraStore> newUser({
      PaySchedule schedule = const PaySchedule.semiMonthly(),
      int budget = 690000,
    }) async {
      final store = await SobraStore.load(now: () => now);
      await store.configureOnboarding(
        budgetCentavos: budget,
        schedule: schedule,
      );
      await store.completeOnboarding();
      return store;
    }

    Future<RecurringExpense> addFixed(
      SobraStore store, {
      required String name,
      required FixedFrequency frequency,
      required DateTime firstDue,
      int amount = 20000,
      PaymentMethod method = PaymentMethod.card,
      bool isVariable = false,
    }) => store.addRecurringExpense(
      name: name,
      amountCentavos: amount,
      category: ExpenseCategory.home,
      paymentMethod: method,
      frequency: frequency,
      firstDueDate: firstDue,
      isVariable: isVariable,
    );

    test('paying rent leaves every budget figure where it was', () async {
      final store = await newUser();
      await store.addExpense(
        amountCentavos: 18000,
        category: ExpenseCategory.food,
        note: 'Tacos',
        occurredAt: now,
        paymentMethod: PaymentMethod.cash,
      );
      final rent = await addFixed(
        store,
        name: 'Renta',
        frequency: FixedFrequency.monthly,
        firstDue: DateTime(2026, 9, 28),
        amount: 800000,
      );
      final before = (
        store.dailyAllowanceCentavos,
        store.todayRemainingCentavos,
        store.totalSpentCentavos,
        store.remainingBudgetCentavos,
        store.budgetProgress,
        store.spentFor(ExpenseCategory.home),
      );

      final payment = await store.recordFixedPayment(
        recurringId: rent.id,
        occurrenceDate: DateTime(2026, 9, 28),
        amountCentavos: 800000,
      );

      expect((
        store.dailyAllowanceCentavos,
        store.todayRemainingCentavos,
        store.totalSpentCentavos,
        store.remainingBudgetCentavos,
        store.budgetProgress,
        store.spentFor(ExpenseCategory.home),
      ), before);
      expect(
        store.cycleSpending.map((entry) => entry.id),
        isNot(contains(payment.id)),
      );
      // Still in the ledger: the user sees where the money went.
      expect(store.transactions.map((entry) => entry.id), contains(payment.id));
      expect(
        store.movements.map((movement) => movement.id),
        contains(payment.id),
      );
      expect(payment.isFixedPayment, isTrue);
      expect(payment.note, 'Renta');
      expect(payment.category, ExpenseCategory.home);
      expect(payment.paymentMethod, PaymentMethod.card);
    });

    test('earns no XP and fills no daily mission', () async {
      final store = await newUser();
      final rent = await addFixed(
        store,
        name: 'Renta',
        frequency: FixedFrequency.monthly,
        firstDue: DateTime(2026, 9, 28),
      );
      final xpBefore = store.totalXp;

      await store.recordFixedPayment(
        recurringId: rent.id,
        occurrenceDate: DateTime(2026, 9, 28),
        amountCentavos: 20000,
      );

      expect(store.totalXp, xpBefore);
    });

    test(
      'a cash payment still leaves the wallet, and comes back if deleted',
      () async {
        final store = await newUser();
        await store.reconcileCashCount(
          actualCentavos: 200000,
          resolution: CashResolution.correction,
        );
        final phone = await addFixed(
          store,
          name: 'Celular',
          frequency: FixedFrequency.monthly,
          firstDue: DateTime(2026, 9, 28),
          method: PaymentMethod.cash,
        );
        now = DateTime(2026, 9, 28, 10);

        final payment = await store.recordFixedPayment(
          recurringId: phone.id,
          occurrenceDate: DateTime(2026, 9, 28),
          amountCentavos: 20000,
        );
        expect(store.expectedCashCentavos, 180000);

        expect(await store.deleteExpense(payment.id), isTrue);
        expect(store.expectedCashCentavos, 200000);
        expect(
          store.fixedOccurrencesInMonth(now).single.status,
          FixedOccurrenceStatus.dueToday,
        );
      },
    );

    test('a cycle that paid rent still closes green', () async {
      now = DateTime(2026, 9, 1, 9);
      final store = await newUser(
        schedule: const PaySchedule.weekly(),
        budget: 100000,
      );
      final rent = await addFixed(
        store,
        name: 'Renta',
        frequency: FixedFrequency.monthly,
        firstDue: DateTime(2026, 9, 7),
        amount: 800000,
      );
      now = DateTime(2026, 9, 7, 12);
      await store.recordFixedPayment(
        recurringId: rent.id,
        occurrenceDate: DateTime(2026, 9, 7),
        amountCentavos: 800000,
      );
      await store.addExpense(
        amountCentavos: 50000,
        category: ExpenseCategory.food,
        note: '',
        occurredAt: now,
        paymentMethod: PaymentMethod.card,
      );

      now = DateTime(2026, 9, 12, 9);
      await store.settleCycles();

      final record = store.cycleRecords.single;
      expect(record.spentCentavos, 50000);
      expect(record.fixedPaidCentavos, 800000);
      expect(record.successful, isTrue);
      expect(
        store.xpEvents.map((event) => event.kind),
        contains(XpEventKind.cycleInGreen),
      );
    });

    test('each due date of the month reads its own status', () async {
      final store = await newUser();
      final rent = await addFixed(
        store,
        name: 'Renta',
        frequency: FixedFrequency.monthly,
        firstDue: DateTime(2026, 9, 1),
        amount: 800000,
      );
      await addFixed(
        store,
        name: 'Abono',
        frequency: FixedFrequency.semiMonthly,
        firstDue: DateTime(2026, 9, 15),
      );
      await addFixed(
        store,
        name: 'Celular',
        frequency: FixedFrequency.monthly,
        firstDue: DateTime(2026, 9, 28),
      );
      await addFixed(
        store,
        name: 'Luz',
        frequency: FixedFrequency.bimonthly,
        firstDue: DateTime(2026, 9, 29),
      );
      await store.recordFixedPayment(
        recurringId: rent.id,
        occurrenceDate: DateTime(2026, 9, 1),
        amountCentavos: 800000,
        paidAt: DateTime(2026, 9, 1, 10),
      );

      final month = store.fixedOccurrencesInMonth(now);

      expect(
        [
          for (final occurrence in month)
            (occurrence.expense.name, occurrence.date.day, occurrence.status),
        ],
        [
          ('Renta', 1, FixedOccurrenceStatus.paid),
          ('Abono', 15, FixedOccurrenceStatus.overdue),
          ('Celular', 28, FixedOccurrenceStatus.dueToday),
          ('Luz', 29, FixedOccurrenceStatus.dueTomorrow),
          ('Abono', 30, FixedOccurrenceStatus.upcoming),
        ],
      );
      // Inicio asks about today and the last couple of days, not about a
      // payment missed two weeks ago.
      expect(
        store.fixedDueOnHome.map((occurrence) => occurrence.expense.name),
        ['Celular'],
      );
    });

    test('a payment settles the latest date that is still open', () async {
      final store = await newUser();
      final abono = await addFixed(
        store,
        name: 'Abono',
        frequency: FixedFrequency.semiMonthly,
        firstDue: DateTime(2026, 9, 15),
      );
      final garrafon = await addFixed(
        store,
        name: 'Garrafón',
        frequency: FixedFrequency.weekly,
        firstDue: DateTime(2026, 9, 4),
      );

      expect(store.nextUnpaidOccurrence(abono)!.date, DateTime(2026, 9, 15));
      await store.recordFixedPayment(
        recurringId: abono.id,
        occurrenceDate: DateTime(2026, 9, 15),
        amountCentavos: 20000,
      );
      expect(store.nextUnpaidOccurrence(abono)!.date, DateTime(2026, 9, 30));
      // Three older Fridays went unrecorded; only the latest is still asked.
      expect(store.nextUnpaidOccurrence(garrafon)!.date, DateTime(2026, 9, 25));
    });

    test('a variable bill takes what was paid as its next estimate', () async {
      final store = await newUser();
      final luz = await addFixed(
        store,
        name: 'Luz',
        frequency: FixedFrequency.bimonthly,
        firstDue: DateTime(2026, 9, 28),
        amount: 62000,
        isVariable: true,
      );
      final phone = await addFixed(
        store,
        name: 'Celular',
        frequency: FixedFrequency.monthly,
        firstDue: DateTime(2026, 9, 28),
      );

      await store.recordFixedPayment(
        recurringId: luz.id,
        occurrenceDate: DateTime(2026, 9, 28),
        amountCentavos: 68400,
      );
      await store.recordFixedPayment(
        recurringId: phone.id,
        occurrenceDate: DateTime(2026, 9, 28),
        amountCentavos: 25000,
      );

      expect(store.recurringExpenseById(luz.id)!.amountCentavos, 68400);
      expect(store.recurringExpenseById(phone.id)!.amountCentavos, 20000);
    });

    test('paying the same date twice files it once', () async {
      final store = await newUser();
      final rent = await addFixed(
        store,
        name: 'Renta',
        frequency: FixedFrequency.monthly,
        firstDue: DateTime(2026, 9, 28),
      );

      final first = await store.recordFixedPayment(
        recurringId: rent.id,
        occurrenceDate: DateTime(2026, 9, 28),
        amountCentavos: 20000,
      );
      final second = await store.recordFixedPayment(
        recurringId: rent.id,
        occurrenceDate: DateTime(2026, 9, 28),
        amountCentavos: 20000,
      );

      expect(second.id, first.id);
      expect(store.transactions, hasLength(1));
    });

    test('refuses a date that is not one of its due dates', () async {
      final store = await newUser();
      final rent = await addFixed(
        store,
        name: 'Renta',
        frequency: FixedFrequency.monthly,
        firstDue: DateTime(2026, 9, 1),
      );

      expect(
        () => store.recordFixedPayment(
          recurringId: rent.id,
          occurrenceDate: DateTime(2026, 9, 2),
          amountCentavos: 20000,
        ),
        throwsArgumentError,
      );
    });

    test('an edited or orphaned payment stays out of the budget', () async {
      final store = await newUser();
      final rent = await addFixed(
        store,
        name: 'Renta',
        frequency: FixedFrequency.monthly,
        firstDue: DateTime(2026, 9, 28),
      );
      final payment = await store.recordFixedPayment(
        recurringId: rent.id,
        occurrenceDate: DateTime(2026, 9, 28),
        amountCentavos: 20000,
      );

      await store.updateExpense(payment.copyWith(amountCentavos: 21000));
      await store.deleteRecurringExpense(rent.id);

      final kept = store.transactions.single;
      expect(kept.isFixedPayment, isTrue);
      expect(kept.amountCentavos, 21000);
      expect(store.totalSpentCentavos, 0);
      expect(store.recurringExpenses, isEmpty);
    });

    test(
      'weekly bills start without a reminder, the rest a day before',
      () async {
        final store = await newUser();
        final garrafon = await addFixed(
          store,
          name: 'Garrafón',
          frequency: FixedFrequency.weekly,
          firstDue: DateTime(2026, 10, 2),
        );
        final rent = await addFixed(
          store,
          name: 'Renta',
          frequency: FixedFrequency.monthly,
          firstDue: DateTime(2026, 10, 1),
        );

        expect(garrafon.reminder, FixedReminder.none);
        expect(rent.reminder, FixedReminder.dayBefore);
      },
    );

    test('everything survives a restart', () async {
      final store = await newUser();
      final rent = await addFixed(
        store,
        name: 'Renta',
        frequency: FixedFrequency.monthly,
        firstDue: DateTime(2026, 9, 28),
        amount: 800000,
      );
      await store.recordFixedPayment(
        recurringId: rent.id,
        occurrenceDate: DateTime(2026, 9, 28),
        amountCentavos: 800000,
      );

      final reloaded = await SobraStore.load(now: () => now);

      expect(reloaded.recurringExpenses.single.toJson(), rent.toJson());
      expect(reloaded.transactions.single.isFixedPayment, isTrue);
      expect(reloaded.totalSpentCentavos, 0);
      expect(
        reloaded.fixedOccurrencesInMonth(now).single.status,
        FixedOccurrenceStatus.paid,
      );
    });

    test('a state saved before fixed expenses existed still opens', () async {
      final store = await newUser();
      await store.addExpense(
        amountCentavos: 18000,
        category: ExpenseCategory.food,
        note: 'Tacos',
        occurredAt: now,
        paymentMethod: PaymentMethod.cash,
      );
      final preferences = await SharedPreferences.getInstance();
      final saved =
          jsonDecode(preferences.getString('sobra_state_v2')!)
              as Map<String, dynamic>;
      saved.remove('recurringExpenses');
      for (final entry in saved['transactions'] as List<dynamic>) {
        (entry as Map<String, dynamic>)
          ..remove('recurringId')
          ..remove('occurrenceDate');
      }
      await preferences.setString('sobra_state_v2', jsonEncode(saved));

      final reloaded = await SobraStore.load(now: () => now);

      expect(reloaded.hasStorageError, isFalse);
      expect(reloaded.recurringExpenses, isEmpty);
      expect(reloaded.totalSpentCentavos, 18000);
    });
  });
}
