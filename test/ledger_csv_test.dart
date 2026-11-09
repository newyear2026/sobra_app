import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sobra_app/l10n/generated/app_localizations.dart';
import 'package:sobra_app/main.dart';
import 'package:sobra_app/models/currency.dart';
import 'package:sobra_app/models/expense_entry.dart';
import 'package:sobra_app/models/income_entry.dart';
import 'package:sobra_app/models/pay_schedule.dart';
import 'package:sobra_app/services/app_telemetry.dart';
import 'package:sobra_app/services/ledger_csv.dart';
import 'package:sobra_app/services/ledger_export.dart';
import 'package:sobra_app/state/sobra_store.dart';

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

    Future<void> openApp(WidgetTester tester, SobraStore store) async {
      useSpanishDevice(tester);
      tester.view.physicalSize = const Size(520, 1360);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(SobraApp(store: store));
      await tester.pump();
    }

    testWidgets('the ledger top bar exports from Movimientos', (tester) async {
      final store = await tester.runAsync(storeWith);
      await openApp(tester, store!);

      await tester.tap(find.text('Movim.'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.byKey(const Key('ledger-export')));
      await tester.pump();

      expect(utf8.decode(files.single.$2), contains('Tacos'));
      expect(sent.last.$2, {'origin': 'movements', 'result': 'shared'});
    });

    testWidgets('the Datos row exports, and an empty ledger says so', (
      tester,
    ) async {
      final store = await tester.runAsync(() => storeWith(entries: false));
      await openApp(tester, store!);

      await tester.tap(find.text('Mi Sobrita'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.scrollUntilVisible(
        find.text('Exportar movimientos (CSV)'),
        200,
      );
      await tester.tap(find.text('Exportar movimientos (CSV)'));
      await tester.pump();

      expect(files, isEmpty);
      expect(sent.last.$2, {'origin': 'settings', 'result': 'empty'});
      expect(
        find.text('Todavía no hay movimientos para exportar.'),
        findsOneWidget,
      );
    });
  });
}
