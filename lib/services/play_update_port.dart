import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'app_update_service.dart';

/// Asks Google Play whether a newer build is waiting, and opens the listing.
///
/// Only the *question* comes from the In-App Update API. The update itself is
/// not started through it: `performImmediateUpdate` puts Google's own
/// full-screen flow in front of the user, which is not a screen this app can
/// write, and `startFlexibleUpdate` makes Sobra responsible for finishing an
/// install it did not begin. Handing over to the store page keeps the one
/// dialog the user sees in Sobra's own language and leaves the install to the
/// app that owns it.
final class PlayUpdatePort implements AppUpdatePort {
  const PlayUpdatePort();

  @override
  Future<PendingUpdate?> check() async {
    try {
      final info = await InAppUpdate.checkForUpdate();
      if (info.updateAvailability != UpdateAvailability.updateAvailable) {
        return null;
      }
      final versionCode = info.availableVersionCode;
      // Play documents this as arbitrary when no update is available, and
      // nullable throughout. With no code there is nothing to remember a
      // dismissal against, so an update that cannot be named is not offered.
      if (versionCode == null) return null;
      return PendingUpdate(
        versionCode: versionCode,
        stalenessDays: info.clientVersionStalenessDays,
      );
    } on Object catch (error) {
      // The ordinary case, not the exceptional one: this throws on every
      // build Play did not install — debug runs, sideloads, emulators without
      // Play services — and on a phone with no network. All of them mean the
      // same thing to the user, which is nothing at all.
      debugPrint('Sobra: could not ask Play about updates: $error');
      return null;
    }
  }

  @override
  Future<bool> openStore() async {
    String packageName;
    try {
      packageName = (await PackageInfo.fromPlatform()).packageName;
    } on Object catch (error) {
      debugPrint('Sobra: could not read the package name: $error');
      return false;
    }
    if (packageName.isEmpty) return false;

    // The Play app first, so the listing opens where the user can actually
    // press Update. The web address is the fallback for a phone that has no
    // Play app to answer the `market:` scheme — it still reaches the listing,
    // in a browser.
    final targets = [
      Uri.parse('market://details?id=$packageName'),
      Uri.https('play.google.com', '/store/apps/details', {'id': packageName}),
    ];
    for (final target in targets) {
      try {
        if (await launchUrl(target, mode: LaunchMode.externalApplication)) {
          return true;
        }
      } on Object catch (error) {
        debugPrint('Sobra: could not open $target: $error');
      }
    }
    return false;
  }
}
