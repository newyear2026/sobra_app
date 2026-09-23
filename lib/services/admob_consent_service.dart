import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'admob_config.dart';

/// Owns Google's UMP consent flow and is the single gate in front of ad calls.
class AdMobConsentController extends ChangeNotifier {
  bool _canRequestAds = false;
  bool _privacyOptionsRequired = false;
  bool _sdkInitialized = false;
  bool _initializing = false;

  bool get canRequestAds => _canRequestAds && _sdkInitialized;
  bool get privacyOptionsRequired => _privacyOptionsRequired;

  /// Refreshes consent on every launch, then starts the ads SDK only when UMP
  /// says an ad request is allowed. A failed refresh still checks the cached
  /// consent state, as recommended by Google.
  Future<void> initialize() async {
    if (!AdMobConfig.isSupported || _initializing) return;
    _initializing = true;
    try {
      final updated = Completer<void>();
      ConsentInformation.instance.requestConsentInfoUpdate(
        ConsentRequestParameters(),
        () => updated.complete(),
        (error) {
          debugPrint('AdMob consent update unavailable: ${error.message}');
          updated.complete();
        },
      );
      await updated.future;

      final formFinished = Completer<void>();
      await ConsentForm.loadAndShowConsentFormIfRequired((error) {
        if (error != null) {
          debugPrint('AdMob consent form unavailable: ${error.message}');
        }
        formFinished.complete();
      });
      await formFinished.future;
      await _refreshAccess();
    } on Object catch (error) {
      debugPrint('AdMob consent initialization failed: $error');
      await _refreshAccess();
    } finally {
      _initializing = false;
    }
  }

  /// Opens the always-available privacy choices required by UMP in applicable
  /// regions. Returns false only when the form itself could not be shown.
  Future<bool> showPrivacyOptions() async {
    if (!AdMobConfig.isSupported) return false;
    var succeeded = true;
    try {
      final finished = Completer<void>();
      await ConsentForm.showPrivacyOptionsForm((error) {
        if (error != null) {
          succeeded = false;
          debugPrint('AdMob privacy options unavailable: ${error.message}');
        }
        finished.complete();
      });
      await finished.future;
    } on Object catch (error) {
      debugPrint('AdMob privacy options failed: $error');
      succeeded = false;
    }
    await _refreshAccess();
    return succeeded;
  }

  Future<void> _refreshAccess() async {
    if (!AdMobConfig.isSupported) return;
    try {
      final allowed = await ConsentInformation.instance.canRequestAds();
      final requirement = await ConsentInformation.instance
          .getPrivacyOptionsRequirementStatus();
      _privacyOptionsRequired =
          requirement == PrivacyOptionsRequirementStatus.required;
      _canRequestAds = allowed;
      if (allowed && !_sdkInitialized) {
        await MobileAds.instance.updateRequestConfiguration(
          RequestConfiguration(testDeviceIds: AdMobConfig.androidTestDeviceIds),
        );
        await MobileAds.instance.initialize();
        _sdkInitialized = true;
      }
      notifyListeners();
    } on Object catch (error) {
      debugPrint('AdMob consent status unavailable: $error');
    }
  }
}

class AdMobConsentScope extends InheritedNotifier<AdMobConsentController> {
  const AdMobConsentScope({
    super.key,
    required AdMobConsentController consent,
    required super.child,
  }) : super(notifier: consent);

  static AdMobConsentController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AdMobConsentScope>()?.notifier;
}
