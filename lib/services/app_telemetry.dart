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
}

enum TelemetryEvent {
  onboardingCompleted('tutorial_complete'),
  expenseRecorded('expense_recorded'),
  incomeRecorded('income_recorded');

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

  Future<void> screen(TelemetryScreen screen) => _safely(
    () => sendEvent?.call('screen_view', {
      'screen_name': screen.name,
      'screen_class': 'Sobrita',
    }),
  );

  Future<void> event(TelemetryEvent event) =>
      _safely(() => sendEvent?.call(event.eventName, const {}));

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
