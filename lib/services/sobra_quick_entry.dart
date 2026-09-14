import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// The small piece of localized copy rendered by Android's lock-screen
/// notification.
///
/// Android owns the card, typography and spacing. Flutter only supplies the
/// words so the notification follows Sobra's in-app language choice.
@immutable
class SobraQuickEntryCopy {
  const SobraQuickEntryCopy({
    required this.question,
    required this.income,
    required this.expense,
  });

  final String question;
  final String income;
  final String expense;

  Map<String, String> toPlatformMap() => {
    'question': question,
    'income': income,
    'expense': expense,
  };

  @override
  bool operator ==(Object other) =>
      other is SobraQuickEntryCopy &&
      other.question == question &&
      other.income == income &&
      other.expense == expense;

  @override
  int get hashCode => Object.hash(question, income, expense);
}

/// Controls Android's opt-in, ongoing quick-entry notification.
///
/// The platform channel is deliberately non-fatal: iOS, web and widget tests
/// can all run the same Flutter tree without an Android notification host.
abstract final class SobraQuickEntry {
  static const _channel = MethodChannel('com.sobra.app/quick_entry');

  static final enabled = ValueNotifier<bool>(false);

  static bool _initialized = false;
  static SobraQuickEntryCopy? _copy;

  static Future<void> initialize() async {
    _initialized = true;
    try {
      enabled.value =
          await _channel.invokeMethod<bool>('getQuickEntryEnabled') ?? false;
      await _pushCopy();
    } on Object {
      enabled.value = false;
    }
  }

  static set copy(SobraQuickEntryCopy value) {
    if (_copy == value) return;
    _copy = value;
    if (_initialized) unawaited(_pushCopy());
  }

  /// Returns whether Android reached the state the user requested.
  ///
  /// Enabling can return false when notification permission is denied. Turning
  /// it off returns true once the notification is cancelled.
  static Future<bool> setEnabled(bool value) async {
    try {
      final actual =
          await _channel.invokeMethod<bool>('setQuickEntryEnabled', value) ??
          false;
      enabled.value = actual;
      return actual == value;
    } on Object {
      enabled.value = false;
      return !value;
    }
  }

  static Future<void> _pushCopy() async {
    final copy = _copy;
    if (copy == null) return;
    try {
      await _channel.invokeMethod<void>(
        'updateQuickEntryCopy',
        copy.toPlatformMap(),
      );
    } on Object {
      // The notification is Android-only; localized copy must never block app
      // startup or a ledger write on the other platforms.
    }
  }
}
