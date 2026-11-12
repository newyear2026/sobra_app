import 'package:excel_community/excel_community.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sobra_app/l10n/generated/app_localizations.dart';
import 'package:sobra_app/models/currency.dart';
import 'package:sobra_app/models/expense_entry.dart';
import 'package:sobra_app/models/income_entry.dart';
import 'package:sobra_app/services/ledger_export_data.dart';
import 'package:sobra_app/services/ledger_xlsx.dart';

ExpenseEntry expense(
  int amount, {
  String note = '',
  bool pending = false,
  String? recurringId,
}) => ExpenseEntry(
  id: 'expense-$amount',
  amountCentavos: amount,
  category: ExpenseCategory.food,
  note: note,
  occurredAt: DateTime(2026, 11, 1, 9, 12),
  paymentMethod: PaymentMethod.cash,
  isPendingCashAdjustment: pending,
  recurringId: recurringId,
);

void main() {
  for (final currency in Currency.values) {
    test(
      '${currency.code}: typed dates, signed amounts and safe notes',
      () async {
        final l10n = await AppLocalizations.delegate.load(const Locale('pt'));
        final workbook = Excel.decodeBytes(
          ledgerXlsx(
            LedgerExportData(
              l10n: l10n,
              currency: currency,
              expenses: [expense(8850, note: '=1+1')],
              incomes: [
                IncomeEntry(
                  id: 'income',
                  amountCentavos: 123456,
                  kind: IncomeKind.salary,
                  note: '+2+2',
                  occurredAt: DateTime(2026, 10, 31, 23, 59),
                  destination: PaymentMethod.card,
                  allocation: IncomeAllocation.cycle,
                ),
              ],
            ),
          ),
        );
        expect(workbook.tables.keys, ['Sobrita']);
        final sheet = workbook['Sobrita'];
        expect(sheet.maxRows, 3);
        expect(sheet.maxColumns, 8);
        Data cell(String address) =>
            sheet.cell(CellIndex.indexByString(address));
        expect(cell('G1').value, TextCellValue(l10n.csvHeaderAmount));
        expect(cell('A2').displayText, '2026-10-31');
        expect(cell('B2').value, const TimeCellValue(hour: 23, minute: 59));
        expect(cell('B2').cellStyle!.numberFormat.formatCode, 'hh:mm');
        expect(cell('A3').displayText, '2026-11-01');
        expect(cell('B3').value, const TimeCellValue(hour: 9, minute: 12));
        expect(cell('E2').value, TextCellValue('+2+2'));
        expect(cell('E3').value, TextCellValue('=1+1'));
        expect(cell('H3').value, TextCellValue(currency.code));
        num amount(Data cell) => switch (cell.value) {
          IntCellValue(:final value) => value,
          DoubleCellValue(:final value) => value,
          _ => throw StateError('Amount is not numeric'),
        };
        expect(
          amount(cell('G2')),
          currency.decimalDigits == 0 ? 1235 : 1234.56,
        );
        expect(amount(cell('G3')), currency.decimalDigits == 0 ? -89 : -88.50);
        expect(
          cell('G3').displayText,
          currency.decimalDigits == 0 ? '-89' : '-88.50',
        );
        expect(
          sheet.rows
              .expand((row) => row)
              .where((cell) => cell?.value is FormulaCellValue),
          isEmpty,
        );
      },
    );
  }

  test(
    'all UI languages preserve text and localized fixed/pending labels',
    () async {
      for (final locale in AppLocalizations.supportedLocales) {
        final l10n = await AppLocalizations.delegate.load(locale);
        const notes = [
          '=1+1',
          '+SUM(A1)',
          '-3+3',
          '@SUM(A1)',
          '＝1+1',
          '점심, "커피"; pão\nleite',
          '<tag> & text',
          '😀',
        ];
        final sheet = Excel.decodeBytes(
          ledgerXlsx(
            LedgerExportData(
              l10n: l10n,
              currency: Currency.brl,
              expenses: [
                for (var i = 0; i < notes.length; i++)
                  expense(i + 1, note: notes[i]),
                expense(100, pending: true, note: 'placeholder'),
                expense(200, recurringId: 'rent'),
              ],
              incomes: const [],
            ),
          ),
        )['Sobrita'];
        expect(
          sheet.rows.first.map((cell) => cell?.value.toString()).toList(),
          [
            l10n.csvHeaderDate,
            l10n.csvHeaderTime,
            l10n.csvHeaderType,
            l10n.csvHeaderCategory,
            l10n.csvHeaderNote,
            l10n.csvHeaderPayment,
            l10n.csvHeaderAmount,
            l10n.csvHeaderCurrency,
          ],
        );
        for (final note in notes) {
          expect(
            sheet.rows.skip(1).map((row) => row[4]?.value),
            contains(TextCellValue(note)),
          );
        }
        expect(
          sheet.rows.skip(1).map((row) => row[4]?.value),
          contains(TextCellValue(l10n.cashResolutionPending)),
        );
        expect(
          sheet.rows.skip(1).map((row) => row[2]?.value),
          contains(TextCellValue(l10n.csvTypeFixedExpense)),
        );
      }
    },
  );

  test(
    'encodes literal SpreadsheetML escapes and invalid XML controls',
    () async {
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      final sheet = Excel.decodeBytes(
        ledgerXlsx(
          LedgerExportData(
            l10n: l10n,
            currency: Currency.usd,
            expenses: [expense(1, note: '_x000A_\u0000=1+1\r\nnext')],
            incomes: const [],
          ),
        ),
      )['Sobrita'];
      // This library exposes raw SpreadsheetML strings. Excel/Sheets decode the
      // escape sequences once to recover the original note, without a formula.
      expect(
        sheet.rows[1][4]?.value,
        TextCellValue('_x005F_x000A__x0000_=1+1_x000D_\nnext'),
      );
    },
  );

  test(
    '1,500 entries are retained and ordered, with no blank extra sheets',
    () async {
      final l10n = await AppLocalizations.delegate.load(const Locale('ko'));
      final data = LedgerExportData(
        l10n: l10n,
        currency: Currency.krw,
        expenses: [
          for (var i = 1499; i >= 0; i--)
            ExpenseEntry(
              id: '$i',
              amountCentavos: 150,
              category: ExpenseCategory.food,
              note: '메모 $i',
              occurredAt: DateTime(2025, 1, 1).add(Duration(hours: i)),
              paymentMethod: PaymentMethod.cash,
            ),
        ],
        incomes: const [],
      );
      final workbook = Excel.decodeBytes(ledgerXlsx(data));
      expect(workbook.tables.length, 1);
      final rows = workbook['Sobrita'].rows;
      expect(rows.length, 1501);
      expect(rows[1][4]?.value, TextCellValue('메모 0'));
      expect(rows.last[4]?.value, TextCellValue('메모 1499'));
      expect(rows.skip(1).map((row) => row[6]?.displayText).toSet(), {'-2'});
    },
  );
}
