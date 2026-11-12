import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:sobra_app/models/expense_entry.dart';
import 'package:sobra_app/models/pay_schedule.dart';
import 'package:sobra_app/models/store_failure.dart';
import 'package:sobra_app/state/sobra_store.dart';

class ImportDisk extends InMemorySharedPreferencesStore {
  ImportDisk() : super.empty();
  String? failKey;
  @override
  Future<bool> setValue(String type, String key, Object value) =>
      key == failKey ? Future.value(false) : super.setValue(type, key, value);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ImportDisk disk;
  late SobraStore store;
  late String original;
  late Map<String, dynamic> incoming;
  final now = DateTime(2026, 10, 4, 12);
  setUp(() async {
    disk = ImportDisk();
    SharedPreferencesStorePlatform.instance = disk;
    SharedPreferences.resetStatic();
    store = await SobraStore.load(now: () => now);
    await store.configureOnboarding(
      budgetCentavos: 600000,
      schedule: const PaySchedule.semiMonthly(),
    );
    await store.completeOnboarding();
    await store.grantCatalogEntries({'rabbit'});
    await store.addExpense(
      amountCentavos: 1200,
      category: ExpenseCategory.food,
      note: 'Current',
      occurredAt: now,
      paymentMethod: PaymentMethod.card,
      receiptFileName: 'current-receipt.jpg',
    );
    original = store.exportJson();
    incoming = jsonDecode(original) as Map<String, dynamic>;
    incoming['transactions'][0]['amountCentavos'] = 2700;
    incoming['transactions'][0]['note'] = 'Imported';
    incoming['transactions'][0]['receiptFileName'] = null;
    incoming['ownedCatalogIds'] = [
      'michi',
      'quokka',
      'platypus',
      'no-ads',
      'sobra.character.alpaca',
    ];
    incoming['characterId'] = 'platypus';
  });
  tearDown(SharedPreferences.resetStatic);

  test(
    'preview is read-only and success replaces data with a recoverable prior copy',
    () async {
      final raw = jsonEncode(incoming);
      final summary = store.inspectBackup(raw);
      expect(summary.expenses, 1);
      expect(summary.budgetCentavos, 600000);
      expect(store.exportJson(), original);
      await store.importBackup(raw);
      expect(store.transactions.single.amountCentavos, 2700);
      expect(store.transactions.single.note, 'Imported');
      final prefs = await SharedPreferences.getInstance();
      expect(
        jsonDecode(prefs.getString('sobra_state_backup_v2')!),
        jsonDecode(original),
      );
      final reopened = await SobraStore.load(now: () => now);
      expect(reopened.transactions.single.note, 'Imported');
      expect(reopened.ownedCatalogIds, containsAll(['rabbit', 'quokka']));
      expect(reopened.ownedCatalogIds, isNot(contains('platypus')));
      expect(
        reopened.ownedCatalogIds,
        isNot(contains('sobra.character.alpaca')),
      );
      expect(reopened.ownsNoAds, isFalse);
      expect(reopened.characterId, 'michi');
      expect(reopened.referencedReceipts, contains('current-receipt.jpg'));
      await reopened.setTotalBudget(700000);
      expect(
        jsonDecode(reopened.backupBeforeImportJson!),
        jsonDecode(original),
      );
      await reopened.importBackup(reopened.backupBeforeImportJson!);
      expect(reopened.transactions.single.note, 'Current');
      expect(reopened.baseBudgetCentavos, 600000);
    },
  );

  test(
    'malformed, truncated and unsupported backups cannot change data',
    () async {
      for (final raw in [
        '{',
        '[]',
        '{}',
        '{"transactions":[],"totalBudgetCentavos":4}',
      ]) {
        expect(() => store.inspectBackup(raw), throwsFormatException);
        await expectLater(store.importBackup(raw), throwsFormatException);
        expect(store.exportJson(), original);
      }
      incoming['schemaVersion'] = 999;
      expect(
        () => store.inspectBackup(jsonEncode(incoming)),
        throwsUnsupportedError,
      );
    },
  );

