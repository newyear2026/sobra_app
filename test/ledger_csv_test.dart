import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sobra_app/l10n/generated/app_localizations.dart';
import 'package:sobra_app/models/currency.dart';
import 'package:sobra_app/models/expense_entry.dart';
import 'package:sobra_app/models/income_entry.dart';
import 'package:sobra_app/models/pay_schedule.dart';
import 'package:sobra_app/screens/settings_screen.dart';
import 'package:sobra_app/screens/transactions_screen.dart';
import 'package:sobra_app/services/app_telemetry.dart';
import 'package:sobra_app/services/ledger_csv.dart';
import 'package:sobra_app/services/ledger_export.dart';
import 'package:sobra_app/state/sobra_store.dart';
import 'package:sobra_app/theme/app_theme.dart';
import 'package:sobra_app/widgets/ledger_export_dialog.dart';

import 'support/localizations.dart';

ExpenseEntry _expense(
  int centavos,
  DateTime at, {
  String note = '',
  ExpenseCategory category = ExpenseCategory.food,
  PaymentMethod method = PaymentMethod.cash,
  String? recurringId,
  bool pending = false,
}) => ExpenseEntry(
  id: 'e$centavos',
  amountCentavos: centavos,
  category: category,
  note: note,
  occurredAt: at,
  paymentMethod: method,
  recurringId: recurringId,
  isPendingCashAdjustment: pending,
);

IncomeEntry _income(int centavos, DateTime at, {String note = ''}) =>
    IncomeEntry(
      id: 'i$centavos',
      amountCentavos: centavos,
      kind: IncomeKind.salary,
      note: note,
      occurredAt: at,
      destination: PaymentMethod.card,
      allocation: IncomeAllocation.cycle,
    );

/// The rows after the header, without the byte-order mark.
List<String> _rows(String csv) {
  expect(csv, startsWith(ledgerCsvByteOrderMark));
  final lines = csv.substring(1).split('\r\n');
  expect(lines.last, isEmpty, reason: 'every line ends in CRLF');
  return lines.sublist(0, lines.length - 1);
}

