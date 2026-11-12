import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sobra_app/models/expense_entry.dart';
import 'package:sobra_app/models/pay_schedule.dart';
import 'package:sobra_app/screens/budget_screen.dart';
import 'package:sobra_app/state/sobra_store.dart';
import 'package:sobra_app/theme/app_theme.dart';
import 'package:sobra_app/widgets/cat_sprite.dart';
import 'package:sobra_app/widgets/pixel_ui.dart';

import 'support/localizations.dart';

int _filled(List<ExpenseCategory?> segments) =>
    segments.where((segment) => segment != null).length;

void main() {
  group('the ring blocks', () {
    test('are all empty before anything is spent', () {
      final segments = categoryRingSegments(
        spentByCategory: const {},
        budgetCentavos: 600000,
      );
      expect(segments, hasLength(12));
      expect(_filled(segments), 0);
    });

    test('fill in proportion to the budget', () {
      final half = categoryRingSegments(
        spentByCategory: const {ExpenseCategory.food: 300000},
        budgetCentavos: 600000,
      );
      expect(_filled(half), 6);
    });

    // A ring reading empty beside a figure that is not zero looks broken, so
    // any spending at all claims one block.
    test('give a sliver of spending one whole block', () {
      final tiny = categoryRingSegments(
        spentByCategory: const {ExpenseCategory.food: 100},
        budgetCentavos: 600000,
      );
      expect(_filled(tiny), 1);
    });

    test('stop at full once the budget is gone', () {
      final over = categoryRingSegments(
        spentByCategory: const {ExpenseCategory.food: 900000},
        budgetCentavos: 600000,
      );
      expect(_filled(over), 12);
      expect(over.every((segment) => segment != null), isTrue);
    });

    test('say nothing when there is no budget to speak of', () {
      final none = categoryRingSegments(
        spentByCategory: const {ExpenseCategory.food: 5000},
        budgetCentavos: 0,
      );
      expect(_filled(none), 0);
    });

    // Largest-remainder: a category can lose its block to rounding, but the
    // coloured run must always be exactly as long as the filled run.
    test('hand out every filled block and no more', () {
      final segments = categoryRingSegments(
        spentByCategory: const {
          ExpenseCategory.food: 156000,
          ExpenseCategory.shopping: 92000,
          ExpenseCategory.transport: 61000,
          ExpenseCategory.services: 38000,
          ExpenseCategory.entertainment: 21000,
          ExpenseCategory.health: 9000,
        },
        budgetCentavos: 600000,
      );
      final spent = 156000 + 92000 + 61000 + 38000 + 21000 + 9000;
      expect(_filled(segments), (spent / 600000 * 12).ceil());
      expect(
        segments.sublist(0, _filled(segments)).every((s) => s != null),
        isTrue,
        reason: 'filled blocks come first, with no gaps',
      );
    });

    test('put the biggest category first and give it the most', () {
      final segments = categoryRingSegments(
        spentByCategory: const {
          ExpenseCategory.transport: 60000,
          ExpenseCategory.food: 240000,
          ExpenseCategory.shopping: 120000,
        },
        budgetCentavos: 600000,
      );
      expect(segments.first, ExpenseCategory.food);
      int blocks(ExpenseCategory c) =>
          segments.where((segment) => segment == c).length;
      expect(
        blocks(ExpenseCategory.food),
        greaterThan(blocks(ExpenseCategory.shopping)),
      );
      expect(
        blocks(ExpenseCategory.shopping),
        greaterThanOrEqualTo(blocks(ExpenseCategory.transport)),
      );
    });

    test('drop a category too small to earn a block, without breaking', () {
      final segments = categoryRingSegments(
        spentByCategory: const {
          ExpenseCategory.food: 590000,
          ExpenseCategory.pets: 100,
        },
        budgetCentavos: 600000,
      );
      expect(_filled(segments), 12);
      expect(segments.contains(ExpenseCategory.pets), isFalse);
    });
  });

  group('the budget screen', () {
    Future<SobraStore> seeded(Map<ExpenseCategory, int> spend) async {
      SharedPreferences.setMockInitialValues({});
      final now = DateTime(2026, 9, 20, 12);
      final store = await SobraStore.load(now: () => now);
      await store.configureOnboarding(
        budgetCentavos: 600000,
        schedule: const PaySchedule.semiMonthly(),
      );
      await store.completeOnboarding();
      for (final entry in spend.entries) {
        await store.addExpense(
          amountCentavos: entry.value,
          category: entry.key,
          note: '',
          occurredAt: now,
          paymentMethod: PaymentMethod.cash,
        );
      }
      await store.setReducedMotion(true);
      return store;
    }

    Future<void> pump(
      WidgetTester tester,
      SobraStore store, {
      bool active = true,
    }) async {
      await tester.pumpWidget(
        SobraScope(
          store: store,
          child: MaterialApp(
            localizationsDelegates: sobraLocalizationsDelegates,
            supportedLocales: sobraSupportedLocales,
            theme: buildSobraTheme(),
            home: Scaffold(body: BudgetScreen(active: active)),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('shows the ring and what it stands for', (tester) async {
      final store = await seeded({
        ExpenseCategory.food: 240000,
        ExpenseCategory.transport: 120000,
      });
      await pump(tester, store);

      expect(find.byType(CategoryRing), findsOneWidget);
      expect(find.text('60% del presupuesto'), findsOneWidget);
      expect(find.text('Gastado \$3,600 MXN'), findsOneWidget);
      expect(find.text('Queda \$2,400 MXN'), findsOneWidget);
    });

    testWidgets('companion saves once, idles, then reacts to a budget edit', (
      tester,
    ) async {
      final store = await seeded({});
      await store.setReducedMotion(false);
      await pump(tester, store);

      CatSprite companion() => tester.widget<CatSprite>(find.byType(CatSprite));
      expect(companion().motion, CatMotion.saving);
      expect(companion().animate, isTrue);
      expect(companion().loop, isFalse);

      await tester.pump(const Duration(milliseconds: 4100));
      await tester.pump();
      expect(companion().motion, CatMotion.idle);
      expect(companion().loop, isTrue);

      await store.setCategoryLimit(ExpenseCategory.food, 123000);
      await tester.pump();
      expect(companion().motion, CatMotion.saving);
    });

    testWidgets('companion pauses off-tab and replays on return', (
      tester,
    ) async {
      final store = await seeded({});
      await store.setReducedMotion(false);
      await pump(tester, store, active: false);

      CatSprite companion() => tester.widget<CatSprite>(find.byType(CatSprite));
      expect(companion().motion, CatMotion.idle);
      expect(companion().animate, isFalse);

      await pump(tester, store);
      expect(companion().motion, CatMotion.saving);
      expect(companion().animate, isTrue);

      await pump(tester, store, active: false);
      expect(companion().motion, CatMotion.idle);
      expect(companion().animate, isFalse);
    });

    testWidgets('reduced motion keeps the companion still', (tester) async {
      final store = await seeded({});
      await pump(tester, store);

      final companion = tester.widget<CatSprite>(find.byType(CatSprite));
      expect(companion.motion, CatMotion.idle);
      expect(companion.animate, isFalse);
    });

    testWidgets('labels each category with its share of the spending', (
      tester,
    ) async {
      final store = await seeded({
        ExpenseCategory.food: 240000,
        ExpenseCategory.transport: 120000,
      });
      await pump(tester, store);

      expect(find.text('67%'), findsOneWidget);
      expect(find.text('33%'), findsOneWidget);
    });

    // The share belongs to rows that have something to share.
    testWidgets('leaves untouched categories unlabelled', (tester) async {
      final store = await seeded({ExpenseCategory.food: 240000});
      await pump(tester, store);

      expect(find.text('100%'), findsOneWidget);
      expect(find.text('0%'), findsNothing);
    });

    PixelCard ringCard(WidgetTester tester) => tester.widget<PixelCard>(
      find
          .ancestor(
            of: find.byType(CategoryRing),
            matching: find.byType(PixelCard),
          )
          .first,
    );

    // The ring's own colours come from the categories, so a cycle blown on
    // Hogar fills it with the teal this app uses for going well. The card is
    // what has to carry the warning.
    testWidgets('turns the card red when the budget is gone', (tester) async {
      final store = await seeded({ExpenseCategory.home: 690000});
      await pump(tester, store);

      expect(find.text('115% del presupuesto'), findsOneWidget);
      expect(ringCard(tester).color, AppColors.dangerSoft);
      expect(ringCard(tester).borderColor, AppColors.dangerInk);
    });

    testWidgets('leaves the card plain while there is budget left', (
      tester,
    ) async {
      final store = await seeded({ExpenseCategory.home: 300000});
      await pump(tester, store);

      expect(ringCard(tester).color, AppColors.surface);
      expect(ringCard(tester).borderColor, AppColors.ink);
    });

    // Exactly spent is not overspent.
    testWidgets('holds off at exactly the budget', (tester) async {
      final store = await seeded({ExpenseCategory.home: 600000});
      await pump(tester, store);

      expect(find.text('100% del presupuesto'), findsOneWidget);
      expect(ringCard(tester).color, AppColors.surface);
    });

    // Order is deliberately not ranked: this screen's job is editing limits,
    // and a card that moves is a card the user has to hunt for.
    testWidgets('keeps categories in a fixed order', (tester) async {
      final store = await seeded({
        ExpenseCategory.other: 240000,
        ExpenseCategory.food: 10000,
      });
      await pump(tester, store);

      final labels = tester
          .widgetList<Text>(find.byType(Text))
          .map((text) => text.data)
          .toList();
      expect(
        labels.indexOf('Comida'),
        lessThan(labels.indexOf('Otros')),
        reason: 'Comida leads the enum, whatever was spent on it',
      );
    });
  });
}
