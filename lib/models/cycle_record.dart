import 'pay_schedule.dart';

/// Elapsed days a cycle needs before a daily average says anything.
///
/// On day one the divisor is one, so the "average" is simply today's
/// spending — a figure that reads on screen as a forecast the user never
/// made. Two days is barely better. Three is where it starts describing a
/// habit rather than a morning.
const minimumDaysForAverage = 3;

/// [spentCentavos] spread over [days], rounded to whole units of currency.
///
/// Null under [minimumDaysForAverage], which callers show as "still gathering"
/// rather than as a number nobody should act on.
///
/// Rounded here rather than in `formatMoney`: the formatter prints centavos
/// whenever an amount has them, and every real transaction should keep them.
/// Only derived figures are rounded, so a daily average reads $394 while a
/// $45.50 coffee still reads $45.50.
int? averagePerDayCentavos(int spentCentavos, int days) {
  if (days < minimumDaysForAverage) return null;
  final perDay = spentCentavos / days;
  return (perDay / 100).round() * 100;
}

/// What one closed cycle came to, written down when it closed.
///
/// This exists because the past cannot be recomputed. Cycle boundaries come
/// from the current pay schedule and the budget from the current total, so
/// asking today "what were September's cycles?" re-cuts September with rules
/// that may have been adopted in October — producing windows the user never
/// lived and figures they never saw. Settling is the one moment all four
/// numbers are true at once, so that is where they get kept.
///
/// Amounts stay a plain count of minor units with no currency attached.
/// Switching currency relabels the whole ledger rather than converting it, and
/// a record that remembered pesos while the rest of the app had moved to
/// dollars would be the only thing on screen disagreeing.
class CycleRecord {
  const CycleRecord({
    required this.start,
    required this.end,
    required this.budgetCentavos,
    required this.spentCentavos,
    required this.cycleType,
  });

  final DateTime start;
  final DateTime end;

  /// The budget as it stood when this cycle closed, not as it stands now.
  final int budgetCentavos;
  final int spentCentavos;

  /// How the cycle was bounded at the time, which a later change to the pay
  /// schedule cannot alter after the fact.
  final PayCycleType cycleType;

  int get lengthInDays => end.difference(start).inDays + 1;

  /// What this cycle spent per day, over every day it covered.
  ///
  /// Days with nothing recorded count. A cycle is a stretch of time the user
  /// lived through, and dividing by only the days they happened to file
  /// something would report a habit nobody has.
  int? get averageSpentPerDayCentavos =>
      averagePerDayCentavos(spentCentavos, lengthInDays);

  /// What was left over, or how far past the budget the cycle went.
  int get resultCentavos => budgetCentavos - spentCentavos;

  bool get successful => budgetCentavos > 0 && spentCentavos <= budgetCentavos;

  Map<String, Object?> toJson() => {
    'start': start.toIso8601String(),
    'end': end.toIso8601String(),
    'budgetCentavos': budgetCentavos,
    'spentCentavos': spentCentavos,
    'cycleType': cycleType.name,
  };

  factory CycleRecord.fromJson(Map<String, dynamic> json) => CycleRecord(
    start: DateTime.parse(json['start'] as String),
    end: DateTime.parse(json['end'] as String),
    budgetCentavos: (json['budgetCentavos'] as num).toInt(),
    spentCentavos: (json['spentCentavos'] as num).toInt(),
    cycleType: PayCycleType.values.byName(json['cycleType'] as String),
  );
}
