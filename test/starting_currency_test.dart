import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sobra_app/models/currency.dart';
import 'package:sobra_app/state/sobra_store.dart';

void main() {
  group('the phone\'s country picks the starting money', () {
    test('Brazil starts in reais, Mexico in pesos', () {
      expect(Currency.forCountry('BR'), Currency.brl);
      expect(Currency.forCountry('MX'), Currency.mxn);
      expect(Currency.forCountry('br'), Currency.brl, reason: 'any case');
    });

    test('the euro area and the dollar countries', () {
      expect(Currency.forCountry('ES'), Currency.eur);
      expect(Currency.forCountry('BG'), Currency.eur);
      expect(Currency.forCountry('EC'), Currency.usd);
      expect(Currency.forCountry('KR'), Currency.krw);
    });

    // Every install started in pesos before this, so that stays the answer
    // when there is nothing better to go on.
    test('an unknown or missing country starts in pesos', () {
      expect(Currency.forCountry(null), Currency.mxn);
      expect(Currency.forCountry('ZZ'), Currency.mxn);
      expect(Currency.forCountry('IN'), Currency.mxn);
    });
  });

  group('a new ledger', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('starts in the money of the phone\'s country', () async {
      final store = await SobraStore.load(deviceCountry: 'BR');
      expect(store.currency, Currency.brl);
    });

    test('starts in pesos when nothing names a country', () async {
      final store = await SobraStore.load();
      expect(store.currency, Currency.mxn);
    });

    // The country is a starting point only. Somebody who moved, or who set
    // pesos by hand, keeps their ledger as it is on the next launch.
    test('an existing ledger never follows the phone', () async {
      final first = await SobraStore.load(deviceCountry: 'MX');
      await first.setCurrency(Currency.usd);
      first.dispose();

      final again = await SobraStore.load(deviceCountry: 'BR');
      expect(again.currency, Currency.usd);
    });
  });

  test('every currency suggests a budget of its own', () {
    for (final currency in Currency.values) {
      expect(
        currency.suggestedBudgetUnits,
        greaterThan(0),
        reason: currency.code,
      );
    }
    expect(Currency.mxn.suggestedBudgetUnits, 6000, reason: 'unchanged');
    expect(
      Currency.krw.suggestedBudgetUnits,
      greaterThan(100000),
      reason: 'not the price of a coffee',
    );
  });
}
