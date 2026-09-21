import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_version_service.dart';

/// An update waiting in the store, identified by the build behind it.
///
/// A `versionCode` rather than a version name because that is all Play hands
/// over: `AppUpdateInfo.availableVersionCode` is the code of the build sitting
/// in the store, and no API turns it into the `1.2.0` a user would recognise.
/// So it is never shown. It is the identity a dismissal is remembered against
/// — dismiss this update and the next one still asks — and nothing else.
@immutable
class PendingUpdate {
  const PendingUpdate({required this.versionCode, this.stalenessDays});

  final int versionCode;

  /// Days since the Play Store on this phone first heard about the update, or
  /// null when Play will not say. Unused by the policy below; kept because it
  /// is the only honest input a "this build is getting old" rule could ever
  /// have, and recomputing it later would mean another round trip.
  final int? stalenessDays;

  @override
  bool operator ==(Object other) =>
      other is PendingUpdate &&
      other.versionCode == versionCode &&
      other.stalenessDays == stalenessDays;

  @override
  int get hashCode => Object.hash(versionCode, stalenessDays);
}

/// What the app needs from the store, with the plugin held at arm's length.
///
/// Everything behind this is Android- and Play-specific, and unavailable far
/// more often than it is available: `InAppUpdate.checkForUpdate` throws on any
/// build Play did not install, which is every debug run, every sideload and
/// the entire test suite.
abstract interface class AppUpdatePort {
  /// The update waiting in the store, or null when there is none.
  ///
  /// Also null when the question could not be asked at all. The two are one
  /// case here deliberately: an app that cannot reach Play has nothing to
  /// offer the user either way, and surfacing the failure would turn a phone
  /// without Play services into a phone that complains on every launch.
  Future<PendingUpdate?> check();

  /// Hands the user to the store page. False when nothing could be opened.
  Future<bool> openStore();
}

/// The port for builds with no store behind them — iOS, web, tests.
final class UnavailableUpdatePort implements AppUpdatePort {
  const UnavailableUpdatePort();

  @override
  Future<PendingUpdate?> check() async => null;

  @override
  Future<bool> openStore() async => false;
}

/// When Sobra mentions an update, and how insistently.
///
/// The rules, in one place because they only make sense together:
///
/// * The store is asked at most once per local day. A ledger that works
///   offline should not spend a round trip on every cold start.
/// * The dialog interrupts once per update. "Ahora no" is remembered against
///   that update's [PendingUpdate.versionCode], so the same update never
///   interrupts twice — and the one after it still gets to.
/// * A dismissed update stays visible as the banner, which is a line of text
///   rather than a wall. Closing the banner lasts the session; it comes back
///   on the next launch, which is the most this is allowed to nag.
/// * Nothing here can block the app. There is no forced update, because there
///   is no server for an old build to be wrong about.
class AppUpdates extends ChangeNotifier {
  AppUpdates({
    required AppUpdatePort port,
    SharedPreferences? preferences,
    DateTime Function()? now,
    AppVersionLoader versionLoader = loadAppVersion,
  }) : _port = port,
       _preferences = preferences,
       _now = now ?? DateTime.now,
       _versionLoader = versionLoader {
    _restore();
  }

  static const _checkedDayKey = 'sobra_update_checked_day';
  static const _dismissedCodeKey = 'sobra_update_dismissed_version_code';
  static const _pendingCodeKey = 'sobra_update_pending_version_code';

  final AppUpdatePort _port;

  /// Deliberately not the ledger's own storage. This is device bookkeeping,
  /// not user data: it must not ride along in a backup, where a restored
  /// "already dismissed" would silence a real update on a different phone,
  /// and it must not grow the blob that has a corruption-recovery path.
  final SharedPreferences? _preferences;
  final DateTime Function() _now;

  /// Only ever asked what build is running, and only to throw away an offer
  /// that has already been installed. See [_restorePending].
  final AppVersionLoader _versionLoader;

  PendingUpdate? _pending;
  String? _checkedDay;
  int? _dismissedVersionCode;
  bool _promptShown = false;
  bool _promptVisible = false;
  bool _bannerHidden = false;
  bool _checking = false;
  bool _pendingRestored = false;

  PendingUpdate? get pending => _pending;

  /// True while a check is in flight, for the Ajustes row to show it.
  bool get isChecking => _checking;

  /// Whether the dialog should interrupt right now.
  bool get shouldPrompt =>
      _pending != null &&
      !_promptShown &&
      _pending!.versionCode != _dismissedVersionCode;

  /// Whether the quiet line belongs at the top of Inicio.
  ///
  /// Never at the same time as the dialog. [_promptShown] alone is not enough
  /// to decide that: it is set before the dialog opens, so between that and
  /// the dialog closing the banner would be drawing behind the scrim — two
  /// copies of the same news, one of them legible over the dim. Hence the
  /// second flag, which is true for exactly as long as the dialog is up.
  bool get showBanner =>
      _pending != null && !_bannerHidden && !shouldPrompt && !_promptVisible;

