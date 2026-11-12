import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sobra_app/l10n/generated/app_localizations.dart';
import 'package:sobra_app/main.dart';
import 'package:sobra_app/models/expense_entry.dart';
import 'package:sobra_app/models/pay_schedule.dart';
import 'package:sobra_app/models/recurring_expense.dart';
import 'package:sobra_app/screens/fixed_expense_form_screen.dart';
import 'package:sobra_app/services/fixed_reminders.dart';
import 'package:sobra_app/state/sobra_store.dart';

import 'support/localizations.dart';

Future<void> frames(WidgetTester tester, [int count = 30]) async {
  for (var i = 0; i < count; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final es = lookupAppLocalizations(const Locale('es'));
  final ko = lookupAppLocalizations(const Locale('ko'));
  late DateTime now;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    // Sunday evening: tomorrow's 9:00 is still ahead, this morning's is gone.
    now = DateTime(2026, 9, 27, 20);
  });

  Future<SobraStore> newUser() async {
    final store = await SobraStore.load(now: () => now);
    await store.configureOnboarding(
      budgetCentavos: 690000,
      schedule: const PaySchedule.semiMonthly(),
    );
    await store.completeOnboarding();
    return store;
  }

  Future<RecurringExpense> add(
    SobraStore store,
    String name,
    FixedFrequency frequency,
    DateTime firstDue, {
    int amount = 20000,
    FixedReminder? reminder,
    bool isVariable = false,
    PaymentMethod method = PaymentMethod.cash,
  }) => store.addRecurringExpense(
    name: name,
    amountCentavos: amount,
    category: ExpenseCategory.services,
    paymentMethod: method,
    frequency: frequency,
    firstDueDate: firstDue,
    isVariable: isVariable,
    reminder: reminder,
  );

  group('the plan', () {
    test('fires at 9:00 on the lead day, worded for that lead', () async {
      final store = await newUser();
      await add(
        store,
        'Renta',
        FixedFrequency.monthly,
        DateTime(2026, 10, 1),
        amount: 800000,
        method: PaymentMethod.card,
      );
      await add(
        store,
        'Celular',
        FixedFrequency.monthly,
        DateTime(2026, 9, 28),
        reminder: FixedReminder.sameDay,
      );
      await add(
        store,
        'Luz',
        FixedFrequency.bimonthly,
        DateTime(2026, 11, 29),
        amount: 62000,
        isVariable: true,
        reminder: FixedReminder.threeDaysBefore,
      );

      final plan = planFixedReminders(store: store, l10n: es);
      PlannedReminder at(DateTime moment) =>
          plan.singleWhere((reminder) => reminder.at == moment);

      expect(
        plan.map((reminder) => reminder.at),
        orderedEquals([...plan.map((r) => r.at)]..sort()),
      );
      expect(at(DateTime(2026, 9, 28, 9)).title, 'Hoy toca pagar Celular');
      final rent = at(DateTime(2026, 9, 30, 9));
      expect(rent.title, 'Mañana toca pagar Renta');
      expect(
        rent.body,
        '\$8,000 MXN · Tarjeta. Cuando pagues, anótalo en Sobrita.',
      );
      final luz = at(DateTime(2026, 11, 26, 9));
      expect(luz.title, 'Luz vence en 3 días');
      expect(luz.body, startsWith('aprox. \$620 MXN · Efectivo.'));
      expect(
        planFixedReminders(store: store, l10n: ko).first.title,
        '오늘은 Celular 내는 날이에요',
      );
    });

    test('skips paid dates, silenced bills and moments already gone', () async {
      final store = await newUser();
      final rent = await add(
        store,
        'Renta',
        FixedFrequency.monthly,
        DateTime(2026, 10, 1),
      );
      // Weekly starts without a reminder.
      await add(
        store,
        'Garrafón',
        FixedFrequency.weekly,
        DateTime(2026, 10, 2),
      );
      // This morning's 9:00 has passed.
      await add(
        store,
        'Agua',
        FixedFrequency.monthly,
        DateTime(2026, 9, 27),
        reminder: FixedReminder.sameDay,
      );

      now = DateTime(2026, 9, 28, 9);
      await store.recordFixedPayment(
        recurringId: rent.id,
        occurrenceDate: DateTime(2026, 10, 1),
        amountCentavos: 20000,
      );
      now = DateTime(2026, 9, 27, 20);

      final plan = planFixedReminders(store: store, l10n: es);
      expect(
        plan.where((reminder) => reminder.title.contains('Garrafón')),
        isEmpty,
      );
      expect(plan.where((reminder) => !reminder.at.isAfter(now)), isEmpty);
      // October's rent is paid, so its reminder is gone and November's leads.
      expect(
        plan
            .where((reminder) => reminder.title == 'Mañana toca pagar Renta')
            .map((reminder) => reminder.at),
        [DateTime(2026, 10, 31, 9), DateTime(2026, 11, 30, 9)],
      );
    });

    test('holds at most the limit, earliest first', () async {
      final store = await newUser();
      for (var index = 0; index < 7; index++) {
        await add(
          store,
          'Semanal $index',
          FixedFrequency.weekly,
          DateTime(2026, 9, 28 + index),
          reminder: FixedReminder.dayBefore,
        );
      }

      final plan = planFixedReminders(store: store, l10n: es);

      expect(plan, hasLength(fixedReminderLimit));
      expect(
        plan.first.at,
        DateTime(2026, 9, 27, 9).add(const Duration(days: 1)),
      );
    });

    test('ids stay put for the same bill and date', () {
      final date = DateTime(2026, 10, 1);
      expect(
        fixedReminderId('fixed-1', date),
        fixedReminderId('fixed-1', date),
      );
      expect(
        fixedReminderId('fixed-1', date),
        isNot(fixedReminderId('fixed-1', DateTime(2026, 11, 1))),
      );
      expect(
        fixedReminderId('fixed-1', date),
        isNot(fixedReminderId('fixed-2', date)),
      );
      expect(fixedReminderId('fixed-1', date), greaterThanOrEqualTo(0));
    });
  });

  test('a change to the fixed expenses reaches Android', () async {
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('com.sobra.app/fixed_reminders'),
          (call) async {
            calls.add(call);
            return null;
          },
        );
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('com.sobra.app/fixed_reminders'),
            null,
          ),
    );
    final store = await newUser();
    SobraFixedReminders.initialize(store);
    SobraFixedReminders.localize(es);
    await Future<void>.delayed(Duration.zero);

    await add(store, 'Renta', FixedFrequency.monthly, DateTime(2026, 10, 1));
    await Future<void>.delayed(Duration.zero);

    final last = calls.lastWhere((call) => call.method == 'schedule');
    final plan = (last.arguments as List).cast<Map<Object?, Object?>>();
    expect(plan.first['title'], 'Mañana toca pagar Renta');
    expect(plan.first['at'], DateTime(2026, 9, 30, 9).millisecondsSinceEpoch);
  });

  testWidgets('the reminder follows the frequency until the user picks one', (
    tester,
  ) async {
    useSpanishDevice(tester);
    final store = await newUser();
    await store.setReducedMotion(true);
    await tester.pumpWidget(SobraApp(store: store));
    await frames(tester);
    final navigator = tester.state<NavigatorState>(
      find.byType(Navigator).first,
    );
    navigator.push(
      MaterialPageRoute<void>(builder: (_) => const FixedExpenseFormScreen()),
    );
    await frames(tester);

    final form = find.byType(FixedExpenseFormScreen);
    final list = find
        .descendant(of: form, matching: find.byType(Scrollable))
        .first;
    Future<void> reveal(Finder finder) async {
      await tester.scrollUntilVisible(finder, 150, scrollable: list);
      await frames(tester, 5);
    }

    await reveal(find.text('1 día antes'));
    await tester.drag(list, const Offset(0, 2000));
    await frames(tester, 5);
    await tester.tap(find.text('Cada semana'));
    await frames(tester, 5);
    await reveal(find.text('Sin aviso'));
    expect(find.text('Sin aviso'), findsOneWidget);

    await tester.tap(find.text('Sin aviso'));
    await frames(tester);
    await tester.tap(find.text('3 días antes').last);
    await frames(tester);
    await tester.drag(list, const Offset(0, 2000));
    await frames(tester, 5);
    await tester.tap(find.text('Cada mes'));
    await frames(tester, 5);
    await reveal(find.text('3 días antes'));
    expect(find.text('3 días antes'), findsOneWidget);
  });

  testWidgets('a refused permission still saves, and says so', (tester) async {
    useSpanishDevice(tester);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('com.sobra.app/fixed_reminders'),
          (call) async => call.method == 'requestPermission' ? false : null,
        );
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('com.sobra.app/fixed_reminders'),
            null,
          ),
    );
    final store = await newUser();
    await store.setReducedMotion(true);
    await tester.pumpWidget(SobraApp(store: store));
    await frames(tester);
    tester
        .state<NavigatorState>(find.byType(Navigator).first)
        .push(
          MaterialPageRoute<void>(
            builder: (_) => const FixedExpenseFormScreen(),
          ),
        );
    await frames(tester);
    final form = find.byType(FixedExpenseFormScreen);
    final fields = find.descendant(
      of: form,
      matching: find.byType(TextFormField),
    );
    await tester.enterText(fields.at(0), '8000');
    await tester.enterText(fields.at(1), 'Renta');
    final save = find.text('Guardar gasto fijo');
    await tester.scrollUntilVisible(
      save,
      200,
      scrollable: find
          .descendant(of: form, matching: find.byType(Scrollable))
          .first,
    );
    await frames(tester, 5);
    await tester.tap(save);
    await frames(tester);

    expect(store.recurringExpenses.single.reminder, FixedReminder.dayBefore);
    expect(
      find.text(
        'Las notificaciones de Sobrita están apagadas, así que no podré avisarte.',
      ),
      findsOneWidget,
    );
  });
}