  test(
    'invalid amounts, duplicate IDs, receipt paths and schedules are rejected',
    () {
      final invalid = <void Function(Map<String, dynamic>)>[
        (d) => d['transactions'][0]['amountCentavos'] = -1,
        (d) => d['baseBudgetCentavos'] = 0.5,
        (d) => d['transactions'][0]['occurredAt'] = '2026-02-31T12:00:00',
        (d) => d['transactions'].add(Map.of(d['transactions'][0])),
        (d) => d['transactions'][0]['receiptFileName'] = '../secret',
        (d) => d['paySchedule']['planningHorizonDays'] = 0,
        (d) => d['cashCountWeekday'] = 0,
        (d) => d['recurringExpenses'] = [
          {
            'id': 'bad-fixed',
            'name': 'Rent',
            'amountCentavos': 100,
            'category': 'home',
            'paymentMethod': 'card',
            'unit': 'week',
            'interval': 0,
            'anchorDate': '2026-10-01',
          },
        ],
      ];
      for (final mutate in invalid) {
        final data = jsonDecode(original) as Map<String, dynamic>;
        mutate(data);
        expect(
          () => store.inspectBackup(jsonEncode(data)),
          throwsFormatException,
        );
        expect(store.exportJson(), original);
      }
    },
  );

  for (final key in [
    'flutter.sobra_before_import_v2',
    'flutter.sobra_state_backup_v2',
    'flutter.sobra_state_v2',
  ]) {
    test(
      'failed write to $key preserves memory and disk and can be retried',
      () async {
        disk.failKey = key;
        await expectLater(
          store.importBackup(jsonEncode(incoming)),
          throwsA(isA<SobraStoreException>()),
        );
        expect(store.exportJson(), original);
        final persisted =
            (await disk.getAll())['flutter.sobra_state_v2']! as String;
        expect(jsonDecode(persisted), jsonDecode(original));
        disk.failKey = null;
        await store.importBackup(jsonEncode(incoming));
        final prefs = await SharedPreferences.getInstance();
        expect(
          jsonDecode(prefs.getString('sobra_state_backup_v2')!),
          jsonDecode(original),
        );
        expect(store.transactions.single.note, 'Imported');
      },
    );
  }

  test(
    'a second import in a row still keeps the ledger from before the first',
    () async {
      Map<String, dynamic> withNote(String note) {
        final copy = jsonDecode(jsonEncode(incoming)) as Map<String, dynamic>;
        copy['transactions'][0]['note'] = note;
        return copy;
      }

      await store.importBackup(jsonEncode(withNote('Wrong file')));
      await store.importBackup(jsonEncode(withNote('Another wrong file')));
      final reopened = await SobraStore.load(now: () => now);
      final previous =
          jsonDecode(reopened.backupBeforeImportJson!) as Map<String, dynamic>;
      expect(previous['transactions'][0]['note'], 'Current');
    },
  );

  test(
    'an import after the user records something keeps that ledger instead',
    () async {
      await store.importBackup(jsonEncode(incoming));
      await store.addExpense(
        amountCentavos: 500,
        category: ExpenseCategory.food,
        note: 'After import',
        occurredAt: now,
        paymentMethod: PaymentMethod.card,
      );
      await store.importBackup(original);
      final previous =
          jsonDecode(store.backupBeforeImportJson!) as Map<String, dynamic>;
      expect(
        (previous['transactions'] as List).map((entry) => entry['note']),
        containsAll(['Imported', 'After import']),
      );
    },
  );

  test(
    'cycles that ended after the backup was taken close on import',
    () async {
      // [original] was exported on Oct 4, before any cycle had closed.
      final later = await SobraStore.load(now: () => DateTime(2026, 11, 2, 9));
      await later.importBackup(original);
      expect(later.cycleRecords, isNotEmpty);
      expect(
        later.cycleRecords.every((r) => r.end.isBefore(later.cycleStart)),
        isTrue,
      );
    },
  );

  test(
    'older exported schemas are migrated before preview and import',
    () async {
      incoming.remove('schemaVersion');
      incoming.remove('starterCharacterId');
      incoming.remove('nativeAdInstallDay');
      expect(store.inspectBackup(jsonEncode(incoming)).expenses, 1);
      await store.importBackup(jsonEncode(incoming));
      expect(store.starterCharacterId, 'michi');
      expect(store.ownedCatalogIds, contains('poodle'));
    },
  );
}
