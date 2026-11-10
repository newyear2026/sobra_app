import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sobra_app/l10n/generated/app_localizations.dart';
import 'package:sobra_app/screens/goal_product_browser_screen.dart';
import 'package:sobra_app/services/goal_product_import.dart';
import 'package:sobra_app/theme/app_theme.dart';

import 'support/localizations.dart';

Map<String, Object?> _product({
  String source = 'https://www.walmart.com.mx/ip/airpods-4/00019594968846',
  Object? price = '1499.00',
  Object? currency = 'MXN',
  Object? image = 'https://i5.walmartimages.com.mx/product.jpg',
}) => {
  'isProduct': true,
  'sourceUrl': source,
  'title': 'AirPods 4',
  'imageUrl': image,
  'price': price,
  'currencyCode': currency,
};

void main() {
  group('shopping link validation', () {
    test('preserves queries and normalizes a pasted fragment', () {
      expect(
        safeGoalUrl(
          ' https://www.amazon.com.mx/dp/B0DHZVB27Q?th=1#reviews ',
        ).toString(),
        'https://www.amazon.com.mx/dp/B0DHZVB27Q?th=1',
      );
    });

    test(
      'rejects local addresses, credentials, scripts and other protocols',
      () {
        for (final link in [
          'http://www.walmart.com.mx/ip/item/123',
          'javascript:alert(1)',
          'file:///etc/passwd',
          'https://user:pass@www.amazon.com.mx/dp/item',
          'https://localhost',
          'https://127.0.0.1/item',
          'https://192.168.1.1/item',
          'https://[::1]/item',
          'https://printer.local/item',
          'https://store.internal/item',
          'https://example.com:8443/item',
          'intent://item',
        ]) {
          expect(safeGoalUrl(link), isNull, reason: link);
        }
      },
    );
  });

  group('product extraction boundary', () {
    test('accepts both native WebView JSON representations', () {
      final json = jsonEncode(_product());
      for (final raw in [json, jsonEncode(json)]) {
        final product = parseGoalProductPayload(raw)!;
        expect(product.title, 'AirPods 4');
        expect(product.priceCentavos, 149900);
        expect(product.currencyCode, 'MXN');
        expect(product.merchantName, 'Walmart México');
        expect(product.imageUrl, 'https://i5.walmartimages.com.mx/product.jpg');
      }
    });

    test('requires a product page and ignores unrelated page metadata', () {
      expect(
        parseGoalProductPayload({..._product(), 'isProduct': false}),
        isNull,
      );
      expect(
        parseGoalProductPayload({
          ..._product(),
          'sourceUrl': 'https://localhost',
        }),
        isNull,
      );
      expect(
        parseGoalProductPayload({..._product(), 'title': '', 'imageUrl': null}),
        isNull,
      );
      expect(parseGoalProductPayload('not JSON'), isNull);
      expect(parseGoalProductPayload('[]'), isNull);
    });

    test('stops before returning any data from human verification screens', () {
      expect(
        () => parseGoalProductPayload({
          ..._product(),
          'verificationRequired': true,
        }),
        throwsA(isA<GoalProductVerificationRequired>()),
      );
    });

    test('amounts remain exact and malformed/ambiguous prices stay empty', () {
      expect(
        parseGoalProductPayload(_product(price: '1242.66'))!.priceCentavos,
        124266,
      );
      expect(
        parseGoalProductPayload(_product(price: '0.01'))!.priceCentavos,
        1,
      );
      for (final price in [
        '1,499',
        '1499 - 2999',
        '9.999',
        '0',
        '-100',
        '1e4',
        'MXN 1499',
        '9999999999999',
        1499,
        null,
      ]) {
        expect(
          parseGoalProductPayload(_product(price: price))!.priceCentavos,
          isNull,
          reason: '$price',
        );
      }
    });

    test('currency is explicit and never inferred from the caller locale', () {
      expect(
        parseGoalProductPayload(_product(currency: 'USD'))!.currencyCode,
        'USD',
      );
      expect(
        parseGoalProductPayload(_product(currency: null))!.currencyCode,
        isNull,
      );
      expect(
        parseGoalProductPayload(_product(currency: r'$'))!.currencyCode,
        isNull,
      );
    });

    test(
      'unsafe image is dropped while an editable title can still be used',
      () {
        final result = parseGoalProductPayload(
          _product(image: 'data:image/png;base64,abc'),
        )!;
        expect(result.title, 'AirPods 4');
        expect(result.imageUrl, isNull);
      },
    );

    test('merchant label uses actual hostname boundaries', () {
      final result = parseGoalProductPayload(
        _product(source: 'https://amazon.com.mx.example.com/item'),
      )!;
      expect(result.merchantName, 'amazon.com.mx.example.com');
      expect(
        parseGoalProductPayload(
          _product(source: 'https://articulo.mercadolibre.com.mx/MLM-123-item'),
        )!.merchantName,
        'Mercado Libre',
      );
    });

    test('long title is bounded without splitting Unicode runes', () {
      final result = parseGoalProductPayload({
        ..._product(),
        'title': List.filled(90, '😀').join(),
      })!;
      expect(result.title!.runes.length, 60);
      expect(result.title!.contains('\uFFFD'), isFalse);
    });

    test('long merchant hostname fits the saved goal label limit', () {
      final label = List.filled(60, 'a').join();
      final result = parseGoalProductPayload(
        _product(source: 'https://$label.$label.$label.com/item'),
      )!;
      expect(result.merchantName!.runes.length, 80);
    });
  });

  testWidgets(
    'unsupported platform offers direct entry without a WebView',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildSobraTheme(),
          localizationsDelegates: sobraLocalizationsDelegates,
          supportedLocales: sobraSupportedLocales,
          home: const GoalProductBrowserScreen(
            url: 'https://www.walmart.com.mx/ip/item/123',
          ),
        ),
      );
      final l10n = AppLocalizations.of(
        tester.element(find.byType(GoalProductBrowserScreen)),
      );
      expect(find.text(l10n.goalBrowserUnsupported), findsOneWidget);
      expect(find.text(l10n.goalBrowserManual), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.linux),
  );
}
