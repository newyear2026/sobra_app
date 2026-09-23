import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens Sobra's own page in Google Play. False when nothing could be opened.
///
/// Shared by the update prompt and the "rate" row, which both want the same
/// page for different buttons on it.
Future<bool> openPlayListing() async {
  String packageName;
  try {
    packageName = (await PackageInfo.fromPlatform()).packageName;
  } on Object catch (error) {
    debugPrint('Sobra: could not read the package name: $error');
    return false;
  }
  if (packageName.isEmpty) return false;

  // The Play app first, so the listing opens where the user can actually
  // press Update or leave stars. The web address is the fallback for a phone
  // that has no Play app to answer the `market:` scheme — it still reaches the
  // listing, in a browser.
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
