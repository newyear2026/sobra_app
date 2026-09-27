import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/money_movement.dart';
import '../state/sobra_store.dart';
import '../widgets/pixel_ui.dart';

enum SobraWidgetDestination { home, register, registerExpense, registerIncome }

/// Turns a movement into the line the home screen widget shows.
///
/// The widget is the one surface with no element tree of its own, so the words
/// cannot be built where every other row builds them. The app root hands this
/// in once localizations resolve; see `SobraWidgetSync.localize`.
typedef MovementLabeler = String Function(MoneyMovement movement);

/// The words the home screen widgets show, in the language the app is set to.
///
/// Android resources follow the phone's language, not the one chosen in
/// Ajustes, so a Spanish widget sat next to an English app. The app root hands
/// this in with the movement labeler; see `SobraWidgetSync.localize`.
@immutable
class SobraWidgetCopy {
  const SobraWidgetCopy({
    required this.todayLeft,
    required this.todayLeftShort,
    required this.cycleBalanceShort,
    required this.cycleBalance,
    required this.cycleProgress,
    required this.openApp,
    required this.registerExpense,
    required this.days,
  });

  final String todayLeft;

  /// [todayLeft] and [cycleBalance] for the 2×1 widget, which has room for
  /// about a dozen letters.
  final String todayLeftShort;
  final String cycleBalanceShort;

  /// Replaces [todayLeft] once the cycle is over budget.
  final String cycleBalance;
  final String cycleProgress;

  /// Stands in for the figure before onboarding or without a budget.
  final String openApp;
  final String registerExpense;

  /// "3 days", with the language's own plural.
  final String Function(int count) days;
}

@immutable
class SobraWidgetMovement {
  const SobraWidgetMovement({
    required this.title,
    required this.amountCentavos,
    required this.kind,
  });

  final String title;
  final int amountCentavos;
  final String kind;

  factory SobraWidgetMovement.fromMovement(
    MoneyMovement movement,
    MovementLabeler label,
  ) {
    final kind = switch (movement.type) {
      MovementType.income => 'income',
      MovementType.adjustment => 'adjustment',
      MovementType.expense => movement.expense?.category.name ?? 'expense',
    };
    return SobraWidgetMovement(
      title: label(movement),
      amountCentavos: movement.amountCentavos,
      kind: kind,
    );
  }
}

/// The small, platform-neutral payload rendered by both Android widgets.
///
/// Keeping this separate from the method channel makes the money/date mapping
/// testable without an Android host and gives the native side only primitives.
@immutable
class SobraWidgetSnapshot {
  const SobraWidgetSnapshot({
    required this.hasCompletedOnboarding,
    required this.hasBudget,
    required this.todayRemainingCentavos,
    required this.todayRemainingText,
    required this.noAmountText,
    required this.currencyCode,
    required this.overCycleBudget,
    required this.daysRemaining,
    required this.totalBudgetCentavos,
    required this.totalSpentCentavos,
    required this.progressSegments,
    required this.reducedMotion,
    required this.characterId,
    required this.movements,
    required this.copy,
  });

  final bool hasCompletedOnboarding;

  /// Whether the figures below describe a plan the user actually set.
  ///
  /// Without it every budget-derived number reads zero, and a widget that
  /// cannot tell that apart would show a confident "0 left today".
  final bool hasBudget;

  final int todayRemainingCentavos;

  /// [todayRemainingCentavos] as the app writes it: the currency's own sign
  /// and separators. Written here so the widget cannot drift from the app —
  /// it used to print every currency as dollars in the Mexican style.
  final String todayRemainingText;

  /// What stands in for the figure when there is no budget to slice.
  final String noAmountText;
  final String currencyCode;

  /// Over budget, [todayRemainingCentavos] carries the cycle's deficit rather
  /// than the day's room, so the widget has to relabel the figure too.
  final bool overCycleBudget;
  final int daysRemaining;
  final int totalBudgetCentavos;
  final int totalSpentCentavos;
  final int progressSegments;
  final bool reducedMotion;
  final String characterId;
  final List<SobraWidgetMovement> movements;

  /// Null until the app root resolves localizations. The widget then keeps
  /// its own resource strings, which follow the phone's language.
  final SobraWidgetCopy? copy;

  factory SobraWidgetSnapshot.fromStore(
    SobraStore store,
    MovementLabeler label, {
    SobraWidgetCopy? copy,
  }) {
    final progress = store.budgetProgress.clamp(0.0, 1.0);
    return SobraWidgetSnapshot(
      hasCompletedOnboarding: store.hasCompletedOnboarding,
      hasBudget: store.hasBudget,
      todayRemainingCentavos: store.todayRemainingCentavos,
      todayRemainingText: formatMoney(
        store.currency,
        store.todayRemainingCentavos,
        showCode: false,
      ),
      noAmountText: '${store.currency.symbol}$emDash',
      currencyCode: store.currency.code,
      overCycleBudget: store.remainingBudgetCentavos < 0,
      daysRemaining: store.daysRemaining,
      totalBudgetCentavos: store.totalBudgetCentavos,
      totalSpentCentavos: store.totalSpentCentavos,
      progressSegments: (progress * 10).ceil(),
      reducedMotion: store.reducedMotion,
      characterId: store.characterId,
      movements: store.movements
          .take(2)
          .map((movement) => SobraWidgetMovement.fromMovement(movement, label))
          .toList(growable: false),
      copy: copy,
    );
  }

