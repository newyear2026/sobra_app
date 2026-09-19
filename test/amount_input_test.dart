import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sobra_app/widgets/pixel_ui.dart';

const _formatter = AmountInputFormatter();

TextEditingValue _at(String text, [int? caret]) => TextEditingValue(
  text: text,
  selection: TextSelection.collapsed(offset: caret ?? text.length),
);

/// What the field holds after [keys] are pressed one at a time.
TextEditingValue _typing(String keys) {
  var value = const TextEditingValue();
  for (final key in keys.split('')) {
    final caret = value.selection.end < 0
        ? value.text.length
        : value.selection.end;
    value = _formatter.formatEditUpdate(
      value,
      _at(
        value.text.substring(0, caret) + key + value.text.substring(caret),
        caret + 1,
      ),
    );
  }
  return value;
}

/// What the field holds after [text] arrives whole, as a paste does.
String _pasting(String text) =>
    _formatter.formatEditUpdate(const TextEditingValue(), _at(text)).text;

void main() {
  group('amount field', () {
    test('a separator typed over and over stays one decimal point', () {
      // 9,,,, used to reach the store as nine pesos with nobody the wiser.
      expect(_typing('9,,,,').text, '9.');
      expect(_typing('9..5').text, '9.5');
      expect(parseAmount(_typing('9,,,,').text), 900);
    });

    test('only digits and one separator survive being typed', () {
      expect(_typing('9abc').text, '9');
      expect(_typing(r'$9').text, '9');
      expect(_typing('€9').text, '9');
      expect(_typing('1e3').text, '13');
    });

    test('grouping is placed, not typed', () {
      expect(_typing('1234567').text, '1,234,567');
      // A fifth digit on 1,234 is a ten-thousand, not the centavos of a peso.
      expect(_typing('12345').text, '12,345');
      expect(_typing('0009').text, '9');
    });

    test('the separator key starts the centavos wherever it lands', () {
      expect(_typing('9,5').text, '9.5');
      expect(_typing('.5').text, '0.5');
      final typed = _typing('9.');
      expect(typed.text, '9.');
      expect(typed.selection.end, 2, reason: 'the caret waits past the point');
    });

    test('a third centavo digit is refused rather than rounded in', () {
      expect(_typing('9.999').text, '9.99');
      expect(_pasting('0.001'), '0.00');
    });

    test('a figure wider than the field is refused whole', () {
      expect(_typing('1234567890123').text, '123,456,789,012');
      expect(_pasting('99999999999999999999'), '');
    });

    test('a pasted figure keeps its value and loses its decoration', () {
      expect(_pasting(r'$1,200.50 MXN'), '1,200.50');
      expect(_pasting('€1,200.50 EUR'), '1,200.50');
      expect(_pasting('1,000,000'), '1,000,000');
      expect(_pasting('1,200'), '1,200');
      expect(_pasting('1.234,56'), '1,234.56');
      expect(_pasting('12,34'), '12.34');
    });

    test('what the field shows is what gets registered', () {
      for (final keys in ['9,,,,', '1234567', '9.999', '.5', '12345']) {
        final shown = _typing(keys).text;
        expect(
          parseAmount(shown),
          isNotNull,
          reason: '$keys shows $shown, which must read back',
        );
      }
    });

    test('a field opens on the figure it holds, centavos and all', () {
      expect(amountFieldText(120050), '1,200.50');
      expect(amountFieldText(600000), '6,000');
      expect(amountFieldText(5), '0.05');
      expect(parseAmount(amountFieldText(120050)), 120050);
    });
  });
}
