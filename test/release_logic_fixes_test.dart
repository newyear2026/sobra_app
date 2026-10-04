import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sobra_app/models/expense_entry.dart';
import 'package:sobra_app/models/pay_schedule.dart';
import 'package:sobra_app/models/recurring_expense.dart';
import 'package:sobra_app/services/purchase_service.dart';
import 'package:sobra_app/state/sobra_store.dart';

import 'support/fake_purchase_backend.dart';

void main() {
  late DateTime now;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    now = DateTime(2026, 10, 1, 12);
  });
  Future<SobraStore> ready() async {
    final store = await SobraStore.load(now: () => now);
    await store.configureOnboarding(
      budgetCentavos: 600000,
      schedule: const PaySchedule.weekly(weeklyPayDay: DateTime.thursday),
    );
    await store.completeOnboarding();
    return store;
  }

  test(
    'late expense, amount/date edits, delete and undo refresh saved history',
    () async {
      final store = await ready();
      now = DateTime(2026, 10, 15, 12);
      await store.settleCycles();
      await store.setTotalBudget(900000);
      final expense = await store.addExpense(
        amountCentavos: 700000,
        category: ExpenseCategory.food,
        note: 'Late entry',
        occurredAt: DateTime(2026, 10, 2),
        paymentMethod: PaymentMethod.card,
      );
      final xpBefore = store.totalXp;
      expect(store.cycleRecords.last.budgetCentavos, 600000);
      expect(store.cycleRecords.last.spentCentavos, 700000);
      expect(store.cycleRecords.last.successful, isFalse);
      await store.updateExpense(
        expense.copyWith(
          amountCentavos: 400000,
          occurredAt: DateTime(2026, 10, 9),
        ),
      );
      expect(store.cycleRecords.last.spentCentavos, 0);
      expect(store.cycleRecords.first.spentCentavos, 400000);
      final updated = store.transactions.single;
      await store.deleteExpense(updated.id);
      expect(store.cycleRecords.first.spentCentavos, 0);
      await store.restoreExpense(updated);
      expect(store.cycleRecords.first.spentCentavos, 400000);
      expect(
        store.totalXp,
        xpBefore,
        reason: 'editing history does not re-award XP',
      );
      final saved = jsonDecode(store.exportJson()) as Map<String, dynamic>;
      expect((saved['cycleRecords'] as List).last['spentCentavos'], 400000);
      final reopened = await SobraStore.load(now: () => now);
      expect(reopened.cycleRecords.first.spentCentavos, 400000);
      expect(reopened.cycleRecords.first.budgetCentavos, 600000);
    },
  );

  test(
    'late fixed payments update fixed totals without changing everyday spending',
    () async {
      final store = await ready();
      final bill = await store.addRecurringExpense(
        name: 'Rent',
        amountCentavos: 200000,
        category: ExpenseCategory.home,
        paymentMethod: PaymentMethod.card,
        frequency: FixedFrequency.monthly,
        firstDueDate: now,
      );
      now = DateTime(2026, 10, 8, 12);
      await store.settleCycles();
      final payment = await store.recordFixedPayment(
        recurringId: bill.id,
        occurrenceDate: DateTime(2026, 10, 1),
        amountCentavos: 200000,
        paidAt: DateTime(2026, 10, 2),
      );
      expect(store.cycleRecords.single.fixedPaidCentavos, 200000);
      expect(store.cycleRecords.single.spentCentavos, 0);
      await store.deleteExpense(payment.id);
      expect(store.cycleRecords.single.fixedPaidCentavos, 0);
      await store.restoreExpense(payment);
      expect(store.cycleRecords.single.fixedPaidCentavos, 200000);
    },
  );

  test(
    'loading an old stale snapshot derives totals from its saved dates',
    () async {
      final store = await ready();
      await store.addExpense(
        amountCentavos: 1200,
        category: ExpenseCategory.food,
        note: '',
        occurredAt: now,
        paymentMethod: PaymentMethod.card,
      );
      now = DateTime(2026, 10, 8, 12);
      await store.settleCycles();
      final data = jsonDecode(store.exportJson()) as Map<String, dynamic>;
      data['cycleRecords'][0]['spentCentavos'] = 0;
      SharedPreferences.setMockInitialValues({
        'sobra_state_v2': jsonEncode(data),
      });
      final restored = await SobraStore.load(now: () => now);
      expect(restored.cycleRecords.single.spentCentavos, 1200);
    },
  );

  group('store reconnect', () {
    late FakeBackend backend;
    late SobraPurchases purchases;
    setUp(() async {
      backend = FakeBackend()
        ..catalogue = [productFor('sobra.character.platypus', 'MX 39')];
      purchases = SobraPurchases(backend: backend, store: await ready());
    });
    tearDown(() async {
      purchases.dispose();
      await backend.close();
    });

    test('offline launch recovers prices and purchases on resume', () async {
      backend.available = false;
      await purchases.start();
      expect(purchases.readiness, StoreReadiness.unavailable);
      backend.available = true;
      await purchases.refreshOnResume();
      expect(purchases.readiness, StoreReadiness.ready);
      expect(purchases.localizedPriceFor('sobra.character.platypus'), 'MX 39');
    });

    test('a failed price query can be manually retried', () async {
      backend.failPrices = true;
      await purchases.start();
      expect(purchases.hasPrices, isFalse);
      backend.failPrices = false;
      await purchases.refresh();
      expect(purchases.localizedPriceFor('sobra.character.platypus'), 'MX 39');
    });

    test('concurrent resume and retry share a single request', () async {
      final waiting = Completer<void>();
      backend.beforePriceQuery = () => waiting.future;
      final first = purchases.start();
      await pumpEventQueue();
      final retry = purchases.refresh();
      final resume = purchases.refreshOnResume();
      expect(purchases.isRefreshing, isTrue);
      expect(backend.priceQueries, 1);
      waiting.complete();
      await Future.wait([first, retry, resume]);
      expect(purchases.isRefreshing, isFalse);
      expect(backend.availabilityChecks, 1);
    });

    test('dispose during refresh does not notify disposed listeners', () async {
      final local = SobraPurchases(backend: backend, store: await ready());
      final waiting = Completer<void>();
      backend.beforePriceQuery = () => waiting.future;
      final refresh = local.start();
      await pumpEventQueue();
      local.dispose();
      waiting.complete();
      await refresh;
    });
  });
}
