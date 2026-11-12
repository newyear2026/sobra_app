import 'expense_entry.dart';
import 'pay_schedule.dart';

/// The step between two occurrences of a [RecurringExpense].
enum RecurrenceUnit {
  week,

  /// Half a month: the quincena rhythm, landing twice in every month.
  semiMonth,
  month,
}

/// The four frequencies the add form offers.
///
/// The model underneath is a unit and an interval, so a frequency that is not
/// here yet (every two weeks, once a year) needs a new entry in this list and
/// nothing else: no new field, no change to what is saved.
enum FixedFrequency {
  weekly(RecurrenceUnit.week, 1),
  semiMonthly(RecurrenceUnit.semiMonth, 1),
  monthly(RecurrenceUnit.month, 1),
  bimonthly(RecurrenceUnit.month, 2);

  const FixedFrequency(this.unit, this.interval);

  final RecurrenceUnit unit;
  final int interval;

  /// The reminder a new fixed expense starts with.
  ///
  /// None for weekly ones: a water jug that buzzes every Friday is the fastest
  /// way to get every Sobra notification switched off.
  FixedReminder get defaultReminder =>
      this == weekly ? FixedReminder.none : FixedReminder.dayBefore;
}

/// How long before an occurrence the user asked to be reminded.
enum FixedReminder { none, sameDay, dayBefore, threeDaysBefore }

/// A bill paid on a schedule: rent, a phone plan, the CFE bill.
///
/// Kept apart from the budget on purpose. The budget is the money the user has
/// to spend once these are paid, so paying one must not move "Hoy te queda",
/// the cycle's spending, or whether the cycle closes green. What Sobra does
/// with a fixed expense is remember it, say when it is due, and file the
/// payment when the user reports it — see [ExpenseEntry.recurringId].
class RecurringExpense {
  const RecurringExpense({
    required this.id,
    required this.name,
    required this.amountCentavos,
    required this.category,
    required this.paymentMethod,
    required this.unit,
    required this.anchorDate,
    this.interval = 1,
    this.isVariable = false,
    this.reminder = FixedReminder.dayBefore,
  });

  final String id;
  final String name;

  /// What one occurrence costs — for a [isVariable] bill, what the next one
  /// is expected to cost. Paying a variable bill moves this to what was paid,
  /// so the estimate follows the season instead of staying at a guess.
  final int amountCentavos;
  final ExpenseCategory category;

  /// How the user usually pays it. The payment sheet starts here and the user
  /// can still change it for one payment.
  final PaymentMethod paymentMethod;
  final RecurrenceUnit unit;
  final int interval;

  /// The first due date, which every later one is counted from.
  ///
  /// Stored instead of "the next due date" because a due date that has been
  /// pulled back to the end of a short month cannot say where it came from:
  /// rent due on the 31st reads the 28th in February, and walking forward
  /// from the 28th would keep it on the 28th for good. Counting each
  /// occurrence from the anchor puts March back on the 31st.
  final DateTime anchorDate;
  final bool isVariable;
  final FixedReminder reminder;

  /// The preset this schedule matches, or null for one the form cannot show.
  FixedFrequency? get frequency {
    for (final value in FixedFrequency.values) {
      if (value.unit == unit && value.interval == interval) return value;
    }
    return null;
  }

  /// The [index]th due date, counting the anchor as zero.
  ///
  /// A day the month does not have becomes that month's last day, for that
  /// month only. Half-month schedules pair a day with the one fifteen days
  /// later, and a second-half day of the 30th or later always means the last
  /// day of the month — the quincena that falls on the 30th in September falls
  /// on the 31st in October and the 28th in February.
  DateTime occurrence(int index) {
    if (index < 0) throw RangeError.value(index, 'index');
    final anchor = dateOnly(anchorDate);
    final steps = index * interval;
    switch (unit) {
      case RecurrenceUnit.week:
        return DateTime(anchor.year, anchor.month, anchor.day + 7 * steps);
      case RecurrenceUnit.month:
        return _clampedDay(anchor.year, anchor.month + steps, anchor.day);
      case RecurrenceUnit.semiMonth:
        final anchorInFirstHalf = anchor.day <= 15;
        final firstDay = anchorInFirstHalf ? anchor.day : anchor.day - 15;
        final secondDay = firstDay + 15;
        final half = (anchorInFirstHalf ? 0 : 1) + steps;
        final month = anchor.month + half ~/ 2;
        if (half.isEven) return _clampedDay(anchor.year, month, firstDay);
        return secondDay >= 30
            ? _clampedDay(anchor.year, month, 31)
            : _clampedDay(anchor.year, month, secondDay);
    }
  }

  /// Every due date from [from] to [to], both included.
  ///
  /// Nothing comes before [anchorDate]: the bill did not exist in Sobra then,
  /// and inventing earlier occurrences would report them as unpaid.
  Iterable<DateTime> occurrencesBetween(DateTime from, DateTime to) sync* {
    final end = dateOnly(to);
    var index = _firstIndexOnOrAfter(dateOnly(from));
    // Far more than any real range needs, and a stop for a damaged date.
    for (var guard = 0; guard < 5000; guard++) {
      final date = occurrence(index);
      if (date.isAfter(end)) return;
      yield date;
      index++;
    }
  }

