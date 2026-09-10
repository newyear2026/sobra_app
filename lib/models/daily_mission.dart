/// The three habits today's board asks for.
///
/// These are actions, not outcomes: recording a movement, dating it the day
/// it happened, and opening the budget. Result rewards (a green cycle, a day
/// under the limit) already have their own XP at settlement, so they stay off
/// this list.
enum DailyMissionKind {
  recordMovement(xp: 10, sourcePrefix: 'mission-record'),
  sameDay(xp: 5, sourcePrefix: 'mission-same-day'),
  reviewBudget(xp: 5, sourcePrefix: 'mission-budget');

  const DailyMissionKind({required this.xp, required this.sourcePrefix});

  final int xp;
  final String sourcePrefix;

  /// Idempotency key for [dateKey], the same `yyyy-mm-dd` the store uses
  /// for cycle keys. A second completion on that calendar day is a no-op.
  String sourceKey(String dateKey) => '$sourcePrefix:$dateKey';
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
