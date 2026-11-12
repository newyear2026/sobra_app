import 'dart:async';
import 'dart:io';
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

import '../../test/support/localizations.dart';

void main() {
  test('expense and income notes must remain text in spreadsheet import', () async {
    final l10n = await AppLocalizations.delegate.load(const Locale('ko'));
    final csv = ledgerCsv(
      l10n: l10n,
      currency: Currency.usd,
      expenses: [ExpenseEntry(
        id: 'expense', amountCentavos: 1234,
        category: ExpenseCategory.food, note: '=1+1',
        occurredAt: DateTime(2026, 11, 1), paymentMethod: PaymentMethod.cash,
      )],
      incomes: [IncomeEntry(
        id: 'income', amountCentavos: 5678, kind: IncomeKind.extra,
        note: '=2+2', occurredAt: DateTime(2026, 11, 2),
        destination: PaymentMethod.card, allocation: IncomeAllocation.cycle,
      )],
    );
    final notes = csv.split('\r\n').skip(1).where((row) => row.isNotEmpty)
        .map((row) => row.split(',')[4]).toList();
    expect(notes.where((note) => note.startsWith('=')), isEmpty,
        reason: 'An exported note must not become an executable formula. Actual: $notes');
  });

  for (final settings in [false, true]) {
    testWidgets('${settings ? 'settings' : 'movements'} double tap starts only one export', (tester) async {
      SharedPreferences.setMockInitialValues({});
      AppTelemetry.instance = AppTelemetry();
      final completion = Completer<ShareResultStatus>();
      var sends = 0;
      LedgerExport.instance = LedgerExport(send: (_, _) {
        sends++;
        return completion.future;
      });
      addTearDown(() {
        LedgerExport.instance = LedgerExport();
        AppTelemetry.instance = AppTelemetry();
      });
      final store = await tester.runAsync(() async {
        final store = await SobraStore.load(now: () => DateTime(2026, 9, 9, 8));
        await store.configureOnboarding(
          budgetCentavos: 600000, schedule: const PaySchedule.semiMonthly(),
          cashCentavos: 124000,
        );
        await store.completeOnboarding();
        store.takePendingXpNotice();
        await store.addExpense(amountCentavos: 18000,
          category: ExpenseCategory.food, note: 'QA',
          occurredAt: DateTime(2026, 9, 8, 14), paymentMethod: PaymentMethod.cash);
        return store;
      });
      useSpanishDevice(tester);
      tester.view.physicalSize = const Size(520, 1360);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(SobraApp(store: store!));
      await tester.pump();
      await tester.tap(find.text(settings ? 'Mi Sobrita' : 'Movim.'));
      await tester.pump(const Duration(milliseconds: 100));
      final button = settings ? find.text('Exportar movimientos (CSV)')
          : find.byKey(const Key('ledger-export'));
      if (settings) await tester.scrollUntilVisible(button, 200);
      await tester.tap(button);
      await tester.pump();
      await tester.tap(button);
      await tester.pump();
      final observedSends = sends;
      completion.complete(ShareResultStatus.dismissed);
      await tester.pump();
      expect(observedSends, 1,
          reason: 'The first share was still pending when the second tap arrived.');
    });
  }

  test('overlapping exports do not race while replacing the cache file', () async {
    final root = await Directory.systemTemp.createTemp('csv_review_');
    addTearDown(() => root.delete(recursive: true));
    final folder = Directory('${root.path}/$ledgerExportFolder');
    final bytes = Uint8List.fromList([65, 44, 66, 13, 10]);
    await writeLedgerExportFile(folder, bytes, 'sobrita_2026-11-09.csv');
    final errors = <Object>[];
    for (var round = 0; round < 10; round++) {
      await Future.wait(List.generate(2, (_) async {
        try {
          await writeLedgerExportFile(folder, bytes, 'sobrita_2026-11-09.csv');
        } catch (error) {
          errors.add(error);
        }
      }));
    }
    expect(errors, isEmpty, reason: 'Overlapping taps must not fail writing the shared CSV cache.');
  });
}
