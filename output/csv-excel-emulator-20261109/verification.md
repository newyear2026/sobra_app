# Emulator CSV / Excel export check — 2026-11-09

Device: Pixel_3 (`emulator-5554`), Korean UI, USD, existing ledger of six expenses and two incomes.

| Entry point | CSV | Excel (.xlsx) |
| --- | --- | --- |
| Transactions toolbar | Passed | Passed |
| Settings → Export activity | Passed | Passed |

All four options were tapped through the running Android app. Each opened the native Android chooser with “Sharing 1 file” and the correct `sobrita_2026-11-09` filename/extension. Closing the chooser returned to the app and allowed another export.

The files pulled from the app's export cache match the pre-test ledger: eight rows, correct dates/times, Korean text, memos, signed amounts and currency. CSV has its UTF-8 BOM and eight columns. XLSX is valid ZIP/XML, uses numeric cells for all amounts, text for memos and contains no formula cells. Only the latest file remains in the export cache. See `file-validation.json` and `device-verification.json`.

Screenshots: `13-csv-share.png`, `16-xlsx-share.png`, `21-settings-csv-share.png`, `24-settings-xlsx-share.png`. Final app screen: `26-final-settings.png`.

Setup issue: an Android input-dispatch ANR appeared before any export, immediately after hot restart (19:15:24 device time). The main native stack was in WebView. The latest debug APK was reinstalled with `adb install -r`, preserving app data, and cold-started. Initial startup was slow. All four export cases then passed; Android's last-ANR timestamp remained 19:15:24 and no exporter exception appeared in the tested process log. This check does not establish the root cause of the startup issue.

The ledger, cash reconciliations, language, currency, budget, schedule, character and room settings were unchanged. The app remains open on Settings. Verification covered file generation and the native share chooser; no external recipient was selected.
