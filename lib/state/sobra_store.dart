import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/catalog_preview_data.dart';
import '../models/cash_reconciliation.dart';
import '../models/catalog_entry.dart';
import '../models/currency.dart';
import '../models/cycle_record.dart';
import '../models/daily_mission.dart';
import '../models/expense_entry.dart';
import '../models/language.dart';
import '../models/income_entry.dart';
import '../models/money_movement.dart';
import '../models/pay_schedule.dart';
import '../models/room_design.dart';
import '../models/store_failure.dart';
import '../models/xp_event.dart';

typedef NowProvider = DateTime Function();

/// Why a rewarded-ad entry cannot take another view right now.
enum RewardedAdAvailability {
  /// A view would count, if the network has an ad to show.
  available,

  /// Nothing left to earn.
  alreadyOwned,

  /// A once-per-day entry already took its view today.
  alreadyEarnedToday,

  /// The daily limit across every entry is used up.
  ///
  /// Unreachable while [SobraStore.rewardedAdsPerDay] is null, which is how
  /// this build ships. Kept so that setting a number is all it takes to bring
  /// the limit back.
  dailyCapReached,
}

/// The local calendar date of [value], as `YYYY-MM-DD`.
///
/// Local rather than UTC, and deliberately not corrected for a device whose
/// clock or time zone moves. Daily limits reset on the day the user is living
/// in, and defending against a changed clock would cost more than it saves:
/// moving it forward does not reduce the ads actually watched, and what the
/// ads unlock has no cash value.
String dayKey(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}'
    '-${value.month.toString().padLeft(2, '0')}'
    '-${value.day.toString().padLeft(2, '0')}';

class SobraStore extends ChangeNotifier {
  SobraStore._(this._preferences, this._now, this.rewardedAdsPerDay);

  /// The schedule every path falls back to: paid on the 15th and on the last
  /// day of the month, the ordinary Mexican quincena.
  ///
  /// Read this rather than writing `PaySchedule.semiMonthly()` inline. The
  /// new-user path and the legacy-restore path used to name different days,
  /// so restoring a file saved before schedules were stored put the user on a
  /// cycle the settings screen cannot even display, let alone edit.
  static const _defaultPaySchedule = PaySchedule.semiMonthly();

  static const _storageKey = 'sobra_state_v2';
  static const _backupKey = 'sobra_state_backup_v2';
  static const _corruptArchiveKey = 'sobra_state_corrupt_v2';

  final SharedPreferences _preferences;
  final NowProvider _now;
  final List<ExpenseEntry> _transactions = [];
  final List<IncomeEntry> _incomes = [];
  final List<CashReconciliationEntry> _cashReconciliations = [];
  final List<XpEvent> _xpEvents = [];
  final Map<String, int> _cycleBudgetExtras = {};
  final List<CycleRecord> _cycleRecords = [];

  /// Catalog entries the user actually acquired — a real-money purchase, or a
  /// rewarded-ad run they finished.
  ///
  /// Level rewards are deliberately absent. [CatalogPreviewData.isUnlockedAtLevel]
  /// derives those from XP every time it is asked, and writing them here too
  /// would create a second answer that can disagree with the first: an entry
  /// whose required level later moves would stay owned at the old threshold.
  final Set<String> _ownedCatalogIds = {};

  /// Rewarded ads watched so far toward each entry, for runs still in progress.
  ///
  /// An entry drops out of this map the moment it is granted. Progress only
  /// means anything while it is short of the target, and keeping a finished
  /// count would grow the saved state for something nothing reads.
  final Map<String, int> _rewardedAdProgress = {};

  /// The local day [_rewardedAdsWatchedOnDay] counts for, as `YYYY-MM-DD`.
  ///
  /// Stored rather than derived so the count survives a restart, and compared
  /// against today on every read so a day that rolled over while the app was
  /// closed resets the count without anything having to run at midnight.
  String? _rewardedAdDay;
  int _rewardedAdsWatchedOnDay = 0;

  /// The local day each once-per-day entry last took a view.
  ///
  /// Only entries with [CatalogEntry.rewardedAdOncePerDay] are ever written
  /// here; for everything else the daily cap is the only limit and a date
  /// would be state nothing reads.
  final Map<String, String> _rewardedAdLastEarnedDate = {};

  /// Native ads begin only after a quiet install/update grace period. Existing
  /// saved states receive this field on their first launch with ads, so they
  /// get the same grace as a new install rather than seeing an ad immediately.
  String? _nativeAdInstallDay;

  /// The local day [_nativeAdImpressionsOnDay] belongs to.
  String? _nativeAdDay;
  int _nativeAdImpressionsOnDay = 0;
  int _idSequence = 0;

  int _baseBudgetCentavos = 600000;

  /// Whether the user has actually chosen a budget.
  ///
  /// [_baseBudgetCentavos] always holds a number, so it cannot say "not
  /// answered" on its own: zero would read as a budget of nothing that the
  /// first expense instantly overruns, which is the opposite of what an
  /// unanswered question means. This is the budget's [hasCashBaseline].
  bool _hasBudget = true;

  /// Which character pack the app draws.
  ///
  /// Stored as a plain id rather than validated here: this layer has no
  /// opinion about what art exists, and a pack that a later build no longer
  /// ships must not stop the file from opening. The sprite resolves it.
  String characterId = 'michi';

  /// The room item the user is showing, or null while the room is bare.
  ///
  /// Characters already had [characterId]; items had nowhere to live, so the
  /// collection screen held the choice in its own State and lost it on every
  /// rebuild of the route.
  String? equippedItemId;

  /// The visible room theme and the replaceable layers stored for each room.
  ///
  /// Placements are keyed by room so changing themes never destroys a room
  /// the user already arranged. A missing slot falls back to that theme's
  /// included decoration (the Casa clara rug and tabletop plant today).
  String equippedRoomId = RoomThemes.casaClaraId;
  final Map<String, Map<RoomSlot, String>> _roomPlacementsByRoom = {};

  int countedCashCentavos = 0;
  int expectedCashCentavos = 0;
  bool reducedMotion = false;

  /// The weekday a cash-count week turns over.
  ///
  /// The weekly cash-count XP can be earned once per week, and this is where
  /// that week starts. Until it was a setting the screen said Sunday while
  /// the code counted Monday-to-Sunday, so the two disagreed by a day.
  int cashCountWeekday = DateTime.sunday;

  /// What Sobra labels money in. Changing it relabels; it never converts.
  Currency currency = Currency.mxn;

  /// The language the user picked, or null to follow the phone.
  ///
  /// Stored as a bare language code rather than a full locale: Sobra's Spanish
  /// is written for Mexico but a reader in the United States should still get
  /// it, and the region only decides formatting the app does not delegate.
  String? languageCode;
  bool hasCompletedOnboarding = false;

  /// Whether the user has answered the one-time offer to connect an account.
  ///
  /// True once they have chosen either way, which is the whole point: the
  /// offer used to live in a widget's State, so "start without an account"
  /// lasted until the process died and every cold start asked again. Somebody
  /// who declined is entitled to have that remembered.
  ///
  /// Not the same as being signed in. Nothing here says an account exists —
  /// only that Sobra has stopped asking on its own. Ajustes is where it can
  /// be picked up later.
  bool hasAnsweredLoginOffer = false;
  bool categoryLimitsCustomized = false;
  int successfulCycles = 0;
  DateTime? lastCashCountAt;
  PaySchedule paySchedule = _defaultPaySchedule;
  PaySchedule? pendingPaySchedule;
  DateTime? pendingPayScheduleEffectiveAt;
  DateTime? payScheduleEffectiveFloor;
  DateTime? xpTrackingStartedAt;
  DateTime? lastSettledCycleEnd;
  bool hasStorageError = false;
  String? corruptedStorage;
  DateTime? _lastObservedDate;
  XpNotice? _pendingXpNotice;

  Map<ExpenseCategory, int> categoryLimits = _categoryLimitsForBudget(600000);

