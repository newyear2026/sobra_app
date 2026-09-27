import '../l10n/generated/app_localizations.dart';

/// How many shipped versions the notes screen keeps.
///
/// Every version retained here costs one ARB string per line in *every*
/// locale, and nobody running v1.4 opens the screen to read what changed in
/// v1.1. So adding a release means dropping the oldest entry below and
/// deleting its keys from all three ARB files — not appending and moving on.
/// `release_notes_test.dart` fails the build if this slips.
const releaseNoteRetention = 5;

/// One shipped version and what changed in it.
///
/// The lines are functions rather than strings because the notes have to read
/// in the locale the screen is built in, and gen-l10n hands out typed getters
/// rather than a map this could look a key up in.
class ReleaseNote {
  ReleaseNote({
    required this.version,
    required this.releasedOn,
    required this.lines,
  });

  /// Matches `pubspec.yaml`'s version without the build number, because that
  /// is what [AppVersion.version] reports and what marks the current card.
  final String version;

  final DateTime releasedOn;
  final List<String Function(AppLocalizations)> lines;
}

/// What changed in each shipped version, newest first.
///
/// Only versions that actually reached users belong here, and only changes a
/// reader would notice. A release whose whole diff is internal — ad
/// eligibility, build plumbing — ships without an entry and announces
/// nothing, which is what [ReleaseAnnouncements] reads a missing note as.
final releaseNotes = <ReleaseNote>[
  ReleaseNote(
    version: '1.0.3',
    releasedOn: DateTime(2026, 9, 26),
    lines: [
      (l10n) => l10n.releaseNote103GuineaPig,
      (l10n) => l10n.releaseNote103Widget,
    ],
  ),
  ReleaseNote(
    version: '1.0.2',
    releasedOn: DateTime(2026, 9, 23),
    lines: [
      (l10n) => l10n.releaseNote102Schnauzer,
      (l10n) => l10n.releaseNote102Rooms,
      (l10n) => l10n.releaseNote102Missions,
      (l10n) => l10n.releaseNote102Amounts,
    ],
  ),
  ReleaseNote(
    version: '1.0.1',
    releasedOn: DateTime(2026, 9, 21),
    lines: [
      (l10n) => l10n.releaseNote101Currencies,
      (l10n) => l10n.releaseNote101Celebration,
    ],
  ),
  ReleaseNote(
    version: '1.0.0',
    releasedOn: DateTime(2026, 9, 11),
    lines: [(l10n) => l10n.releaseNote100Launch],
  ),
];
