import '../l10n/generated/app_localizations.dart';

/// Another app from the people who make Sobra, as the "more apps" screen
/// shows it.
///
/// The name stays as the store spells it in every language; only the kind and
/// the blurb are translated. They are functions rather than strings for the
/// same reason [ReleaseNote.lines] are: gen-l10n hands out typed getters, not
/// a map to look a key up in.
class OurApp {
  const OurApp({
    required this.packageName,
    required this.name,
    required this.icon,
    required this.kind,
    required this.blurb,
  });

  /// The Play application id the listing is opened by.
  final String packageName;

  final String name;

  /// The launcher icon, bundled under `assets/apps/`.
  final String icon;

  /// One word for what the app is for, shown under its name.
  final String Function(AppLocalizations) kind;

  final String Function(AppLocalizations) blurb;
}

/// Tells each app's Play Console that the install came from this screen.
const ourAppsReferrer = 'utm_source=sobrita&utm_medium=our_apps';

/// The apps the screen lists, oldest first.
///
/// Every card is the same size and none is marked, so the order is the only
/// thing that could read as a preference; age is the one that says nothing.
/// Only apps already live on Play belong here — a card whose button lands on
/// "item not found" is worse than no card. Currency Mate joins once it ships
/// under a real package name.
final ourApps = <OurApp>[
  OurApp(
    packageName: 'com.randomfocus.app',
    name: 'RandomFocus',
    icon: 'assets/apps/randomfocus.png',
    kind: (l10n) => l10n.ourAppsRandomFocusKind,
    blurb: (l10n) => l10n.ourAppsRandomFocusBlurb,
  ),
  OurApp(
    packageName: 'com.dayround.app',
    name: 'LOOPET',
    icon: 'assets/apps/loopet.png',
    kind: (l10n) => l10n.ourAppsLoopetKind,
    blurb: (l10n) => l10n.ourAppsLoopetBlurb,
  ),
];
