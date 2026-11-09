import '../l10n/generated/app_localizations.dart';
import '../l10n/labels.dart';
import '../models/currency.dart';
import '../models/expense_entry.dart';
import '../models/income_entry.dart';

/// Excel on Windows reads a CSV without this mark as the system code page,
/// which turns every accent, every Hangul syllable and every kana into noise.
/// Sheets and Numbers ignore it, so it costs nothing to always write it.
const ledgerCsvByteOrderMark = '﻿';

/// The column separator a spreadsheet in this money's country expects.
///
/// Follows [Currency.decimalComma], not the language on screen, for the same
/// reason amounts do: a spreadsheet set up where 1,5 is one and a half splits
/// a row on commas into garbage, so those countries' Excel opens CSV on `;`.
String ledgerCsvDelimiter(Currency currency) =>
    currency.decimalComma ? ';' : ',';

/// The file name the share sheet shows, dated so two exports never collide.
String ledgerCsvFileName(DateTime now) => 'sobrita_${_date(now)}.csv';

/// Every expense and income as a spreadsheet-ready CSV, oldest first.
///
/// Labels follow the app's language; numbers follow [currency]. Amounts are
/// signed — spending negative, income positive — so one SUM over the column is
/// the net, and carry no thousands mark, which a spreadsheet would otherwise
/// have to guess at. Dates are ISO, which every spreadsheet reads in every
/// locale and then shows in its own format.
///
/// Cash-count reconciliations that moved no money (a transfer, a corrected
/// count) are not rows: they are neither spending nor income. Receipt photos
/// stay out, as they do from the JSON backup.
String ledgerCsv({
  required AppLocalizations l10n,
  required Currency currency,
  required Iterable<ExpenseEntry> expenses,
  required Iterable<IncomeEntry> incomes,
}) {
  final delimiter = ledgerCsvDelimiter(currency);
  final rows = <({DateTime at, List<String> cells})>[
    for (final expense in expenses)
      (
        at: expense.occurredAt,
        cells: [
          _date(expense.occurredAt),
          _time(expense.occurredAt),
          expense.isFixedPayment
              ? l10n.csvTypeFixedExpense
              : l10n.csvTypeExpense,
          expense.category.label(l10n),
          // A count that came up short has a placeholder note, not the
          // user's; the ledger shows it as "to identify", and so does this.
          expense.isPendingCashAdjustment
              ? l10n.cashResolutionPending
              : expense.note.trim(),
          expense.paymentMethod.label(l10n),
          _amount(currency, -expense.amountCentavos),
          currency.code,
        ],
      ),
    for (final income in incomes)
      (
        at: income.occurredAt,
        cells: [
          _date(income.occurredAt),
          _time(income.occurredAt),
          l10n.csvTypeIncome,
          income.kind.label(l10n),
          income.note.trim(),
          income.destination.label(l10n),
          _amount(currency, income.amountCentavos),
          currency.code,
        ],
      ),
  ]..sort((a, b) => a.at.compareTo(b.at));

  final header = [
    l10n.csvHeaderDate,
    l10n.csvHeaderTime,
    l10n.csvHeaderType,
    l10n.csvHeaderCategory,
    l10n.csvHeaderNote,
    l10n.csvHeaderPayment,
    l10n.csvHeaderAmount,
    l10n.csvHeaderCurrency,
  ];
  final buffer = StringBuffer(ledgerCsvByteOrderMark);
  for (final cells in [header, for (final row in rows) row.cells]) {
    buffer
      ..write(cells.map((cell) => _escape(cell, delimiter)).join(delimiter))
      // RFC 4180 line ends; Excel is the reader that cares.
      ..write('\r\n');
  }
  return buffer.toString();
}

/// Quotes a cell when it holds anything that would end it early.
String _escape(String cell, String delimiter) {
  final needsQuotes =
      cell.contains(delimiter) ||
      cell.contains('"') ||
      cell.contains('\n') ||
      cell.contains('\r');
  return needsQuotes ? '"${cell.replaceAll('"', '""')}"' : cell;
}

String _two(int value) => value.toString().padLeft(2, '0');

String _date(DateTime at) =>
    '${at.year.toString().padLeft(4, '0')}-${_two(at.month)}-${_two(at.day)}';

String _time(DateTime at) => '${_two(at.hour)}:${_two(at.minute)}';

/// A signed amount in whole units, with the currency's decimal mark and no
/// grouping: `-1150,00`, `79.90`, `-12000`.
String _amount(Currency currency, int centavos) {
  final sign = centavos < 0 ? '-' : '';
  final magnitude = centavos.abs();
  if (currency.decimalDigits == 0) {
    // Same half-up integer rounding as the screen, so a yen relabelled from a
    // currency with hundredths exports the figure the ledger shows.
    final whole =
        (magnitude + Currency.minorUnitsPerUnit ~/ 2) ~/
        Currency.minorUnitsPerUnit;
    return '$sign$whole';
  }
  final whole = magnitude ~/ Currency.minorUnitsPerUnit;
  final cents = magnitude % Currency.minorUnitsPerUnit;
  return '$sign$whole${currency.decimalSeparator}${_two(cents)}';
}
