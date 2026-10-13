import 'package:flutter/foundation.dart';

/// AdMob identifiers and release policy for Sobra's Android app.
///
/// Debug and profile builds use Google's sample units. Release builds serve
/// live ads unless they are built with an explicit opt-out.
abstract final class AdMobConfig {
  static const androidAppId = 'ca-app-pub-2706404530136726~6701842938';

  static const _androidNativeProduction =
      'ca-app-pub-2706404530136726/9277878691';
  static const _androidRewardedProduction =
      'ca-app-pub-2706404530136726/2239406637';

  static const _androidNativeTest = 'ca-app-pub-3940256099942544/2247696110';
  static const _androidRewardedTest = 'ca-app-pub-3940256099942544/5224354917';

  /// The app is in production, so a release build serves live ads by default:
  /// an opt-in once let 1.0.5 through 1.0.12 ship with no ads at all. Set
  /// --dart-define=SOBRA_DISABLE_LIVE_ADS=true for an ad-free release build,
  /// such as a testing-track build whose devices aren't registered as AdMob
  /// test devices. Google's sample units are only for local builds.
  static const _liveAdsOptOut = bool.fromEnvironment('SOBRA_DISABLE_LIVE_ADS');
  static bool get servesLiveAds => kReleaseMode && !_liveAdsOptOut;

  /// Devices that keep receiving test ads when live ads are explicitly enabled.
  ///
  /// Emulators are test devices already. This list is only needed when testing
  /// production ad units on physical hardware; sample units are test ads on
  /// every device. Identifiers are device scoped, so listing one here leaves
  /// every other tester and user untouched.
  ///
  /// To add a phone, run the app on it once and read the identifier the SDK
  /// prints: `adb logcat -d | grep -i setTestDeviceIds`.
  static const androidTestDeviceIds = <String>[];

  /// This set of identifiers is Android-only. iOS stays ad-free until its
  /// own AdMob app, units, and ATT copy exist. Release builds serve ads
  /// unless live ads are explicitly disabled. Mediation and AdSense are
  /// out of scope: AdSense is a website product, and a second network is
  /// not worth the fill until impressions are in the thousands per day.
  static bool get isSupported =>
      !kIsWeb &&
      defaultTargetPlatform == TargetPlatform.android &&
      (!kReleaseMode || servesLiveAds);

  static String get nativeAdUnitId =>
      kReleaseMode ? _androidNativeProduction : _androidNativeTest;

  static String get rewardedAdUnitId =>
      kReleaseMode ? _androidRewardedProduction : _androidRewardedTest;

  /// Native ads are eligible immediately for new users when ads are enabled.
  static int get nativeGraceDays => 0;
}
