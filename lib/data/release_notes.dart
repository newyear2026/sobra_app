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
/// A picture across the top of the announcement card, for a release tied to
/// a season. Pictures carry no words, so one drawing serves every locale.
enum ReleaseNoteArt {
  /// Buen Fin and Black Friday: a goal bought on sale.
  saleNight,
}

class ReleaseNote {
  ReleaseNote({
    required this.version,
    required this.releasedOn,
    required this.lines,
    this.seasonalGift = false,
    this.art,
    this.artShownThrough,
  }) : assert((art == null) == (artShownThrough == null));

  /// Matches `pubspec.yaml`'s version without the build number, because that
  /// is what [AppVersion.version] reports and what marks the current card.
  final String version;

  final DateTime releasedOn;
  final List<String Function(AppLocalizations)> lines;

  /// Whether the release brought the seasonal costume gift. Its card shows
  /// the costumes and, while the gift can still be claimed, opens it.
  final bool seasonalGift;

  final ReleaseNoteArt? art;

  /// The last day [art] is drawn. A season's picture on a card read in
  /// January would date the release, so after this the card goes plain.
  final DateTime? artShownThrough;

  /// Whether [art] belongs on a card opened at [now].
  bool showsArtOn(DateTime now) {
    final through = artShownThrough;
    if (art == null || through == null) return false;
    final today = DateTime(now.year, now.month, now.day);
    return !today.isAfter(DateTime(through.year, through.month, through.day));
  }
}

/// What changed in each shipped version, newest first.
///
/// Only versions that actually reached users belong here, and only changes a
/// reader would notice. A release whose whole diff is internal — ad
/// eligibility, build plumbing — ships without an entry and announces
/// nothing, which is what [ReleaseAnnouncements] reads a missing note as.
final releaseNotes = <ReleaseNote>[
  ReleaseNote(
    version: '1.0.19',
    releasedOn: DateTime(2026, 11, 11),
    // Through Cyber Monday, the Monday after Black Friday.
    art: ReleaseNoteArt.saleNight,
    artShownThrough: DateTime(2026, 11, 30),
    lines: [
      (l10n) => l10n.releaseNote1019Goal,
      (l10n) => l10n.releaseNote1019Bought,
    ],
  ),
  ReleaseNote(
    version: '1.0.18',
    releasedOn: DateTime(2026, 11, 9),
    lines: [(l10n) => l10n.releaseNote1018Export],
  ),
  ReleaseNote(
    version: '1.0.17',
    releasedOn: DateTime(2026, 10, 29),
    lines: [
      (l10n) => l10n.releaseNote1017Delete,
      (l10n) => l10n.releaseNote1017Dates,
      (l10n) => l10n.releaseNote1017Projection,
    ],
  ),
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
];
