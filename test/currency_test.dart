import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sobra_app/main.dart';
import 'package:sobra_app/models/currency.dart';
import 'package:sobra_app/models/expense_entry.dart';
import 'package:sobra_app/models/pay_schedule.dart';
import 'package:sobra_app/state/sobra_store.dart';
import 'package:sobra_app/widgets/pixel_ui.dart';

import 'support/localizations.dart';

Future<SobraStore> _onboardedStore() async {
  SharedPreferences.setMockInitialValues({});
  final store = await SobraStore.load(now: () => DateTime(2026, 9, 15, 12));
  await store.configureOnboarding(
    budgetCentavos: 600000,
    schedule: const PaySchedule.semiMonthly(),
  );
  await store.completeOnboarding();
  return store;
}

void main() {
  group('formatting an amount', () {
    test('puts the code beside the figure', () {
      expect(formatMoney(Currency.mxn, 123456), r'$1,234.56 MXN');
      expect(formatMoney(Currency.usd, 123456), r'$1,234.56 USD');
      expect(formatMoney(Currency.cad, 123456), r'$1,234.56 CAD');
      expect(formatMoney(Currency.eur, 123456), '€1,234.56 EUR');
    });

    test('drops the code when asked, for figures shown in pairs', () {
      expect(formatMoney(Currency.usd, 123456, showCode: false), r'$1,234.56');
      expect(formatMoney(Currency.eur, 123456, showCode: false), '€1,234.56');
    });

    test('keeps whole amounts whole and groups thousands', () {
      expect(formatMoney(Currency.mxn, 600000), r'$6,000 MXN');
      expect(formatMoney(Currency.mxn, 100000000), r'$1,000,000 MXN');
      expect(formatMoney(Currency.mxn, 5), r'$0.05 MXN');
    });

    test('writes a negative with a typographic minus', () {
      expect(formatMoney(Currency.mxn, -8850), '$minusSign\$88.50 MXN');
    });
  });

  group('the currency setting', () {
    test('starts as pesos, and old data without one reads as pesos', () async {
      final store = await _onboardedStore();
      expect(store.currency, Currency.mxn);
      expect(Currency.fromCode(null), Currency.mxn);
      expect(Currency.fromCode('KRW'), Currency.mxn);
      expect(Currency.fromCode('USD'), Currency.usd);
      expect(Currency.fromCode('EUR'), Currency.eur);
    });

    test('survives a reload and rides along in the backup', () async {
      final store = await _onboardedStore();
      await store.setCurrency(Currency.usd);

      final json = jsonDecode(store.exportJson()) as Map<String, dynamic>;
      expect(json['currencyCode'], 'USD');

      final restored = await SobraStore.load(now: () => DateTime(2026, 9, 15));
      expect(restored.currency, Currency.usd);
    });

    // The whole point of the setting: it relabels, it does not convert. A
    // budget of 600000 minor units stays 600000 minor units.
    test('never converts the amounts it relabels', () async {
      final store = await _onboardedStore();
      await store.addExpense(
        amountCentavos: 8850,
        category: ExpenseCategory.food,
        note: '',
        occurredAt: DateTime(2026, 9, 15, 12),
        paymentMethod: PaymentMethod.cash,
      );
      final budgetBefore = store.totalBudgetCentavos;
      final spentBefore = store.totalSpentCentavos;

      await store.setCurrency(Currency.usd);

      expect(store.totalBudgetCentavos, budgetBefore);
      expect(store.totalSpentCentavos, spentBefore);
      expect(store.transactions.single.amountCentavos, 8850);
    });

    // Every currency Sobra offers splits into 100, which is what lets the
    // stored integer mean the same thing across all of them.
    test('only offers currencies that split into a hundred', () {
      expect(Currency.minorUnitsPerUnit, 100);
      for (final currency in Currency.values) {
        expect(
          formatMoney(currency, 100),
          contains('1'),
          reason: '${currency.code} must read one whole unit as 1',
        );
        expect(
          formatMoney(currency, 100, showCode: false),
          '${currency.symbol}1',
        );
      }
    });
  });

  group('the running app', () {
    testWidgets('relabels every figure on screen when the currency changes', (
      tester,
    ) async {
      useSpanishDevice(tester);
      final store = await _onboardedStore();
      await tester.pumpWidget(SobraApp(store: store));
      await tester.pump();

      expect(find.textContaining('MXN'), findsWidgets);
      expect(find.textContaining('USD'), findsNothing);

      await store.setCurrency(Currency.usd);
      await tester.pump();

      expect(find.textContaining('USD'), findsWidgets);
      expect(find.textContaining('MXN'), findsNothing);

      await store.setCurrency(Currency.eur);
      await tester.pump();

      expect(find.textContaining('EUR'), findsWidgets);
      expect(find.textContaining('USD'), findsNothing);
    });
  });
}
