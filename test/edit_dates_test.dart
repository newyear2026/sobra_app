import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sobra_app/main.dart';
import 'package:sobra_app/models/cash_reconciliation.dart';
import 'package:sobra_app/models/expense_entry.dart';
import 'package:sobra_app/models/income_entry.dart';
import 'package:sobra_app/models/pay_schedule.dart';
import 'package:sobra_app/models/recurring_expense.dart';
import 'package:sobra_app/state/sobra_store.dart';
import 'package:sobra_app/widgets/transaction_row.dart';

import 'support/localizations.dart';

/// Dates on file can move, and the savings figures the app already had are
/// where people look. Both came from the same Play review.
void main() {
  late DateTime now;

  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<SobraStore> newUser({
    PaySchedule schedule = const PaySchedule.semiMonthly(),
    int budget = 600000,
    int? cash,
  }) async {
    final store = await SobraStore.load(now: () => now);
    await store.configureOnboarding(
      budgetCentavos: budget,
      schedule: schedule,
      cashCentavos: cash,
    );
    await store.completeOnboarding();
    return store;
  }

  Future<IncomeEntry> income(
    SobraStore store, {
    required DateTime on,
    IncomeAllocation allocation = IncomeAllocation.cycle,
  }) => store.addIncome(
    amountCentavos: 50000,
    kind: IncomeKind.extra,
    note: 'Propina',
    occurredAt: on,
    destination: PaymentMethod.card,
    allocation: allocation,
  );

  IncomeEntry rewritten(
    IncomeEntry entry, {
    DateTime? occurredAt,
    IncomeAllocation? allocation,
  }) => IncomeEntry(
    id: entry.id,
    amountCentavos: entry.amountCentavos,
    kind: entry.kind,
    note: entry.note,
    occurredAt: occurredAt ?? entry.occurredAt,
    destination: entry.destination,
    allocation: allocation ?? entry.allocation,
  );

  group('updateIncome', () {
    test(
      'a new date takes the cycle money to the cycle it now falls in',
      () async {
        now = DateTime(2026, 3, 20, 9);
        final store = await newUser();
        final entry = await income(store, on: DateTime(2026, 3, 18, 12));
        expect(store.cycleBudgetExtrasCentavos, 50000);

        // 3/10 sits in the cycle before, which the current one no longer sees.
        final changed = await store.updateIncome(
          rewritten(entry, occurredAt: DateTime(2026, 3, 10, 12)),
        );

        expect(changed, isTrue);
        expect(store.cycleBudgetExtrasCentavos, 0);
        expect(store.incomes.single.occurredAt, DateTime(2026, 3, 10, 12));
      },
    );

    test(
      'moving it to savings leaves the budget and counts as saved',
      () async {
        now = DateTime(2026, 3, 20, 9);
        final store = await newUser();
        final entry = await income(store, on: DateTime(2026, 3, 18, 12));

        await store.updateIncome(
          rewritten(entry, allocation: IncomeAllocation.savings),
        );

        expect(store.cycleBudgetExtrasCentavos, 0);
        expect(store.savedThisCycleCentavos, 50000);
      },
    );

    test('a cash-count income stays as the count left it', () async {
      now = DateTime(2026, 3, 10, 9);
      final store = await newUser(cash: 200000);
      now = DateTime(2026, 3, 11, 9);
      await store.reconcileCashCount(
        actualCentavos: 230000,
        resolution: CashResolution.income,
      );
      final counted = store.incomes.single;

      final changed = await store.updateIncome(
        rewritten(counted, occurredAt: DateTime(2026, 3, 9, 12)),
      );

      expect(changed, isFalse);
      expect(store.incomes.single.occurredAt, counted.occurredAt);
    });
  });

  test(
    'a fixed payment moves its paid day and keeps its installment',
    () async {
      now = DateTime(2026, 10, 8, 12);
      final store = await newUser();
      final bill = await store.addRecurringExpense(
        name: 'Renta',
        amountCentavos: 200000,
        category: ExpenseCategory.home,
        paymentMethod: PaymentMethod.card,
        frequency: FixedFrequency.monthly,
        firstDueDate: DateTime(2026, 10, 1),
      );
      final payment = await store.recordFixedPayment(
        recurringId: bill.id,
        occurrenceDate: DateTime(2026, 10, 1),
        amountCentavos: 200000,
        paidAt: DateTime(2026, 10, 2, 12),
      );

      await store.updateExpense(
        payment.copyWith(occurredAt: DateTime(2026, 10, 5, 12)),
      );

      final moved = store.transactions.single;
      expect(moved.occurredAt, DateTime(2026, 10, 5, 12));
      expect(moved.occurrenceDate, DateTime(2026, 10, 1));
      final installment = store
          .fixedOccurrencesInMonth(DateTime(2026, 10))
          .singleWhere((occurrence) => occurrence.expense.id == bill.id);
      expect(
        installment.payment?.id,
        payment.id,
        reason: 'the 10/1 installment is still the one this paid',
      );
    },
  );

  test('closed cycles net their overruns against what they left', () async {
    now = DateTime(2026, 9, 4, 9);
    final store = await newUser(
      schedule: const PaySchedule.weekly(),
      budget: 100000,
    );
    Future<void> spend(int amount, DateTime on) async {
      now = on;
      await store.addExpense(
        amountCentavos: amount,
        category: ExpenseCategory.food,
        note: '',
        occurredAt: on,
        paymentMethod: PaymentMethod.cash,
      );
    }

    // One week under by 300, the next over by 500.
    await spend(70000, DateTime(2026, 9, 7, 12));
    await spend(150000, DateTime(2026, 9, 14, 12));
    now = DateTime(2026, 9, 19, 9);
    await store.settleCycles();

    final results = store.cycleRecords
        .where((record) => record.budgetCentavos > 0)
        .map((record) => record.resultCentavos);
    expect(store.closedCyclesResultCentavos, results.reduce((a, b) => a + b));
    expect(
      store.closedCyclesResultCentavos,
      lessThan(results.reduce((a, b) => a > b ? a : b)),
    );
  });

  group('on screen', () {
    Future<void> settle(WidgetTester tester) async {
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    Future<void> openLedger(WidgetTester tester, SobraStore store) async {
      useSpanishDevice(tester);
      tester.view.physicalSize = const Size(520, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(SobraApp(store: store));
      await tester.pump();
      await tester.tap(find.text('Movim.'));
      await tester.pump();
    }

    testWidgets('an expense takes a new day from its sheet', (tester) async {
      now = DateTime(2026, 3, 10, 9);
      final store = await newUser();
      await store.addExpense(
        amountCentavos: 12000,
        category: ExpenseCategory.food,
        note: 'Tacos',
        occurredAt: now,
        paymentMethod: PaymentMethod.card,
      );

      await openLedger(tester, store);
      await tester.tap(find.text('Tacos'));
      await settle(tester);
      expect(find.text('Fecha'), findsOneWidget);
      expect(find.text('10 mar 2026'), findsOneWidget);

      await tester.tap(find.text('10 mar 2026'));
      await settle(tester);
      await tester.tap(find.text('8'));
      // The picker's confirm button, whatever Material calls it in Spanish.
      await tester.tap(
        find
            .descendant(
              of: find.byType(DatePickerDialog),
              matching: find.byType(TextButton),
            )
            .last,
      );
      await settle(tester);
      expect(find.text('8 mar 2026'), findsOneWidget);

      await tester.tap(find.text('Guardar cambios'));
      await settle(tester);
      // A past day files at noon, the way a new past expense would.
      expect(store.transactions.single.occurredAt, DateTime(2026, 3, 8, 12));
    });

    testWidgets('a cash-count expense shows its date locked', (tester) async {
      now = DateTime(2026, 3, 10, 9);
      final store = await newUser(cash: 200000);
      now = DateTime(2026, 3, 11, 9);
      await store.reconcileCashCount(
        actualCentavos: 170000,
        resolution: CashResolution.expense,
      );

      await openLedger(tester, store);
      await tester.tap(find.byType(MovementRow).first);
      await settle(tester);

      expect(find.text('11 mar 2026'), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline), findsWidgets);
      expect(find.byIcon(Icons.expand_more), findsNothing);
    });

    testWidgets('an income row opens its own editor', (tester) async {
      now = DateTime(2026, 3, 20, 9);
      final store = await newUser();
      await income(store, on: DateTime(2026, 3, 18, 12));

      await openLedger(tester, store);
      await tester.tap(find.text('Ingreso'));
      await tester.pump();
      await tester.tap(find.byType(MovementRow).first);
      await settle(tester);
      expect(find.text('Editar ingreso'), findsOneWidget);

      await tester.tap(find.text('Guardarlo'));
      await tester.pump();
      await tester.ensureVisible(find.text('Guardar cambios'));
      await tester.tap(find.text('Guardar cambios'));
      await settle(tester);

      expect(store.incomes.single.allocation, IncomeAllocation.savings);
      expect(find.text('Editar ingreso'), findsNothing);
    });

    testWidgets('Inicio says where the cycle is heading', (tester) async {
      now = DateTime(2026, 3, 20, 9);
      final store = await newUser();
      await store.takeLaunchGiftNotice();
      useSpanishDevice(tester);
      tester.view.physicalSize = const Size(520, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(SobraApp(store: store));
      await tester.pump();

      expect(
        find.textContaining('A este ritmo, al cierre del'),
        findsOneWidget,
      );
      expect(find.textContaining('te sobran'), findsOneWidget);
    });
  });
}
