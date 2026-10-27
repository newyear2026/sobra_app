import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

/// Controls Android's ongoing quick-entry notification.
///
/// On by default, once: nobody finds a lock-screen shortcut they have never
/// seen, so every user gets it one time and Ajustes turns it off. Where Android
/// has to ask for notification permission, the asking waits for the next
/// saved record, when what the shortcut is for is obvious.
///
/// The platform channel is deliberately non-fatal: iOS, web and widget tests
/// can all run the same Flutter tree without an Android notification host.
abstract final class SobraQuickEntry {
  static const _channel = MethodChannel('com.sobra.app/quick_entry');

  /// `pending` while the default waits on a record to ask for permission,
  /// `done` once it has been applied or asked for.
  static const _defaultKey = 'sobra_quick_entry_default_on';

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

  /// Turns the shortcut on, once ever, for someone past onboarding.
  static Future<void> applyDefaultOnce() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      if (preferences.getString(_defaultKey) != null) return;
      if (enabled.value) {
        await preferences.setString(_defaultKey, 'done');
        return;
      }
      final needsPermission =
          await _channel.invokeMethod<bool>('needsQuickEntryPermission') ??
          false;
      if (needsPermission) {
        await preferences.setString(_defaultKey, 'pending');
        return;
      }
      await preferences.setString(_defaultKey, 'done');
      await setEnabled(true);
    } on Object {
      // No Android host, or nothing to remember it in: the toggle stays off.
    }
  }

  /// After a saved record, asks for the permission the default is waiting on.
  /// Once: a "no" here is not asked again, and Ajustes still has the toggle.
  static Future<void> offerAfterRecord() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      if (preferences.getString(_defaultKey) != 'pending') return;
      await preferences.setString(_defaultKey, 'done');
      if (!enabled.value) await setEnabled(true);
    } on Object {
      // Same as above: the shortcut is a convenience, never a failed save.
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
