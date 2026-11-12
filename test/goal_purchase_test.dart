import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sobra_app/l10n/generated/app_localizations.dart';
import 'package:sobra_app/models/expense_entry.dart';
import 'package:sobra_app/models/pay_schedule.dart';
import 'package:sobra_app/models/savings_goal.dart';
import 'package:sobra_app/screens/savings_goal_screen.dart';
import 'package:sobra_app/services/goal_product_import.dart';
import 'package:sobra_app/state/sobra_store.dart';
import 'package:sobra_app/theme/app_theme.dart';

import 'support/localizations.dart';

const _url = 'https://www.mercadolibre.com.mx/smart-tv/p/MLM12345678';

/// Weekly budget $3,000 on Monday 9 Nov, $1,000 cash, and a $8,999 TV goal
/// with $7,700 saved. Buen Fin sells it for $7,499.
Future<(SobraStore, void Function(DateTime))> _store({
  int starting = 770000,
}) async {
  SharedPreferences.setMockInitialValues({});
  var now = DateTime(2026, 11, 9, 10);
  final store = await SobraStore.load(now: () => now);
  await store.configureOnboarding(
    budgetCentavos: 300000,
    schedule: const PaySchedule.weekly(weeklyPayDay: DateTime.monday),
    cashCentavos: 100000,
  );
  await store.completeOnboarding();
  await store.saveSavingsGoal(
    kind: SavingsGoalKind.product,
    name: 'Smart TV',
    targetCentavos: 899900,
    startingCentavos: starting,
    productUrl: _url,
    merchantName: 'Mercado Libre',
  );
  return (store, (DateTime value) => now = value);
}

