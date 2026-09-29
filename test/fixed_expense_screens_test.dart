import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sobra_app/l10n/generated/app_localizations.dart';
import 'package:sobra_app/l10n/labels.dart';
import 'package:sobra_app/main.dart';
import 'package:sobra_app/models/expense_entry.dart';
import 'package:sobra_app/models/pay_schedule.dart';
import 'package:sobra_app/models/recurring_expense.dart';
import 'package:sobra_app/screens/fixed_expense_form_screen.dart';
import 'package:sobra_app/state/sobra_store.dart';

import 'support/localizations.dart';

/// The cat animations never stop, so `pumpAndSettle` would time out here.
Future<void> frames(WidgetTester tester, [int count = 40]) async {
  for (var i = 0; i < count; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late DateTime now;

  setUp(() {
    // Android answers the permission prompt; without an answer the save
    // would wait on it forever.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('com.sobra.app/fixed_reminders'),
          (call) async => call.method == 'requestPermission' ? true : null,
        );
    SharedPreferences.setMockInitialValues({});
    // The last Monday of the Sep 16 – 30 quincena.
    now = DateTime(2026, 9, 28, 9);
  });

  Future<SobraStore> newUser() async {
    final store = await SobraStore.load(now: () => now);
    await store.configureOnboarding(
      budgetCentavos: 690000,
      schedule: const PaySchedule.semiMonthly(),
    );
    await store.completeOnboarding();
    await store.setReducedMotion(true);
    return store;
  }

  Future<void> openBudgetTab(WidgetTester tester, SobraStore store) async {
    await tester.pumpWidget(SobraApp(store: store));
    await frames(tester);
    await tester.tap(find.text('Presup.'));
    await frames(tester);
  }

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await frames(tester, 10);
    await tester.tap(finder);
    await frames(tester);
  }

  testWidgets('adding the first fixed expense, then the one-time note', (
    tester,
  ) async {
    useSpanishDevice(tester);
    final store = await newUser();
    await openBudgetTab(tester, store);

    await tapVisible(tester, find.text('Agregar gasto fijo'));
    expect(find.byType(FixedExpenseFormScreen), findsOneWidget);

    final fields = find.descendant(
      of: find.byType(FixedExpenseFormScreen),
      matching: find.byType(TextFormField),
    );
    await tester.enterText(fields.at(0), '620');
    await tester.enterText(fields.at(1), 'Luz (CFE)');
    await tester.tap(find.text('Cada 2 meses'));
    await frames(tester, 5);
    // The preview is what catches a wrong month before it is saved.
    expect(find.text('Después: 28 nov, 28 ene, 28 mar…'), findsOneWidget);
    // The form is a lazy list: the button is not built until scrolled to.
    await tester.scrollUntilVisible(
      find.text('Guardar gasto fijo'),
      200,
      scrollable: find
          .descendant(
            of: find.byType(FixedExpenseFormScreen),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tapVisible(tester, find.text('Guardar gasto fijo'));

    expect(
      find.text('Tu presupuesto es para gastar, sin fijos'),
      findsOneWidget,
    );
    await tester.tap(find.text('Está bien así'));
    await frames(tester);

    final saved = store.recurringExpenses.single;
    expect(saved.name, 'Luz (CFE)');
    expect(saved.amountCentavos, 62000);
    expect(saved.frequency, FixedFrequency.bimonthly);
    expect(saved.anchorDate, DateTime(2026, 9, 28));
    expect(find.text('Luz (CFE)'), findsOneWidget);
    expect(find.text('Pagado \$0 de \$620'), findsOneWidget);
  });

  testWidgets('Inicio asks on the due date and paying leaves today alone', (
    tester,
  ) async {
    useSpanishDevice(tester);
    final store = await newUser();
    await store.addRecurringExpense(
      name: 'Celular',
      amountCentavos: 20000,
      category: ExpenseCategory.services,
      paymentMethod: PaymentMethod.cash,
      frequency: FixedFrequency.monthly,
      firstDueDate: DateTime(2026, 9, 28),
    );
    final todayBefore = store.todayRemainingCentavos;

    await tester.pumpWidget(SobraApp(store: store));
    await frames(tester);
    expect(find.text('Celular · \$200'), findsOneWidget);

    await tester.tap(find.text('Ya lo pagué'));
    await frames(tester);

    expect(store.transactions.single.isFixedPayment, isTrue);
    expect(store.todayRemainingCentavos, todayBefore);
    expect(find.text('Celular · \$200'), findsNothing);
  });

  testWidgets('"Todavía no" puts the card off until tomorrow only', (
    tester,
  ) async {
    useSpanishDevice(tester);
    final store = await newUser();
    await store.addRecurringExpense(
      name: 'Celular',
      amountCentavos: 20000,
      category: ExpenseCategory.services,
      paymentMethod: PaymentMethod.cash,
      frequency: FixedFrequency.monthly,
      firstDueDate: DateTime(2026, 9, 28),
    );

    await tester.pumpWidget(SobraApp(store: store));
    await frames(tester);
    await tester.tap(find.text('Todavía no'));
    await frames(tester);

    expect(find.text('Celular · \$200'), findsNothing);
    expect(store.transactions, isEmpty);
    expect(
      (await SobraStore.load(now: () => now)).isFixedHomeCardSnoozed,
      isTrue,
    );

    now = DateTime(2026, 9, 29, 9);
    expect(store.isFixedHomeCardSnoozed, isFalse);
    expect(store.fixedDueOnHome.single.status, FixedOccurrenceStatus.overdue);
  });

  testWidgets('a variable bill can take the new amount before it is paid', (
    tester,
  ) async {
    useSpanishDevice(tester);
    final store = await newUser();
    final luz = await store.addRecurringExpense(
      name: 'Luz (CFE)',
      amountCentavos: 62000,
      category: ExpenseCategory.services,
      paymentMethod: PaymentMethod.cash,
      frequency: FixedFrequency.bimonthly,
      firstDueDate: DateTime(2026, 9, 29),
      isVariable: true,
    );
    await openBudgetTab(tester, store);

    await tapVisible(tester, find.text('Luz (CFE)'));
    final sheetField = find.descendant(
      of: find.byType(BottomSheet),
      matching: find.byType(TextField),
    );
    await tester.enterText(sheetField, '684');
    await frames(tester, 5);
    await tester.tap(find.text('Solo llegó el recibo'));
    await frames(tester);

    expect(store.recurringExpenseById(luz.id)!.amountCentavos, 68400);
    expect(store.transactions, isEmpty);

    await tapVisible(tester, find.text('Luz (CFE)'));
    await tester.tap(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text('Ya lo pagué'),
      ),
    );
    await frames(tester);

    final payment = store.transactions.single;
    expect(payment.isFixedPayment, isTrue);
    expect(payment.amountCentavos, 68400);
    expect(payment.occurrenceDate, DateTime(2026, 9, 29));
  });

  test('a fixed payment reads as such in the movements list', () async {
    final store = await newUser();
    final rent = await store.addRecurringExpense(
      name: 'Renta',
      amountCentavos: 800000,
      category: ExpenseCategory.home,
      paymentMethod: PaymentMethod.card,
      frequency: FixedFrequency.monthly,
      firstDueDate: DateTime(2026, 9, 28),
    );
    await store.recordFixedPayment(
      recurringId: rent.id,
      occurrenceDate: DateTime(2026, 9, 28),
      amountCentavos: 800000,
    );
    final movement = store.movements.single;

    final es = lookupAppLocalizations(const Locale('es'));
    final ko = lookupAppLocalizations(const Locale('ko'));
    expect(movementTitle(es, movement), 'Renta');
    expect(movementSubtitle(es, movement), 'Fijo · Tarjeta');
    expect(movementSubtitle(ko, movement), '고정 · 카드');
  });
}
