import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sobra_app/state/sobra_store.dart';

/// Closed testers run 1.0.7 (13), and their phones hold ledgers that build
/// wrote. The fixture is one: onboarding on Sep 20 with a cash count, card and
/// cash expenses, an extra income, two fixed expenses with payments, a cash
/// reconciliation, a purchased friend, a budget change and a pay-schedule
/// change queued for later. It was produced by running that sequence against
/// d5da348, the code 1.0.7 (13) was built from, and holds what that build
/// itself showed on Oct 2 and after reopening on Oct 20.
///
/// Every later build has to read the file and show the same numbers.
Map<String, Object?> _shown(SobraStore s) => {
  'transactions': s.transactions.length,
  'incomes': s.incomes.length,
  'cashReconciliations': s.cashReconciliations.length,
  'recurring': s.recurringExpenses.length,
  'totalXp': s.totalXp,
  'cycleRecords': [
    for (final r in s.cycleRecords)
      '${r.start.toIso8601String()}|${r.end.toIso8601String()}|'
          '${r.budgetCentavos}|${r.spentCentavos}|${r.fixedPaidCentavos}',
  ],
  'cycleStart': s.cycleStart.toIso8601String(),
  'cycleEnd': s.cycleEnd.toIso8601String(),
  'totalBudget': s.totalBudgetCentavos,
  'baseBudget': s.baseBudgetCentavos,
  'spent': s.totalSpentCentavos,
  'remaining': s.remainingBudgetCentavos,
  'dailyAllowance': s.dailyAllowanceCentavos,
  'todayRemaining': s.todayRemainingCentavos,
  'expectedCash': s.expectedCashCentavos,
  'countedCash': s.countedCashCentavos,
  'characterId': s.characterId,
  'owned': s.ownedCatalogIds.toList()..sort(),
  'paySchedule': s.paySchedule.type.name,
  'pending': s.pendingPaySchedule?.type.name,
  'currency': s.currency.code,
  'recordedDays': s.recordedDayCount,
  'onboarded': s.hasCompletedOnboarding,
  'storageError': s.hasStorageError,
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final fixture =
      jsonDecode(File('test/fixtures/ledger_1_0_7.json').readAsStringSync())
          as Map<String, dynamic>;

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'sobra_state_v2': fixture['state'] as String,
      'sobra_state_backup_v2': fixture['backup'] as String,
    });
  });

  test('a 1.0.7 ledger opens with the figures 1.0.7 showed', () async {
    final store = await SobraStore.load(now: () => DateTime(2026, 10, 2, 18));
    expect(_shown(store), fixture['atBuild']);
  });

  test('a 1.0.7 ledger settles its cycles the way 1.0.7 did', () async {
    final store = await SobraStore.load(now: () => DateTime(2026, 10, 20, 9));
    expect(_shown(store), fixture['later']);
  });

  test('the save 1.0.7 kept as its backup still restores', () async {
    final store = await SobraStore.load(now: () => DateTime(2026, 10, 2, 18));
    expect(store.hasRecoverableBackup, isTrue);
  });
}