void main() {
  group('store', () {
    test('a goal purchase leaves today and the cycle budget alone', () async {
      final (store, _) = await _store();
      final today = store.todayRemainingCentavos;
      final remaining = store.remainingBudgetCentavos;
      final goal = store.activeSavingsGoal!;

      final entry = await store.recordSavingsGoalPurchase(
        goalId: goal.id,
        amountCentavos: 749900,
        paymentMethod: PaymentMethod.card,
      );

      expect(entry.savingsGoalId, goal.id);
      expect(entry.isOutsideBudget, isTrue);
      expect(entry.category, ExpenseCategory.shopping);
      expect(entry.note, 'Smart TV');
      expect(store.transactions.single.id, entry.id);
      expect(store.todayRemainingCentavos, today);
      expect(store.remainingBudgetCentavos, remaining);
      expect(store.totalSpentCentavos, 0);
      expect(store.cycleSpending, isEmpty);
    });

    test('the goal moves to history with what was saved and paid', () async {
      final (store, _) = await _store();
      final goal = store.activeSavingsGoal!;
      final entry = await store.recordSavingsGoalPurchase(
        goalId: goal.id,
        amountCentavos: 749900,
        paymentMethod: PaymentMethod.card,
      );
      expect(store.activeSavingsGoal, isNull);
      expect(store.pendingSavingsGoalCompletionId, isNull);
      final record = store.completedSavingsGoals.single;
      expect(record.goal.id, goal.id);
      // Under the $8,999 target: a sale price still closes the goal.
      expect(record.progressCentavos, 770000);
      expect(record.purchaseCentavos, 749900);
      expect(record.purchaseExpenseId, entry.id);
    });

    test('cash comes out of the expected cash, a card does not', () async {
      // After the onboarding count: same-moment cash is already counted.
      final (store, setNow) = await _store(starting: 900000);
      setNow(DateTime(2026, 11, 9, 12));
      final cash = store.expectedCashCentavos;
      await store.recordSavingsGoalPurchase(
        goalId: store.activeSavingsGoal!.id,
        amountCentavos: 80000,
        paymentMethod: PaymentMethod.cash,
      );
      expect(store.expectedCashCentavos, cash - 80000);

      final (cardStore, setCardNow) = await _store(starting: 900000);
      setCardNow(DateTime(2026, 11, 9, 12));
      final cardCash = cardStore.expectedCashCentavos;
      await cardStore.recordSavingsGoalPurchase(
        goalId: cardStore.activeSavingsGoal!.id,
        amountCentavos: 80000,
        paymentMethod: PaymentMethod.card,
      );
      expect(cardStore.expectedCashCentavos, cardCash);
    });

    test('only saved money can be spent, on the active goal', () async {
      final (store, _) = await _store();
      final goal = store.activeSavingsGoal!;
      await expectLater(
        store.recordSavingsGoalPurchase(
          goalId: goal.id,
          amountCentavos: 770001,
          paymentMethod: PaymentMethod.card,
        ),
        throwsA(isA<ArgumentError>()),
      );
      await expectLater(
        store.recordSavingsGoalPurchase(
          goalId: 'another',
          amountCentavos: 1000,
          paymentMethod: PaymentMethod.card,
        ),
        throwsA(isA<StateError>()),
      );
      expect(store.transactions, isEmpty);
      expect(store.activeSavingsGoal?.id, goal.id);
      expect(store.completedSavingsGoals, isEmpty);
    });

    test('a cycle with a goal purchase still closes green', () async {
      final (store, setNow) = await _store();
      await store.recordSavingsGoalPurchase(
        goalId: store.activeSavingsGoal!.id,
        amountCentavos: 749900,
        paymentMethod: PaymentMethod.card,
      );
      setNow(DateTime(2026, 11, 16, 10));
      await store.settleCycles();
      final record = store.cycleRecords.single;
      expect(record.spentCentavos, 0);
      expect(record.fixedPaidCentavos, 0);
      expect(record.successful, isTrue);
    });

    test(
      'the purchase survives a reload; other expenses keep their JSON',
      () async {
        final (store, _) = await _store();
        final plain = await store.addExpense(
          amountCentavos: 5000,
          category: ExpenseCategory.food,
          note: '',
          occurredAt: DateTime(2026, 11, 9, 9),
          paymentMethod: PaymentMethod.cash,
        );
        expect(plain.toJson().containsKey('savingsGoalId'), isFalse);
        await store.recordSavingsGoalPurchase(
          goalId: store.activeSavingsGoal!.id,
          amountCentavos: 749900,
          paymentMethod: PaymentMethod.card,
        );

        final reloaded = await SobraStore.load(
          now: () => DateTime(2026, 11, 9, 11),
        );
        expect(reloaded.hasStorageError, isFalse);
        final purchase = reloaded.transactions.firstWhere(
          (entry) => entry.isGoalPurchase,
        );
        expect(purchase.amountCentavos, 749900);
        expect(reloaded.completedSavingsGoals.single.purchaseCentavos, 749900);
        expect(reloaded.totalSpentCentavos, 5000);

        // A backup carries both, and imports back.
        final backup =
            jsonDecode(reloaded.exportJson()) as Map<String, dynamic>;
        final records = backup['completedSavingsGoals'] as List<dynamic>;
        expect((records.single as Map)['purchaseCentavos'], 749900);
      },
    );

    test('editing the purchase keeps the history in step', () async {
      final (store, _) = await _store();
      final entry = await store.recordSavingsGoalPurchase(
        goalId: store.activeSavingsGoal!.id,
        amountCentavos: 749900,
        paymentMethod: PaymentMethod.card,
      );
      await store.updateExpense(entry.copyWith(amountCentavos: 739900));
      expect(store.completedSavingsGoals.single.purchaseCentavos, 739900);
      expect(store.totalSpentCentavos, 0);

      // Above what the goal saved is not goal money any more.
      await expectLater(
        store.updateExpense(entry.copyWith(amountCentavos: 780000)),
        throwsA(isA<ArgumentError>()),
      );
      // Nor can an edit turn it back into everyday spending.
      await expectLater(
        store.updateExpense(
          ExpenseEntry(
            id: entry.id,
            amountCentavos: entry.amountCentavos,
            category: entry.category,
            note: entry.note,
            occurredAt: entry.occurredAt,
            paymentMethod: entry.paymentMethod,
          ),
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(store.completedSavingsGoals.single.purchaseCentavos, 739900);
      expect(store.transactions.single.isGoalPurchase, isTrue);
    });

    test('a purchase record must fit what was saved', () {
      final goal = SavingsGoal(
        id: 'goal-1',
        name: 'TV',
        targetCentavos: 899900,
        startingCentavos: 0,
        createdAt: DateTime(2026, 11, 1),
        excludedIncomeIds: const {},
      );
      CompletedSavingsGoal make({
        required int progress,
        int? purchase,
        String? expenseId,
      }) => CompletedSavingsGoal(
        goal: goal,
        progressCentavos: progress,
        completedAt: DateTime(2026, 11, 9),
        purchaseCentavos: purchase,
        purchaseExpenseId: expenseId,
      );
      expect(
        make(progress: 770000, purchase: 749900, expenseId: 'e').wasPurchased,
        isTrue,
      );
      expect(() => make(progress: 770000), throwsArgumentError);
      expect(
        () => make(progress: 770000, purchase: 780000, expenseId: 'e'),
        throwsArgumentError,
      );
      expect(() => make(progress: 770000, purchase: 1000), throwsArgumentError);
    });
  });

  group('screens', () {
    Future<SobraStore> pumpGoal(
      WidgetTester tester, {
      GoalProductLoader? readPrice,
    }) async {
      tester.view.physicalSize = const Size(390, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final (store, _) = await _store();
      await tester.pumpWidget(
        SobraScope(
          store: store,
          child: MaterialApp(
            locale: const Locale('ko'),
            localizationsDelegates: sobraLocalizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: buildSobraTheme(),
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: TextButton(
                    key: const ValueKey('open-goal'),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => SavingsGoalScreen(
                          existing: store.activeSavingsGoal,
                          readPrice: readPrice,
                        ),
                      ),
                    ),
                    child: const Text('home'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(const ValueKey('open-goal')));
      await tester.pumpAndSettle();
      return store;
    }

    Future<void> tap(WidgetTester tester, String key) async {
      final finder = find.byKey(ValueKey(key));
      await tester.ensureVisible(finder);
      await tester.pumpAndSettle();
      await tester.tap(finder);
      await tester.pumpAndSettle();
    }

    testWidgets('read the Buen Fin price, record, and land back home', (
      tester,
    ) async {
      final store = await pumpGoal(
        tester,
        readPrice: (_, url) async {
          expect(url, _url);
          return GoalProductImport(
            sourceUrl: url,
            title: 'Smart TV',
            priceCentavos: 749900,
            currencyCode: 'MXN',
          );
        },
      );
      await tap(tester, 'goal-purchase');
      // Prefilled with everything saved, since the list price is above it.
      expect(find.text('7,700'), findsOneWidget);
      await tap(tester, 'goal-purchase-read-price');
      expect(find.text('7,499'), findsOneWidget);
      expect(find.text('오늘 가격 \$7,499'), findsOneWidget);
      expect(find.text('\$201'), findsOneWidget);

      await tap(tester, 'goal-purchase-confirm');
      expect(find.byKey(const ValueKey('open-goal')), findsOneWidget);
      expect(find.text('구매를 기록했어요: Smart TV'), findsOneWidget);
      expect(store.activeSavingsGoal, isNull);
      expect(store.transactions.single.amountCentavos, 749900);
      expect(store.transactions.single.paymentMethod, PaymentMethod.card);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the rest can start the next goal', (tester) async {
      final store = await pumpGoal(tester);
      await tap(tester, 'goal-purchase');
      await tester.enterText(
        find.byKey(const ValueKey('goal-purchase-amount')),
        '7499',
      );
      await tester.pump();
      await tap(tester, 'goal-purchase-confirm-next');
      expect(store.activeSavingsGoal, isNull);
      // A fresh goal editor, with the $201 already filled in as saved once
      // a goal type is picked.
      expect(find.byKey(const ValueKey('goal-purchase')), findsNothing);
      await tap(tester, 'goal-type-amount');
      expect(find.text('201'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a price above the savings is refused on screen', (
      tester,
    ) async {
      final store = await pumpGoal(tester);
      await tap(tester, 'goal-purchase');
      await tester.enterText(
        find.byKey(const ValueKey('goal-purchase-amount')),
        '8999',
      );
      await tester.pump();
      expect(
        find.byKey(const ValueKey('goal-purchase-confirm-next')),
        findsNothing,
      );
      await tap(tester, 'goal-purchase-confirm');
      expect(find.byKey(const ValueKey('goal-purchase-error')), findsOneWidget);
      expect(store.transactions, isEmpty);
      expect(store.activeSavingsGoal, isNotNull);
    });

    testWidgets('the purchase screen fits a small phone in every language', (
      tester,
    ) async {
      final (store, _) = await _store();
      for (final locale in AppLocalizations.supportedLocales) {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1;
        await tester.pumpWidget(
          SobraScope(
            store: store,
            child: MaterialApp(
              locale: locale,
              localizationsDelegates: sobraLocalizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              theme: buildSobraTheme(),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: const TextScaler.linear(1.3)),
                child: child!,
              ),
              home: SavingsGoalScreen(existing: store.activeSavingsGoal),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final button = find.byKey(const ValueKey('goal-purchase'));
        await tester.ensureVisible(button);
        await tester.pumpAndSettle();
        await tester.tap(button);
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('goal-purchase-confirm')),
          findsOneWidget,
          reason: '$locale',
        );
        expect(tester.takeException(), isNull, reason: '$locale');
        // A new tree per language, so no route stays pushed.
        await tester.pumpWidget(const SizedBox.shrink());
      }
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });
}
