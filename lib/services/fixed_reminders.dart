import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../l10n/generated/app_localizations.dart';
import '../l10n/labels.dart';
import '../models/currency.dart';
import '../models/recurring_expense.dart';
import '../state/sobra_store.dart';
import '../widgets/pixel_ui.dart';

/// One reminder Android should post, fully worded.
///
/// Worded here rather than on the device: the notification has to follow the
/// language chosen inside Sobra, and Android only knows the phone's.
@immutable
class PlannedReminder {
  const PlannedReminder({
    required this.id,
    required this.at,
    required this.title,
    required this.body,
  });

  /// Stable for the same bill and due date, so rescheduling replaces an alarm
  /// instead of stacking a second one beside it.
  final int id;
  final DateTime at;
  final String title;
  final String body;

  Map<String, Object> toPlatformMap() => {
    'id': id,
    'at': at.millisecondsSinceEpoch,
    'title': title,
    'body': body,
  };

  @override
  bool operator ==(Object other) =>
      other is PlannedReminder &&
      other.id == id &&
      other.at == at &&
      other.title == title &&
      other.body == body;

  @override
  int get hashCode => Object.hash(id, at, title, body);
}

/// The hour every reminder fires at, local time.
///
/// Morning, so a bill due today is known before the day's spending starts.
const fixedReminderHour = 9;

/// How far ahead reminders are handed to Android.
///
/// Long enough to cover a two-monthly bill and a few weeks of the app going
/// unopened; every launch and every change pushes a fresh window.
const fixedReminderHorizonDays = 70;

/// Android keeps every alarm in memory, so there is a ceiling on how many one
/// app should hold. Weekly bills over ten weeks are what get near it.
const fixedReminderLimit = 40;

/// Days between the reminder and the due date.
int fixedReminderLeadDays(FixedReminder reminder) => switch (reminder) {
  FixedReminder.none => 0,
  FixedReminder.sameDay => 0,
  FixedReminder.dayBefore => 1,
  FixedReminder.threeDaysBefore => 3,
};

/// Every reminder still to come for the unpaid due dates ahead.
///
/// A date already paid gets none, and neither does a reminder whose moment
/// has passed: the payment is never filed on the user's behalf, so a
/// reminder is only ever a nudge to open Sobra and say so.
List<PlannedReminder> planFixedReminders({
  required SobraStore store,
  required AppLocalizations l10n,
}) {
  final now = store.currentMoment;
  final today = store.today;
  final currency = store.currency;
  final last = DateTime(
    today.year,
    today.month,
    today.day + fixedReminderHorizonDays,
  );
  final planned = <PlannedReminder>[];
  for (final occurrence in store.fixedOccurrencesBetween(today, last)) {
    final expense = occurrence.expense;
    if (occurrence.isPaid || expense.reminder == FixedReminder.none) continue;
    final lead = fixedReminderLeadDays(expense.reminder);
    final date = occurrence.date;
    final at = DateTime(
      date.year,
      date.month,
      date.day - lead,
      fixedReminderHour,
    );
    if (!at.isAfter(now)) continue;
    planned.add(
      PlannedReminder(
        id: fixedReminderId(expense.id, date),
        at: at,
        title: _title(l10n, expense.name, lead),
        body: l10n.fixedReminderBody(
          _amount(l10n, currency, expense),
          expense.paymentMethod.label(l10n),
        ),
      ),
    );
  }
  planned.sort((a, b) => a.at.compareTo(b.at));
  return planned.take(fixedReminderLimit).toList();
}

String _title(AppLocalizations l10n, String name, int lead) => switch (lead) {
  0 => l10n.fixedReminderTitleToday(name),
  1 => l10n.fixedReminderTitleTomorrow(name),
  _ => l10n.fixedReminderTitleInDays(name, lead),
};

String _amount(
  AppLocalizations l10n,
  Currency currency,
  RecurringExpense expense,
) {
  final amount = formatMoney(currency, expense.amountCentavos);
  return expense.isVariable ? l10n.fixedApprox(amount) : amount;
}

/// A 31-bit notification id for one due date of one bill.
///
/// FNV-1a over the pair rather than [String.hashCode], which Dart does not
/// promise to keep the same from one run to the next.
@visibleForTesting
int fixedReminderId(String expenseId, DateTime date) {
  var hash = 0x811c9dc5;
  final key = '$expenseId|${dayKey(date)}';
  for (final unit in utf8.encode(key)) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0xffffffff;
  }
  return hash & 0x7fffffff;
}

/// Hands the planned reminders to Android and asks for permission to post.
///
/// Every call is non-fatal: tests, web and a phone that refuses alarms all run
/// the same app, and none of them may lose a ledger write over a reminder.
abstract final class SobraFixedReminders {
  static const _channel = MethodChannel('com.sobra.app/fixed_reminders');

  static SobraStore? _store;
  static AppLocalizations? _l10n;
  static List<PlannedReminder>? _pushed;

  static void initialize(SobraStore store) {
    if (identical(_store, store)) return;
    _store?.removeListener(_onStoreChanged);
    _store = store..addListener(_onStoreChanged);
    unawaited(_sync());
  }

  /// Set once localizations resolve, and again when the language changes,
  /// which rewords every pending reminder.
  static void localize(AppLocalizations l10n) {
    if (identical(_l10n, l10n)) return;
    _l10n = l10n;
    unawaited(_sync());
  }

  /// Whether Android will show a reminder, asking for permission if it has
  /// not been answered yet.
  static Future<bool> requestPermission() async {
    try {
      return await _channel.invokeMethod<bool>('requestPermission') ?? false;
    } on Object {
      return false;
    }
  }

  static void _onStoreChanged() => unawaited(_sync());

  static Future<void> _sync() async {
    final store = _store;
    final l10n = _l10n;
    if (store == null || l10n == null) return;
    final plan = planFixedReminders(store: store, l10n: l10n);
    if (listEquals(plan, _pushed)) return;
    _pushed = plan;
    try {
      await _channel.invokeMethod<void>('schedule', [
        for (final reminder in plan) reminder.toPlatformMap(),
      ]);
    } on Object {
      // Android is the only platform with these reminders. Forget what was
      // pushed so the next change tries again.
      _pushed = null;
    }
  }
}
