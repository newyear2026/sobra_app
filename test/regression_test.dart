import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'support/localizations.dart';
import 'package:sobra_app/main.dart';
import 'package:sobra_app/models/cash_reconciliation.dart';
import 'package:sobra_app/models/currency.dart';
import 'package:sobra_app/models/expense_entry.dart';
import 'package:sobra_app/models/income_entry.dart';
import 'package:sobra_app/models/money_movement.dart';
import 'package:sobra_app/models/pay_schedule.dart';
import 'package:sobra_app/screens/cash_count_screen.dart';
import 'package:sobra_app/state/sobra_store.dart';
import 'package:sobra_app/widgets/cat_sprite.dart';
import 'package:sobra_app/widgets/pixel_ui.dart';

Future<SobraStore> _seeded(DateTime Function() now, {int? cash}) async {
  SharedPreferences.setMockInitialValues({});
  final store = await SobraStore.load(now: now);
  await store.configureOnboarding(
    budgetCentavos: 600000,
    schedule: const PaySchedule.semiMonthly(),
    cashCentavos: cash,
  );
  return store;
}

void main() {
  test('money parser treats display commas as grouping separators', () {
    expect(parseAmount(Currency.mxn, '1,200'), 120000);
    expect(parseAmount(Currency.mxn, r'$1,200.50 MXN'), 120050);
    expect(parseAmount(Currency.mxn, '1200,50'), 120050);
    expect(parseAmount(Currency.mxn, '1,000,000'), 100000000);
    expect(parseNonNegativeAmount(Currency.mxn, '0'), 0);
    expect(parseAmount(Currency.mxn, '1,20,0'), isNull);
    expect(parseNonNegativeAmount(Currency.mxn, '.'), isNull);
  });

  test('money parser turns down what it cannot register faithfully', () {
    // Finer than a centavo used to round: 0.001 registered as nothing at all
    // and 9.999 as ten pesos.
    expect(parseAmount(Currency.mxn, '0.001'), isNull);
    expect(parseAmount(Currency.mxn, '9.999'), isNull);
    expect(parseNonNegativeAmount(Currency.mxn, '0.001'), isNull);
    // And a pasted wall of digits used to land at the far end of int64.
    expect(parseAmount(Currency.mxn, '99999999999999999999'), isNull);
    expect(parseAmount(Currency.mxn, '9.99'), 999);
    expect(parseAmount(Currency.mxn, '999999999999'), 99999999999900);
  });

  testWidgets('Inicio relabels its headline when the cycle goes over', (
    tester,
  ) async {
    useSpanishDevice(tester);
    tester.view.physicalSize = const Size(520, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final now = DateTime(2026, 9, 4, 10);
    final store = await _seeded(() => now);
    await store.completeOnboarding();
    await tester.pumpWidget(SobraApp(store: store));
    await tester.pump();

    expect(find.text('Hoy te queda'), findsOneWidget);
    expect(find.text('Saldo del ciclo'), findsNothing);

    await store.addExpense(
      amountCentavos: 800000,
      category: ExpenseCategory.transport,
      note: 'Transporte',
      occurredAt: now,
      paymentMethod: PaymentMethod.cash,
    );
    await tester.pump();

    // 8,000 out of a 6,000 budget: the headline is the cycle's −2,000, under
    // a label that says so, rather than the day's slice minus the whole
    // expense.
    expect(find.text('Saldo del ciclo'), findsOneWidget);
    expect(find.text('Hoy te queda'), findsNothing);
    expect(find.text('$minusSign\$2,000 MXN'), findsOneWidget);
    final cat = tester.widget<CatSprite>(find.byType(CatSprite));
    expect(cat.motion, CatMotion.concern);
    expect(cat.loop, isFalse);
  });

  testWidgets('saving an expense closes its own dialog and returns to Inicio', (
    tester,
  ) async {
    useSpanishDevice(tester);
    tester.view.physicalSize = const Size(520, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({});
    final store = await SobraStore.load();
    await store.configureOnboarding(
      budgetCentavos: 600000,
      schedule: const PaySchedule.semiMonthly(),
      cashCentavos: 200000,
    );
    await store.completeOnboarding();

    await tester.pumpWidget(SobraApp(store: store));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    await tester.enterText(find.byType(TextFormField).first, '180');
    await tester.pump();
    await tester.dragUntilVisible(
      find.text('Guardar'),
      find.byType(SingleChildScrollView),
      const Offset(0, -120),
    );
    await tester.pump();
    await tester.tap(find.text('Guardar'));
    // Not pumpAndSettle: the cat on Inicio loops forever, so nothing settles.
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }
    // Recording today posts an XP toast over the nav. Hide it so the
    // register tile can be tapped again.
    ScaffoldMessenger.of(
      tester.element(find.text('Movimientos recientes')),
    ).hideCurrentSnackBar();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(store.transactions, hasLength(1));
    expect(find.byType(Dialog), findsNothing, reason: 'dialog must close');
    // The shell hopped back to Inicio, which is where onSaved points it.
    expect(find.text('Movimientos recientes'), findsOneWidget);

    // And the form it left behind is blank, ready for the next expense.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    expect(
      tester
          .widget<TextFormField>(find.byType(TextFormField).first)
          .controller
          ?.text,
      isEmpty,
    );
  });

  testWidgets('a cash shortage offers transfer and correction choices', (
    tester,
  ) async {
    useSpanishDevice(tester);
    tester.view.physicalSize = const Size(520, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final fixed = DateTime(2026, 3, 10, 9);
    final store = await _seeded(() => fixed, cash: 200000);
    await tester.pumpWidget(
      SobraScope(
        store: store,
        child: const MaterialApp(
          localizationsDelegates: sobraLocalizationsDelegates,
          supportedLocales: sobraSupportedLocales,
          home: CashCountScreen(),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField).first, '1700');
    await tester.pump();

    expect(find.text('Gasto identificado'), findsOneWidget);
    expect(find.text('Movimiento entre cuentas'), findsOneWidget);
    expect(find.text('Corrección del conteo'), findsOneWidget);
    expect(find.text('Ingreso en efectivo'), findsNothing);
  });

  test('cycle income still counts after a pay-schedule change', () async {
    var now = DateTime(2026, 3, 10, 9);
    final store = await _seeded(() => now);
    await store.queuePayScheduleChange(const PaySchedule.weekly());
    final effectiveAt = store.cycleEnd.add(const Duration(days: 1));
    now = DateTime(effectiveAt.year, effectiveAt.month, effectiveAt.day, 9);
    await store.refreshForCurrentDate();

    // The floor clamps the first cycle, so raw and real bounds disagree here.
    expect(store.cycleStart, isNot(store.paySchedule.boundsFor(now).start));

    final before = store.totalBudgetCentavos;
    final income = await store.addIncome(
      amountCentavos: 50000,
      kind: IncomeKind.extra,
      note: 'Propina',
      occurredAt: now,
      destination: PaymentMethod.card,
      allocation: IncomeAllocation.cycle,
    );
    expect(store.totalBudgetCentavos - before, 50000);

    await store.deleteIncome(income.id);
    expect(store.totalBudgetCentavos, before, reason: 'and it reverses');
  });

  test('saving the displayed budget does not add cycle income twice', () async {
    final fixed = DateTime(2026, 3, 10, 9);
    final store = await _seeded(() => fixed);
    await store.addIncome(
      amountCentavos: 50000,
      kind: IncomeKind.extra,
      note: 'Propina',
      occurredAt: fixed,
      destination: PaymentMethod.card,
      allocation: IncomeAllocation.cycle,
    );

    expect(store.baseBudgetCentavos, 600000);
    expect(store.totalBudgetCentavos, 650000);

    await store.setTotalBudget(store.totalBudgetCentavos);

    expect(store.baseBudgetCentavos, 600000);
    expect(store.totalBudgetCentavos, 650000);

    final restored = await SobraStore.load(now: () => fixed);
    expect(restored.baseBudgetCentavos, 600000);
    expect(restored.totalBudgetCentavos, 650000);
  });

  group('an expense that came from a cash count', () {
    late SobraStore store;
    late ExpenseEntry linked;

    Future<void> setUpGap() async {
      var now = DateTime(2026, 3, 10, 9);
      store = await _seeded(() => now, cash: 200000);
      now = DateTime(2026, 3, 11, 9);
      await store.reconcileCashCount(
        actualCentavos: 170000,
        resolution: CashResolution.pending,
      );
      linked = store.transactions.firstWhere((e) => e.isLinkedToCashCount);
    }

    test('cannot be deleted', () async {
      await setUpGap();
      expect(await store.deleteExpense(linked.id), isFalse);
      expect(store.totalSpentCentavos, 30000);
      expect(store.transactions, hasLength(1));
    });

    test('keeps its measured amount when edited', () async {
      await setUpGap();
      await store.updateExpense(
        linked.copyWith(
          amountCentavos: 500,
          category: ExpenseCategory.food,
          note: 'Tacos',
        ),
      );
      final after = store.transactions.single;
      expect(after.amountCentavos, 30000, reason: 'the measurement holds');
      expect(
        after.category,
        ExpenseCategory.food,
        reason: 'but this is theirs',
      );
      expect(after.note, 'Tacos');
      expect(store.totalSpentCentavos, 30000);
      expect(store.expectedCashCentavos, 170000);
    });

    test('an ordinary expense is still fully editable', () async {
      final fixed = DateTime(2026, 3, 10, 9);
      final store = await _seeded(() => fixed);
      final entry = await store.addExpense(
        amountCentavos: 1000,
        category: ExpenseCategory.food,
        note: 'A',
        occurredAt: fixed,
        paymentMethod: PaymentMethod.card,
      );
      await store.updateExpense(entry.copyWith(amountCentavos: 2500));
      expect(store.totalSpentCentavos, 2500);
      expect(await store.deleteExpense(entry.id), isTrue);
      expect(store.totalSpentCentavos, 0);
    });
  });

  group('an income that came from a cash count', () {
    late SobraStore store;
    late IncomeEntry linked;

    Future<void> setUpSurplus() async {
      var now = DateTime(2026, 3, 10, 9);
      store = await _seeded(() => now, cash: 200000);
      now = DateTime(2026, 3, 11, 9);
      await store.reconcileCashCount(
        actualCentavos: 230000,
        resolution: CashResolution.income,
        incomeAllocation: IncomeAllocation.cycle,
      );
      linked = store.incomes.firstWhere((entry) => entry.isLinkedToCashCount);
    }

    test('cannot be deleted, so the count keeps its row', () async {
      await setUpSurplus();
      // The reconciliation suppresses its own movement in favour of this
      // income. Letting the income go would take the count off the ledger
      // while the counted cash figure kept the money.
      expect(await store.deleteIncome(linked.id), isFalse);
      expect(store.incomes, hasLength(1));
      expect(store.totalBudgetCentavos, 630000);
      expect(
        store.movements.where((movement) => movement.income?.id == linked.id),
        hasLength(1),
      );
    });

    test('an ordinary income is still deletable', () async {
      final fixed = DateTime(2026, 3, 10, 9);
      final store = await _seeded(() => fixed, cash: 200000);
      final entry = await store.addIncome(
        amountCentavos: 50000,
        kind: IncomeKind.extra,
        note: 'Propina',
        occurredAt: fixed,
        destination: PaymentMethod.cash,
        allocation: IncomeAllocation.cycle,
      );
      expect(await store.deleteIncome(entry.id), isTrue);
      expect(store.incomes, isEmpty);
      expect(store.totalBudgetCentavos, 600000);
    });
  });

  testWidgets('Ingresos offers no way to delete a cash-count income', (
    tester,
  ) async {
    useSpanishDevice(tester);
    tester.view.physicalSize = const Size(520, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var now = DateTime(2026, 3, 10, 9);
    SharedPreferences.setMockInitialValues({});
    final store = await SobraStore.load(now: () => now);
    await store.configureOnboarding(
      budgetCentavos: 600000,
      schedule: const PaySchedule.semiMonthly(),
      cashCentavos: 200000,
    );
    await store.completeOnboarding();
    now = DateTime(2026, 3, 11, 9);
    await store.reconcileCashCount(
      actualCentavos: 230000,
      resolution: CashResolution.income,
    );

    await tester.pumpWidget(SobraApp(store: store));
    await tester.pump();
    await tester.tap(find.text('Movim.'));
    await tester.pump();
    // The ledger opens on Gasto, and the income half of a count only lives on
    // the other segment.
    await tester.tap(find.text('Ingreso'));
    await tester.pump();

    // The count hides its own row behind this income, and the income cannot
    // be edited either, so the row carries no menu at all rather than a
    // button that opens onto nothing.
    expect(find.text('Ingreso en efectivo'), findsWidgets);
    expect(find.byType(PopupMenuButton<String>), findsNothing);

    // An ordinary income beside it still gets its Eliminar.
    await store.addIncome(
      amountCentavos: 50000,
      kind: IncomeKind.extra,
      note: 'Propina',
      occurredAt: now,
      destination: PaymentMethod.cash,
      allocation: IncomeAllocation.cycle,
    );
    await tester.pump();
    expect(find.byType(PopupMenuButton<String>), findsOneWidget);

    await tester.tap(find.byType(PopupMenuButton<String>));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('Eliminar'), findsOneWidget);
    expect(find.text('Editar'), findsNothing, reason: 'income has no editor');
  });

  test('undo cannot file the same entry twice', () async {
    final fixed = DateTime(2026, 3, 10, 9);
    final store = await _seeded(() => fixed);
    final entry = await store.addExpense(
      amountCentavos: 1000,
      category: ExpenseCategory.food,
      note: 'A',
      occurredAt: fixed,
      paymentMethod: PaymentMethod.card,
    );
    await store.deleteExpense(entry.id);
    await store.restoreExpense(entry);
    await store.restoreExpense(entry);
    expect(store.transactions, hasLength(1));
    expect(store.totalSpentCentavos, 1000);
  });

  test('"adjust proportionally" keeps the user\'s own split', () async {
    final fixed = DateTime(2026, 3, 10, 9);
    final store = await _seeded(() => fixed);
    // The user rebalances: half of everything on food, nothing on pets.
    await store.setCategoryLimit(ExpenseCategory.food, 300000);
    await store.setCategoryLimit(ExpenseCategory.pets, 0);
    final assigned = store.categoryLimits.values.reduce((a, b) => a + b);
    final foodShare = store.categoryLimits[ExpenseCategory.food]! / assigned;

    await store.setTotalBudget(1200000, adjustCategoryLimits: true);

    final newAssigned = store.categoryLimits.values.reduce((a, b) => a + b);
    expect(newAssigned, 1200000, reason: 'the plan fills the new budget');
    expect(
      store.categoryLimits[ExpenseCategory.food]! / newAssigned,
      closeTo(foodShare, 0.001),
      reason: 'their ratio survives',
    );
    expect(
      store.categoryLimits[ExpenseCategory.pets],
      0,
      reason: 'a category they zeroed out stays zero',
    );
  });

  test('untouched limits still land on the stock split', () async {
    final fixed = DateTime(2026, 3, 10, 9);
    final store = await _seeded(() => fixed);
    await store.setTotalBudget(300000, adjustCategoryLimits: true);
    expect(store.categoryLimits.values.reduce((a, b) => a + b), 300000);
    expect(store.categoryLimits[ExpenseCategory.food], 90000);
  });

  test('ids are not reused after a delete', () async {
    // A clock that never moves is the worst case: only the sequence separates
    // one id from the next.
    final frozen = DateTime(2026, 3, 10, 9);
    final store = await _seeded(() => frozen);
    final ids = <String>{};
    for (var i = 0; i < 5; i++) {
      final entry = await store.addExpense(
        amountCentavos: 1000,
        category: ExpenseCategory.food,
        note: 'E$i',
        occurredAt: frozen,
        paymentMethod: PaymentMethod.card,
      );
      ids.add(entry.id);
      await store.deleteExpense(entry.id);
    }
    expect(ids, hasLength(5), reason: 'every id is its own');
  });

  test('a cash adjustment row carries no plus sign', () async {
    var now = DateTime(2026, 3, 10, 9);
    final store = await _seeded(() => now, cash: 200000);
    now = DateTime(2026, 3, 11, 9);
    await store.reconcileCashCount(
      actualCentavos: 250000,
      resolution: CashResolution.transfer,
    );
    final row = store.movements.first;
    expect(row.type, MovementType.adjustment);
    // The budget did not move, so the row must not claim income did.
    expect(store.totalBudgetCentavos, 600000);
  });
}