void main() {
  group('the file', () {
    test('is labelled in the app language, oldest first, signed', () async {
      final l10n = await AppLocalizations.delegate.load(const Locale('ko'));
      final csv = ledgerCsv(
        l10n: l10n,
        currency: Currency.krw,
        expenses: [
          _expense(950000, DateTime(2026, 11, 3, 12, 40), note: '점심'),
          _expense(
            150000,
            DateTime(2026, 11, 4, 8, 5),
            category: ExpenseCategory.transport,
            method: PaymentMethod.card,
          ),
        ],
        incomes: [_income(320000000, DateTime(2026, 11, 1, 9, 12))],
      );

      expect(_rows(csv), [
        '날짜,시간,유형,분류,메모,결제,금액,통화',
        '2026-11-01,09:12,수입,${l10n.incomeKindSalary},,카드,3200000,KRW',
        '2026-11-03,12:40,지출,식비,점심,현금,-9500,KRW',
        '2026-11-04,08:05,지출,교통,,카드,-1500,KRW',
      ]);
    });

    test('splits on ; with a decimal comma where the money does', () async {
      final l10n = await AppLocalizations.delegate.load(const Locale('pt'));
      final csv = ledgerCsv(
        l10n: l10n,
        currency: Currency.brl,
        expenses: [_expense(115000, DateTime(2026, 11, 1, 10, 5))],
        incomes: [_income(7990, DateTime(2026, 11, 8, 11, 30))],
      );

      expect(_rows(csv), [
        'Data;Hora;Tipo;Categoria;Nota;Pagamento;Valor;Moeda',
        '2026-11-01;10:05;Gasto;Comida;;Dinheiro;-1150,00;BRL',
        '2026-11-08;11:30;Entrada;${l10n.incomeKindSalary};;Cartão;79,90;BRL',
      ]);
    });

    test('keeps , and a decimal point for pesos, with no grouping', () async {
      final l10n = await AppLocalizations.delegate.load(const Locale('es'));
      final csv = ledgerCsv(
        l10n: l10n,
        currency: Currency.mxn,
        expenses: [_expense(123456705, DateTime(2026, 11, 2, 7))],
        incomes: const [],
      );

      expect(_rows(csv).last, endsWith(',-1234567.05,MXN'));
    });

    test('rounds a whole-unit money the way the screen does', () async {
      final l10n = await AppLocalizations.delegate.load(const Locale('ja'));
      String last(int centavos) => _rows(
        ledgerCsv(
          l10n: l10n,
          currency: Currency.jpy,
          expenses: [_expense(centavos, DateTime(2026, 11, 2))],
          incomes: const [],
        ),
      ).last;

      expect(last(8850), endsWith(',-89,JPY'));
      expect(last(8849), endsWith(',-88,JPY'));
    });

    test('quotes a note that holds the separator, a quote or a line', () async {
      final l10n = await AppLocalizations.delegate.load(const Locale('pt'));
      final csv = ledgerCsv(
        l10n: l10n,
        currency: Currency.brl,
        expenses: [
          _expense(4500, DateTime(2026, 11, 6, 20), note: 'Cinema; pipoca'),
          _expense(1200, DateTime(2026, 11, 6, 21), note: 'o "melhor" café'),
          _expense(800, DateTime(2026, 11, 6, 22), note: 'pão\nleite'),
          // A comma is not this file's separator, so it needs no quotes.
          _expense(300, DateTime(2026, 11, 6, 23), note: 'bala, chiclete'),
        ],
        incomes: const [],
      );
      final body = csv.substring(1);

      expect(body, contains(';"Cinema; pipoca";'));
      expect(body, contains(';"o ""melhor"" café";'));
      expect(body, contains(';"pão\nleite";'));
      expect(body, contains(';bala, chiclete;'));
    });

    test(
      'protects formula-like notes without changing saved notes or amounts',
      () async {
        final l10n = await AppLocalizations.delegate.load(const Locale('ko'));
        const notes = [
          '=1+1',
          '+1+1',
          '-1+1',
          '@SUM(A1)',
          '  =1+1',
          '\t=1+1',
          '\r\n=1+1',
          '\u0000=1+1',
          '＝1+1',
          '＋1+1',
          '－1+1',
          '＠SUM(A1)',
          '=SUM(1,2)',
          '=SUM(1;2)',
          '=IF(1,"한글","")',
          '=1+1\n두 번째 줄',
        ];
        for (final currency in [Currency.usd, Currency.brl, Currency.krw]) {
          final delimiter = ledgerCsvDelimiter(currency);
          for (final note in notes) {
            final expense = _expense(12345, DateTime(2026, 11, 1), note: note);
            final income = _income(67890, DateTime(2026, 11, 2), note: note);
            final csv = ledgerCsv(
              l10n: l10n,
              currency: currency,
              expenses: [expense],
              incomes: [income],
            );
            final protectedCell = '"\t${note.trim().replaceAll('"', '""')}"';
            expect(
              protectedCell.allMatches(csv),
              hasLength(2),
              reason: '${currency.code}: both note columns protect $note',
            );
            expect(csv, contains('$delimiter$protectedCell$delimiter'));
            final expenseAmount = switch (currency) {
              Currency.krw => '-123',
              Currency.brl => '-123,45',
              _ => '-123.45',
            };
            final incomeAmount = switch (currency) {
              Currency.krw => '679',
              Currency.brl => '678,90',
              _ => '678.90',
            };
            expect(
              csv,
              contains(
                '$delimiter$expenseAmount$delimiter${currency.code}\r\n',
              ),
            );
            expect(
              csv,
              contains('$delimiter$incomeAmount$delimiter${currency.code}\r\n'),
            );
            expect(expense.note, note);
            expect(income.note, note);
          }
        }
      },
    );

    test(
      'ordinary notes stay unchanged and dangerous text stays in one cell',
      () async {
        final l10n = await AppLocalizations.delegate.load(const Locale('en'));
        final csv = ledgerCsv(
          l10n: l10n,
          currency: Currency.usd,
          expenses: [
            _expense(1000, DateTime(2026, 11, 1), note: '점심 식사'),
            _expense(2000, DateTime(2026, 11, 2), note: 'coffee, "milk"\n=1+1'),
          ],
          incomes: [],
        );
        expect(csv, contains(',점심 식사,'));
        expect(csv, contains(',"coffee, ""milk""\n=1+1",'));
        expect(csv, isNot(contains('\t')));
      },
    );

    test('marks fixed payments and leaves a count placeholder out', () async {
      final l10n = await AppLocalizations.delegate.load(const Locale('es'));
      final csv = ledgerCsv(
        l10n: l10n,
        currency: Currency.mxn,
        expenses: [
          _expense(
            500000,
            DateTime(2026, 11, 1),
            note: 'Renta',
            category: ExpenseCategory.home,
            recurringId: 'r1',
          ),
          _expense(
            2000,
            DateTime(2026, 11, 2),
            note: 'placeholder from the count',
            pending: true,
          ),
        ],
        incomes: const [],
      );
      final rows = _rows(csv);

      expect(rows[1], contains(',Gasto fijo,Hogar,Renta,'));
      expect(rows[2], contains(',Gasto,Comida,${l10n.cashResolutionPending},'));
      expect(csv, isNot(contains('placeholder')));
    });

    test('is named by the day it was made', () {
      expect(
        ledgerCsvFileName(DateTime(2026, 11, 9, 23, 59)),
        'sobrita_2026-11-09.csv',
      );
    });
  });

  group('the export file', () {
    test('is the only file left in its folder, however many exports', () async {
      final root = await Directory.systemTemp.createTemp('sobrita_export');
      addTearDown(() => root.delete(recursive: true));
      final folder = Directory('${root.path}/$ledgerExportFolder');
      final bytes = Uint8List.fromList(utf8.encode('a,b\r\n'));

      await writeLedgerExportFile(folder, bytes, 'sobrita_2026-11-08.csv');
      await writeLedgerExportFile(folder, bytes, 'sobrita_2026-11-09.csv');
      final last = await writeLedgerExportFile(
        folder,
        bytes,
        'sobrita_2026-11-09.csv',
      );

      final left = folder.listSync().map((e) => e.uri.pathSegments.last);
      expect(left, ['sobrita_2026-11-09.csv']);
      expect(await last.readAsBytes(), bytes);
      // Nothing else under the temp root, unlike share_plus's random folders.
      expect(root.listSync(), hasLength(1));
    });

    test(
      'serializes overlapping writes and recovers after a failed write',
      () async {
        final root = await Directory.systemTemp.createTemp('sobrita_export');
        addTearDown(() => root.delete(recursive: true));
        final folder = Directory('${root.path}/$ledgerExportFolder');
        final first = Uint8List.fromList(utf8.encode('first\r\n'));
        final last = Uint8List.fromList(utf8.encode('last\r\n'));
        await Future.wait([
          writeLedgerExportFile(folder, first, 'first.csv'),
          writeLedgerExportFile(folder, last, 'last.csv'),
        ]);
        expect(folder.listSync().map((file) => file.uri.pathSegments.last), [
          'last.csv',
        ]);
        expect(await File('${folder.path}/last.csv').readAsBytes(), last);
        final blocker = await File(
          '${root.path}/blocker',
        ).writeAsString('file');
        await expectLater(
          writeLedgerExportFile(
            Directory('${blocker.path}/child'),
            first,
            'failed.csv',
          ),
          throwsA(isA<FileSystemException>()),
        );
        final recovered = await writeLedgerExportFile(
          folder,
          first,
          'recovered.csv',
        );
        expect(await recovered.readAsBytes(), first);
      },
    );
  });

  group('exporting', () {
    late List<(String, Uint8List)> files;
    late List<(String, Map<String, Object>)> sent;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      files = [];
      sent = [];
      LedgerExport.instance = LedgerExport(
        send: (Uint8List bytes, String name) async {
          files.add((name, bytes));
          return ShareResultStatus.success;
        },
        clock: () => DateTime(2026, 11, 9, 8),
      );
      AppTelemetry.instance = AppTelemetry(
        sendEvent: (name, parameters) async => sent.add((name, parameters)),
      );
      addTearDown(() {
        LedgerExport.instance = LedgerExport();
        AppTelemetry.instance = AppTelemetry();
      });
    });

    // September, like the other whole-app tests: a November day opens the
    // seasonal gift over the tabs.
    Future<SobraStore> storeWith({bool entries = true}) async {
      final store = await SobraStore.load(now: () => DateTime(2026, 9, 9, 8));
      await store.configureOnboarding(
        budgetCentavos: 600000,
        schedule: const PaySchedule.semiMonthly(),
        cashCentavos: 124000,
      );
      await store.completeOnboarding();
      store.takePendingXpNotice();
      if (entries) {
        await store.addExpense(
          amountCentavos: 18000,
          category: ExpenseCategory.food,
          note: 'Tacos',
          occurredAt: DateTime(2026, 9, 8, 14),
          paymentMethod: PaymentMethod.cash,
        );
      }
      return store;
    }

    test(
      'hands the share sheet a dated file and reports how it ended',
      () async {
        final l10n = await AppLocalizations.delegate.load(const Locale('es'));
        final store = await storeWith();

        final result = await LedgerExport.instance.share(
          l10n,
          store,
          LedgerExportOrigin.movements,
        );

        expect(result, LedgerExportResult.shared);
        expect(files.single.$1, 'sobrita_2026-11-09.csv');
        // The mark has to reach the bytes: `utf8.decode` would hide it.
        expect(files.single.$2.take(3), [0xEF, 0xBB, 0xBF]);
        expect(utf8.decode(files.single.$2), contains('Tacos'));
        expect(sent.single.$1, 'ledger_exported');
        expect(sent.single.$2, {'origin': 'movements', 'result': 'shared'});
      },
    );

    test('opens nothing for an empty ledger', () async {
      final l10n = await AppLocalizations.delegate.load(const Locale('es'));
      final store = await storeWith(entries: false);

      final result = await LedgerExport.instance.share(
        l10n,
        store,
        LedgerExportOrigin.settings,
      );

      expect(result, LedgerExportResult.empty);
      expect(files, isEmpty);
      expect(sent.single.$2, {'origin': 'settings', 'result': 'empty'});
    });

    test(
      'XLSX selection shares an actual workbook with its own extension',
      () async {
        final l10n = await AppLocalizations.delegate.load(const Locale('pt'));
        final store = await storeWith();
        final result = await LedgerExport.instance.share(
          l10n,
          store,
          LedgerExportOrigin.settings,
          format: LedgerExportFormat.xlsx,
        );
        expect(result, LedgerExportResult.shared);
        expect(files.single.$1, 'sobrita_2026-11-09.xlsx');
        expect(files.single.$2.take(4), [0x50, 0x4b, 0x03, 0x04]);
      },
    );

    test(
      'one picker across entry points, cancellation releases the lock',
      () async {
        final l10n = await AppLocalizations.delegate.load(const Locale('ko'));
        final store = await storeWith();
        final choice = Completer<LedgerExportFormat?>();
        var pickers = 0;
        Future<LedgerExportFormat?> choose() {
          pickers++;
          return choice.future;
        }

        final first = LedgerExport.instance.share(
          l10n,
          store,
          LedgerExportOrigin.settings,
          chooseFormat: choose,
        );
        final duplicate = LedgerExport.instance.share(
          l10n,
          store,
          LedgerExportOrigin.movements,
          chooseFormat: choose,
        );
        expect(identical(first, duplicate), isTrue);
        expect(pickers, 1);
        expect(files, isEmpty);
        choice.complete(null);
        expect(await first, LedgerExportResult.dismissed);
        expect(LedgerExport.instance.isSharing, isFalse);
        expect(files, isEmpty);
        expect(
          await LedgerExport.instance.share(
            l10n,
            store,
            LedgerExportOrigin.settings,
            chooseFormat: () async => LedgerExportFormat.csv,
          ),
          LedgerExportResult.shared,
        );
        expect(files.single.$1, endsWith('.csv'));
      },
    );

    test('a sheet that cannot open is reported, not thrown', () async {
      final l10n = await AppLocalizations.delegate.load(const Locale('es'));
      final store = await storeWith();
      LedgerExport.instance = LedgerExport(
        send: (_, _) => throw StateError('no sheet'),
      );

      final result = await LedgerExport.instance.share(
        l10n,
        store,
        LedgerExportOrigin.settings,
      );

      expect(result, LedgerExportResult.failed);
      expect(sent.single.$2, {'origin': 'settings', 'result': 'failed'});
    });

    test(
      'both origins share one pending export and log only its first origin',
      () async {
        final l10n = await AppLocalizations.delegate.load(const Locale('es'));
        final store = await storeWith();
        final completion = Completer<ShareResultStatus>();
        var sends = 0;
        final exporter = LedgerExport(
          send: (_, _) {
            sends++;
            return completion.future;
          },
        );
        final busy = <bool>[];
        exporter.addListener(() => busy.add(exporter.isSharing));
        final first = exporter.share(l10n, store, LedgerExportOrigin.settings);
        final duplicate = exporter.share(
          l10n,
          store,
          LedgerExportOrigin.movements,
        );
        expect(identical(first, duplicate), isTrue);
        expect(exporter.isSharing, isTrue);
        expect(sends, 1);
        completion.complete(ShareResultStatus.dismissed);
        expect(await first, LedgerExportResult.dismissed);
        expect(await duplicate, LedgerExportResult.dismissed);
        expect(busy, [true, false]);
        expect(sent.single.$2, {'origin': 'settings', 'result': 'dismissed'});
        expect(
          await exporter.share(l10n, store, LedgerExportOrigin.movements),
          LedgerExportResult.dismissed,
        );
        expect(sends, 2);
      },
    );

    test(
      'failure and empty results release the lock for another export',
      () async {
        final l10n = await AppLocalizations.delegate.load(const Locale('es'));
        final store = await storeWith();
        var attempts = 0;
        final exporter = LedgerExport(
          send: (_, _) async {
            if (attempts++ == 0) throw StateError('test failure');
            return ShareResultStatus.success;
          },
        );
        expect(
          await exporter.share(l10n, store, LedgerExportOrigin.settings),
          LedgerExportResult.failed,
        );
        expect(exporter.isSharing, isFalse);
        expect(
          await exporter.share(l10n, store, LedgerExportOrigin.settings),
          LedgerExportResult.shared,
        );
        // Use a fresh preferences store so this case contains no previous entries.
        SharedPreferences.setMockInitialValues({});
        final fresh = await storeWith(entries: false);
        expect(
          await exporter.share(l10n, fresh, LedgerExportOrigin.settings),
          LedgerExportResult.empty,
        );
        expect(exporter.isSharing, isFalse);
        expect(attempts, 2);
      },
    );

    Future<void> openExportScreen(
      WidgetTester tester,
      SobraStore store, {
      bool settings = false,
    }) async {
      useSpanishDevice(tester);
      tester.view.physicalSize = const Size(520, 1360);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        SobraScope(
          store: store,
          child: MaterialApp(
            locale: const Locale('es'),
            localizationsDelegates: sobraLocalizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: buildSobraTheme(),
            home: Scaffold(
              body: settings
                  ? const SettingsScreen()
                  : const TransactionsScreen(),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('the ledger top bar exports from Movimientos', (tester) async {
      final store = await tester.runAsync(storeWith);
      await openExportScreen(tester, store!);
      await tester.tap(find.byKey(const Key('ledger-export')));
      await tester.pump();
      expect(find.byType(LedgerExportDialog), findsOneWidget);
      expect(files, isEmpty);
      await tester.tap(find.byKey(const Key('ledger-export-csv')));
      await tester.pump();

      expect(utf8.decode(files.single.$2), contains('Tacos'));
      expect(sent.last.$2, {'origin': 'movements', 'result': 'shared'});
    });

    testWidgets('the Datos row exports, and an empty ledger says so', (
      tester,
    ) async {
      final store = await tester.runAsync(() => storeWith(entries: false));
      await openExportScreen(tester, store!, settings: true);
      await tester.scrollUntilVisible(find.text('Exportar movimientos'), 200);
      await tester.tap(find.text('Exportar movimientos'));
      await tester.pump();

      expect(files, isEmpty);
      expect(sent.last.$2, {'origin': 'settings', 'result': 'empty'});
      expect(
        find.text('Todavía no hay movimientos para exportar.'),
        findsOneWidget,
      );
    });

    testWidgets('settings offers both formats and shares the chosen XLSX', (
      tester,
    ) async {
      final store = await tester.runAsync(storeWith);
      final received = Completer<String>();
      LedgerExport.instance = LedgerExport(
        send: (bytes, name) async {
          expect(bytes.take(4), [0x50, 0x4b, 0x03, 0x04]);
          received.complete(name);
          return ShareResultStatus.success;
        },
      );
      await openExportScreen(tester, store!, settings: true);
      final button = find.text('Exportar movimientos');
      await tester.scrollUntilVisible(button, 200);
      await tester.tap(button);
      await tester.pump();
      expect(find.byKey(const Key('ledger-export-csv')), findsOneWidget);
      expect(find.byKey(const Key('ledger-export-xlsx')), findsOneWidget);
      // Cancel once; neither a file nor an orphaned busy state should remain.
      await tester.tap(find.text('Cancelar'));
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump();
      expect(received.isCompleted, isFalse);
      expect(LedgerExport.instance.isSharing, isFalse);
      await tester.tap(button);
      await tester.pump();
      await tester.tap(find.byKey(const Key('ledger-export-xlsx')));
      await tester.pump();
      // XLSX encoding runs in a real isolate. Alternate real event-loop time
      // with fake UI frames so its completion can reach the share callback.
      for (var attempt = 0; attempt < 200 && !received.isCompleted; attempt++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)),
        );
        await tester.pump();
      }
      expect(received.isCompleted, isTrue);
      final name = await received.future;
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump();
      expect(name, endsWith('.xlsx'));
      expect(find.byType(LedgerExportDialog), findsNothing);
      expect(LedgerExport.instance.isSharing, isFalse);
    });

    for (final settings in [false, true]) {
      testWidgets(
        '${settings ? 'settings' : 'movements'} blocks repeated taps and enables retry',
        (tester) async {
          final store = await tester.runAsync(storeWith);
          final completion = Completer<ShareResultStatus>();
          var sends = 0;
          LedgerExport.instance = LedgerExport(
            send: (_, _) {
              sends++;
              return completion.future;
            },
          );
          await openExportScreen(tester, store!, settings: settings);
          final button = settings
              ? find.text('Exportar movimientos')
              : find.byKey(const Key('ledger-export'));
          if (settings) await tester.scrollUntilVisible(button, 200);
          if (settings) {
            await tester.tap(button);
          } else {
            // Invoke the same callback again before the disabled UI rebuilds.
            final onTap = tester.widget<GestureDetector>(button).onTap!;
            onTap();
            onTap();
          }
          await tester.pump();
          expect(find.byType(LedgerExportDialog), findsOneWidget);
          expect(sends, 0);
          await tester.tap(find.byKey(const Key('ledger-export-csv')));
          await tester.pump(const Duration(milliseconds: 250));
          if (settings) expect(find.text('Preparando…'), findsOneWidget);
          expect(find.byIcon(Icons.hourglass_top), findsWidgets);
          await tester.tap(button);
          await tester.pump();
          expect(sends, 1);
          completion.complete(ShareResultStatus.dismissed);
          await tester.pump();
          await tester.pump();
          expect(LedgerExport.instance.isSharing, isFalse);
          if (settings) expect(find.text('Preparando…'), findsNothing);
          await tester.tap(button);
          await tester.pump();
          await tester.tap(find.byKey(const Key('ledger-export-csv')));
          await tester.pump(const Duration(milliseconds: 250));
          expect(sends, 2);
        },
      );
    }
  });
}
