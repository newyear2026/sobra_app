import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sobra_app/l10n/generated/app_localizations.dart';
import 'package:sobra_app/models/currency.dart';
import 'package:sobra_app/models/expense_entry.dart';
import 'package:sobra_app/models/income_entry.dart';
import 'package:sobra_app/services/ledger_csv.dart';
import 'package:sobra_app/services/ledger_export_data.dart';
import 'package:sobra_app/services/ledger_xlsx.dart';

void main() {
  test('generates synthetic CSV samples using the production exporter', () async {
    const notes = [
      '=1+1', '+2+2', '-3+3', '@SUM(A1)', '＝1+1',
      '  =1+1', '\t=1+1', '점심, "커피"', 'Cinema; pipoca',
      'pão\nleite', '=IF(1,"한글","")', '일반 메모',
    ];
    const cases = [('ko', Currency.usd), ('ko', Currency.krw), ('pt', Currency.brl)];
    final root = Directory('output/csv-export-review-20261109/samples');
    await root.create(recursive: true);
    final manifest = <Map<String, Object>>[];
    for (final (locale, currency) in cases) {
      final l10n = await AppLocalizations.delegate.load(Locale(locale));
      final expenses = [for (var i = 0; i < notes.length; i++) ExpenseEntry(
        id: 'qa-$i', amountCentavos: (i + 1) * 12345,
        category: ExpenseCategory.food, note: notes[i],
        occurredAt: DateTime(2026, 11, 1, i), paymentMethod: PaymentMethod.cash,
      )];
      final incomes = [IncomeEntry(
        id: 'qa-income', amountCentavos: 2000000, kind: IncomeKind.salary,
        note: '=2+2', occurredAt: DateTime(2026, 11, 2, 9),
        destination: PaymentMethod.card, allocation: IncomeAllocation.cycle,
      )];
      final csv = ledgerCsv(l10n: l10n, currency: currency,
          expenses: expenses.reversed, incomes: incomes);
      final filename = 'sobrita_qa_${locale}_${currency.code.toLowerCase()}.csv';
      await File('${root.path}/$filename').writeAsBytes(utf8.encode(csv));
      await File('${root.path}/${filename.replaceAll('.csv', '.xlsx')}').writeAsBytes(
        ledgerXlsx(LedgerExportData(l10n: l10n, currency: currency,
          expenses: expenses.reversed, incomes: incomes)),
      );
      manifest.add({
        'file': filename, 'locale': locale, 'currency': currency.code,
        'delimiter': ledgerCsvDelimiter(currency),
        'notes': [...notes, '=2+2'],
        'centavos': [for (final expense in expenses) -expense.amountCentavos, 2000000],
        'decimalDigits': currency.decimalDigits,
      });
      expect(csv, startsWith(ledgerCsvByteOrderMark));
    }
    await File('${root.path}/manifest.json').writeAsString(
      const JsonEncoder.withIndent('  ').convert(manifest));
  });
}
