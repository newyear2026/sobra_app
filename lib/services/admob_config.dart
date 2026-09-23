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

  /// Devices that keep receiving test ads even from a release build.
  ///
  /// Emulators are test devices already, so this list stays empty until the
  /// app runs on real hardware. A closed testing build is a release build and
  /// asks for the production units above, which would turn our own taps into
  /// real impressions on the account. Identifiers are device scoped: listing
  /// one here leaves every other tester and user untouched.
  ///
  /// To add a phone, run the app on it once and read the identifier the SDK
  /// prints: `adb logcat -d | grep -i setTestDeviceIds`.
  static const androidTestDeviceIds = <String>[];

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

  /// Native ads are eligible immediately for new users in every build mode.
  static int get nativeGraceDays => 0;
}
