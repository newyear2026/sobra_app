import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/cash_reconciliation.dart';
import '../models/expense_entry.dart';
import '../models/income_entry.dart';
import '../models/money_movement.dart';
import '../models/pay_schedule.dart';

typedef NowProvider = DateTime Function();

class SobraStore extends ChangeNotifier {
  SobraStore._(this._preferences, this._now);

  static const _storageKey = 'sobra_state_v2';
  static const _backupKey = 'sobra_state_backup_v2';
  static const _corruptArchiveKey = 'sobra_state_corrupt_v2';

  final SharedPreferences _preferences;
  final NowProvider _now;
  final List<ExpenseEntry> _transactions = [];
  final List<IncomeEntry> _incomes = [];
  final List<CashReconciliationEntry> _cashReconciliations = [];
  final Map<String, int> _cycleBudgetExtras = {};
  int _idSequence = 0;

  int _baseBudgetCentavos = 600000;
  int countedCashCentavos = 0;
  int expectedCashCentavos = 0;
  bool reducedMotion = false;
  bool hasCompletedOnboarding = false;
  bool categoryLimitsCustomized = false;
  int successfulCycles = 0;
  DateTime? lastCashCountAt;
  PaySchedule paySchedule = const PaySchedule.semiMonthly();
  PaySchedule? pendingPaySchedule;
  DateTime? pendingPayScheduleEffectiveAt;
  DateTime? payScheduleEffectiveFloor;
  bool hasStorageError = false;
  String? corruptedStorage;
  DateTime? _lastObservedDate;

  Map<ExpenseCategory, int> categoryLimits = _categoryLimitsForBudget(600000);

  static Future<SobraStore> load({NowProvider? now}) async {
    final preferences = await SharedPreferences.getInstance();
    final store = SobraStore._(preferences, now ?? DateTime.now);
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
    await store._applyPendingScheduleIfNeeded();
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
  int get baseBudgetCentavos => _baseBudgetCentavos;
  int get totalBudgetCentavos =>
      _baseBudgetCentavos + (_cycleBudgetExtras[_cycleKey(cycleStart)] ?? 0);

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

  List<MoneyMovement> get movements {
    final result = <MoneyMovement>[
      for (final entry in _transactions)
        MoneyMovement(
          id: entry.id,
          title: entry.note,
          subtitle: entry.isPendingCashAdjustment
              ? 'Pendiente · Efectivo'
              : '${entry.category.label} · ${entry.paymentMethod == PaymentMethod.cash ? 'Efectivo' : 'Tarjeta'}',
          amountCentavos: -entry.amountCentavos,
          occurredAt: entry.occurredAt,
          type: MovementType.expense,
          expense: entry,
          isPending: entry.isPendingCashAdjustment,
        ),
      for (final entry in _incomes)
        MoneyMovement(
          id: entry.id,
          title: entry.note,
          subtitle:
              '${entry.kind.label} · ${entry.allocation == IncomeAllocation.cycle ? 'Este ciclo' : 'Ahorro'}',
          amountCentavos: entry.amountCentavos,
          occurredAt: entry.occurredAt,
          type: MovementType.income,
          income: entry,
        ),
      for (final entry in _cashReconciliations)
        if (entry.linkedExpenseId == null && entry.linkedIncomeId == null)
          MoneyMovement(
            id: entry.id,
            title: entry.resolution.label,
            subtitle: 'Conteo de efectivo',
            amountCentavos: entry.differenceCentavos,
            occurredAt: entry.occurredAt,
            type: MovementType.adjustment,
            reconciliation: entry,
            isPending: entry.resolution == CashResolution.pending,
          ),
    ]..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    return List.unmodifiable(result);
  }

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
  int get spentTodayCentavos => cycleTransactions
      .where((entry) => _isSameDay(entry.occurredAt, today))
      .fold(0, (total, entry) => total + entry.amountCentavos);
  int get spentBeforeTodayCentavos => totalSpentCentavos - spentTodayCentavos;
  int get remainingBudgetCentavos => totalBudgetCentavos - totalSpentCentavos;

  int get dailyAllowanceCentavos {
    final availableAtStartOfDay =
        totalBudgetCentavos - spentBeforeTodayCentavos;
    return daysRemaining <= 0 ? 0 : availableAtStartOfDay ~/ daysRemaining;
  }

  int get todayRemainingCentavos => dailyAllowanceCentavos - spentTodayCentavos;
  double get budgetProgress =>
      totalBudgetCentavos == 0 ? 0 : totalSpentCentavos / totalBudgetCentavos;

  int get projectedRemainderCentavos {
    if (elapsedDays <= 0) return remainingBudgetCentavos;
    final average = totalSpentCentavos / elapsedDays;
    final futureDays = daysRemaining > 0 ? daysRemaining - 1 : 0;
    return remainingBudgetCentavos - (average * futureDays).round();
  }

  int spentFor(ExpenseCategory category) => cycleTransactions
      .where((entry) => entry.category == category)
      .fold(0, (total, entry) => total + entry.amountCentavos);

  Future<void> refreshForCurrentDate() async {
    await _applyPendingScheduleIfNeeded();
    final currentDate = today;
    if (_lastObservedDate == currentDate) return;
    _lastObservedDate = currentDate;
    notifyListeners();
  }

  Future<ExpenseEntry> addExpense({
    required int amountCentavos,
    required ExpenseCategory category,
    required String note,
    required DateTime occurredAt,
    required PaymentMethod paymentMethod,
  }) async {
    _validateMovement(amountCentavos, occurredAt);
    final entry = ExpenseEntry(
      id: _newId('expense'),
      amountCentavos: amountCentavos,
      category: category,
      note: note.trim().isEmpty ? category.label : note.trim(),
      occurredAt: occurredAt,
      paymentMethod: paymentMethod,
    );
    _transactions.add(entry);
    if (_affectsCurrentCash(entry)) expectedCashCentavos -= amountCentavos;
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
      note: note.trim().isEmpty ? kind.label : note.trim(),
      occurredAt: occurredAt,
      destination: destination,
      allocation: allocation,
    );
    _incomes.add(entry);
    _applyIncome(entry, 1);
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
        ? previous.copyWith(category: updated.category, note: updated.note)
        : updated;

    if (_affectsCurrentCash(previous))
      expectedCashCentavos += previous.amountCentavos;
    if (_affectsCurrentCash(next)) expectedCashCentavos -= next.amountCentavos;
    _transactions[index] = next;
    await _save();
    notifyListeners();
  }

