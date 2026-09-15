import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sobra_app/models/cycle_record.dart';
import 'package:sobra_app/models/expense_entry.dart';
import 'package:sobra_app/models/pay_schedule.dart';
import 'package:sobra_app/state/sobra_store.dart';

void main() {
  late DateTime now;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    now = DateTime(2026, 9, 15, 11);
  });

  CycleRecord recordOf({
    required int spentCentavos,
    required int days,
    int budgetCentavos = 680000,
  }) => CycleRecord(
    start: DateTime(2026, 9, 1),
    end: DateTime(2026, 9, 1).add(Duration(days: days - 1)),
    budgetCentavos: budgetCentavos,
    spentCentavos: spentCentavos,
    cycleType: PayCycleType.monthly,
  );

  group('the average is rounded to whole units, not centavos', () {
    // The worked example from the spec: MX$5,912 over 15 days.
    test('5,912 over 15 days reads as 394, not 394.13', () {
      expect(averagePerDayCentavos(591200, 15), 39400);
    });

    test('it rounds rather than truncates', () {
      // 1,000.50 a day rounds up to 1,001.
      expect(averagePerDayCentavos(300150, 3), 100100);
      // 999.49 a day rounds down to 999.
      expect(averagePerDayCentavos(299847, 3), 99900);
    });

    test('a cycle that spent nothing averages nothing', () {
      expect(averagePerDayCentavos(0, 30), 0);
    });
  });

  group('the average waits until it means something', () {
    // On day one the divisor is one, so the "average" is just today. Showing
    // it reads as a forecast the user never made.
    test('one and two elapsed days answer null', () {
      expect(averagePerDayCentavos(591200, 1), isNull);
      expect(averagePerDayCentavos(591200, 2), isNull);
    });

    test('three elapsed days is where it starts', () {
      expect(minimumDaysForAverage, 3);
      expect(averagePerDayCentavos(591200, 3), isNotNull);
    });
  });

  group('a closed cycle divides by every day it covered', () {
    test('days with nothing recorded still count', () {
      // Fifteen days, all the spending in the first three of them.
      final record = recordOf(spentCentavos: 591200, days: 15);

      expect(record.lengthInDays, 15);
      expect(record.averageSpentPerDayCentavos, 39400);
    });

    test('a cycle shorter than the minimum has no average', () {
      expect(recordOf(spentCentavos: 10000, days: 2).averageSpentPerDayCentavos,
          isNull);
    });
  });

  group('a cycle in progress divides by the days lived so far', () {
    Future<SobraStore> storeSpending(int centavos) async {
      final store = await SobraStore.load(now: () => now);
      await store.configureOnboarding(
        budgetCentavos: 680000,
        schedule: PaySchedule.irregular(
          planningHorizonDays: 30,
          irregularCycleStart: DateTime(2026, 9),
        ),
      );
      await store.addExpense(
        amountCentavos: centavos,
        category: ExpenseCategory.food,
        note: 'Comida',
        occurredAt: DateTime(2026, 9, 2, 9),
        paymentMethod: PaymentMethod.cash,
      );
      return store;
    }

    test('today counts, and the cycle start is the first day', () async {
      final store = await storeSpending(591200);

      // 1 September through 15 September inclusive.
      expect(store.cycleElapsedDays, 15);
      expect(store.cycleAveragePerDayCentavos, 39400);
    });

    // The mistake every earlier mockup made: the home screen's "left for
    // today" is not the settlement screen's "spent per day".
    test('it is not the daily allowance', () async {
      final store = await storeSpending(591200);

      expect(
        store.cycleAveragePerDayCentavos,
        isNot(store.dailyAllowanceCentavos),
      );
    });

    test('the opening days of a cycle have no average yet', () async {
      now = DateTime(2026, 9, 2, 11);
      final store = await storeSpending(591200);

      expect(store.cycleElapsedDays, 2);
      expect(store.cycleAveragePerDayCentavos, isNull);
    });
  });
}
