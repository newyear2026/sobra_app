import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
/// * Once, ever. The first attempt is remembered on the device and nothing
///   asks again, whether or not Play showed its sheet.
/// * Not before a day of use: something recorded, and a later calendar day
///   than the one the app was first opened on. Asking on the first day would
///   be asking about an app nobody has lived with yet.
/// * Never once the user has opened the listing from Ajustes. They went to
///   the store on their own, which is the answer this was asking for.
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

  /// Whether [askAfterFirstDay] would ask with these facts about the user.
  ///
  /// [firstOpenedOn] is the day the app was first opened; [recordedDays] how
  /// many days have a movement on them.
  bool wouldAsk({required DateTime? firstOpenedOn, required int recordedDays}) {
    if (_askedAt != null || _visitedStore) return false;
    if (firstOpenedOn == null || recordedDays < 1) return false;
    final now = _now();
    final today = DateTime(now.year, now.month, now.day);
    final first = DateTime(
      firstOpenedOn.year,
      firstOpenedOn.month,
      firstOpenedOn.day,
    );
    return today.isAfter(first);
  }

  /// Asks Play for its sheet if [wouldAsk] says so, and never again after.
  Future<void> askAfterFirstDay({
    required DateTime? firstOpenedOn,
    required int recordedDays,
  }) async {
    if (!wouldAsk(firstOpenedOn: firstOpenedOn, recordedDays: recordedDays)) {
      return;
    }
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
