import '../l10n/generated/app_localizations.dart';

/// How many shipped versions the notes screen keeps.
///
/// Every version retained here costs one ARB string per line in *every*
/// locale, and nobody running v1.4 opens the screen to read what changed in
/// v1.1. So adding a release means dropping the oldest entry below and
/// deleting its keys from every ARB file — not appending and moving on.
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
    this.seasonalGift = false,
  });

  /// Matches `pubspec.yaml`'s version without the build number, because that
  /// is what [AppVersion.version] reports and what marks the current card.
  final String version;

  final DateTime releasedOn;
  final List<String Function(AppLocalizations)> lines;

  /// Whether the release brought the seasonal costume gift. Its card shows
  /// the costumes and, while the gift can still be claimed, opens it.
  final bool seasonalGift;
}

/// What changed in each shipped version, newest first.
///
/// Only versions that actually reached users belong here, and only changes a
/// reader would notice. A release whose whole diff is internal — ad
/// eligibility, build plumbing — ships without an entry and announces
/// nothing, which is what [ReleaseAnnouncements] reads a missing note as.
final releaseNotes = <ReleaseNote>[
  ReleaseNote(
    version: '1.0.16',
    releasedOn: DateTime(2026, 10, 28),
    seasonalGift: true,
    lines: [
      (l10n) => l10n.releaseNote1016Costumes,
      (l10n) => l10n.releaseNote1016Keeps,
    ],
  ),
  ReleaseNote(
    version: '1.0.15',
    releasedOn: DateTime(2026, 10, 21),
    lines: [
      (l10n) => l10n.releaseNote1015Penguin,
      (l10n) => l10n.releaseNote1015Ads,
    ],
  ),
  ReleaseNote(
    version: '1.0.14',
    releasedOn: DateTime(2026, 10, 19),
    lines: [
      (l10n) => l10n.releaseNote1014FirstExpense,
      (l10n) => l10n.releaseNote1014Currency,
    ],
  ),
  ReleaseNote(
    version: '1.0.13',
    releasedOn: DateTime(2026, 10, 15),
    lines: [
      (l10n) => l10n.releaseNote1013Rewards,
      (l10n) => l10n.releaseNote1013Rooms,
      (l10n) => l10n.releaseNote1013Kept,
      (l10n) => l10n.releaseNote1013Home,
      (l10n) => l10n.releaseNote1013Share,
      (l10n) => l10n.releaseNote1013Fixes,
    ],
  ),
  ReleaseNote(
    version: '1.0.4',
    releasedOn: DateTime(2026, 9, 28),
    lines: [
      (l10n) => l10n.releaseNote104Fixed,
      (l10n) => l10n.releaseNote104Decor,
      (l10n) => l10n.releaseNote104Names,
      (l10n) => l10n.releaseNote104Widget,
      (l10n) => l10n.releaseNote104Languages,
    ],
  ),
];
