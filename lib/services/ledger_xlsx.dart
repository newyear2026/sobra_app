import 'dart:typed_data';

import 'package:excel_community/excel_community.dart';

import '../models/currency.dart';
import 'ledger_export_data.dart';

/// Numeric cells carry values, not locale-dependent strings. User text is
/// explicitly text, so even a note beginning with '=' cannot become a formula.
Uint8List ledgerXlsx(LedgerExportData data) {
  final workbook = Excel.createExcel();
  workbook.rename(workbook.getDefaultSheet()!, 'Sobrita');
  final sheet = workbook['Sobrita'];
  sheet.frozenRows = 1;
  sheet.appendRow(data.headers.map(TextCellValue.new).toList());
  final headerStyle = CellStyle(
    bold: true,
    fontFamily: 'Calibri',
    fontSize: 11,
    fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
    backgroundColorHex: ExcelColor.fromHexString('#202848'),
    textWrapping: TextWrapping.WrapText,
  );
  final dateStyle = CellStyle(
    numberFormat: NumFormat.custom(formatCode: 'yyyy-mm-dd'),
  );
  final timeStyle = CellStyle(
    numberFormat: NumFormat.custom(formatCode: 'hh:mm'),
  );
  final amountStyle = CellStyle(
    numberFormat: NumFormat.custom(
      formatCode: data.currency.decimalDigits == 0 ? '0' : '0.00',
    ),
    horizontalAlign: HorizontalAlign.Right,
  );
  final noteStyle = CellStyle(textWrapping: TextWrapping.WrapText);
  const widths = [13.0, 9.0, 20.0, 24.0, 42.0, 18.0, 18.0, 12.0];
  for (var column = 0; column < widths.length; column++) {
    sheet.setColumnWidth(column, widths[column]);
    sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: column, rowIndex: 0))
            .cellStyle =
        headerStyle;
  }
  sheet.setRowHeight(0, 30);

  for (var index = 0; index < data.rows.length; index++) {
    final row = data.rows[index];
    sheet.appendRow([
      DateCellValue(year: row.at.year, month: row.at.month, day: row.at.day),
      TimeCellValue(hour: row.at.hour, minute: row.at.minute),
      TextCellValue(row.type),
      TextCellValue(row.category),
      TextCellValue(_xlsxText(row.note)),
      TextCellValue(row.payment),
      data.currency.decimalDigits == 0
          ? IntCellValue(ledgerWholeAmount(row.centavos))
          : DoubleCellValue(row.centavos / Currency.minorUnitsPerUnit),
      TextCellValue(data.currency.code),
    ]);
    for (final (column, style) in [
      (0, dateStyle),
      (1, timeStyle),
      (4, noteStyle),
      (6, amountStyle),
    ]) {
      sheet
              .cell(
                CellIndex.indexByColumnRow(
                  columnIndex: column,
                  rowIndex: index + 1,
                ),
              )
              .cellStyle =
          style;
    }
  }
  sheet.setAutoFilterByString('A1:H${data.rows.length + 1}');
  final bytes = workbook.encode();
  if (bytes == null) throw StateError('Could not encode ledger workbook');
  return Uint8List.fromList(bytes);
}

// The writer XML-escapes &, < and >, but not SpreadsheetML's own string
// escapes. Preserve literal _xNNNN_ notes and encode XML-invalid controls so
// pasted text cannot corrupt the workbook. Tabs and newlines remain readable.
String _xlsxText(String text) => text
    .replaceAllMapped(
      RegExp(r'_[xX][0-9a-fA-F]{4}_'),
      (match) => '_x005F_${match[0]!.substring(1)}',
    )
    .replaceAllMapped(
      RegExp(r'[\x00-\x08\x0b-\x1f\uFFFE\uFFFF]'),
      (match) =>
          '_x${match[0]!.codeUnitAt(0).toRadixString(16).toUpperCase().padLeft(4, '0')}_',
    );
