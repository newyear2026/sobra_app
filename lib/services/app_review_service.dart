import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/cycle_record.dart';

/// What the app needs from the store to be rated, with the plugin held at
/// arm's length.
abstract interface class AppReviewPort {
  /// Asks Play for its in-app review sheet.
  ///
  /// Play alone decides whether the sheet appears, on a quota it does not
  /// publish, and it never reports either way — nor whether anyone rated.
  /// Completing is therefore not evidence of anything.
  Future<void> requestReview();

  /// Hands the user to the store page. False when nothing could be opened.
  Future<bool> openStore();
}

/// When Sobra asks to be rated.
///
/// The rules, in one place because they only make sense together:
///
/// * Only right after a cycle closed with money left over. That is the one
///   moment the app has something good to say, and asking after an overspent
///   cycle would be asking somebody to rate the app that just told them so.
/// * At most once every [quietPeriod]. Play keeps its own quota, but it is
///   unpublished and it is not ours; a weekly cycle would otherwise knock on
///   Play's door every week.
/// * Never again once the user has opened the listing from Ajustes. They went
///   to the store on their own, which is the answer this was asking for.
/// * No Sobra dialog in front of Play's sheet. A "do you like Sobrita?" gate
///   that routes only the happy to the store is exactly what Play's policy
///   forbids.
class AppReviews {
  AppReviews({
    required AppReviewPort port,
    SharedPreferences? preferences,
    DateTime Function()? now,
  }) : _port = port,
       _preferences = preferences,
       _now = now ?? DateTime.now {
    final asked = _preferences?.getInt(_askedAtKey);
    _askedAt = asked == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(asked);
    _visitedStore = _preferences?.getBool(_visitedStoreKey) ?? false;
  }

  static const quietPeriod = Duration(days: 120);
  static const _askedAtKey = 'sobra_review_asked_at';
  static const _visitedStoreKey = 'sobra_review_visited_store';

  final AppReviewPort _port;

  /// Device bookkeeping, like the update check's, and kept out of the ledger
  /// for the same reason: a backup restored onto a new phone should not carry
  /// "already asked" along with the money.
  final SharedPreferences? _preferences;
  final DateTime Function() _now;

  DateTime? _askedAt;
  bool _visitedStore = false;

  /// Whether [afterSettlement] would ask for [record] right now.
  bool wouldAskAfter(CycleRecord? record) {
    if (record == null || record.resultCentavos < 0) return false;
    if (_visitedStore) return false;
    final asked = _askedAt;
    return asked == null || _now().difference(asked) >= quietPeriod;
  }

  /// Called once the settlement screen has closed, so the sheet lands on
  /// Inicio rather than on top of the result it would be interrupting.
  Future<void> afterSettlement(CycleRecord? record) async {
    if (!wouldAskAfter(record)) return;
    // Spent before the request, not after: Play does not say whether the
    // sheet appeared, so the attempt is the only thing there is to count.
    _askedAt = _now();
    await _persist();
    try {
      await _port.requestReview();
    } on Object catch (error) {
      debugPrint('Sobra: could not ask Play for a review: $error');
    }
  }

  /// The Ajustes row. False when nothing could be opened.
  Future<bool> openStore() async {
    final opened = await _port.openStore();
    if (opened && !_visitedStore) {
      _visitedStore = true;
      await _persist();
    }
    return opened;
  }

  /// Best-effort: a phone that will not save this asks once more than it had
  /// to, which is not worth an error path.
  Future<void> _persist() async {
    final preferences = _preferences;
    if (preferences == null) return;
    try {
      final asked = _askedAt;
      if (asked != null) {
        await preferences.setInt(_askedAtKey, asked.millisecondsSinceEpoch);
      }
      if (_visitedStore) await preferences.setBool(_visitedStoreKey, true);
    } on Object catch (error) {
      debugPrint('Sobra: could not save the review state: $error');
    }
  }
}

/// Null above a screen means there is no store to be rated in — every
/// platform but Android, and any harness that does not provide one. The row
/// is then absent and nothing is ever asked.
class AppReviewScope extends InheritedWidget {
  const AppReviewScope({
    super.key,
    required this.reviews,
    required super.child,
  });

  final AppReviews reviews;

  static AppReviews? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppReviewScope>()?.reviews;

  @override
  bool updateShouldNotify(AppReviewScope oldWidget) =>
      reviews != oldWidget.reviews;
}
