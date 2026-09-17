import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/release_notes.dart';
import 'app_version_service.dart';

/// Mentions what changed, once, after the phone has installed it.
///
/// The other half of the update story and the opposite end of it: [AppUpdates]
/// speaks before an update and asks for something, this speaks after one and
/// asks for nothing. They never talk about the same build.
///
/// The rules:
///
/// * A version announces itself once. What is remembered is the version name,
///   so two builds of `1.1.0` are one release and only interrupt once.
/// * A version with no entry in [releaseNotes] says nothing. A hotfix that
///   shipped without a note would otherwise open an empty card.
/// * The first launch ever announces nothing. Everything is new to somebody
///   who just installed the app, and a "what's changed" card on top of
///   onboarding is a non-sequitur.
/// * Being told is not the same as having read it. Dismissing the card leaves
///   the dot on the Ajustes row; only opening the notes clears it.
class ReleaseAnnouncements extends ChangeNotifier {
  ReleaseAnnouncements({
    SharedPreferences? preferences,
    AppVersionLoader versionLoader = loadAppVersion,
    List<ReleaseNote>? notes,
  }) : _preferences = preferences,
       _versionLoader = versionLoader,
       _notes = notes ?? releaseNotes;

  static const _announcedKey = 'sobra_notes_announced_version';
  static const _readKey = 'sobra_notes_read_version';

  /// Device bookkeeping rather than ledger state, for the same reason
  /// [AppUpdates] keeps its own: restoring a backup onto another phone must
  /// not carry "already seen" with it.
  final SharedPreferences? _preferences;
  final AppVersionLoader _versionLoader;
  final List<ReleaseNote> _notes;

  AppVersion? _version;
  String? _announcedVersion;
  String? _readVersion;
  bool _started = false;

  /// The running build, kept whole so the notes screen can mark its own card
  /// current without loading it a second time.
  AppVersion? get version => _version;

  String? get _runningVersion => _version?.version;

  /// The note for the build in hand, or null when this version shipped
  /// without one — or when the platform would not say which build it is.
  ReleaseNote? get currentNote {
    final version = _runningVersion;
    if (version == null) return null;
    for (final note in _notes) {
      if (note.version == version) return note;
    }
    return null;
  }

  bool get shouldAnnounce =>
      currentNote != null && _runningVersion != _announcedVersion;

  /// Whether the Ajustes row wears its dot.
  bool get hasUnreadNotes =>
      currentNote != null && _runningVersion != _readVersion;

  /// Reads the running build and decides what this launch owes the user.
  ///
  /// Safe to call more than once; only the first call does anything, so the
  /// shell can call it from `didChangeDependencies` without counting.
  Future<void> start() async {
    if (_started) return;
    _started = true;

    final version = await _versionLoader();
    // No version, no comparison. The card cannot be shown against a build
    // the app cannot name, and guessing at the newest note would announce
    // the wrong thing on a phone that skipped a release.
    if (version == null) return;
    _version = version;

    final preferences = _preferences;
    _announcedVersion = preferences?.getString(_announcedKey);
    _readVersion = preferences?.getString(_readKey);

    if (_announcedVersion == null && _readVersion == null) {
      // The first launch this ever ran on. Record where we are and say
      // nothing: on a new install there is no "what changed", and on an
      // upgrade from a build that predates this field there is no honest
      // answer either — only the version in hand, which they are already
      // looking at.
      _announcedVersion = _runningVersion;
      _readVersion = _runningVersion;
      await _persist();
    }
    notifyListeners();
  }

  Future<void> _persist() async {
    final preferences = _preferences;
    if (preferences == null) return;
    try {
      final announced = _announcedVersion;
      final read = _readVersion;
      if (announced != null) {
        await preferences.setString(_announcedKey, announced);
      }
      if (read != null) await preferences.setString(_readKey, read);
    } on Object catch (error) {
      // Worth one repeated card, not an error path. See [AppUpdates].
      debugPrint('Sobra: could not save the release notes state: $error');
    }
  }

  /// The card has been shown. The dot stays until the notes are opened.
  Future<void> markAnnounced() async {
    if (_announcedVersion == _runningVersion) return;
    _announcedVersion = _runningVersion;
    await _persist();
    notifyListeners();
  }

  /// The notes screen was opened, which covers being told as well.
  Future<void> markRead() async {
    if (_readVersion == _runningVersion &&
        _announcedVersion == _runningVersion) {
      return;
    }
    _announcedVersion = _runningVersion;
    _readVersion = _runningVersion;
    await _persist();
    notifyListeners();
  }
}

class ReleaseAnnouncementScope extends InheritedNotifier<ReleaseAnnouncements> {
  const ReleaseAnnouncementScope({
    super.key,
    required ReleaseAnnouncements announcements,
    required super.child,
  }) : super(notifier: announcements);

  static ReleaseAnnouncements? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<ReleaseAnnouncementScope>()
      ?.notifier;
}
