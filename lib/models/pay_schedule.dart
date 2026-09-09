enum PayCycleType { semiMonthly, biweekly, monthly, weekly, irregular }

class CycleBounds {
  const CycleBounds({required this.start, required this.end});

  final DateTime start;
  final DateTime end;

  int get lengthInDays => end.difference(start).inDays + 1;
  bool contains(DateTime value) {
    final date = dateOnly(value);
    return !date.isBefore(start) && !date.isAfter(end);
  }
}

class PaySchedule {
  const PaySchedule({
    required this.type,
    this.firstPayDay = 15,
    this.secondPayDay = 0,
    this.monthlyPayDay = 30,
    this.weeklyPayDay = DateTime.friday,
    this.planningHorizonDays = 7,
    this.irregularCycleStart,
    this.biweeklyAnchor,
  });

  const PaySchedule.semiMonthly({this.firstPayDay = 15, this.secondPayDay = 0})
    : type = PayCycleType.semiMonthly,
      monthlyPayDay = 30,
      weeklyPayDay = DateTime.friday,
      planningHorizonDays = 7,
      irregularCycleStart = null,
      biweeklyAnchor = null;

  /// Every fourteen days, counted from a payday the user names.
  ///
  /// This is not the quincena: a quincena lands on the 15th and the last day
  /// of the month, twenty-four times a year, while this repeats twenty-six
  /// times and drifts across month boundaries. Somebody budgeting in
  /// quincenas while a US employer pays them fortnightly needs both to exist.
  const PaySchedule.biweekly({required DateTime anchor})
    : type = PayCycleType.biweekly,
      biweeklyAnchor = anchor,
      firstPayDay = 15,
      secondPayDay = 0,
      monthlyPayDay = 30,
      weeklyPayDay = DateTime.friday,
      planningHorizonDays = 7,
      irregularCycleStart = null;

  const PaySchedule.monthly({this.monthlyPayDay = 30})
    : type = PayCycleType.monthly,
      firstPayDay = 15,
      secondPayDay = 0,
      weeklyPayDay = DateTime.friday,
      planningHorizonDays = 7,
      irregularCycleStart = null,
      biweeklyAnchor = null;

  const PaySchedule.weekly({this.weeklyPayDay = DateTime.friday})
    : type = PayCycleType.weekly,
      firstPayDay = 15,
      secondPayDay = 0,
      monthlyPayDay = 30,
      planningHorizonDays = 7,
      irregularCycleStart = null,
      biweeklyAnchor = null;

  const PaySchedule.irregular({
    this.planningHorizonDays = 7,
    required this.irregularCycleStart,
  }) : type = PayCycleType.irregular,
       firstPayDay = 15,
       secondPayDay = 0,
       monthlyPayDay = 30,
       weeklyPayDay = DateTime.friday,
       biweeklyAnchor = null;

  final PayCycleType type;
  final int firstPayDay;
  final int secondPayDay;
  final int monthlyPayDay;
  final int weeklyPayDay;
  final int planningHorizonDays;
  final DateTime? irregularCycleStart;

  /// A day the user was paid. Every fourteenth day from it starts a cycle,
  /// forwards and backwards, so older entries still land in a window.
  final DateTime? biweeklyAnchor;

  CycleBounds boundsFor(DateTime value) {
    final today = dateOnly(value);
    return switch (type) {
      PayCycleType.semiMonthly => _boundsFromRecurringDates(
        today,
        _semiMonthlyDatesAround(today),
      ),
      PayCycleType.monthly => _boundsFromRecurringDates(
        today,
        _monthlyDatesAround(today),
      ),
      PayCycleType.biweekly => _anchoredBlockBounds(
        today,
        anchor: biweeklyAnchor ?? today,
        blockDays: 14,
      ),
      PayCycleType.weekly => _weeklyBounds(today),
      PayCycleType.irregular => _anchoredBlockBounds(
        today,
        anchor: irregularCycleStart ?? today,
        blockDays: planningHorizonDays,
      ),
    };
  }

  PaySchedule copyWith({
    PayCycleType? type,
    int? firstPayDay,
    int? secondPayDay,
    int? monthlyPayDay,
    int? weeklyPayDay,
    int? planningHorizonDays,
    DateTime? irregularCycleStart,
    DateTime? biweeklyAnchor,
  }) => PaySchedule(
    type: type ?? this.type,
    firstPayDay: firstPayDay ?? this.firstPayDay,
    secondPayDay: secondPayDay ?? this.secondPayDay,
    monthlyPayDay: monthlyPayDay ?? this.monthlyPayDay,
    weeklyPayDay: weeklyPayDay ?? this.weeklyPayDay,
    planningHorizonDays: planningHorizonDays ?? this.planningHorizonDays,
    irregularCycleStart: irregularCycleStart ?? this.irregularCycleStart,
    biweeklyAnchor: biweeklyAnchor ?? this.biweeklyAnchor,
  );

