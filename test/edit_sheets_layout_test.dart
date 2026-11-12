import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sobra_app/l10n/generated/app_localizations.dart';
import 'package:sobra_app/models/cash_reconciliation.dart';
import 'package:sobra_app/models/expense_entry.dart';
import 'package:sobra_app/models/income_entry.dart';
import 'package:sobra_app/models/pay_schedule.dart';
import 'package:sobra_app/models/recurring_expense.dart';
import 'package:sobra_app/screens/app_shell.dart';
import 'package:sobra_app/screens/budget_screen.dart';
import 'package:sobra_app/screens/home_screen.dart';
import 'package:sobra_app/screens/transactions_screen.dart';
import 'package:sobra_app/state/sobra_store.dart';
import 'package:sobra_app/theme/app_theme.dart';
import 'package:sobra_app/widgets/pixel_ui.dart';
import 'package:sobra_app/widgets/transaction_row.dart';

import 'support/localizations.dart';

/// The screens 1.0.17 grew, on a small phone at large text, in every
/// language. German and Portuguese run longest, and the income editor is the
/// tallest sheet the app has.
void main() {
  late DateTime now;

  /// One of everything the new screens treat differently: an ordinary
  /// expense, a fixed payment, a cash count, saved income, a closed cycle.
  Future<SobraStore> seeded() async {
    SharedPreferences.setMockInitialValues({});
    now = DateTime(2026, 10, 10, 9);
    final store = await SobraStore.load(now: () => now);
    await store.configureOnboarding(
      budgetCentavos: 700000,
      schedule: const PaySchedule.semiMonthly(),
      cashCentavos: 200000,
    );
    await store.completeOnboarding();
    await store.setReducedMotion(true);
    Future<void> spend(int amount, DateTime on, String note) async {
      now = on;
      await store.addExpense(
        amountCentavos: amount,
        category: ExpenseCategory.food,
        note: note,
        occurredAt: on,
        paymentMethod: PaymentMethod.card,
      );
    }

    await spend(520000, DateTime(2026, 10, 20, 12), 'groceries');
    now = DateTime(2026, 11, 1, 9);
    await store.settleCycles();
    final bill = await store.addRecurringExpense(
      name: 'rent',
      amountCentavos: 350000,
      category: ExpenseCategory.home,
      paymentMethod: PaymentMethod.card,
      frequency: FixedFrequency.monthly,
      firstDueDate: DateTime(2026, 11, 1),
    );
    now = DateTime(2026, 11, 3, 12);
    await store.recordFixedPayment(
      recurringId: bill.id,
      occurrenceDate: DateTime(2026, 11, 1),
      amountCentavos: 350000,
      paidAt: now,
    );
    await spend(50000, DateTime(2026, 11, 4, 13), 'lunch');
    now = DateTime(2026, 11, 5, 18);
    await store.addIncome(
      amountCentavos: 50000,
      kind: IncomeKind.extra,
      note: 'sale',
      occurredAt: now,
      destination: PaymentMethod.card,
      allocation: IncomeAllocation.savings,
    );
    now = DateTime(2026, 11, 11, 20);
    await store.reconcileCashCount(
      actualCentavos: store.expectedCashCentavos - 8000,
      resolution: CashResolution.expense,
    );
    now = DateTime(2026, 11, 12, 10);
    await store.settleCycles();
    return store;
  }

  Future<void> mount(
    WidgetTester tester,
    SobraStore store,
    Locale locale,
    Widget screen, {
    double textScale = 1.3,
  }) async {
    await tester.pumpWidget(
      SobraScope(
        store: store,
        child: MaterialApp(
          key: UniqueKey(),
          locale: locale,
          theme: buildSobraTheme(),
          localizationsDelegates: sobraLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
          home: AppShellScope(
            select: (_) {},
            current: AppTab.home,
            child: Scaffold(body: screen),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
  }

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  /// Opens a row's sheet, checks its save button can be reached and pressed,
  /// and closes it again.
  Future<void> openSheet(WidgetTester tester, Finder row) async {
    await tester.scrollUntilVisible(
      row,
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
    await tester.tap(row);
    await settle(tester);
    final sheet = find.byType(BottomSheet);
    expect(sheet, findsOneWidget);
    final save = find.descendant(of: sheet, matching: find.byType(PixelButton));
    await tester.ensureVisible(save.first);
    await tester.pump();
    expect(save.first.hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
    Navigator.of(tester.element(sheet)).pop();
    await settle(tester);
  }

  for (final locale in AppLocalizations.supportedLocales) {
    group('$locale on a small phone', () {
      Future<void> smallPhone(WidgetTester tester) async {
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
      }

      testWidgets('Inicio fits the projection line', (tester) async {
        await smallPhone(tester);
        final store = await seeded();
        await mount(tester, store, locale, const HomeScreen());
        expect(tester.takeException(), isNull);
        expect(find.byIcon(Icons.savings_outlined), findsOneWidget);
      });

      // At normal text size: under large text the category rows further down
      // already overflowed before the projection card moved above them.
      testWidgets('Presupuesto fits the projection card', (tester) async {
        await smallPhone(tester);
        final store = await seeded();
        await mount(tester, store, locale, const BudgetScreen(), textScale: 1);
        expect(tester.takeException(), isNull);
        final l10n = AppLocalizations.of(
          tester.element(find.byType(BudgetScreen)),
        );
        expect(find.text(l10n.budgetSavedThisCycle), findsOneWidget);
        expect(find.text(l10n.budgetClosedCyclesResult), findsOneWidget);
      });

      testWidgets('every edit sheet can still be saved', (tester) async {
        await smallPhone(tester);
        final store = await seeded();
        await mount(tester, store, locale, const TransactionsScreen());
        final l10n = AppLocalizations.of(
          tester.element(find.byType(TransactionsScreen)),
        );
        await openSheet(tester, find.text('lunch'));
        await openSheet(tester, find.text('rent'));
        // The cash count's expense is the newest row.
        await tester.drag(find.byType(ListView).first, const Offset(0, 3000));
        await tester.pump();
        await openSheet(tester, find.byType(MovementRow).first);

        await tester.drag(find.byType(ListView).first, const Offset(0, 3000));
        await tester.pump();
        await tester.tap(find.text(l10n.registerIncome).first);
        await tester.pump();
        await openSheet(tester, find.text('sale'));
      });
    });
  }
}
