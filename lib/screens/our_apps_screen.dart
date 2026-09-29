import 'package:flutter/material.dart';

import '../data/our_apps.dart';
import '../l10n/generated/app_localizations.dart';
import '../services/play_listing.dart';
import '../theme/app_theme.dart';
import '../widgets/pixel_ui.dart';

/// Opens [packageName]'s store page. False when nothing could be opened.
typedef ListingOpener =
    Future<bool> Function(String packageName, {String? referrer});

/// The other apps from the people who make Sobra.
///
/// Reached only from its Ajustes row, the same posture as the release notes:
/// no dot, no card on Inicio, no reward for installing — Play forbids that
/// last one outright. Somebody who comes here came to look.
class OurAppsScreen extends StatelessWidget {
  const OurAppsScreen({
    super.key,
    this.apps,
    this.openListing = openPlayListingOf,
  });

  /// Defaults to [ourApps]; a test passes its own.
  final List<OurApp>? apps;

  /// Injected so a test can see which listing a button asked for without the
  /// url_launcher channel.
  final ListingOpener openListing;

  Future<void> _open(BuildContext context, OurApp app) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    if (await openListing(app.packageName, referrer: ourAppsReferrer)) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.updateStoreFailed)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
              children: [
                PixelTopBar(
                  title: l10n.settingsOurApps,
                  onBack: () => Navigator.pop(context),
                ),
                const SizedBox(height: 14),
                Text(
                  l10n.ourAppsIntro,
                  style: pixelText(size: 13, color: AppColors.inkSoft),
                ),
                const SizedBox(height: 18),
                for (final app in apps ?? ourApps)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _AppCard(
                      app: app,
                      onOpen: () => _open(context, app),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AppCard extends StatelessWidget {
  const _AppCard({required this.app, required this.onOpen});

  final OurApp app;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return PixelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              // The icon is the other app's own artwork, so it is not
              // filtered the way Sobra's sprites are: it was drawn to be
              // scaled down smoothly by a launcher.
              // In front of the icon, not behind it: a square icon covers
              // its whole box, and LOOPET's cream would melt into the card.
              DecoratedBox(
                position: DecorationPosition.foreground,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.ink, width: 2.5),
                ),
                child: Image.asset(
                  app.icon,
                  width: 58,
                  height: 58,
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.medium,
                  excludeFromSemantics: true,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(app.name, style: pixelText(size: 18, bold: true)),
                    const SizedBox(height: 3),
                    Text(
                      app.kind(l10n).toUpperCase(),
                      style: pixelText(
                        size: 12,
                        bold: true,
                        color: AppColors.teal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          Text(
            app.blurb(l10n),
            style: pixelText(size: 13, color: AppColors.inkSoft, height: 1.5),
          ),
          const SizedBox(height: 13),
          // Secondary, not the teal primary: nothing on this screen is the
          // one action Sobra wants taken, and two primaries side by side
          // would say the opposite.
          PixelButton(
            label: l10n.ourAppsOpen,
            variant: PixelButtonVariant.secondary,
            onPressed: onOpen,
          ),
        ],
      ),
    );
  }
}