  Future<void> classifyPendingCashExpense({
    required String expenseId,
    required ExpenseCategory category,
    required String note,
  }) async {
    final index = _transactions.indexWhere((entry) => entry.id == expenseId);
    if (index == -1 || !_transactions[index].isPendingCashAdjustment) return;
    final previous = _transactions[index];
    _transactions[index] = previous.copyWith(
      category: category,
      note: note.trim().isEmpty ? category.label : note.trim(),
      isPendingCashAdjustment: false,
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
    if (_affectsCurrentCash(removed))
      expectedCashCentavos += removed.amountCentavos;
    await _save();
    notifyListeners();
    return true;
  }

  Future<void> restoreExpense(ExpenseEntry entry) async {
    if (_transactions.any((existing) => existing.id == entry.id)) return;
    _transactions.add(entry);
    if (_affectsCurrentCash(entry))
      expectedCashCentavos -= entry.amountCentavos;
    await _save();
    notifyListeners();
  }

  Future<void> deleteIncome(String id) async {
    final index = _incomes.indexWhere((entry) => entry.id == id);
    if (index == -1) return;
    final removed = _incomes.removeAt(index);
    _applyIncome(removed, -1);
    await _save();
    notifyListeners();
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
    _baseBudgetCentavos = centavos;
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
    if (actualCentavos < 0)
      throw ArgumentError.value(actualCentavos, 'actualCentavos');
    final moment = currentMoment;
    if (!hasCashBaseline) {
      countedCashCentavos = actualCentavos;
      expectedCashCentavos = actualCentavos;
      lastCashCountAt = moment;
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
      await _save();
      notifyListeners();
      return null;
    }

    final reconciliationId = _newId('cash');
    String? linkedExpenseId;
    String? linkedIncomeId;
    if (difference < 0) {
      if (resolution != CashResolution.expense &&
          resolution != CashResolution.pending) {
        throw ArgumentError('A cash shortage must be an expense or pending.');
      }
      final expense = ExpenseEntry(
        id: _newId('expense'),
        amountCentavos: -difference,
        category: category ?? ExpenseCategory.other,
        note: resolution == CashResolution.pending
            ? 'Diferencia por identificar'
            : (note.trim().isEmpty
                  ? (category ?? ExpenseCategory.other).label
                  : note.trim()),
        occurredAt: moment,
        paymentMethod: PaymentMethod.cash,
        cashReconciliationId: reconciliationId,
        isPendingCashAdjustment: resolution == CashResolution.pending,
      );
      _transactions.add(expense);
      linkedExpenseId = expense.id;
    } else if (resolution == CashResolution.income) {
      final income = IncomeEntry(
        id: _newId('income'),
        amountCentavos: difference,
        kind: IncomeKind.cash,
        note: note.trim().isEmpty ? 'Ingreso en efectivo' : note.trim(),
        occurredAt: moment,
        destination: PaymentMethod.cash,
        allocation: incomeAllocation,
        cashReconciliationId: reconciliationId,
      );
      _incomes.add(income);
      _applyIncome(income, 1);
      linkedIncomeId = income.id;
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

  String exportJson() => const JsonEncoder.withIndent('  ').convert(_toJson());
  String? get exportCorruptedJson => corruptedStorage;

  Future<void> configureOnboarding({
    required int budgetCentavos,
    required PaySchedule schedule,
    int? cashCentavos,
  }) async {
    _baseBudgetCentavos = budgetCentavos;
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
    categoryLimits = _categoryLimitsForBudget(budgetCentavos);
    categoryLimitsCustomized = false;
    await _save();
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    hasCompletedOnboarding = true;
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
    notifyListeners();
    return true;
  }

  Future<bool> restoreBackup() async {
    final raw = _preferences.getString(_backupKey);
    if (raw == null || !_tryRestore(raw)) return false;
    hasStorageError = false;
    corruptedStorage = null;
    final saved = await _preferences.setString(_storageKey, raw);
    if (!saved) throw StateError('No se pudo restaurar el respaldo.');
    notifyListeners();
    return true;
  }

  Future<void> startFreshAfterCorruption() async {
    final raw = corruptedStorage;
    if (raw != null) {
      final archived = await _preferences.setString(_corruptArchiveKey, raw);
      if (!archived)
        throw StateError('No se pudo conservar el archivo original.');
    }
    _initializeNewUser();
    hasStorageError = false;
    corruptedStorage = null;
    await _save();
    notifyListeners();
  }

  void _validateMovement(int amountCentavos, DateTime occurredAt) {
    if (amountCentavos <= 0)
      throw ArgumentError.value(amountCentavos, 'amountCentavos');
    if (dateOnly(occurredAt).isAfter(today)) {
      throw ArgumentError('No se permiten movimientos futuros.');
    }
  }

  bool _affectsCurrentCash(ExpenseEntry entry) {
    if (!hasCashBaseline || entry.paymentMethod != PaymentMethod.cash)
      return false;
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

  Future<void> _applyPendingScheduleIfNeeded() async {
    final effectiveAt = pendingPayScheduleEffectiveAt;
    final pending = pendingPaySchedule;
    if (effectiveAt == null || pending == null || today.isBefore(effectiveAt))
      return;
    paySchedule = pending;
    pendingPaySchedule = null;
    pendingPayScheduleEffectiveAt = null;
    payScheduleEffectiveFloor = effectiveAt;
    await _save();
  }

  void _initializeNewUser() {
    _transactions.clear();
    _incomes.clear();
    _cashReconciliations.clear();
    _cycleBudgetExtras.clear();
    _baseBudgetCentavos = 600000;
    countedCashCentavos = 0;
    expectedCashCentavos = 0;
    reducedMotion = false;
    hasCompletedOnboarding = false;
    categoryLimitsCustomized = false;
    successfulCycles = 0;
    lastCashCountAt = null;
    paySchedule = const PaySchedule.semiMonthly();
    pendingPaySchedule = null;
    pendingPayScheduleEffectiveAt = null;
    payScheduleEffectiveFloor = null;
    categoryLimits = _categoryLimitsForBudget(_baseBudgetCentavos);
  }

  bool _tryRestore(String raw) {
    try {
      final candidate = SobraStore._(_preferences, _now);
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
    _cycleBudgetExtras
      ..clear()
      ..addAll(other._cycleBudgetExtras);
    _baseBudgetCentavos = other._baseBudgetCentavos;
    countedCashCentavos = other.countedCashCentavos;
    expectedCashCentavos = other.expectedCashCentavos;
    reducedMotion = other.reducedMotion;
    hasCompletedOnboarding = other.hasCompletedOnboarding;
    categoryLimitsCustomized = other.categoryLimitsCustomized;
    successfulCycles = other.successfulCycles;
    lastCashCountAt = other.lastCashCountAt;
    paySchedule = other.paySchedule;
    pendingPaySchedule = other.pendingPaySchedule;
    pendingPayScheduleEffectiveAt = other.pendingPayScheduleEffectiveAt;
    payScheduleEffectiveFloor = other.payScheduleEffectiveFloor;
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
    _baseBudgetCentavos =
        (json['baseBudgetCentavos'] as num? ??
                json['totalBudgetCentavos'] as num)
            .toInt();
    countedCashCentavos = (json['countedCashCentavos'] as num).toInt();
    expectedCashCentavos = (json['expectedCashCentavos'] as num).toInt();
    reducedMotion = json['reducedMotion'] as bool? ?? false;
    hasCompletedOnboarding = json['hasCompletedOnboarding'] as bool? ?? false;
    categoryLimitsCustomized =
        json['categoryLimitsCustomized'] as bool? ?? false;
    successfulCycles = (json['successfulCycles'] as num?)?.toInt() ?? 0;
    final savedCount = json['lastCashCountAt'] as String?;
    lastCashCountAt = savedCount == null ? null : DateTime.parse(savedCount);
    final scheduleJson = json['paySchedule'] as Map<String, dynamic>?;
    paySchedule = scheduleJson == null
        ? const PaySchedule.semiMonthly(firstPayDay: 1, secondPayDay: 16)
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
    'schemaVersion': 3,
    'transactions': _transactions.map((entry) => entry.toJson()).toList(),
    'incomes': _incomes.map((entry) => entry.toJson()).toList(),
    'cashReconciliations': _cashReconciliations
        .map((entry) => entry.toJson())
        .toList(),
    'baseBudgetCentavos': _baseBudgetCentavos,
    'totalBudgetCentavos': _baseBudgetCentavos,
    'cycleBudgetExtras': _cycleBudgetExtras,
    'countedCashCentavos': countedCashCentavos,
    'expectedCashCentavos': expectedCashCentavos,
    'reducedMotion': reducedMotion,
    'hasCompletedOnboarding': hasCompletedOnboarding,
    'categoryLimitsCustomized': categoryLimitsCustomized,
    'successfulCycles': successfulCycles,
    'lastCashCountAt': lastCashCountAt?.toIso8601String(),
    'paySchedule': paySchedule.toJson(),
    'pendingPaySchedule': pendingPaySchedule?.toJson(),
    'pendingPayScheduleEffectiveAt': pendingPayScheduleEffectiveAt
        ?.toIso8601String(),
    'payScheduleEffectiveFloor': payScheduleEffectiveFloor?.toIso8601String(),
    'categoryLimits': {
      for (final entry in categoryLimits.entries) entry.key.name: entry.value,
    },
  };

  Future<void> _save() async {
    final next = jsonEncode(_toJson());
    final current = _preferences.getString(_storageKey);
    if (current != null && current != next && _isPlausibleState(current)) {
      final backupSaved = await _preferences.setString(_backupKey, current);
      if (!backupSaved) throw StateError('No se pudo guardar el respaldo.');
    }
    final saved = await _preferences.setString(_storageKey, next);
    if (!saved) throw StateError('No se pudieron guardar los datos.');
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
      _cashReconciliations.any((entry) => entry.id == id);
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

class SobraScope extends InheritedNotifier<SobraStore> {
  const SobraScope({super.key, required SobraStore store, required super.child})
    : super(notifier: store);

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
