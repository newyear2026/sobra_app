import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sobra_app/models/pay_schedule.dart';
import 'package:sobra_app/state/sobra_store.dart';

/// Clocks in the United States move forward on Mar 14, 2027, so that day is
/// 23 hours long there. Mexico no longer changes its clocks, so on a machine
/// set to Mexico City these tests skip; run them where it matters with
///
///     TZ=America/Chicago flutter test test/daylight_saving_test.dart
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final clocksChange =
      DateTime(2027, 3, 14).timeZoneOffset !=
      DateTime(2027, 3, 15).timeZoneOffset;
  final skip = clocksChange ? false : 'the local zone has no clock change';

  Future<SobraStore> on(DateTime day, PaySchedule schedule) async {
    SharedPreferences.setMockInitialValues({});
    final store = await SobraStore.load(
      now: () => DateTime(day.year, day.month, day.day, 12),
    );
    await store.configureOnboarding(budgetCentavos: 150000, schedule: schedule);
    await store.completeOnboarding();
    return store;
  }

  test('a quincena keeps the day the clocks change', () async {
    final store = await on(
      DateTime(2027, 3, 14),
      const PaySchedule.semiMonthly(),
    );
    expect(store.cycleStart, DateTime(2027, 2, 28));
    expect(store.cycleEnd, DateTime(2027, 3, 14));
    expect(store.cycleBounds.lengthInDays, 15);
    expect(store.daysRemaining, 1);
    expect(store.dailyAllowanceCentavos, 150000);
  }, skip: skip);

  test('days left count the short day as a whole day', () async {
    final store = await on(
      DateTime(2027, 3, 1),
      const PaySchedule.semiMonthly(),
    );
    expect(store.daysRemaining, 14);
    expect(store.dailyAllowanceCentavos, 150000 ~/ 14);
  }, skip: skip);

  test('a week that spans the change starts on its payday', () async {
    final store = await on(
      DateTime(2027, 3, 16),
      const PaySchedule.weekly(weeklyPayDay: DateTime.friday),
    );
    expect(store.cycleStart, DateTime(2027, 3, 12));
    expect(store.cycleEnd, DateTime(2027, 3, 18));
    expect(store.elapsedDays, 5);
  }, skip: skip);

  test('calendar helpers ignore the hour that went missing', () {
    expect(addDays(DateTime(2027, 3, 15), -1), DateTime(2027, 3, 14));
    expect(addDays(DateTime(2027, 3, 13), 1), DateTime(2027, 3, 14));
    expect(daysBetween(DateTime(2027, 3, 1), DateTime(2027, 3, 31)), 30);
  });
}