  Map<String, Object?> toJson() => {
    'type': type.name,
    'firstPayDay': firstPayDay,
    'secondPayDay': secondPayDay,
    'monthlyPayDay': monthlyPayDay,
    'weeklyPayDay': weeklyPayDay,
    'planningHorizonDays': planningHorizonDays,
    'irregularCycleStart': irregularCycleStart?.toIso8601String(),
    'biweeklyAnchor': biweeklyAnchor?.toIso8601String(),
  };

  factory PaySchedule.fromJson(Map<String, dynamic> json) => PaySchedule(
    type: PayCycleType.values.byName(json['type'] as String),
    firstPayDay: (json['firstPayDay'] as num?)?.toInt() ?? 15,
    secondPayDay: (json['secondPayDay'] as num?)?.toInt() ?? 0,
    monthlyPayDay: (json['monthlyPayDay'] as num?)?.toInt() ?? 30,
    weeklyPayDay: (json['weeklyPayDay'] as num?)?.toInt() ?? DateTime.friday,
    planningHorizonDays: (json['planningHorizonDays'] as num?)?.toInt() ?? 7,
    irregularCycleStart: json['irregularCycleStart'] == null
        ? null
        : DateTime.parse(json['irregularCycleStart'] as String),
    biweeklyAnchor: json['biweeklyAnchor'] == null
        ? null
        : DateTime.parse(json['biweeklyAnchor'] as String),
  );

  CycleBounds _weeklyBounds(DateTime today) {
    final daysSinceStart = (today.weekday - weeklyPayDay + 7) % 7;
    final start = today.subtract(Duration(days: daysSinceStart));
    return CycleBounds(start: start, end: start.add(const Duration(days: 6)));
  }

  /// The block of [blockDays] containing [today], counted from [anchor].
  ///
  /// Both the fortnight and the "no fixed date" horizon are this: a window
  /// that repeats forwards and backwards from one day the user named, so a
  /// budget never has a gap and an entry dated before the anchor still lands
  /// in a cycle rather than falling outside every one of them.
  CycleBounds _anchoredBlockBounds(
    DateTime today, {
    required DateTime anchor,
    required int blockDays,
  }) {
    if (blockDays <= 0) {
      throw StateError('A repeating cycle needs at least one day.');
    }
    final from = dateOnly(anchor);
    // Counted in UTC so a daylight-saving change cannot make a block come out
    // a day short.
    final daysFromAnchor = DateTime.utc(
      today.year,
      today.month,
      today.day,
    ).difference(DateTime.utc(from.year, from.month, from.day)).inDays;
    final blockIndex = daysFromAnchor >= 0
        ? daysFromAnchor ~/ blockDays
        : -((-daysFromAnchor + blockDays - 1) ~/ blockDays);
    final start = DateTime(
      from.year,
      from.month,
      from.day + blockIndex * blockDays,
    );
    return CycleBounds(
      start: start,
      end: DateTime(start.year, start.month, start.day + blockDays - 1),
    );
  }

  List<DateTime> _semiMonthlyDatesAround(DateTime today) {
    final result = <DateTime>[];
    for (var offset = -2; offset <= 2; offset++) {
      final month = DateTime(today.year, today.month + offset);
      result
        ..add(_clampedDay(month.year, month.month, firstPayDay))
        ..add(_clampedDay(month.year, month.month, secondPayDay));
    }
    return result;
  }

  List<DateTime> _monthlyDatesAround(DateTime today) => [
    for (var offset = -2; offset <= 2; offset++)
      _clampedDay(
        DateTime(today.year, today.month + offset).year,
        DateTime(today.year, today.month + offset).month,
        monthlyPayDay,
      ),
  ];

  CycleBounds _boundsFromRecurringDates(
    DateTime today,
    List<DateTime> candidates,
  ) {
    final sorted = candidates.toSet().toList()..sort();
    final previous = sorted.lastWhere(
      (date) => !date.isAfter(today),
      orElse: () => sorted.first,
    );
    final next = sorted.firstWhere(
      (date) => date.isAfter(today),
      orElse: () => previous.add(const Duration(days: 30)),
    );
    return CycleBounds(
      start: previous,
      end: next.subtract(const Duration(days: 1)),
    );
  }

  static DateTime _clampedDay(int year, int month, int configuredDay) {
    final lastDay = DateTime(year, month + 1, 0).day;
    final day = configuredDay <= 0 ? lastDay : configuredDay.clamp(1, lastDay);
    return DateTime(year, month, day);
  }
}

DateTime dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);