  String _dayKey(DateTime moment) =>
      '${moment.year.toString().padLeft(4, '0')}-'
      '${moment.month.toString().padLeft(2, '0')}-'
      '${moment.day.toString().padLeft(2, '0')}';

  void _restore() {
    final preferences = _preferences;
    if (preferences == null) return;
    _checkedDay = preferences.getString(_checkedDayKey);
    _dismissedVersionCode = preferences.getInt(_dismissedCodeKey);
  }

  /// Best-effort, like every other write in this app that is not the ledger.
  ///
  /// A phone that will not persist this asks the store once more than it had
  /// to, or interrupts once more than it had to. Neither is worth an error
  /// path, and neither is worth an exception escaping a post-frame callback.
  Future<void> _persist() async {
    final preferences = _preferences;
    if (preferences == null) return;
    try {
      final day = _checkedDay;
      if (day != null) await preferences.setString(_checkedDayKey, day);
      final dismissed = _dismissedVersionCode;
      if (dismissed == null) {
        await preferences.remove(_dismissedCodeKey);
      } else {
        await preferences.setInt(_dismissedCodeKey, dismissed);
      }
      final pending = _pending;
      if (pending == null) {
        await preferences.remove(_pendingCodeKey);
      } else {
        await preferences.setInt(_pendingCodeKey, pending.versionCode);
      }
    } on Object catch (error) {
      debugPrint('Sobra: could not save the update check state: $error');
    }
  }

  /// Asks the store, unless it has already been asked today.
  ///
  /// [force] is the Ajustes row: the user asked, so the daily budget does not
  /// apply and an earlier "Ahora no" is cleared — they would not have tapped
  /// it if they still meant later.
  Future<PendingUpdate?> refresh({bool force = false}) async {
    if (_checking) return _pending;
    final today = _dayKey(_now());
    if (!force && _checkedDay == today) {
      await _restorePending();
      return _pending;
    }

    _pendingRestored = true;
    _checking = true;
    if (force) notifyListeners();
    PendingUpdate? found;
    try {
      found = await _port.check();
    } finally {
      _checking = false;
    }

    _checkedDay = today;
    if (force) {
      _promptShown = false;
      _bannerHidden = false;
      _dismissedVersionCode = null;
    }
    _pending = found;
    await _persist();
    notifyListeners();
    return found;
  }

  /// Brings back the offer an earlier launch today already paid for.
  ///
  /// [_pending] is the one part of this state a new process does not inherit,
  /// and the daily budget above means that process will not re-ask. Without
  /// this the whole feature would live exactly one cold start: the second
  /// launch of the day would skip the check, find nothing in hand, and show
  /// neither the dialog nor the banner — so the banner this class promises
  /// "on the next launch" could not return until the day turned.
  ///
  /// Only the version code is kept. [PendingUpdate.stalenessDays] is Play's
  /// answer to a question asked at one moment, and replaying yesterday's count
  /// as though it were fresh is the one dishonest thing this could store.
  Future<void> _restorePending() async {
    if (_pendingRestored) return;
    _pendingRestored = true;
    final code = _preferences?.getInt(_pendingCodeKey);
    if (code == null) return;

    // A stored offer outlives the update it names: install it and the app
    // comes straight back, the same day, with the budget already spent and
    // the code of the build now running still sitting in preferences. Left
    // alone, Sobra would advertise the very version the banner is drawn on.
    final installed = int.tryParse((await _versionLoader())?.buildNumber ?? '');
    if (installed != null && installed >= code) {
      await _persist();
      return;
    }

    _pending = PendingUpdate(versionCode: code);
    // The dialog has already had its turn — some earlier launch today opened
    // it. What survives a restart is the banner, which is the quiet half of
    // the policy and the only half allowed to come back on its own.
    _promptShown = true;
    notifyListeners();
  }

  /// The dialog is opening: it has had its turn, and it is on screen.
  void markPromptShown() {
    if (_promptShown && _promptVisible) return;
    _promptShown = true;
    _promptVisible = true;
    notifyListeners();
  }

  /// The dialog has closed, whichever way. The banner may take over now.
  void markPromptClosed() {
    if (!_promptVisible) return;
    _promptVisible = false;
    notifyListeners();
  }

  /// "Ahora no": this update never interrupts again.
  Future<void> dismiss() async {
    _promptShown = true;
    _dismissedVersionCode = _pending?.versionCode;
    await _persist();
    notifyListeners();
  }

  /// The banner's close button. Session-only on purpose — see the class doc.
  void hideBanner() {
    if (_bannerHidden) return;
    _bannerHidden = true;
    notifyListeners();
  }

  Future<bool> openStore() => _port.openStore();
}

class AppUpdateScope extends InheritedNotifier<AppUpdates> {
  const AppUpdateScope({
    super.key,
    required AppUpdates updates,
    required super.child,
  }) : super(notifier: updates);

  static AppUpdates? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppUpdateScope>()?.notifier;
}
