import 'pay_schedule.dart';

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
