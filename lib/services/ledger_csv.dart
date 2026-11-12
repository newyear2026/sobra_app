import '../l10n/generated/app_localizations.dart';
import '../models/currency.dart';
import '../models/expense_entry.dart';
import '../models/income_entry.dart';
import 'ledger_export_data.dart';

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
/// have to guess at. Dates use ISO YYYY-MM-DD; automatic type recognition still
/// depends on the importing spreadsheet's settings.
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
  final data = LedgerExportData(
    l10n: l10n,
    currency: currency,
    expenses: expenses,
    incomes: incomes,
  );
  final buffer = StringBuffer(ledgerCsvByteOrderMark);
  for (final cells in [
    data.headers,
    for (final row in data.rows)
      [
        _date(row.at),
        _time(row.at),
        row.type,
        row.category,
        _spreadsheetNote(row.note),
        row.payment,
        _amount(currency, row.centavos),
        currency.code,
      ],
  ]) {
    buffer
      ..write(cells.map((cell) => _escape(cell, delimiter)).join(delimiter))
      // RFC 4180 line ends; Excel is the reader that cares.
      ..write('\r\n');
  }
  return buffer.toString();
}

// Some spreadsheet importers skip whitespace/control characters before deciding
// whether a cell is a formula. Include full-width prefixes used in CJK text.
final _formulaPrefix = RegExp(r'^[\s\x00-\x1f\x7f\uFEFF]*[=+\-@＝＋－＠]');

/// Protects user-written notes when Excel opens the CSV. The leading tab must
/// stay inside a quoted field; quoting alone does not prevent formula parsing.
/// This changes only the exported note, never the saved entry or numeric amount.
/// The tab remains part of the CSV value for other consumers.
String _spreadsheetNote(String note) {
  final text = note.trim();
  return _formulaPrefix.hasMatch(text) ? '\t$text' : text;
}

/// Quotes delimiters and line breaks, and keeps a note's protective tab inside
/// the quoted field.
String _escape(String cell, String delimiter) {
  final needsQuotes =
      cell.contains(delimiter) ||
      cell.contains('"') ||
      cell.contains('\t') ||
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
    final whole = ledgerWholeAmount(magnitude);
    return '$sign$whole';
  }
  final whole = magnitude ~/ Currency.minorUnitsPerUnit;
  final cents = magnitude % Currency.minorUnitsPerUnit;
  return '$sign$whole${currency.decimalSeparator}${_two(cents)}';
}