  /// The latest due date on or before [day], or null before the anchor.
  DateTime? lastOccurrenceOnOrBefore(DateTime day) {
    final target = dateOnly(day);
    final index = _firstIndexOnOrAfter(target);
    final candidate = occurrence(index);
    if (candidate == target) return candidate;
    return index == 0 ? null : occurrence(index - 1);
  }

  /// The earliest due date on or after [day].
  DateTime nextOccurrenceOnOrAfter(DateTime day) =>
      occurrence(_firstIndexOnOrAfter(dateOnly(day)));

  /// Whether [day] is one of this schedule's due dates.
  bool isOccurrence(DateTime day) =>
      nextOccurrenceOnOrAfter(day) == dateOnly(day);

  int _firstIndexOnOrAfter(DateTime day) {
    final anchor = dateOnly(anchorDate);
    if (!day.isAfter(anchor)) return 0;
    // Start from a guess that cannot overshoot — each step is at most this
    // long — and walk forward the few steps that are left.
    final longestStep = switch (unit) {
      RecurrenceUnit.week => 7,
      RecurrenceUnit.semiMonth => 16,
      RecurrenceUnit.month => 31,
    };
    var index = day.difference(anchor).inDays ~/ (longestStep * interval);
    while (occurrence(index).isBefore(day)) {
      index++;
    }
    return index;
  }

  RecurringExpense copyWith({
    String? name,
    int? amountCentavos,
    ExpenseCategory? category,
    PaymentMethod? paymentMethod,
    RecurrenceUnit? unit,
    int? interval,
    DateTime? anchorDate,
    bool? isVariable,
    FixedReminder? reminder,
  }) => RecurringExpense(
    id: id,
    name: name ?? this.name,
    amountCentavos: amountCentavos ?? this.amountCentavos,
    category: category ?? this.category,
    paymentMethod: paymentMethod ?? this.paymentMethod,
    unit: unit ?? this.unit,
    interval: interval ?? this.interval,
    anchorDate: anchorDate ?? this.anchorDate,
    isVariable: isVariable ?? this.isVariable,
    reminder: reminder ?? this.reminder,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'amountCentavos': amountCentavos,
    'category': category.name,
    'paymentMethod': paymentMethod.name,
    'unit': unit.name,
    'interval': interval,
    'anchorDate': dateOnly(anchorDate).toIso8601String(),
    'isVariable': isVariable,
    'reminder': reminder.name,
  };

  factory RecurringExpense.fromJson(Map<String, dynamic> json) =>
      RecurringExpense(
        id: json['id'] as String,
        name: json['name'] as String,
        amountCentavos: (json['amountCentavos'] as num).toInt(),
        category: ExpenseCategory.values.byName(json['category'] as String),
        paymentMethod: PaymentMethod.values.byName(
          json['paymentMethod'] as String,
        ),
        unit: RecurrenceUnit.values.byName(json['unit'] as String),
        interval: (json['interval'] as num?)?.toInt() ?? 1,
        anchorDate: DateTime.parse(json['anchorDate'] as String),
        isVariable: json['isVariable'] as bool? ?? false,
        reminder:
            FixedReminder.values.asNameMap()[json['reminder']] ??
            FixedReminder.dayBefore,
      );

  static DateTime _clampedDay(int year, int month, int day) {
    final lastDay = DateTime(year, month + 1, 0).day;
    return DateTime(year, month, day > lastDay ? lastDay : day);
  }
}

/// Where one occurrence of a fixed expense stands, seen from a given day.
enum FixedOccurrenceStatus { upcoming, dueTomorrow, dueToday, overdue, paid }

/// One due date of a [RecurringExpense], and the payment filed for it if any.
class FixedOccurrence {
  const FixedOccurrence({
    required this.expense,
    required this.date,
    required this.status,
    this.payment,
  });

  final RecurringExpense expense;
  final DateTime date;
  final FixedOccurrenceStatus status;
  final ExpenseEntry? payment;

  bool get isPaid => payment != null;

  /// What was paid, or — until it is — what the bill is expected to cost.
  int get amountCentavos => payment?.amountCentavos ?? expense.amountCentavos;

  static FixedOccurrenceStatus statusFor({
    required DateTime date,
    required DateTime today,
    required bool paid,
  }) {
    if (paid) return FixedOccurrenceStatus.paid;
    final day = dateOnly(date);
    final now = dateOnly(today);
    if (day.isBefore(now)) return FixedOccurrenceStatus.overdue;
    if (day == now) return FixedOccurrenceStatus.dueToday;
    if (day == DateTime(now.year, now.month, now.day + 1)) {
      return FixedOccurrenceStatus.dueTomorrow;
    }
    return FixedOccurrenceStatus.upcoming;
  }
}
