/// Which part of today's board a mission can fill.
///
/// The anchor is on every board; the other two slots each draw one mission
/// from their own pool, so the day's XP stays within a narrow band however
/// the rotation lands.
enum DailyMissionSlot { anchor, light, effort }

/// The habits today's board can ask for.
///
/// These are actions, not outcomes: recording a movement, dating it the day
/// it happened, opening the budget, and the small extras that make a record
/// more useful later. Result rewards (a green cycle, a day under the limit)
/// already have their own XP at settlement, so they stay off this list, and
/// so do cash counts, which have their own weekly XP.
///
/// XP follows effort: a tap is 5, a real record is 10, and anything that asks
/// for a second step (a photo, a third record) is 15.
///
/// Declaration order is the rotation order within each pool; reordering these
/// reshuffles every future board.
enum DailyMissionKind {
  recordMovement(
    xp: 10,
    slot: DailyMissionSlot.anchor,
    sourcePrefix: 'mission-record',
  ),
  sameDay(
    xp: 5,
    slot: DailyMissionSlot.light,
    sourcePrefix: 'mission-same-day',
  ),
  reviewBudget(
    xp: 5,
    slot: DailyMissionSlot.light,
    sourcePrefix: 'mission-budget',
  ),
  addNote(xp: 10, slot: DailyMissionSlot.effort, sourcePrefix: 'mission-note'),
  attachReceipt(
    xp: 15,
    slot: DailyMissionSlot.effort,
    sourcePrefix: 'mission-receipt',
  ),
  threeToday(
    xp: 15,
    slot: DailyMissionSlot.effort,
    sourcePrefix: 'mission-three-today',
  );

  const DailyMissionKind({
    required this.xp,
    required this.slot,
    required this.sourcePrefix,
  });

  final int xp;
  final DailyMissionSlot slot;
  final String sourcePrefix;

  /// How many movements dated today [threeToday] asks for.
  static const threeTodayTarget = 3;

  /// Idempotency key for [dateKey], the same `yyyy-mm-dd` the store uses
  /// for cycle keys. A second completion on that calendar day is a no-op.
  String sourceKey(String dateKey) => '$sourcePrefix:$dateKey';

  /// The board for [day]: the anchor, then one light and one effort mission.
  ///
  /// Derived from the date alone, so a restart or a state change never
  /// reshuffles a board mid-day, and nothing extra has to be saved. The two
  /// pool sizes are coprime, so both slots change every day and every pairing
  /// comes round before any repeats.
  static List<DailyMissionKind> forDay(DateTime day) {
    // UTC dates, so a daylight-saving change cannot skip or repeat a day.
    final dayNumber = DateTime.utc(
      day.year,
      day.month,
      day.day,
    ).difference(DateTime.utc(1970)).inDays;
    List<DailyMissionKind> pool(DailyMissionSlot slot) =>
        values.where((kind) => kind.slot == slot).toList();
    final light = pool(DailyMissionSlot.light);
    final effort = pool(DailyMissionSlot.effort);
    return [
      ...pool(DailyMissionSlot.anchor),
      light[dayNumber % light.length],
      effort[dayNumber % effort.length],
    ];
  }
}

class DailyMission {
  const DailyMission({required this.kind, this.completedAt});

  final DailyMissionKind kind;
  final DateTime? completedAt;

  bool get isDone => completedAt != null;
  int get xp => kind.xp;
}

/// Today's three missions, derived from XP rows rather than a second table.
class DailyMissionBoard {
  const DailyMissionBoard({required this.missions});

  final List<DailyMission> missions;

  int get completedCount => missions.where((mission) => mission.isDone).length;
  int get totalCount => missions.length;
  int get earnedXp => missions
      .where((mission) => mission.isDone)
      .fold(0, (sum, mission) => sum + mission.xp);
  int get possibleXp => missions.fold(0, (sum, mission) => sum + mission.xp);
  bool get allDone => completedCount == totalCount && totalCount > 0;
}
