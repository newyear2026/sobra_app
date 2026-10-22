import 'package:flutter/foundation.dart';

enum TelemetryScreen {
  welcome,
  onboarding,
  recovery,
  home,
  movements,
  register,
  budget,
  settings,

  /// Pushed over a tab rather than one itself. `origin`: a
  /// `CollectionOrigin`.
  collection,
}

enum TelemetryEvent {
  onboardingCompleted('tutorial_complete'),

  /// How a first-expense prompt ended. `origin`: a `FirstExpenseOrigin`;
  /// `result`: a `FirstExpenseResult`.
  firstExpense('first_expense'),
  expenseRecorded('expense_recorded'),
  incomeRecorded('income_recorded'),

  /// How a rewarded-ad run ended. `result`: a `RewardedAdOutcome`; `kind`:
  /// the catalog kind the ad was for.
  rewardedAdResult('rewarded_ad_result'),

  /// SDK lifecycle, separate from the reward actually credited by the store.
  /// `stage`: a `RewardedAdStage`; optional `reason`: a `RewardedAdFailure`.
  rewardedAdLifecycle('rewarded_ad_lifecycle'),

  /// An entry became owned through Sobra's own rules. `method`: how; `kind`:
  /// what. Paid ones are already Firebase's automatic `in_app_purchase`.
  itemUnlocked('item_unlocked'),

  /// Play's checkout was opened. Set against `in_app_purchase` for the share
  /// that finishes paying.
  purchaseStarted('purchase_started'),
  fixedExpenseAdded('fixed_expense_added'),
  fixedPaymentRecorded('fixed_payment_recorded'),

  /// One budget cycle closed.
  cycleSettled('cycle_settled'),

  /// The app was opened from a widget, the lock-screen entry or a reminder.
  /// `destination`: where it was sent.
  shortcutOpened('shortcut_opened'),

  /// The share sheet closed. `origin`: a `ShareOrigin`; `result`: the
  /// platform's `ShareResultStatus`.
  shared('share');

  const TelemetryEvent(this.eventName);
  final String eventName;
}

typedef EventSender = Future<void> Function(String, Map<String, Object>);
typedef ErrorSender = Future<void> Function(String, StackTrace, bool);

/// Only fixed event names and screen names cross this boundary. Budget amounts,
/// notes, receipts, purchase tokens and user identifiers are never parameters.
class AppTelemetry {
  AppTelemetry({this.sendEvent, this.sendError});

  static AppTelemetry instance = AppTelemetry();

  final EventSender? sendEvent;
  final ErrorSender? sendError;

  Future<void> screen(
    TelemetryScreen screen, [
    Map<String, Enum> parameters = const {},
  ]) => _safely(
    () => sendEvent?.call('screen_view', {
      'screen_name': screen.name,
      'screen_class': 'Sobrita',
      for (final MapEntry(:key, :value) in parameters.entries) key: value.name,
    }),
  );

  /// Parameters are enum values only, sent by name. No caller can pass an
  /// amount, a note or any text a user typed, because none of them is one.
  Future<void> event(
    TelemetryEvent event, [
    Map<String, Enum> parameters = const {},
  ]) => _safely(
    () => sendEvent?.call(event.eventName, {
      for (final MapEntry(:key, :value) in parameters.entries) key: value.name,
    }),
  );

  Future<void> reportError(
    Object error,
    StackTrace stack, {
    bool fatal = false,
  }) => _safely(
    () => sendError?.call(error.runtimeType.toString(), stack, fatal),
  );

  // Exception messages can contain a rejected amount, a note or file contents.
  // Preserve the error type and stack for diagnosis without sending that text.
  Future<void> _safely(Future<void>? Function() action) async {
    try {
      await action();
    } on Object catch (error) {
      debugPrint('Telemetry unavailable: ${error.runtimeType}');
    }
  }
}
