import 'pay_schedule.dart';

enum XpEventKind {
  cashCount,
  cycleInGreen,
  daysUnderDailyLimit,
  firstSuccessfulCycle,
  dailyMissionRecord,
  dailyMissionSameDay,
  dailyMissionBudget,
}

class XpEvent {
  const XpEvent({
    required this.id,
    required this.kind,
    required this.xp,
    required this.occurredAt,
    required this.sourceKey,
    this.cycleType,
    this.cycleStart,
    this.cycleEnd,
    this.quantity,
    this.budgetCentavos,
    this.spentCentavos,
  });

  final String id;
  final XpEventKind kind;
  final int xp;
  final DateTime occurredAt;

  /// A deterministic business key, independent from the generated row id.
  ///
  /// This is the idempotency boundary: a weekly cash count or a cycle reward
  /// can be evaluated repeatedly, but only one event with this key can exist.
  final String sourceKey;
  final PayCycleType? cycleType;
  final DateTime? cycleStart;
  final DateTime? cycleEnd;
  final int? quantity;
  final int? budgetCentavos;
  final int? spentCentavos;

  bool get hasCalculation => cycleStart != null && cycleEnd != null;

  Map<String, Object?> toJson() => {
    'id': id,
    'kind': kind.name,
    'xp': xp,
    'occurredAt': occurredAt.toIso8601String(),
    'sourceKey': sourceKey,
    'cycleType': cycleType?.name,
    'cycleStart': cycleStart?.toIso8601String(),
    'cycleEnd': cycleEnd?.toIso8601String(),
    'quantity': quantity,
    'budgetCentavos': budgetCentavos,
    'spentCentavos': spentCentavos,
  };

  factory XpEvent.fromJson(Map<String, dynamic> json) => XpEvent(
    id: json['id'] as String,
    kind: XpEventKind.values.byName(json['kind'] as String),
    xp: (json['xp'] as num).toInt(),
    occurredAt: DateTime.parse(json['occurredAt'] as String),
    sourceKey: json['sourceKey'] as String,
    cycleType: json['cycleType'] == null
        ? null
        : PayCycleType.values.byName(json['cycleType'] as String),
    cycleStart: json['cycleStart'] == null
        ? null
        : DateTime.parse(json['cycleStart'] as String),
    cycleEnd: json['cycleEnd'] == null
        ? null
        : DateTime.parse(json['cycleEnd'] as String),
    quantity: (json['quantity'] as num?)?.toInt(),
    budgetCentavos: (json['budgetCentavos'] as num?)?.toInt(),
    spentCentavos: (json['spentCentavos'] as num?)?.toInt(),
  );
}

/// Something worth telling the user about, once, the next time a screen can.
///
/// This holds why XP arrived and how much, not the sentence announcing it. The
/// notice is produced when a cycle settles and read on a later frame, possibly
/// after the locale has changed, so the wording is built at the moment it is
/// shown rather than at the moment it is earned. See `l10n/labels.dart`.
enum XpNoticeKind { cyclesClosed, cashCountSaved, missionCompleted }

class XpNotice {
  const XpNotice({
    required this.kind,
    required this.xp,
    this.closedCycles = 0,
    this.missionCount = 0,
    this.newLevel,
  });

  final XpNoticeKind kind;
  final int xp;

  /// How many cycles the settlement closed. Only meaningful for
  /// [XpNoticeKind.cyclesClosed], where it decides singular from plural.
  final int closedCycles;

  /// How many daily missions this award completed at once.
  ///
  /// Recording today's movement can finish two missions in one write.
  /// Only meaningful for [XpNoticeKind.missionCompleted].
  final int missionCount;

  /// The level this award reached, when it crossed a level boundary.
  ///
  /// Null for the everyday case where XP arrived but the level stayed put.
  /// Level-ups are rare enough that the shell celebrates them with a card
  /// instead of the usual quiet toast.
  final int? newLevel;
}

class XpProgress {
  const XpProgress({
    required this.level,
    required this.totalXp,
    required this.levelStartXp,
    required this.nextLevelXp,
  });

  static const _levelStarts = [0, 150, 450, 850, 1550];

  /// How many levels exist, so the view knows the range it has to name.
  static const levelCount = 5;

  factory XpProgress.fromTotal(int totalXp) {
    final safeTotal = totalXp < 0 ? 0 : totalXp;
    var index = 0;
    for (var candidate = 1; candidate < _levelStarts.length; candidate++) {
      if (safeTotal < _levelStarts[candidate]) break;
      index = candidate;
    }
    return XpProgress(
      level: index + 1,
      totalXp: safeTotal,
      levelStartXp: _levelStarts[index],
      nextLevelXp: index == _levelStarts.length - 1
          ? null
          : _levelStarts[index + 1],
    );
  }

  final int level;
  final int totalXp;
  final int levelStartXp;
  final int? nextLevelXp;

  bool get isMaxLevel => nextLevelXp == null;
  int get currentLevelXp => totalXp - levelStartXp;
  int get targetLevelXp => isMaxLevel
      ? (currentLevelXp == 0 ? 1 : currentLevelXp)
      : nextLevelXp! - levelStartXp;
  int get remainingXp => isMaxLevel ? 0 : nextLevelXp! - totalXp;
}
