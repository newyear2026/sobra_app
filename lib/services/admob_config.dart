import 'package:flutter/foundation.dart';

/// AdMob identifiers and release policy for Sobra's Android app.
///
/// Google's dedicated sample units are deliberately used in debug and profile
/// builds. This keeps development traffic away from the production account and
/// prevents accidental clicks from being counted as invalid traffic.
abstract final class AdMobConfig {
  static const androidAppId = 'ca-app-pub-2706404530136726~6701842938';

  static const _androidNativeProduction =
      'ca-app-pub-2706404530136726/9277878691';
  static const _androidRewardedProduction =
      'ca-app-pub-2706404530136726/2239406637';

  static const _androidNativeTest = 'ca-app-pub-3940256099942544/2247696110';
  static const _androidRewardedTest = 'ca-app-pub-3940256099942544/5224354917';

  /// This set of identifiers is Android-only. iOS stays ad-free until its
  /// own AdMob app, units, and ATT copy exist. Mediation and AdSense are
  /// out of scope: AdSense is a website product, and a second network is
  /// not worth the fill until impressions are in the thousands per day.
  static bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static String get nativeAdUnitId =>
      kReleaseMode ? _androidNativeProduction : _androidNativeTest;

  static String get rewardedAdUnitId =>
      kReleaseMode ? _androidRewardedProduction : _androidRewardedTest;

  /// New installs get a calm first week. Debug builds skip it so the test
  /// creative can be checked immediately on a device.
  static int get nativeGraceDays => kReleaseMode ? 7 : 0;
}