  Map<String, Object> toPlatformMap() {
    final result = <String, Object>{
      'hasData': hasCompletedOnboarding,
      'hasBudget': hasBudget,
      'todayRemainingCentavos': todayRemainingCentavos,
      'todayRemainingText': todayRemainingText,
      'noAmountText': noAmountText,
      'currencyCode': currencyCode,
      'overCycleBudget': overCycleBudget,
      'daysRemaining': daysRemaining,
      'totalBudgetCentavos': totalBudgetCentavos,
      'totalSpentCentavos': totalSpentCentavos,
      'progressSegments': progressSegments,
      'reducedMotion': reducedMotion,
      'characterId': characterId,
      'movementCount': movements.length,
      // Empty until the app is localized; Android falls back to its own
      // resource strings for an empty one.
      'todayLeftText': copy?.todayLeft ?? '',
      'todayLeftShortText': copy?.todayLeftShort ?? '',
      'cycleBalanceText': copy?.cycleBalance ?? '',
      'cycleBalanceShortText': copy?.cycleBalanceShort ?? '',
      'cycleProgressText': copy?.cycleProgress ?? '',
      'openAppText': copy?.openApp ?? '',
      'registerExpenseText': copy?.registerExpense ?? '',
      'daysRemainingText': copy?.days(daysRemaining) ?? '',
    };
    for (var index = 0; index < movements.length; index++) {
      final movement = movements[index];
      final number = index + 1;
      result
        ..['movement${number}Title'] = movement.title
        ..['movement${number}AmountCentavos'] = movement.amountCentavos
        ..['movement${number}Kind'] = movement.kind;
    }
    return result;
  }
}

/// Bridges Sobra's persisted Flutter state into Android RemoteViews.
///
/// A missing platform implementation is deliberately non-fatal so the same
/// application still runs on iOS, web and in Flutter tests.
abstract final class SobraWidgetSync {
  static const _channel = MethodChannel('com.sobra.app/widgets');
  static final destination = ValueNotifier<SobraWidgetDestination?>(null);

  static SobraStore? _store;
  static bool _initialized = false;
  static MovementLabeler _label = _untitled;
  static SobraWidgetCopy? _copy;

  /// Until the app root resolves localizations there is nothing to call a
  /// movement, and a widget row without its title still shows the amount.
  static String _untitled(MoneyMovement movement) => '';

  /// Set once the app can name a movement, and again whenever the locale
  /// changes, which re-pushes the payload so the widget follows the app.
  static void localize(MovementLabeler label, SobraWidgetCopy copy) {
    if (identical(_label, label) && identical(_copy, copy)) return;
    _label = label;
    _copy = copy;
    unawaited(_sync());
  }

  static Future<void> initialize(SobraStore store) async {
    if (!_initialized) {
      _channel.setMethodCallHandler(_handlePlatformCall);
      _initialized = true;
    }
    if (!identical(_store, store)) {
      _store?.removeListener(_onStoreChanged);
      _store = store..addListener(_onStoreChanged);
    }

    await _sync();
    try {
      final pending = await _channel.invokeMethod<String>(
        'getPendingDestination',
      );
      _setDestination(pending);
    } on Object {
      // Android is the only platform with a Sobra home-screen widget.
    }
  }

  static void consumeDestination(SobraWidgetDestination value) {
    if (destination.value == value) destination.value = null;
  }

  static void _onStoreChanged() => unawaited(_sync());

  static Future<void> _sync() async {
    final store = _store;
    if (store == null) return;
    try {
      await _channel.invokeMethod<void>(
        'updateWidgets',
        SobraWidgetSnapshot.fromStore(
          store,
          _label,
          copy: _copy,
        ).toPlatformMap(),
      );
    } on Object {
      // Widget sync must never prevent the budget itself from being saved.
    }
  }

  static Future<Object?> _handlePlatformCall(MethodCall call) async {
    if (call.method == 'openDestination') {
      _setDestination(call.arguments as String?);
    }
    return null;
  }

  static void _setDestination(String? raw) {
    final value = switch (raw) {
      'register' => SobraWidgetDestination.register,
      'register_expense' => SobraWidgetDestination.registerExpense,
      'register_income' => SobraWidgetDestination.registerIncome,
      'home' => SobraWidgetDestination.home,
      _ => null,
    };
    if (value != null) destination.value = value;
  }
}
