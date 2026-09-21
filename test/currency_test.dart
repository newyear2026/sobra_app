import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sobra_app/main.dart';
import 'package:sobra_app/l10n/generated/app_localizations.dart';
import 'package:sobra_app/l10n/labels.dart';
import 'package:sobra_app/models/currency.dart';
import 'package:sobra_app/models/expense_entry.dart';
import 'package:flutter/material.dart';
import 'package:sobra_app/models/pay_schedule.dart';
import 'package:sobra_app/screens/settings_screen.dart';
import 'package:sobra_app/theme/app_theme.dart';
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
      expect(formatMoney(Currency.gbp, 123456), '£1,234.56 GBP');
      expect(formatMoney(Currency.pen, 123456), 'S/1,234.56 PEN');
      expect(formatMoney(Currency.brl, 123456), r'R$1,234.56 BRL');
      expect(formatMoney(Currency.aud, 123456), r'$1,234.56 AUD');
    });

    // The whole dollar family, which is the reason the code is printed at all.
    test('tells the currencies sharing a sign apart by their code', () {
      final dollars = Currency.values.where((c) => c.symbol == r'$');
      expect(dollars.map((c) => c.code), [
        'MXN',
        'USD',
        'CAD',
        'COP',
        'ARS',
        'CLP',
        'AUD',
      ]);
      expect(
        dollars.map((c) => formatMoney(c, 120000)).toSet(),
        hasLength(dollars.length),
        reason: 'a figure must not read the same in two currencies',
      );
    });

    test('writes a currency with no subdivision in whole units', () {
      expect(formatMoney(Currency.clp, 123400), r'$1,234 CLP');
      expect(formatMoney(Currency.jpy, 123400), '¥1,234 JPY');
      expect(formatMoney(Currency.krw, 123400), '₩1,234 KRW');
      expect(formatMoney(Currency.krw, 100000000), '₩1,000,000 KRW');
      expect(formatMoney(Currency.jpy, 100000000), '¥1,000,000 JPY');
      expect(formatMoney(Currency.jpy, 100), '¥1 JPY');
      expect(formatMoney(Currency.jpy, -123400), '$minusSign¥1,234 JPY');
    });

    // Hundredths only ever reach the yen by being relabelled out of a
    // currency that had them. Rounding them into the unit is the reading that
    // does not quietly shave money off a figure the user already wrote down.
    test('rounds the hundredths a relabelled figure brought with it', () {
      expect(formatMoney(Currency.jpy, 8850), '¥89 JPY');
      expect(formatMoney(Currency.jpy, 8849), '¥88 JPY');
      expect(formatMoney(Currency.jpy, 49), '¥0 JPY');
      expect(formatMoney(Currency.jpy, 50), '¥1 JPY');
    });

    test('drops the code when asked, for figures shown in pairs', () {
      expect(formatMoney(Currency.usd, 123456, showCode: false), r'$1,234.56');
      expect(formatMoney(Currency.eur, 123456, showCode: false), '€1,234.56');
      expect(formatMoney(Currency.jpy, 123400, showCode: false), '¥1,234');
      expect(formatMoney(Currency.krw, 123400, showCode: false), '₩1,234');
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
      // A code Sobra does not offer, which is what a backup from a fork or a
      // future version could carry. XXX is ISO 4217's own "no currency", so
      // unlike the KRW and BRL that used to stand here it cannot become real.
      expect(Currency.fromCode('XXX'), Currency.mxn);
      expect(Currency.fromCode('not a code'), Currency.mxn);
      expect(Currency.fromCode('USD'), Currency.usd);
      expect(Currency.fromCode('EUR'), Currency.eur);
      expect(Currency.fromCode('JPY'), Currency.jpy);
      for (final currency in Currency.values) {
        expect(
          Currency.fromCode(currency.code),
          currency,
          reason: '${currency.code} must read back as itself',
        );
      }
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

    // Every currency Sobra offers stores one whole unit as 100, whatever it
    // prints, which is what lets the stored integer mean the same thing
    // across all of them — and what lets relabelling leave the ledger alone.
    test('stores one whole unit as a hundred, in every currency', () {
      expect(Currency.minorUnitsPerUnit, 100);
      for (final currency in Currency.values) {
        expect(
          formatMoney(currency, 100, showCode: false),
          '${currency.symbol}1',
          reason: '${currency.code} must read one whole unit as 1',
        );
      }
    });
  });

  // The picker is a SimpleDialog listing every value of the enum, so it is
  // the one place where adding a currency can quietly break something.
  group('the currency picker', () {
    testWidgets('gives every currency a row and a sample of its own', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      useSpanishDevice(tester);

      final store = await _onboardedStore();
      await tester.pumpWidget(
        SobraScope(
          store: store,
          child: MaterialApp(
            localizationsDelegates: sobraLocalizationsDelegates,
            supportedLocales: sobraSupportedLocales,
            theme: buildSobraTheme(),
            home: const Scaffold(
              backgroundColor: AppColors.surface,
              body: SettingsScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Moneda'),
        120,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      // The row is a PixelCard, not a ListTile, and only the card takes a tap.
      await tester.tap(
        find
            .ancestor(of: find.text('Moneda'), matching: find.byType(PixelCard))
            .first,
      );
      await tester.pumpAndSettle();

      final l10n = AppLocalizations.of(
        tester.element(find.byType(SettingsScreen)),
      );
      final samples = <String>{};
      for (final currency in Currency.values) {
        final row = find.widgetWithText(RadioListTile<Currency>, currency.code);
        expect(row, findsOneWidget, reason: '${currency.code} has no row');
        samples.add(formatMoney(currency, store.totalBudgetCentavos));
      }

      // Every heading is drawn, and each one stands above its own rows rather
      // than all of them piling up at the top.
      for (final region in CurrencyRegion.values) {
        final heading = find.text(region.label(l10n).toUpperCase());
        expect(heading, findsOneWidget, reason: 'no heading for $region');
        final top = tester.getTopLeft(heading).dy;
        for (final currency in Currency.values) {
          final row = tester
              .getTopLeft(
                find.widgetWithText(RadioListTile<Currency>, currency.code),
              )
              .dy;
          if (currency.region == region) {
            expect(
              row,
              greaterThan(top),
              reason:
                  '${currency.code} sits above '
                  'the heading it belongs under',
            );
          }
        }
      }
      // A heading is not a row: tapping one must not pick anything.
      expect(
        find.byType(RadioListTile<Currency>),
        findsNWidgets(Currency.values.length),
      );
      // A sample that reads the same in two currencies would make the picker
      // look like it were offering the same thing twice.
      expect(samples, hasLength(Currency.values.length));
      // The dialog scrolls rather than overflowing, however long the list is.
      expect(tester.takeException(), isNull);
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

      await store.setCurrency(Currency.jpy);
      await tester.pump();

      expect(find.textContaining('JPY'), findsWidgets);
      expect(find.textContaining('EUR'), findsNothing);
    });
  });
}
