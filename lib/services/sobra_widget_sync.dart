import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/money_movement.dart';
import '../state/sobra_store.dart';

enum SobraWidgetDestination { home, register }

/// Turns a movement into the line the home screen widget shows.
///
/// The widget is the one surface with no element tree of its own, so the words
/// cannot be built where every other row builds them. The app root hands this
/// in once localizations resolve; see `SobraWidgetSync.movementLabeler`.
typedef MovementLabeler = String Function(MoneyMovement movement);

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
    required this.overCycleBudget,
    required this.daysRemaining,
    required this.totalBudgetCentavos,
    required this.totalSpentCentavos,
    required this.progressSegments,
    required this.reducedMotion,
    required this.movements,
  });

  final bool hasCompletedOnboarding;

  /// Whether the figures below describe a plan the user actually set.
  ///
  /// Without it every budget-derived number reads zero, and a widget that
  /// cannot tell that apart would show a confident "0 left today".
  final bool hasBudget;

  final int todayRemainingCentavos;

  /// Over budget, [todayRemainingCentavos] carries the cycle's deficit rather
  /// than the day's room, so the widget has to relabel the figure too.
  final bool overCycleBudget;
  final int daysRemaining;
  final int totalBudgetCentavos;
  final int totalSpentCentavos;
  final int progressSegments;
  final bool reducedMotion;
  final List<SobraWidgetMovement> movements;

  factory SobraWidgetSnapshot.fromStore(
    SobraStore store,
    MovementLabeler label,
  ) {
    final progress = store.budgetProgress.clamp(0.0, 1.0);
    return SobraWidgetSnapshot(
      hasCompletedOnboarding: store.hasCompletedOnboarding,
      hasBudget: store.hasBudget,
      todayRemainingCentavos: store.todayRemainingCentavos,
      overCycleBudget: store.remainingBudgetCentavos < 0,
      daysRemaining: store.daysRemaining,
      totalBudgetCentavos: store.totalBudgetCentavos,
      totalSpentCentavos: store.totalSpentCentavos,
      progressSegments: (progress * 10).ceil(),
      reducedMotion: store.reducedMotion,
      movements: store.movements
          .take(2)
          .map((movement) => SobraWidgetMovement.fromMovement(movement, label))
          .toList(growable: false),
    );
  }

  Map<String, Object> toPlatformMap() {
    final result = <String, Object>{
      'hasData': hasCompletedOnboarding,
      'hasBudget': hasBudget,
      'todayRemainingCentavos': todayRemainingCentavos,
      'overCycleBudget': overCycleBudget,
      'daysRemaining': daysRemaining,
      'totalBudgetCentavos': totalBudgetCentavos,
      'totalSpentCentavos': totalSpentCentavos,
      'progressSegments': progressSegments,
      'reducedMotion': reducedMotion,
      'movementCount': movements.length,
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

  /// Until the app root resolves localizations there is nothing to call a
  /// movement, and a widget row without its title still shows the amount.
  static String _untitled(MoneyMovement movement) => '';

  /// Set once the app can name a movement, and again whenever the locale
  /// changes, which re-pushes the payload so the widget follows the app.
  static set movementLabeler(MovementLabeler value) {
    if (identical(_label, value)) return;
    _label = value;
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
        SobraWidgetSnapshot.fromStore(store, _label).toPlatformMap(),
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
      'home' => SobraWidgetDestination.home,
      _ => null,
    };
    if (value != null) destination.value = value;
  }
}
