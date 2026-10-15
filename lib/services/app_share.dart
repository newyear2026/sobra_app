import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n/generated/app_localizations.dart';
import 'app_telemetry.dart';

/// The application id of the release listing.
///
/// A constant rather than the running package: a debug or test build that
/// shared its own id would hand a friend a listing that does not exist.
const sobraPackageName = 'com.sobra.app.sobra_app';

/// Where in the app the share sheet was opened from.
///
/// Rides along as the link's `utm_medium`, so Firebase attributes each
/// install that follows to the place that earned it.
enum ShareOrigin { settlement, settings }

/// Opens the platform share sheet on [text] and reports how it ended.
typedef ShareSender = Future<ShareResultStatus> Function(String text);

Future<ShareResultStatus> _shareWithPlatform(String text) async =>
    (await SharePlus.instance.share(ShareParams(text: text))).status;

/// Sobra's Play listing, tagged with [origin] as the install referrer.
Uri shareLink(ShareOrigin origin) =>
    Uri.https('play.google.com', '/store/apps/details', {
      'id': sobraPackageName,
      'referrer': 'utm_source=sobrita_share&utm_medium=${origin.name}',
    });

/// The message and link handed to the share sheet.
///
/// No amount, however good the cycle was: what was left over is the user's
/// to mention, and they can still type it in before sending.
String shareText(AppLocalizations l10n, ShareOrigin origin) {
  final message = switch (origin) {
    ShareOrigin.settlement => l10n.shareMessageSettlement,
    ShareOrigin.settings => l10n.shareMessageSettings,
  };
  return '$message\n${shareLink(origin)}';
}

/// "Tell a friend": one tap opens the sheet, no screen in between.
class AppShare {
  AppShare({ShareSender? send}) : _send = send ?? _shareWithPlatform;

  static AppShare instance = AppShare();

  final ShareSender _send;

  Future<void> share(AppLocalizations l10n, ShareOrigin origin) async {
    ShareResultStatus result;
    try {
      result = await _send(shareText(l10n, origin));
    } on Object catch (error) {
      debugPrint('Sobra: could not open the share sheet: ${error.runtimeType}');
      result = ShareResultStatus.unavailable;
    }
    await AppTelemetry.instance.event(TelemetryEvent.shared, {
      'origin': origin,
      'result': result,
    });
  }
}
