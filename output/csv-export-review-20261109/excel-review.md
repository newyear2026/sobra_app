# CSV / Excel export verification — 2026-11-09

- Both the transactions toolbar and Settings open the same CSV / Excel (.xlsx) picker.
- Both formats export the same full history and eight columns, oldest first.
- CSV retains UTF-8 BOM, regional delimiters, signed amounts and quoted-tab memo protection.
- XLSX stores dates, times and amounts as typed values and notes as text. KRW/JPY/CLP keep whole-unit rounding. The header is frozen and columns are filterable.
- One shared lock covers format selection, generation and sharing. Cancel, empty history and errors release it; rapid repeated choices cannot pop the underlying screen.
- 60 relevant automated tests passed: CSV generation, XLSX for 13 currencies and seven languages, a 1,500-row ledger, both export entry points, cancellation/retry, formula-like notes, large-text layout, currency regressions and localization parity. See `excel-tests.log`.
- Static analysis of the affected exporter, picker, settings screen and tests passed; see `excel-analyze.log`.
- Independently parsed the three production-generated XLSX samples as ZIP/XML: all entries retained, numeric amounts and totals match, no formula cells, correct date/time formats and frozen header. See `samples/xlsx-validation.json`.
- Imported the production BRL workbook into Google Sheets while its locale was ko_KR: all 13 amounts were numeric and the sum was 10370.90. Changing the locale to pt_BR preserved the values and sum; only display separators changed. `=1+1` remained literal text in both locales. See `xlsx-sheets-verification.json`.
- Rendered the actual Korean picker component: `export-picker-ko.png`.
- Desktop Microsoft Excel was not available for a native open-file check. The XLSX option was exercised through automated UI/share-callback tests and real Google Sheets import. A subsequent Pixel_3 emulator check also passed both CSV and XLSX from the transactions toolbar and Settings, including native Android chooser/file generation and comparison with all eight existing ledger records. See `../csv-excel-emulator-20261109/verification.md` for device evidence and the separate startup ANR observed before these export tests.
