import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../data/costume_motion_atlases.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/character_costume.dart';
import '../state/sobra_store.dart';

/// The one notification the seasonal gift gets: on its last morning, to
/// whoever has not opened it yet.
///
/// Only the last day, because that is the only one where saying nothing costs
/// the user something. It never asks for notification permission either; a
/// gift is not a reason to, so it reaches the phones that already said yes
/// for fixed-expense reminders and quietly skips the rest.
@immutable
class PlannedSeasonalReminder {
  const PlannedSeasonalReminder({
    required this.at,
    required this.title,
    required this.body,
    required this.iconAsset,
    required this.iconSource,
  });

  final DateTime at;
  final String title;
  final String body;

  /// The costume atlas the large icon is cut from, and the normalized rect of
  /// its poster frame. Android crops it itself, so nothing is rendered here.
  final String iconAsset;
  final Rect iconSource;

  Map<String, Object> toPlatformMap() => {
    'at': at.millisecondsSinceEpoch,
    'title': title,
    'body': body,
    'iconAsset': iconAsset,
    'iconSource': [
      iconSource.left,
      iconSource.top,
      iconSource.width,
      iconSource.height,
    ],
  };

  @override
  bool operator ==(Object other) =>
      other is PlannedSeasonalReminder &&
      other.at == at &&
      other.title == title &&
      other.body == body &&
      other.iconAsset == iconAsset &&
      other.iconSource == iconSource;

  @override
  int get hashCode => Object.hash(at, title, body, iconAsset, iconSource);
}

/// The reminder this ledger is owed right now, or null for none.
///
/// None once the costumes are claimed, before onboarding is finished, and
/// once its moment has passed. The icon is the companion on screen, in its
/// own costume.
@visibleForTesting
PlannedSeasonalReminder? planSeasonalGiftReminder({
  required SobraStore store,
  required AppLocalizations l10n,
}) {
  if (!store.hasCompletedOnboarding || store.hasClaimedSeasonalCostumes) {
    return null;
  }
  final at = CharacterCostumes.lastDayReminderAt;
  if (!store.currentMoment.isBefore(at)) return null;

  final costume =
      CharacterCostumes.forCharacter(store.characterId).firstOrNull ??
      CharacterCostumes.all.first;
  final idle = costumeMotionAtlases[costume.characterId]!['idle']!;
  return PlannedSeasonalReminder(
    at: at,
    title: l10n.seasonalGiftLastDayTitle,
    body: l10n.seasonalGiftLastDayBody(CharacterCostumes.all.length),
    iconAsset: idle.asset,
    iconSource: idle.sources[idle.posterFrame],
  );
}

/// Hands the planned reminder to Android, or takes it back.
///
/// Non-fatal like [SobraFixedReminders]: no ledger write waits on it.
abstract final class SeasonalGiftReminder {
  static const _channel = MethodChannel('com.sobra.app/seasonal_reminder');

  static SobraStore? _store;
  static AppLocalizations? _l10n;
  static bool _synced = false;
  static PlannedSeasonalReminder? _pushed;

  static void initialize(SobraStore store) {
    if (identical(_store, store)) return;
    _store?.removeListener(_onStoreChanged);
    _store = store..addListener(_onStoreChanged);
    unawaited(_sync());
  }

  /// Set once localizations resolve, and again when the language changes.
  static void localize(AppLocalizations l10n) {
    if (identical(_l10n, l10n)) return;
    _l10n = l10n;
    unawaited(_sync());
  }

  static void _onStoreChanged() => unawaited(_sync());

  static Future<void> _sync() async {
    final store = _store;
    final l10n = _l10n;
    if (store == null || l10n == null || store.hasStorageError) return;
    final plan = planSeasonalGiftReminder(store: store, l10n: l10n);
    // The first sync always goes through: a claim on the last run may have
    // left an alarm behind that only a cancel clears.
    if (_synced && plan == _pushed) return;
    _synced = true;
    _pushed = plan;
    try {
      if (plan == null) {
        await _channel.invokeMethod<void>('cancel');
      } else {
        await _channel.invokeMethod<void>('schedule', plan.toPlatformMap());
      }
    } on Object {
      // Android is the only platform with this reminder.
      _synced = false;
    }
  }
}