  static Future<SobraStore> load({
    NowProvider? now,
    int? rewardedAdsPerDay,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    final store = SobraStore._(
      preferences,
      now ?? DateTime.now,
      rewardedAdsPerDay,
    );
    final saved = preferences.getString(_storageKey);
    if (saved == null) {
      store._initializeNewUser();
      await store._save();
    } else if (!store._tryRestore(saved)) {
      store
        .._initializeNewUser()
        ..hasStorageError = true
        ..corruptedStorage = saved;
    }
    // One-time migration for states written before native ads existed. Saving
    // now matters: if the missing value were only filled in memory, every
    // restart would begin a fresh seven-day grace period forever.
    await store._ensureNativeAdInstallDay();
    await store.settleCycles();
    store._lastObservedDate = store.today;
    return store;
  }

  DateTime get currentMoment => _now();
  DateTime get today => dateOnly(_now());

  /// The cycle [date] falls into, with the pay-schedule change floor applied.
  ///
  /// Everything that keys anything by cycle must go through here rather than
  /// calling [PaySchedule.boundsFor] directly. A schedule change clamps the
  /// first cycle's start to the day it took effect, so the raw bounds and the
  /// real bounds disagree for exactly that window — and anything written under
  /// one key and read under the other silently disappears.
  CycleBounds boundsFor(DateTime date) {
    final day = dateOnly(date);
    final bounds = paySchedule.boundsFor(day);
    final floor = payScheduleEffectiveFloor;
    if (floor != null && !day.isBefore(floor) && bounds.start.isBefore(floor)) {
      return CycleBounds(start: floor, end: bounds.end);
    }
    return bounds;
  }

  CycleBounds get cycleBounds => boundsFor(today);

  DateTime get cycleStart => cycleBounds.start;
  DateTime get cycleEnd => cycleBounds.end;
  bool get hasCashBaseline => lastCashCountAt != null;

  /// Whether a budget has been set, and so whether the figures derived from
  /// it mean anything.
  ///
  /// Every budget-derived getter reads zero while this is false. Zero is a
  /// placeholder there, not a measurement: ask this before presenting any of
  /// them, the way the cash figures are gated on [hasCashBaseline].
  bool get hasBudget => _hasBudget;

  int get baseBudgetCentavos => _baseBudgetCentavos;
  int get cycleBudgetExtrasCentavos =>
      _cycleBudgetExtras[_cycleKey(cycleStart)] ?? 0;
  int get totalBudgetCentavos =>
      _baseBudgetCentavos + cycleBudgetExtrasCentavos;

  int get daysRemaining {
    if (today.isAfter(cycleEnd)) return 0;
    if (today.isBefore(cycleStart)) return cycleBounds.lengthInDays;
    return cycleEnd.difference(today).inDays + 1;
  }

  int get elapsedDays {
    if (today.isBefore(cycleStart)) return 0;
    if (today.isAfter(cycleEnd)) return cycleBounds.lengthInDays;
    return today.difference(cycleStart).inDays + 1;
  }

  List<ExpenseEntry> get transactions {
    final sorted = List<ExpenseEntry>.of(_transactions)
      ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    return List.unmodifiable(sorted);
  }

  List<IncomeEntry> get incomes {
    final sorted = List<IncomeEntry>.of(_incomes)
      ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    return List.unmodifiable(sorted);
  }

  List<CashReconciliationEntry> get cashReconciliations =>
      List.unmodifiable(_cashReconciliations);

  List<XpEvent> get xpEvents {
    final sorted = List<XpEvent>.of(_xpEvents)
      ..sort((a, b) {
        final byDate = b.occurredAt.compareTo(a.occurredAt);
        return byDate != 0 ? byDate : b.id.compareTo(a.id);
      });
    return List.unmodifiable(sorted);
  }

  int get totalXp => _xpEvents.fold(0, (sum, event) => sum + event.xp);
  XpProgress get xpProgress => XpProgress.fromTotal(totalXp);
  XpNotice? get pendingXpNotice => _pendingXpNotice;

  /// Today's three missions, read from XP rows keyed on [today].
  DailyMissionBoard get dailyMissions {
    final dateKey = _cycleKey(today);
    return DailyMissionBoard(
      missions: [
        for (final kind in DailyMissionKind.values)
          DailyMission(
            kind: kind,
            completedAt: _xpEventForSource(kind.sourceKey(dateKey))?.occurredAt,
          ),
      ],
    );
  }

  XpNotice? takePendingXpNotice() {
    final notice = _pendingXpNotice;
    _pendingXpNotice = null;
    return notice;
  }

  List<MoneyMovement> get movements {
    final result = <MoneyMovement>[
      for (final entry in _transactions)
        MoneyMovement(
          id: entry.id,
          amountCentavos: -entry.amountCentavos,
          occurredAt: entry.occurredAt,
          type: MovementType.expense,
          expense: entry,
          isPending: entry.isPendingCashAdjustment,
        ),
      for (final entry in _incomes)
        MoneyMovement(
          id: entry.id,
          amountCentavos: entry.amountCentavos,
          occurredAt: entry.occurredAt,
          type: MovementType.income,
          income: entry,
        ),
      for (final entry in _cashReconciliations)
        if (entry.linkedExpenseId == null && entry.linkedIncomeId == null)
          MoneyMovement(
            id: entry.id,
            amountCentavos: entry.differenceCentavos,
            occurredAt: entry.occurredAt,
            type: MovementType.adjustment,
            reconciliation: entry,
            isPending: entry.resolution == CashResolution.pending,
          ),
    ]..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    return List.unmodifiable(result);
  }

  /// Closed cycles, most recent first.
  List<CycleRecord> get cycleRecords =>
      List.unmodifiable(_cycleRecords.reversed);

  List<ExpenseEntry> get cycleTransactions => _transactions
      .where((entry) => cycleBounds.contains(entry.occurredAt))
      .toList();
  List<IncomeEntry> get cycleIncomes => _incomes
      .where((entry) => cycleBounds.contains(entry.occurredAt))
      .toList();

  ExpenseEntry? get latestPendingCashExpense {
    final pending =
        _transactions.where((entry) => entry.isPendingCashAdjustment).toList()
          ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    return pending.isEmpty ? null : pending.first;
  }

  int get totalSpentCentavos =>
      cycleTransactions.fold(0, (total, entry) => total + entry.amountCentavos);
  /// Days of the current cycle lived so far, today included.
  ///
  /// Counts from the cycle's start rather than from the first thing recorded,
  /// so a quiet opening week lowers the average instead of vanishing from it.
  int get cycleElapsedDays => today.difference(cycleStart).inDays + 1;

  /// What the current cycle is spending per day, or null while it is too early
  /// for that to mean anything.
  int? get cycleAveragePerDayCentavos =>
      averagePerDayCentavos(totalSpentCentavos, cycleElapsedDays);

  int get spentTodayCentavos => cycleTransactions
      .where((entry) => _isSameDay(entry.occurredAt, today))
      .fold(0, (total, entry) => total + entry.amountCentavos);
  int get spentBeforeTodayCentavos => totalSpentCentavos - spentTodayCentavos;
  int get remainingBudgetCentavos =>
      _hasBudget ? totalBudgetCentavos - totalSpentCentavos : 0;

  int get dailyAllowanceCentavos {
    if (!_hasBudget) return 0;
    final availableAtStartOfDay =
        totalBudgetCentavos - spentBeforeTodayCentavos;
    return daysRemaining <= 0 ? 0 : availableAtStartOfDay ~/ daysRemaining;
  }

  /// What is still spendable today, expressed so it never overstates the hole.
  ///
  /// The allowance is a per-day slice while an expense is a cycle-level
  /// amount, so their raw difference mixes units: one 8,000 day against a
  /// 750 allowance reads as −7,250 even though the cycle is only 2,000 over,
  /// and it would heal to −285 by itself tomorrow once the overspend is
  /// spread across the days that are left. Neither number describes anything
  /// the user can act on, so the day stops at zero and an over-budget cycle
  /// reports its own deficit instead — a quantity that only moves when money
  /// actually moves.
  int get todayRemainingCentavos {
    if (!_hasBudget) return 0;
    if (remainingBudgetCentavos < 0) return remainingBudgetCentavos;
    final remaining = dailyAllowanceCentavos - spentTodayCentavos;
    return remaining < 0 ? 0 : remaining;
  }

  double get budgetProgress => !_hasBudget || totalBudgetCentavos == 0
      ? 0
      : totalSpentCentavos / totalBudgetCentavos;

  int get projectedRemainderCentavos {
    if (!_hasBudget) return 0;
    if (elapsedDays <= 0) return remainingBudgetCentavos;
    final average = totalSpentCentavos / elapsedDays;
    final futureDays = daysRemaining > 0 ? daysRemaining - 1 : 0;
    return remainingBudgetCentavos - (average * futureDays).round();
  }

  int spentFor(ExpenseCategory category) => cycleTransactions
      .where((entry) => entry.category == category)
      .fold(0, (total, entry) => total + entry.amountCentavos);

  Future<void> refreshForCurrentDate() async {
    await settleCycles();
    final currentDate = today;
    if (_lastObservedDate == currentDate) return;
    _lastObservedDate = currentDate;
    notifyListeners();
  }

  /// Closes every elapsed budget cycle exactly once.
  ///
  /// A pending pay-schedule change splits the run in two: old cycles are
  /// settled up to its effective date, then the new schedule is applied and
  /// any later cycles are evaluated with the new boundaries.
  Future<void> settleCycles() async {
    final trackingStarted = _startXpTrackingIfNeeded();
    final levelBefore = xpProgress.level;
    var run = const _SettlementRun();
    final effectiveAt = pendingPayScheduleEffectiveAt;
    final scheduleIsDue = effectiveAt != null && !today.isBefore(effectiveAt);

    if (scheduleIsDue) {
      run = run + _settleClosedCycles(untilExclusive: effectiveAt);
    }
    final scheduleChanged = await _applyPendingScheduleIfNeeded();
    run = run + _settleClosedCycles(untilExclusive: today);

    if (run.closedCycles > 0 || trackingStarted) {
      await _save();
    }
    if (run.closedCycles > 0) {
      if (run.awardedXp > 0) {
        final levelNow = xpProgress.level;
        _pendingXpNotice = XpNotice(
          kind: XpNoticeKind.cyclesClosed,
          xp: run.awardedXp,
          closedCycles: run.closedCycles,
          newLevel: levelNow > levelBefore ? levelNow : null,
          previousLevel: levelNow > levelBefore ? levelBefore : null,
        );
      }
    }
    if (run.closedCycles > 0 || scheduleChanged || trackingStarted) {
      notifyListeners();
    }
  }

  bool _startXpTrackingIfNeeded() {
    if (!hasCompletedOnboarding || xpTrackingStartedAt != null) return false;
    // Existing installs begin with the day this schema first sees them. A
    // partial cycle can earn daily XP, but not the full-cycle reward.
    xpTrackingStartedAt = today;
    return true;
  }

  _SettlementRun _settleClosedCycles({required DateTime untilExclusive}) {
    final trackingStart = xpTrackingStartedAt;
    if (!hasCompletedOnboarding || trackingStart == null) {
      return const _SettlementRun();
    }

    var cursor =
        lastSettledCycleEnd?.add(const Duration(days: 1)) ??
        dateOnly(trackingStart);
    var closedCycles = 0;
    var awardedXp = 0;

    // More than enough for decades of weekly cycles, while still protecting a
    // damaged date from creating an infinite loop during app startup.
    for (var guard = 0; guard < 5000; guard++) {
      final bounds = boundsFor(cursor);
      if (!bounds.end.isBefore(untilExclusive)) break;
      awardedXp += _settleCycle(bounds, trackingStart);
      lastSettledCycleEnd = bounds.end;
      closedCycles++;
      cursor = bounds.end.add(const Duration(days: 1));
    }
    return _SettlementRun(closedCycles: closedCycles, awardedXp: awardedXp);
  }

  int _settleCycle(CycleBounds bounds, DateTime trackingStart) {
    final cycleKey = _cycleKey(bounds.start);
    final budget = _baseBudgetCentavos + (_cycleBudgetExtras[cycleKey] ?? 0);
    final spent = _transactions
        .where((entry) => bounds.contains(entry.occurredAt))
        .fold(0, (sum, entry) => sum + entry.amountCentavos);
    final fullCycleTracked = !dateOnly(trackingStart).isAfter(bounds.start);
    final successful = budget > 0 && spent <= budget;
    _recordCycle(
      bounds,
      budget: budget,
      spent: spent,
      tracked: fullCycleTracked,
    );
    final occurredAt = DateTime(
      bounds.end.year,
      bounds.end.month,
      bounds.end.day,
      23,
      59,
      59,
    );
    var awarded = 0;

    if (fullCycleTracked && successful) {
      final cycleXp = _normalizedCycleXp(bounds.lengthInDays);
      final cycleAward = _awardXp(
        kind: XpEventKind.cycleInGreen,
        xp: cycleXp,
        occurredAt: occurredAt,
        sourceKey: 'cycle-green:$cycleKey',
        bounds: bounds,
        budgetCentavos: budget,
        spentCentavos: spent,
      );
      awarded += cycleAward;
      if (cycleAward > 0 && successfulCycles == 0) {
        awarded += _awardXp(
          kind: XpEventKind.firstSuccessfulCycle,
          xp: 50,
          occurredAt: occurredAt,
          sourceKey: 'first-cycle-green',
          bounds: bounds,
          budgetCentavos: budget,
          spentCentavos: spent,
        );
      }
      if (cycleAward > 0) successfulCycles++;
    }

    final underLimitDays = _daysUnderDailyLimit(
      bounds: bounds,
      budgetCentavos: budget,
      trackingStart: trackingStart,
    );
    if (underLimitDays > 0) {
      awarded += _awardXp(
        kind: XpEventKind.daysUnderDailyLimit,
        xp: underLimitDays * 5,
        occurredAt: occurredAt,
        sourceKey: 'daily-limit:$cycleKey',
        bounds: bounds,
        quantity: underLimitDays,
        budgetCentavos: budget,
        spentCentavos: spent,
      );
    }
    return awarded;
  }

  int _daysUnderDailyLimit({
    required CycleBounds bounds,
    required int budgetCentavos,
    required DateTime trackingStart,
  }) {
    if (budgetCentavos <= 0) return 0;
    final spentByDay = <String, int>{};
    for (final entry in _transactions) {
      if (!bounds.contains(entry.occurredAt)) continue;
      final key = _cycleKey(entry.occurredAt);
      spentByDay[key] = (spentByDay[key] ?? 0) + entry.amountCentavos;
    }

    var spentBeforeDay = 0;
    var successfulDays = 0;
    final firstTrackedDay = dateOnly(trackingStart);
    for (var offset = 0; offset < bounds.lengthInDays; offset++) {
      final day = bounds.start.add(Duration(days: offset));
      final remainingDays = bounds.lengthInDays - offset;
      final allowance = (budgetCentavos - spentBeforeDay) ~/ remainingDays;
      final spentToday = spentByDay[_cycleKey(day)] ?? 0;
      if (!day.isBefore(firstTrackedDay) && spentToday <= allowance) {
        successfulDays++;
      }
      spentBeforeDay += spentToday;
    }
    return successfulDays;
  }

  int _awardXp({
    required XpEventKind kind,
    required int xp,
    required DateTime occurredAt,
    required String sourceKey,
    CycleBounds? bounds,
    int? quantity,
    int? budgetCentavos,
    int? spentCentavos,
  }) {
    if (xp <= 0 || _xpEvents.any((event) => event.sourceKey == sourceKey)) {
      return 0;
    }
    _xpEvents.add(
      XpEvent(
        id: _newId('xp'),
        kind: kind,
        xp: xp,
        occurredAt: occurredAt,
        sourceKey: sourceKey,
        cycleType: bounds == null ? null : paySchedule.type,
        cycleStart: bounds?.start,
        cycleEnd: bounds?.end,
        quantity: quantity,
        budgetCentavos: budgetCentavos,
        spentCentavos: spentCentavos,
      ),
    );
    return xp;
  }

  /// Files what a cycle came to, once, whatever it came to.
  ///
  /// A cycle the user only tracked part of is left out rather than written
  /// down short: its spend is missing whatever happened before they started,
  /// so the row would read as a good cycle for the wrong reason. Better one
  /// fewer row than one that lies.
  ///
  /// Keyed on the start date so a repeated settlement cannot double-file, the
  /// same way [_awardXp] keys on its source.
  void _recordCycle(
    CycleBounds bounds, {
    required int budget,
    required int spent,
    required bool tracked,
  }) {
    if (!tracked) return;
    if (_cycleRecords.any((record) => record.start == bounds.start)) return;
    _cycleRecords.add(
      CycleRecord(
        start: bounds.start,
        end: bounds.end,
        budgetCentavos: budget,
        spentCentavos: spent,
        cycleType: paySchedule.type,
      ),
    );
  }

  int _normalizedCycleXp(int days) {
    final raw = days * 100 / 15;
    final roundedToFive = (raw / 5).round() * 5;
    return roundedToFive < 5 ? 5 : roundedToFive;
  }

  void _recordCashCountXp(DateTime moment) {
    final trackingStart = xpTrackingStartedAt;
    if (!hasCompletedOnboarding ||
        trackingStart == null ||
        moment.isBefore(trackingStart)) {
      return;
    }
    final day = dateOnly(moment);
    final weekStart = day.subtract(Duration(days: cashCountWeekOffset(day)));
    if (_hasCashCountXpInWeek(weekStart)) return;
    final levelBefore = xpProgress.level;
    final awarded = _awardXp(
      kind: XpEventKind.cashCount,
      xp: 25,
      occurredAt: moment,
      sourceKey: 'cash-count-week:${_cycleKey(weekStart)}',
    );
    if (awarded > 0) {
      final levelNow = xpProgress.level;
      _pendingXpNotice = XpNotice(
        kind: XpNoticeKind.cashCountSaved,
        xp: 25,
        newLevel: levelNow > levelBefore ? levelNow : null,
        previousLevel: levelNow > levelBefore ? levelBefore : null,
      );
    }
  }

  /// Whether a cash-count award already landed in [weekStart, weekStart + 7).
  ///
  /// The source key is the week start under the *current* weekday setting.
  /// Changing that setting re-cuts the week, so a second count of the same
  /// habit would mint a new key. Looking at the dates themselves — not the
  /// keys — is what keeps one real week from paying twice.
  bool _hasCashCountXpInWeek(DateTime weekStart) {
    final weekEnd = weekStart.add(const Duration(days: 7));
    return _xpEvents.any((event) {
      if (event.kind != XpEventKind.cashCount) return false;
      final at = dateOnly(event.occurredAt);
      return !at.isBefore(weekStart) && at.isBefore(weekEnd);
    });
  }

  XpEvent? _xpEventForSource(String sourceKey) {
    for (final event in _xpEvents) {
      if (event.sourceKey == sourceKey) return event;
    }
    return null;
  }

  XpEventKind _xpKindFor(DailyMissionKind kind) => switch (kind) {
    DailyMissionKind.recordMovement => XpEventKind.dailyMissionRecord,
    DailyMissionKind.sameDay => XpEventKind.dailyMissionSameDay,
    DailyMissionKind.reviewBudget => XpEventKind.dailyMissionBudget,
  };

  int _awardDailyMission(DailyMissionKind kind, DateTime moment) {
    if (!hasCompletedOnboarding) return 0;
    return _awardXp(
      kind: _xpKindFor(kind),
      xp: kind.xp,
      occurredAt: moment,
      sourceKey: kind.sourceKey(_cycleKey(today)),
    );
  }

  void _postMissionNotice({
    required int awarded,
    required int missionCount,
    required int levelBefore,
  }) {
    if (awarded <= 0) return;
    final levelNow = xpProgress.level;
    _pendingXpNotice = XpNotice(
      kind: XpNoticeKind.missionCompleted,
      xp: awarded,
      missionCount: missionCount,
      newLevel: levelNow > levelBefore ? levelNow : null,
      previousLevel: levelNow > levelBefore ? levelBefore : null,
    );
  }

  /// Completes the record / same-day missions for a user-typed movement.
  ///
  /// Cash-count rows skip this on purpose: that path already has its own
  /// weekly XP, and stuffing a count through the ledger should not also
  /// clear today's recording habit.
  void _awardDailyMissionsForMovement(DateTime occurredAt) {
    final moment = currentMoment;
    final levelBefore = xpProgress.level;
    var awarded = 0;
    var completed = 0;
    final recordXp = _awardDailyMission(
      DailyMissionKind.recordMovement,
      moment,
    );
    if (recordXp > 0) {
      awarded += recordXp;
      completed++;
    }
    if (_isSameDay(dateOnly(occurredAt), today)) {
      final sameDayXp = _awardDailyMission(DailyMissionKind.sameDay, moment);
      if (sameDayXp > 0) {
        awarded += sameDayXp;
        completed++;
      }
    }
    _postMissionNotice(
      awarded: awarded,
      missionCount: completed,
      levelBefore: levelBefore,
    );
  }

  /// Marks the budget tab as seen for today.
  ///
  /// Called when the user selects the tab, not when IndexedStack first
  /// builds it offstage.
  /// Every receipt photo the ledger still points at.
  ///
  /// The input to `ReceiptStore.sweepOrphans`; anything on disk and not in
  /// here belongs to no expense.
  Iterable<String> get referencedReceipts =>
      _transactions.map((entry) => entry.receiptFileName).whereType<String>();

  Future<void> noteBudgetReviewed() async {
    final moment = currentMoment;
    final levelBefore = xpProgress.level;
    final awarded = _awardDailyMission(DailyMissionKind.reviewBudget, moment);
    if (awarded <= 0) return;
    _postMissionNotice(
      awarded: awarded,
      missionCount: 1,
      levelBefore: levelBefore,
    );
    await _save();
    notifyListeners();
  }

  Future<ExpenseEntry> addExpense({
    required int amountCentavos,
    required ExpenseCategory category,
    required String note,
    required DateTime occurredAt,
    required PaymentMethod paymentMethod,
    String? receiptFileName,
  }) async {
    _validateMovement(amountCentavos, occurredAt);
    final entry = ExpenseEntry(
      id: _newId('expense'),
      amountCentavos: amountCentavos,
      category: category,
      note: note.trim(),
      occurredAt: occurredAt,
      paymentMethod: paymentMethod,
      receiptFileName: receiptFileName,
    );
    _transactions.add(entry);
    if (_affectsCurrentCash(entry)) expectedCashCentavos -= amountCentavos;
    _awardDailyMissionsForMovement(occurredAt);
    await _save();
    notifyListeners();
    return entry;
  }

  Future<IncomeEntry> addIncome({
    required int amountCentavos,
    required IncomeKind kind,
    required String note,
    required DateTime occurredAt,
    required PaymentMethod destination,
    required IncomeAllocation allocation,
  }) async {
    _validateMovement(amountCentavos, occurredAt);
    final entry = IncomeEntry(
      id: _newId('income'),
      amountCentavos: amountCentavos,
      kind: kind,
      note: note.trim(),
      occurredAt: occurredAt,
      destination: destination,
      allocation: allocation,
    );
    _incomes.add(entry);
    _applyIncome(entry, 1);
    _awardDailyMissionsForMovement(occurredAt);
    await _save();
    notifyListeners();
    return entry;
  }

  Future<void> updateExpense(ExpenseEntry updated) async {
    _validateMovement(updated.amountCentavos, updated.occurredAt);
    final index = _transactions.indexWhere((entry) => entry.id == updated.id);
    if (index == -1) return;
    final previous = _transactions[index];

    // An expense that came out of a cash count carries a measured amount and
    // date. Only what the user actually knows — the category and the note —
    // can be rewritten; keeping the rest pinned to the count is what stops the
    // budget and the wallet from drifting apart.
    final next = previous.isLinkedToCashCount
        ? previous.copyWith(
            category: updated.category,
            note: updated.note,
            // A photo is user knowledge, the same kind the category and note
            // carry, so it crosses the pin that holds the measured amount.
            receiptFileName: updated.receiptFileName,
            clearReceipt: updated.receiptFileName == null,
          )
        : updated;

    if (_affectsCurrentCash(previous)) {
      expectedCashCentavos += previous.amountCentavos;
    }
    if (_affectsCurrentCash(next)) expectedCashCentavos -= next.amountCentavos;
    _transactions[index] = next;
    // Dated today: the same two habits a new save would complete. Cash-count
    // rows keep their own weekly XP and must not also fill today's missions.
    if (!next.isLinkedToCashCount &&
        _isSameDay(dateOnly(next.occurredAt), today)) {
      _awardDailyMissionsForMovement(next.occurredAt);
    }
    await _save();
    notifyListeners();
  }

  Future<void> classifyPendingCashExpense({
    required String expenseId,
    required ExpenseCategory category,
    required String note,
    String? receiptFileName,
  }) async {
    final index = _transactions.indexWhere((entry) => entry.id == expenseId);
    if (index == -1 || !_transactions[index].isPendingCashAdjustment) return;
    final previous = _transactions[index];
    _transactions[index] = previous.copyWith(
      category: category,
      note: note.trim(),
      isPendingCashAdjustment: false,
      // Putting a face on an unexplained gap is exactly what a photo is for,
      // so a ticket travels with the answer.
      receiptFileName: receiptFileName,
      clearReceipt: receiptFileName == null,
    );
    await _save();
    notifyListeners();
  }

  /// Removes an expense, reporting whether it was allowed to go.
  ///
  /// Refuses an expense created by a cash count: the money is already gone
  /// from the wallet, so deleting the row would hand the budget back cash the
  /// user does not have, and the count that recorded it would be left pointing
  /// at nothing. Recounting the cash is the way to correct one of these.
  Future<bool> deleteExpense(String id) async {
    final index = _transactions.indexWhere((entry) => entry.id == id);
    if (index == -1) return false;
    if (_transactions[index].isLinkedToCashCount) return false;
    final removed = _transactions.removeAt(index);
    if (_affectsCurrentCash(removed)) {
      expectedCashCentavos += removed.amountCentavos;
    }
    await _save();
    notifyListeners();
    return true;
  }

  Future<void> restoreExpense(ExpenseEntry entry) async {
    if (_transactions.any((existing) => existing.id == entry.id)) return;
    _transactions.add(entry);
    if (_affectsCurrentCash(entry)) {
      expectedCashCentavos -= entry.amountCentavos;
    }
    await _save();
    notifyListeners();
  }

  /// Removes an income, reporting whether it was allowed to go.
  ///
  /// Refuses an income created by a cash count, for the same reason
  /// [deleteExpense] refuses its counterpart: the money is already in the
  /// wallet and the count that recorded it hides its own row in favour of
  /// this one, so deleting it would erase the count from the ledger while
  /// the counted cash figure kept the money. Recounting is the way out.
  Future<bool> deleteIncome(String id) async {
    final index = _incomes.indexWhere((entry) => entry.id == id);
    if (index == -1) return false;
    if (_incomes[index].isLinkedToCashCount) return false;
    final removed = _incomes.removeAt(index);
    _applyIncome(removed, -1);
    await _save();
    notifyListeners();
    return true;
  }

  Future<void> restoreIncome(IncomeEntry entry) async {
    if (_incomes.any((existing) => existing.id == entry.id)) return;
    _incomes.add(entry);
    _applyIncome(entry, 1);
    await _save();
    notifyListeners();
  }

  Future<void> setTotalBudget(
    int centavos, {
    bool adjustCategoryLimits = false,
  }) async {
    if (centavos <= 0) throw ArgumentError.value(centavos, 'centavos');
    // The budget screen edits the total the user can see. Income allocated to
    // this cycle is already included in that figure, so keeping it in the base
    // as well would add the same money twice on the next read.
    final nextBaseBudget = centavos - cycleBudgetExtrasCentavos;
    if (nextBaseBudget <= 0) {
      throw const SobraStoreException(StoreFailure.budgetBelowCycleIncome);
    }
    _baseBudgetCentavos = nextBaseBudget;
    _hasBudget = true;
    if (adjustCategoryLimits) {
      // Scale what is there rather than reinstating the stock split: somebody
      // who moved Comida to half their budget asked for that, and "adjust
      // proportionally" is a promise to keep their shape, not to overwrite it.
      // Scaling the defaults reproduces the defaults, so one path covers both.
      categoryLimits = _scaledCategoryLimits(centavos);
    }
    await _save();
    notifyListeners();
  }

  /// The current limits restretched to add up to [budget], keeping each
  /// category's share of the plan.
  ///
  /// Scaling is measured against what the limits themselves total, not against
  /// the old budget figure: the two drift apart as soon as the budget is
  /// changed once without touching the limits, and the ratio the user cares
  /// about is the one between their categories.
  Map<ExpenseCategory, int> _scaledCategoryLimits(int budget) {
    final assigned = categoryLimits.values.fold(0, (sum, value) => sum + value);
    // Nothing to keep the shape of yet.
    if (assigned <= 0) return _categoryLimitsForBudget(budget);
    final factor = budget / assigned;
    final scaled = {
      for (final category in ExpenseCategory.values)
        category: ((categoryLimits[category] ?? 0) * factor).round(),
    };

    // Ten independent roundings leave the plan a few centavos off the budget.
    // Park the difference on the largest category, where it disappears, so
    // "proportionally" still adds up to exactly what the user set.
    final drift =
        budget - scaled.values.fold<int>(0, (sum, value) => sum + value);
    if (drift != 0) {
      final largest = scaled.entries.reduce(
        (a, b) => b.value > a.value ? b : a,
      );
      scaled[largest.key] = largest.value + drift;
    }
    return scaled;
  }

  Future<void> setCategoryLimit(ExpenseCategory category, int centavos) async {
    if (centavos < 0) throw ArgumentError.value(centavos, 'centavos');
    categoryLimits = {...categoryLimits, category: centavos};
    categoryLimitsCustomized = true;
    await _save();
    notifyListeners();
  }

  Future<CashReconciliationEntry?> reconcileCashCount({
    required int actualCentavos,
    required CashResolution resolution,
    ExpenseCategory? category,
    String note = '',
    IncomeAllocation incomeAllocation = IncomeAllocation.savings,
  }) async {
    if (actualCentavos < 0) {
      throw ArgumentError.value(actualCentavos, 'actualCentavos');
    }
    final moment = currentMoment;
    if (!hasCashBaseline) {
      countedCashCentavos = actualCentavos;
      expectedCashCentavos = actualCentavos;
      lastCashCountAt = moment;
      _recordCashCountXp(moment);
      await _save();
      notifyListeners();
      return null;
    }

    final expectedBefore = expectedCashCentavos;
    final difference = actualCentavos - expectedBefore;
    if (difference == 0) {
      countedCashCentavos = actualCentavos;
      expectedCashCentavos = actualCentavos;
      lastCashCountAt = moment;
      _recordCashCountXp(moment);
      await _save();
      notifyListeners();
      return null;
    }

    final reconciliationId = _newId('cash');
    String? linkedExpenseId;
    String? linkedIncomeId;
    if (difference < 0) {
      const allowed = {
        CashResolution.expense,
        CashResolution.transfer,
        CashResolution.correction,
        CashResolution.pending,
      };
      if (!allowed.contains(resolution)) {
        throw ArgumentError('A cash shortage cannot be classified as income.');
      }
      if (resolution == CashResolution.expense ||
          resolution == CashResolution.pending) {
        final expense = ExpenseEntry(
          id: _newId('expense'),
          amountCentavos: -difference,
          category: category ?? ExpenseCategory.other,
          note: note.trim(),
          occurredAt: moment,
          paymentMethod: PaymentMethod.cash,
          cashReconciliationId: reconciliationId,
          isPendingCashAdjustment: resolution == CashResolution.pending,
        );
        _transactions.add(expense);
        linkedExpenseId = expense.id;
      }
    } else {
      const allowed = {
        CashResolution.income,
        CashResolution.transfer,
        CashResolution.correction,
        CashResolution.pending,
      };
      if (!allowed.contains(resolution)) {
        throw ArgumentError('Extra cash cannot be classified as an expense.');
      }
      if (resolution == CashResolution.income) {
        final income = IncomeEntry(
          id: _newId('income'),
          amountCentavos: difference,
          kind: IncomeKind.cash,
          note: note.trim(),
          occurredAt: moment,
          destination: PaymentMethod.cash,
          allocation: incomeAllocation,
          cashReconciliationId: reconciliationId,
        );
        _incomes.add(income);
        _applyIncome(income, 1);
        linkedIncomeId = income.id;
      }
    }

    final reconciliation = CashReconciliationEntry(
      id: reconciliationId,
      expectedBeforeCentavos: expectedBefore,
      actualCentavos: actualCentavos,
      occurredAt: moment,
      resolution: resolution,
      linkedExpenseId: linkedExpenseId,
      linkedIncomeId: linkedIncomeId,
    );
    _cashReconciliations.add(reconciliation);
    countedCashCentavos = actualCentavos;
    expectedCashCentavos = actualCentavos;
    lastCashCountAt = moment;
    _recordCashCountXp(moment);
    await _save();
    notifyListeners();
    return reconciliation;
  }

  Future<void> queuePayScheduleChange(PaySchedule schedule) async {
    final effectiveAt = cycleEnd.add(const Duration(days: 1));
    pendingPaySchedule = schedule.type == PayCycleType.irregular
        ? schedule.copyWith(irregularCycleStart: effectiveAt)
        : schedule;
    pendingPayScheduleEffectiveAt = effectiveAt;
    await _save();
    notifyListeners();
  }

  Future<void> setReducedMotion(bool value) async {
    reducedMotion = value;
    await _save();
    notifyListeners();
  }

  /// Moves the day a cash-count week turns over.
  ///
  /// Weeks already awarded keep their XP: the award is keyed on the week it
  /// fell in, and changing the boundary cannot reach back and un-earn one.
  Future<void> setCashCountWeekday(int weekday) async {
    if (cashCountWeekday == weekday) return;
    cashCountWeekday = weekday;
    await _save();
    notifyListeners();
  }

  /// How many days [day] sits past the start of its cash-count week.
  @visibleForTesting
  int cashCountWeekOffset(DateTime day) =>
      (day.weekday - cashCountWeekday + 7) % 7;

  /// Relabels every amount in a new currency.
  ///
  /// Nothing is converted: 20000 stays 20000 minor units and only the code
  /// beside it changes. That is the honest behaviour for a ledger of what the
  /// user actually counted, and the screen says so before calling this.
  Future<void> setCurrency(Currency value) async {
    if (currency == value) return;
    currency = value;
    await _save();
    notifyListeners();
  }

  /// Picks the language, or passes null to go back to following the phone.
  Future<void> setLanguageCode(String? value) async {
    if (languageCode == value) return;
    languageCode = value;
    await _save();
    notifyListeners();
  }

  String exportJson() => const JsonEncoder.withIndent('  ').convert(_toJson());
  String? get exportCorruptedJson => corruptedStorage;

  /// Writes the answers onboarding collected.
  ///
  /// A null [budgetCentavos] is "not answered yet", not a budget of nothing —
  /// see [hasBudget]. The stored figure keeps its default anyway so the
  /// category split has something to be a share of; nothing reads it until a
  /// budget is actually set.
  Future<void> configureOnboarding({
    required int? budgetCentavos,
    required PaySchedule schedule,
    int? cashCentavos,
  }) async {
    _baseBudgetCentavos = budgetCentavos ?? 600000;
    _hasBudget = budgetCentavos != null;
    paySchedule =
        schedule.type == PayCycleType.irregular &&
            schedule.irregularCycleStart == null
        ? schedule.copyWith(irregularCycleStart: today)
        : schedule;
    pendingPaySchedule = null;
    pendingPayScheduleEffectiveAt = null;
    payScheduleEffectiveFloor = null;
    countedCashCentavos = cashCentavos ?? 0;
    expectedCashCentavos = cashCentavos ?? 0;
    lastCashCountAt = cashCentavos == null ? null : currentMoment;
    categoryLimits = _categoryLimitsForBudget(_baseBudgetCentavos);
    categoryLimitsCustomized = false;
    await _save();
    notifyListeners();
  }

  Future<void> chooseCharacter(String id) async {
    if (id.isEmpty || id == characterId) return;
    characterId = id;
    await _save();
    notifyListeners();
  }

  /// Whether [entry] is available to the user right now.
  ///
  /// The only place that answers this. Three unlock routes resolve three
  /// different ways — included entries always, level rewards from XP, and the
  /// rest from what was acquired — and a caller that checks only the stored
  /// set would report a level reward as locked.
  /// Matched on both ids on purpose. A store restore knows products, not
  /// catalog entries, and an id it could not map to this build's lineup is
  /// kept verbatim — so the same entitlement can be sitting in the set under
  /// either name, and asking for only one of them silently revokes a purchase.
  bool ownsCatalogEntry(CatalogEntry entry) {
    final productId = entry.storeProductId;
    return entry.unlockMethod == CatalogUnlockMethod.included ||
        CatalogPreviewData.isUnlockedAtLevel(entry, xpProgress.level) ||
        _ownedCatalogIds.contains(entry.id) ||
        (productId != null && _ownedCatalogIds.contains(productId));
  }

  /// Whether general (native) ads should stay off.
  ///
  /// Granted by the pack or by the standalone remove-ads product. Rewarded
  /// ads are not covered: those stay a choice in the collection.
  bool get ownsNoAds =>
      _ownedCatalogIds.contains(CatalogPreviewData.noAdsEntitlement);

  /// Whether the Michi & Friends pack has been delivered.
  ///
  /// The decoration is pack-only, so it is a cheaper signal than asking for
  /// every character the bundle lists.
  bool get ownsPack =>
      _ownedCatalogIds.contains(CatalogPreviewData.packDecorationId);

  /// The rewarded-ad entry a settlement card should open, or null when the
  /// card must be hidden.
  ///
  /// Hidden when the daily cap is spent or nothing unlockable remains. Order:
  /// an entry already in progress, then the fewest remaining views, then
  /// catalog order.
  CatalogEntry? get recommendedRewardedAdEntry {
    if ((rewardedAdsLeftToday ?? 1) <= 0) return null;
    final catalog = CatalogPreviewData.all;
    final candidates = [
      for (final entry in catalog)
        if (entry.unlockMethod == CatalogUnlockMethod.rewardedAd &&
            rewardedAdAvailabilityFor(entry) ==
                RewardedAdAvailability.available)
          entry,
    ];
    if (candidates.isEmpty) return null;
    candidates.sort((a, b) {
      final progressA = rewardedAdProgressFor(a.id);
      final progressB = rewardedAdProgressFor(b.id);
      final startedA = progressA > 0;
      final startedB = progressB > 0;
      if (startedA != startedB) return startedA ? -1 : 1;
      final remainingA = (a.rewardedAdTarget ?? 1) - progressA;
      final remainingB = (b.rewardedAdTarget ?? 1) - progressB;
      final byRemaining = remainingA.compareTo(remainingB);
      if (byRemaining != 0) return byRemaining;
      return catalog.indexOf(a).compareTo(catalog.indexOf(b));
    });
    return candidates.first;
  }

  /// Ids acquired by purchase or by finishing a rewarded-ad run.
  ///
  /// Level rewards are not in here by design — read [ownsCatalogEntry] rather
  /// than this to ask whether something is available.
  Set<String> get ownedCatalogIds => Set.unmodifiable(_ownedCatalogIds);

  /// Rewarded ads watched toward [id], or zero once it has been granted.
  int rewardedAdProgressFor(String id) => _rewardedAdProgress[id] ?? 0;

  /// Rewarded ads a user may watch in one local day, across every entry, or
  /// null for no limit.
  ///
  /// Null is what the app ships. A rewarded ad is started by the user, every
  /// time, and a cap is the one place Sobra would tell somebody who wants to
  /// watch one that they may not — the opposite of what the rest of this
  /// design promises. It also bought very little: the whole rewarded lineup is
  /// ten views, the special tier already forces its three onto three separate
  /// days, and a cap of three only stretched a three-day run into a four-day
  /// one. The finite lineup is the real limit.
  ///
  /// Settable rather than deleted, because the reason it might come back is
  /// real: a lineup that grows through updates would want pacing again. Kept
  /// injectable rather than as a constant so the limit's own behaviour stays
  /// covered by tests while the app runs without one — a path nothing can
  /// reach is a path that stops working quietly.
  final int? rewardedAdsPerDay;

  /// Today, as the key the daily limits are stored against.
  String get todayKey => dayKey(_now());

  /// Rewarded ads watched today.
  ///
  /// Answers zero for a stored count that belongs to an earlier day, so a
  /// limit would reset by itself rather than needing something to run at
  /// midnight.
  ///
  /// Kept counted while [rewardedAdsPerDay] is null. The day it carries is the
  /// same one the once-per-day tier already needs, so counting costs nothing,
  /// and a cap introduced later starts from a real number instead of from a
  /// gap in everybody's history.
  int get rewardedAdsWatchedToday =>
      _rewardedAdDay == todayKey ? _rewardedAdsWatchedOnDay : 0;

  /// Rewarded ads still allowed today, or null where there is no limit.
  int? get rewardedAdsLeftToday {
    final perDay = rewardedAdsPerDay;
    if (perDay == null) return null;
    return (perDay - rewardedAdsWatchedToday).clamp(0, perDay);
  }

  /// The local day [id] last took a view, or null for an entry that never has.
  String? rewardedAdLastEarnedDateFor(String id) =>
      _rewardedAdLastEarnedDate[id];

  /// Native impressions counted today. A stale stored day reads as zero.
  int get nativeAdImpressionsToday =>
      _nativeAdDay == todayKey ? _nativeAdImpressionsOnDay : 0;

  /// Whether the install/update grace period has elapsed.
  ///
  /// Asked from inside a build — [NativeAds.canOffer] runs while the ledger
  /// lays itself out — so this must not be able to throw. A stored day that
  /// will not parse is treated as no day at all: the grace holds, and
  /// [_ensureNativeAdInstallDay] writes a usable one on the next launch.
  /// Every other corrupt-state path in this store degrades the same way
  /// rather than taking a screen down with it.
  bool nativeAdGraceComplete(int days) {
    if (days <= 0) return true;
    final installed = _nativeAdInstallDay;
    if (installed == null) return false;
    final start = DateTime.tryParse(installed);
    if (start == null) return false;
    return today.difference(start).inDays >= days;
  }

  /// Records a native ad only after the SDK reports a real impression.
  ///
  /// The day and cap are checked again here so two callbacks racing one
  /// another cannot both spend the last slot.
  Future<bool> recordNativeAdImpression({int maxPerDay = 2}) async {
    if (maxPerDay <= 0 || nativeAdImpressionsToday >= maxPerDay) return false;
    final count = nativeAdImpressionsToday;
    _nativeAdDay = todayKey;
    _nativeAdImpressionsOnDay = count + 1;
    await _save();
    notifyListeners();
    return true;
  }

  /// Whether a rewarded view would count toward [entry] right now.
  ///
  /// Says nothing about whether the network has an ad — that is the ad
  /// surface's question. This is only about the rules Sobra imposes on itself.
  ///
  /// Most specific reason first: an owned entry is reported as owned even on a
  /// day whose cap is spent, because that is the reason its card will never
  /// offer an ad again.
  RewardedAdAvailability rewardedAdAvailabilityFor(CatalogEntry entry) {
    if (ownsCatalogEntry(entry)) return RewardedAdAvailability.alreadyOwned;
    if (entry.rewardedAdOncePerDay &&
        _rewardedAdLastEarnedDate[entry.id] == todayKey) {
      return RewardedAdAvailability.alreadyEarnedToday;
    }
    if ((rewardedAdsLeftToday ?? 1) <= 0) {
      return RewardedAdAvailability.dailyCapReached;
    }
    return RewardedAdAvailability.available;
  }

  /// The entry the user is showing for [kind], or null for none.
  String? equippedIdFor(CatalogKind kind) => switch (kind) {
    CatalogKind.character => characterId,
    CatalogKind.item => equippedItemId,
  };

  Map<RoomSlot, String> roomDecorationsFor([String? roomId]) =>
      Map.unmodifiable({
        ...RoomThemes.defaultPlacementsFor(roomId ?? equippedRoomId),
        ...?_roomPlacementsByRoom[roomId ?? equippedRoomId],
      });

  Future<void> saveRoomDecorations(Map<RoomSlot, String> placements) async {
    for (final itemId in placements.values) {
      if (RoomDecorAssets.assetFor(itemId) == null) {
        throw ArgumentError.value(itemId, 'placements', 'unknown room item');
      }
      final entry = CatalogPreviewData.items
          .where((candidate) => candidate.id == itemId)
          .firstOrNull;
      if (entry != null && !ownsCatalogEntry(entry)) {
        throw ArgumentError.value(itemId, 'placements', 'item not owned');
      }
    }
    _roomPlacementsByRoom[equippedRoomId] = Map.of(placements);
    final catalogItems = placements.values.where(
      (id) => CatalogPreviewData.items.any((entry) => entry.id == id),
    );
    equippedItemId = catalogItems.isEmpty ? null : catalogItems.last;
    await _save();
    notifyListeners();
  }

  /// Records that [entry] was acquired.
  ///
  /// Takes a bare id rather than a [CatalogEntry] because the caller that
  /// matters most cannot supply one: a store restore hands back product ids
  /// for entries this build may no longer ship, and dropping those would
  /// silently revoke something the user paid for.
  Future<void> grantCatalogEntry(String id) => grantCatalogEntries({id});

  /// Records that every id in [ids] was acquired, in one write.
  ///
  /// What a bundle needs: granting its contents one at a time would save once
  /// per id, and a failure partway through would leave somebody who paid for
  /// three characters owning one of them. Here the whole delivery either lands
  /// or is replayed by the store on the next launch.
  ///
  /// Ids already owned are skipped rather than refused, so a bundle that
  /// overlaps something the user bought separately still delivers the rest.
  /// Nothing is refunded for the overlap; the purchase sheet says so before
  /// the user pays.
  Future<void> grantCatalogEntries(Set<String> ids) async {
    final added = ids.where((id) => id.isNotEmpty).toSet()
      ..removeAll(_ownedCatalogIds);
    if (added.isEmpty) return;
    _ownedCatalogIds.addAll(added);
    _rewardedAdProgress.removeWhere((id, _) => added.contains(id));
    await _save();
    notifyListeners();
  }

  /// Counts one watched ad toward [entry], granting it once the run completes.
  ///
  /// Called by the ad surface only after the network confirms a completed
  /// view, so that a dismissed ad or one that never loaded cannot advance the
  /// count. Answers whether the view counted: anything [rewardedAdAvailabilityFor]
  /// rules out is refused here too rather than trusted to have been checked,
  /// which is what keeps a second confirmation for the same ad from being
  /// counted twice.
  ///
  /// The progress, the daily count and the per-entry date are one write. A
  /// view that advanced the run but left the daily count behind would hand
  /// back a free ad on every restart.
  Future<bool> recordRewardedAdView(CatalogEntry entry) async {
    final target = entry.rewardedAdTarget;
    if (target == null) {
      throw ArgumentError.value(entry.id, 'entry', 'not a rewarded-ad entry');
    }
    if (rewardedAdAvailabilityFor(entry) != RewardedAdAvailability.available) {
      return false;
    }
    final today = todayKey;
    // Read before the day is written: reading it afterwards would find a count
    // from an earlier day sitting under today's key and carry it over.
    final watchedToday = rewardedAdsWatchedToday;
    _rewardedAdDay = today;
    _rewardedAdsWatchedOnDay = watchedToday + 1;
    if (entry.rewardedAdOncePerDay) {
      _rewardedAdLastEarnedDate[entry.id] = today;
    }
    final next = rewardedAdProgressFor(entry.id) + 1;
    if (next >= target) {
      _rewardedAdProgress.remove(entry.id);
      _ownedCatalogIds.add(entry.id);
    } else {
      _rewardedAdProgress[entry.id] = next;
    }
    await _save();
    notifyListeners();
    return true;
  }

  /// Shows [entry] in the room.
  ///
  /// Refuses an entry the user does not own rather than storing it and letting
  /// the room fall back to placeholder art, which would read as a bug the user
  /// cannot undo.
  /// Shows [entry]'s character wherever the app draws one.
  ///
  /// Characters only. Items came through here too once, writing a room
  /// placement on the user's behalf from a screen that could not show them
  /// where it landed — and, for an item belonging to no slot, setting a mark
  /// nothing ever read back. Placing is the decorate screen's work now.
  ///
  /// The ownership check is why this exists rather than a bare
  /// [chooseCharacter]: the chosen character is drawn on the register screen
  /// and in every celebration, so an unowned one here would give away what
  /// the catalog is still selling.
  Future<void> equipCharacter(CatalogEntry entry) async {
    if (entry.kind != CatalogKind.character) {
      throw ArgumentError.value(entry.id, 'entry', 'not a character');
    }
    if (!ownsCatalogEntry(entry)) {
      throw ArgumentError.value(entry.id, 'entry', 'not owned');
    }
    await chooseCharacter(entry.id);
  }

  /// Records that the account offer has been answered, whichever way.
  Future<void> answerLoginOffer() async {
    if (hasAnsweredLoginOffer) return;
    hasAnsweredLoginOffer = true;
    await _save();
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    hasCompletedOnboarding = true;
    // Onboarding sits behind the account offer, so reaching the end of it is
    // proof the offer was answered. Recording that here keeps the two from
    // ever disagreeing — an install that finished onboarding can never be
    // asked the opening question again.
    hasAnsweredLoginOffer = true;
    xpTrackingStartedAt ??= today;
    await _save();
    notifyListeners();
  }

  bool get hasRecoverableBackup {
    final raw = _preferences.getString(_backupKey);
    return raw != null && _isPlausibleState(raw);
  }

  Future<bool> retryRestore() async {
    final raw = _preferences.getString(_storageKey);
    if (raw == null || !_tryRestore(raw)) return false;
    hasStorageError = false;
    corruptedStorage = null;
    await _ensureNativeAdInstallDay();
    await settleCycles();
    notifyListeners();
    return true;
  }

  Future<bool> restoreBackup() async {
    final raw = _preferences.getString(_backupKey);
    if (raw == null || !_tryRestore(raw)) return false;
    hasStorageError = false;
    corruptedStorage = null;
    final saved = await _preferences.setString(_storageKey, raw);
    if (!saved) throw const SobraStoreException(StoreFailure.restoreFailed);
    await _ensureNativeAdInstallDay();
    await settleCycles();
    notifyListeners();
    return true;
  }

  Future<void> startFreshAfterCorruption() async {
    final raw = corruptedStorage;
    if (raw != null) {
      final archived = await _preferences.setString(_corruptArchiveKey, raw);
      if (!archived) {
        throw const SobraStoreException(StoreFailure.originalNotKept);
      }
    }
    _initializeNewUser();
    hasStorageError = false;
    corruptedStorage = null;
    await _save();
    notifyListeners();
  }

  void _validateMovement(int amountCentavos, DateTime occurredAt) {
    if (amountCentavos <= 0) {
      throw ArgumentError.value(amountCentavos, 'amountCentavos');
    }
    if (dateOnly(occurredAt).isAfter(today)) {
      throw const SobraStoreException(StoreFailure.futureMovement);
    }
  }

  bool _affectsCurrentCash(ExpenseEntry entry) {
    if (!hasCashBaseline || entry.paymentMethod != PaymentMethod.cash) {
      return false;
    }
    if (entry.cashReconciliationId != null) return false;
    return entry.occurredAt.isAfter(lastCashCountAt!);
  }

  void _applyIncome(IncomeEntry entry, int direction) {
    if (entry.destination == PaymentMethod.cash &&
        hasCashBaseline &&
        entry.cashReconciliationId == null &&
        entry.occurredAt.isAfter(lastCashCountAt!)) {
      expectedCashCentavos += direction * entry.amountCentavos;
    }
    if (entry.allocation == IncomeAllocation.cycle) {
      final key = _cycleKey(boundsFor(entry.occurredAt).start);
      _cycleBudgetExtras[key] =
          (_cycleBudgetExtras[key] ?? 0) + direction * entry.amountCentavos;
      if (_cycleBudgetExtras[key] == 0) _cycleBudgetExtras.remove(key);
    }
  }

  Future<bool> _applyPendingScheduleIfNeeded() async {
    final effectiveAt = pendingPayScheduleEffectiveAt;
    final pending = pendingPaySchedule;
    if (effectiveAt == null || pending == null || today.isBefore(effectiveAt)) {
      return false;
    }
    paySchedule = pending;
    pendingPaySchedule = null;
    pendingPayScheduleEffectiveAt = null;
    payScheduleEffectiveFloor = effectiveAt;
    await _save();
    return true;
  }

  void _initializeNewUser() {
    _transactions.clear();
    _incomes.clear();
    _cashReconciliations.clear();
    _xpEvents.clear();
    _cycleRecords.clear();
    _cycleBudgetExtras.clear();
    _baseBudgetCentavos = 600000;
    _hasBudget = true;
    characterId = 'michi';
    equippedItemId = null;
    equippedRoomId = RoomThemes.casaClaraId;
    _roomPlacementsByRoom.clear();
    _ownedCatalogIds.clear();
    _rewardedAdProgress.clear();
    _rewardedAdDay = null;
    _rewardedAdsWatchedOnDay = 0;
    _rewardedAdLastEarnedDate.clear();
    _nativeAdInstallDay = todayKey;
    _nativeAdDay = null;
    _nativeAdImpressionsOnDay = 0;
    countedCashCentavos = 0;
    expectedCashCentavos = 0;
    reducedMotion = false;
    hasCompletedOnboarding = false;
    hasAnsweredLoginOffer = false;
    categoryLimitsCustomized = false;
    successfulCycles = 0;
    lastCashCountAt = null;
    paySchedule = _defaultPaySchedule;
    pendingPaySchedule = null;
    pendingPayScheduleEffectiveAt = null;
    payScheduleEffectiveFloor = null;
    xpTrackingStartedAt = null;
    lastSettledCycleEnd = null;
    _pendingXpNotice = null;
    categoryLimits = _categoryLimitsForBudget(_baseBudgetCentavos);
  }

  Future<void> _ensureNativeAdInstallDay() async {
    if (_nativeAdInstallDay != null) return;
    _nativeAdInstallDay = todayKey;
    try {
      await _save();
    } on Object catch (error) {
      // Awaited from [load], so an escaping throw is an app that does not
      // start — and this runs for every existing install on its first launch
      // after ads shipped, which is the worst possible population to lock out
      // over a failed write. The day stays set for this session and the next
      // launch writes it; a disk that keeps refusing only restarts the grace
      // period, which delays ads rather than breaking the ledger.
      debugPrint('Sobra: could not save the native ad install day: $error');
    }
  }

  bool _tryRestore(String raw) {
    try {
      final candidate = SobraStore._(
        _preferences,
        _now,
        rewardedAdsPerDay,
      );
      candidate._restore(jsonDecode(raw) as Map<String, dynamic>);
      _copyFrom(candidate);
      return true;
    } on Object {
      return false;
    }
  }

  void _copyFrom(SobraStore other) {
    _transactions
      ..clear()
      ..addAll(other._transactions);
    _incomes
      ..clear()
      ..addAll(other._incomes);
    _cashReconciliations
      ..clear()
      ..addAll(other._cashReconciliations);
    _xpEvents
      ..clear()
      ..addAll(other._xpEvents);
    _cycleRecords
      ..clear()
      ..addAll(other._cycleRecords);
    _cycleBudgetExtras
      ..clear()
      ..addAll(other._cycleBudgetExtras);
    _ownedCatalogIds
      ..clear()
      ..addAll(other._ownedCatalogIds);
    _rewardedAdProgress
      ..clear()
      ..addAll(other._rewardedAdProgress);
    _rewardedAdDay = other._rewardedAdDay;
    _rewardedAdsWatchedOnDay = other._rewardedAdsWatchedOnDay;
    _rewardedAdLastEarnedDate
      ..clear()
      ..addAll(other._rewardedAdLastEarnedDate);
    _nativeAdInstallDay = other._nativeAdInstallDay;
    _nativeAdDay = other._nativeAdDay;
    _nativeAdImpressionsOnDay = other._nativeAdImpressionsOnDay;
    _baseBudgetCentavos = other._baseBudgetCentavos;
    _hasBudget = other._hasBudget;
    characterId = other.characterId;
    equippedItemId = other.equippedItemId;
    equippedRoomId = other.equippedRoomId;
    _roomPlacementsByRoom
      ..clear()
      ..addAll({
        for (final entry in other._roomPlacementsByRoom.entries)
          entry.key: Map.of(entry.value),
      });
    countedCashCentavos = other.countedCashCentavos;
    expectedCashCentavos = other.expectedCashCentavos;
    reducedMotion = other.reducedMotion;
    languageCode = other.languageCode;
    currency = other.currency;
    cashCountWeekday = other.cashCountWeekday;
    hasCompletedOnboarding = other.hasCompletedOnboarding;
    hasAnsweredLoginOffer = other.hasAnsweredLoginOffer;
    categoryLimitsCustomized = other.categoryLimitsCustomized;
    successfulCycles = other.successfulCycles;
    lastCashCountAt = other.lastCashCountAt;
    paySchedule = other.paySchedule;
    pendingPaySchedule = other.pendingPaySchedule;
    pendingPayScheduleEffectiveAt = other.pendingPayScheduleEffectiveAt;
    payScheduleEffectiveFloor = other.payScheduleEffectiveFloor;
    xpTrackingStartedAt = other.xpTrackingStartedAt;
    lastSettledCycleEnd = other.lastSettledCycleEnd;
    _pendingXpNotice = other._pendingXpNotice;
    categoryLimits = Map.of(other.categoryLimits);
  }

  void _restore(Map<String, dynamic> json) {
    _transactions
      ..clear()
      ..addAll(
        (json['transactions'] as List<dynamic>).map(
          (entry) => ExpenseEntry.fromJson(entry as Map<String, dynamic>),
        ),
      );
    _incomes
      ..clear()
      ..addAll(
        (json['incomes'] as List<dynamic>? ?? const []).map(
          (entry) => IncomeEntry.fromJson(entry as Map<String, dynamic>),
        ),
      );
    _cashReconciliations
      ..clear()
      ..addAll(
        (json['cashReconciliations'] as List<dynamic>? ?? const []).map(
          (entry) =>
              CashReconciliationEntry.fromJson(entry as Map<String, dynamic>),
        ),
      );
    _xpEvents
      ..clear()
      ..addAll(
        (json['xpEvents'] as List<dynamic>? ?? const []).map(
          (entry) => XpEvent.fromJson(entry as Map<String, dynamic>),
        ),
      );
    _cycleRecords
      ..clear()
      ..addAll(
        (json['cycleRecords'] as List<dynamic>? ?? const []).map(
          (entry) => CycleRecord.fromJson(entry as Map<String, dynamic>),
        ),
      );
    _baseBudgetCentavos =
        (json['baseBudgetCentavos'] as num? ??
                json['totalBudgetCentavos'] as num)
            .toInt();
    // Absent from every state written before the budget could be left
    // unanswered. Those users answered it during onboarding, so their saved
    // figure is a real one and the flag reads true.
    _hasBudget = json['hasBudget'] as bool? ?? true;
    characterId = json['characterId'] as String? ?? 'michi';
    equippedItemId = json['equippedItemId'] as String?;
    equippedRoomId =
        json['equippedRoomId'] as String? ?? RoomThemes.casaClaraId;
    final savedRoomPlacements =
        json['roomPlacementsByRoom'] as Map<String, dynamic>? ?? {};
    _roomPlacementsByRoom
      ..clear()
      ..addAll({
        for (final room in savedRoomPlacements.entries)
          room.key: {
            for (final placement
                in (room.value as Map<String, dynamic>).entries)
              if (RoomSlot.values.any((slot) => slot.name == placement.key))
                RoomSlot.values.firstWhere(
                  (slot) => slot.name == placement.key,
                ): placement.value as String,
          },
      });
    if (_roomPlacementsByRoom[equippedRoomId] == null &&
        equippedItemId != null) {
      final legacySlot = RoomDecorAssets.slotForItemId(equippedItemId!);
      if (legacySlot != null) {
        _roomPlacementsByRoom[equippedRoomId] = {legacySlot: equippedItemId!};
      }
    }
    // Absent from every state written before the collection was persisted.
    // Those users owned nothing beyond what their level already grants, and
    // that part is derived rather than read from here.
    _ownedCatalogIds
      ..clear()
      ..addAll(
        (json['ownedCatalogIds'] as List<dynamic>? ?? const []).cast<String>(),
      );
    final adProgress =
        json['rewardedAdProgress'] as Map<String, dynamic>? ?? {};
    _rewardedAdProgress
      ..clear()
      ..addAll({
        for (final entry in adProgress.entries)
          entry.key: (entry.value as num).toInt(),
      });
    // Absent from every state written before the daily limit existed. A
    // missing day reads as "no ads watched yet", which is what those users
    // had.
    _rewardedAdDay = json['rewardedAdDay'] as String?;
    _rewardedAdsWatchedOnDay =
        (json['rewardedAdsWatchedOnDay'] as num?)?.toInt() ?? 0;
    final lastEarned =
        json['rewardedAdLastEarnedDate'] as Map<String, dynamic>? ?? {};
    _rewardedAdLastEarnedDate
      ..clear()
      ..addAll({
        for (final entry in lastEarned.entries) entry.key: entry.value as String,
      });
    // Dropped rather than carried when it will not parse, so the field holds
    // either a usable day or nothing. _ensureNativeAdInstallDay then fills it
    // the way it fills a state written before native ads existed.
    final installDay = json['nativeAdInstallDay'] as String?;
    _nativeAdInstallDay =
        installDay != null && DateTime.tryParse(installDay) != null
        ? installDay
        : null;
    _nativeAdDay = json['nativeAdDay'] as String?;
    _nativeAdImpressionsOnDay =
        (json['nativeAdImpressionsOnDay'] as num?)?.toInt() ?? 0;
    countedCashCentavos = (json['countedCashCentavos'] as num).toInt();
    expectedCashCentavos = (json['expectedCashCentavos'] as num).toInt();
    reducedMotion = json['reducedMotion'] as bool? ?? false;
    // A release build that no longer offers a language reads its code as
    // "follow the phone" rather than holding a choice it cannot honour.
    final savedLanguage = json['languageCode'] as String?;
    languageCode = SobraLanguage.fromCode(savedLanguage).code;
    currency = Currency.fromCode(json['currencyCode'] as String?);
    cashCountWeekday =
        (json['cashCountWeekday'] as num?)?.toInt() ?? DateTime.sunday;
    hasCompletedOnboarding = json['hasCompletedOnboarding'] as bool? ?? false;
    // Absent from every state written before the offer existed. Those users
    // have been using Sobra without an account all along, so reading a missing
    // flag as "not answered" would interrupt them to ask a question they have
    // effectively already answered.
    hasAnsweredLoginOffer =
        json['hasAnsweredLoginOffer'] as bool? ?? hasCompletedOnboarding;
    categoryLimitsCustomized =
        json['categoryLimitsCustomized'] as bool? ?? false;
    successfulCycles = (json['successfulCycles'] as num?)?.toInt() ?? 0;
    final savedCount = json['lastCashCountAt'] as String?;
    lastCashCountAt = savedCount == null ? null : DateTime.parse(savedCount);
    final scheduleJson = json['paySchedule'] as Map<String, dynamic>?;
    paySchedule = scheduleJson == null
        ? _defaultPaySchedule
        : PaySchedule.fromJson(scheduleJson);
    final pendingJson = json['pendingPaySchedule'] as Map<String, dynamic>?;
    pendingPaySchedule = pendingJson == null
        ? null
        : PaySchedule.fromJson(pendingJson);
    final effective = json['pendingPayScheduleEffectiveAt'] as String?;
    pendingPayScheduleEffectiveAt = effective == null
        ? null
        : DateTime.parse(effective);
    final floor = json['payScheduleEffectiveFloor'] as String?;
    payScheduleEffectiveFloor = floor == null ? null : DateTime.parse(floor);
    final trackingStarted = json['xpTrackingStartedAt'] as String?;
    xpTrackingStartedAt = trackingStarted == null
        ? null
        : DateTime.parse(trackingStarted);
    final settledEnd = json['lastSettledCycleEnd'] as String?;
    lastSettledCycleEnd = settledEnd == null
        ? null
        : DateTime.parse(settledEnd);
    final extras = json['cycleBudgetExtras'] as Map<String, dynamic>? ?? {};
    _cycleBudgetExtras
      ..clear()
      ..addAll({
        for (final entry in extras.entries)
          entry.key: (entry.value as num).toInt(),
      });
    final limits = json['categoryLimits'] as Map<String, dynamic>? ?? {};
    categoryLimits = {
      for (final category in ExpenseCategory.values)
        category: (limits[category.name] as num?)?.toInt() ?? 0,
    };
  }

  Map<String, Object?> _toJson() => {
    'schemaVersion': 8,
    'transactions': _transactions.map((entry) => entry.toJson()).toList(),
    'incomes': _incomes.map((entry) => entry.toJson()).toList(),
    'cashReconciliations': _cashReconciliations
        .map((entry) => entry.toJson())
        .toList(),
    'xpEvents': _xpEvents.map((entry) => entry.toJson()).toList(),
    'cycleRecords': _cycleRecords.map((entry) => entry.toJson()).toList(),
    'baseBudgetCentavos': _baseBudgetCentavos,
    'totalBudgetCentavos': _baseBudgetCentavos,
    'hasBudget': _hasBudget,
    'characterId': characterId,
    'equippedItemId': equippedItemId,
    'equippedRoomId': equippedRoomId,
    'roomPlacementsByRoom': {
      for (final room in _roomPlacementsByRoom.entries)
        room.key: {
          for (final placement in room.value.entries)
            placement.key.name: placement.value,
        },
    },
    // Sorted so that the same ownership serialises to the same string. [_save]
    // compares against what is stored to decide whether to take a backup, and
    // set iteration order alone would make an unchanged state look changed.
    'ownedCatalogIds': _ownedCatalogIds.toList()..sort(),
    'rewardedAdProgress': _rewardedAdProgress,
    'rewardedAdDay': _rewardedAdDay,
    'rewardedAdsWatchedOnDay': _rewardedAdsWatchedOnDay,
    'rewardedAdLastEarnedDate': _rewardedAdLastEarnedDate,
    'nativeAdInstallDay': _nativeAdInstallDay,
    'nativeAdDay': _nativeAdDay,
    'nativeAdImpressionsOnDay': _nativeAdImpressionsOnDay,
    'cycleBudgetExtras': _cycleBudgetExtras,
    'countedCashCentavos': countedCashCentavos,
    'expectedCashCentavos': expectedCashCentavos,
    'reducedMotion': reducedMotion,
    'languageCode': languageCode,
    'currencyCode': currency.code,
    'cashCountWeekday': cashCountWeekday,
    'hasCompletedOnboarding': hasCompletedOnboarding,
    'hasAnsweredLoginOffer': hasAnsweredLoginOffer,
    'categoryLimitsCustomized': categoryLimitsCustomized,
    'successfulCycles': successfulCycles,
    'lastCashCountAt': lastCashCountAt?.toIso8601String(),
    'paySchedule': paySchedule.toJson(),
    'pendingPaySchedule': pendingPaySchedule?.toJson(),
    'pendingPayScheduleEffectiveAt': pendingPayScheduleEffectiveAt
        ?.toIso8601String(),
    'payScheduleEffectiveFloor': payScheduleEffectiveFloor?.toIso8601String(),
    'xpTrackingStartedAt': xpTrackingStartedAt?.toIso8601String(),
    'lastSettledCycleEnd': lastSettledCycleEnd?.toIso8601String(),
    'categoryLimits': {
      for (final entry in categoryLimits.entries) entry.key.name: entry.value,
    },
  };

  Future<void> _save() async {
    final next = jsonEncode(_toJson());
    final current = _preferences.getString(_storageKey);
    if (current != null && current != next && _isPlausibleState(current)) {
      final backupSaved = await _preferences.setString(_backupKey, current);
      if (!backupSaved) {
        throw const SobraStoreException(StoreFailure.backupNotSaved);
      }
    }
    final saved = await _preferences.setString(_storageKey, next);
    if (!saved) throw const SobraStoreException(StoreFailure.saveFailed);
  }

  bool _isPlausibleState(String raw) {
    try {
      final json = jsonDecode(raw);
      if (json is! Map<String, dynamic>) return false;
      return json['transactions'] is List &&
          (json['baseBudgetCentavos'] is num ||
              json['totalBudgetCentavos'] is num);
    } on Object {
      return false;
    }
  }

  String _newId(String prefix) {
    // Never derived from how many entries exist: deleting one used to walk the
    // counter backwards and hand the next entry an id that had already been
    // used. Web builds make that worse - DateTime there has millisecond, not
    // microsecond, resolution, so the timestamp alone separates far less.
    final stamp = currentMoment.microsecondsSinceEpoch;
    var id = '$prefix-$stamp-${_idSequence++}';
    while (_isIdTaken(id)) {
      id = '$prefix-$stamp-${_idSequence++}';
    }
    return id;
  }

  bool _isIdTaken(String id) =>
      _transactions.any((entry) => entry.id == id) ||
      _incomes.any((entry) => entry.id == id) ||
      _cashReconciliations.any((entry) => entry.id == id) ||
      _xpEvents.any((entry) => entry.id == id);
  String _cycleKey(DateTime date) => dateOnly(date).toIso8601String();
  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static Map<ExpenseCategory, int> _categoryLimitsForBudget(int budget) => {
    ExpenseCategory.food: (budget * .30).round(),
    ExpenseCategory.transport: (budget * .15).round(),
    ExpenseCategory.shopping: (budget * .10).round(),
    ExpenseCategory.home: (budget * .10).round(),
    ExpenseCategory.services: (budget * .10).round(),
    ExpenseCategory.health: (budget * .08).round(),
    ExpenseCategory.education: (budget * .05).round(),
    ExpenseCategory.entertainment: (budget * .05).round(),
    ExpenseCategory.pets: (budget * .04).round(),
    ExpenseCategory.other: (budget * .03).round(),
  };
}

class _SettlementRun {
  const _SettlementRun({this.closedCycles = 0, this.awardedXp = 0});

  final int closedCycles;
  final int awardedXp;

  _SettlementRun operator +(_SettlementRun other) => _SettlementRun(
    closedCycles: closedCycles + other.closedCycles,
    awardedXp: awardedXp + other.awardedXp,
  );
}

class SobraScope extends InheritedNotifier<SobraStore> {
  const SobraScope({super.key, required SobraStore store, required super.child})
    : super(notifier: store);

  /// The store above [context], or null where there is none.
  ///
  /// For widgets that can still draw something sensible without app state —
  /// a sprite in a preview or a test. Anything that needs the store uses
  /// [of], which says so.
  static SobraStore? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SobraScope>()?.notifier;

  static SobraStore of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<SobraScope>();
    assert(scope != null, 'SobraScope is missing above this context.');
    return scope!.notifier!;
  }
}

/// Whether motion should be held back — either because the user asked for it
/// in Ajustes, or because they already asked the OS for it system-wide.
///
/// Read this rather than `store.reducedMotion`: somebody who turned on "reduce
/// motion" in iOS or Android should not have to find the same switch again
/// inside the app.
bool reducedMotionOf(BuildContext context) =>
    SobraScope.of(context).reducedMotion ||
    MediaQuery.disableAnimationsOf(context);
