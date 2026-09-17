import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'admob_config.dart';
import 'rewarded_ad_service.dart';

/// The Google Mobile Ads implementation behind the existing collection flow.
final class AdMobRewardedAdPort implements RewardedAdPort {
  AdMobRewardedAdPort({
    required bool Function() canRequestAds,
    this.loadTimeout = const Duration(seconds: 30),
    this.showTimeout = const Duration(minutes: 5),
  }) : _canRequestAds = canRequestAds;

  /// How long a request may go unanswered before it counts as no fill.
  ///
  /// [RewardedAd.load] answers through callbacks, and nothing guarantees one
  /// arrives: an SDK that was never initialised, a platform channel dropped
  /// after consent was withdrawn, or a crash in the ad process all leave the
  /// request silent. Without this, `_loading` would stay non-null forever and
  /// every later request would return the same dead future.
  final Duration loadTimeout;

  /// How long a presented ad may go unanswered before the run is abandoned.
  ///
  /// Long on purpose. A rewarded ad runs well under a minute, but the app can
  /// sit backgrounded behind one for much longer, and cutting a run short
  /// would deny somebody the reward they actually earned. This is the floor
  /// under a wedged UI, not a deadline for the ad.
  final Duration showTimeout;

  final bool Function() _canRequestAds;
  RewardedAd? _ad;
  Future<void>? _loading;

  @override
  bool get isReady => _canRequestAds() && _ad != null;

  @override
  Future<void> load() {
    if (!_canRequestAds() || _ad != null) return Future<void>.value();
    final inFlight = _loading;
    if (inFlight != null) return inFlight;

    final completer = Completer<void>();
    _loading = completer.future;
    // Clears `_loading` as well as answering the caller, so a silent request
    // costs one wait rather than every wait after it.
    Timer(loadTimeout, () => _finishLoad(completer));
    try {
      RewardedAd.load(
        adUnitId: AdMobConfig.rewardedAdUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            if (_canRequestAds()) {
              _ad = ad;
            } else {
              ad.dispose();
            }
            _finishLoad(completer);
          },
          onAdFailedToLoad: (error) {
            debugPrint('Rewarded ad did not load: ${error.message}');
            _finishLoad(completer);
          },
        ),
      ).catchError((Object error) {
        debugPrint('Rewarded ad request failed: $error');
        _finishLoad(completer);
      });
    } on Object catch (error) {
      debugPrint('Rewarded ad request failed: $error');
      _finishLoad(completer);
    }
    return completer.future;
  }

  void _finishLoad(Completer<void> completer) {
    _loading = null;
    if (!completer.isCompleted) completer.complete();
  }

  @override
  Future<RewardedAdResult> show() async {
    if (!_canRequestAds()) return RewardedAdResult.failed;
    final ad = _ad;
    if (ad == null) return RewardedAdResult.failed;
    _ad = null;

    final result = Completer<RewardedAdResult>();
    var earned = false;
    void finish(RewardedAdResult value) {
      if (!result.isCompleted) result.complete(value);
    }

    ad.fullScreenContentCallback = FullScreenContentCallback<RewardedAd>(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        finish(earned ? RewardedAdResult.earned : RewardedAdResult.dismissed);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('Rewarded ad could not be shown: ${error.message}');
        ad.dispose();
        finish(RewardedAdResult.failed);
      },
    );
    // Deliberately does not dispose. The ad may still be on screen, and
    // tearing it down under the user is worse than the wedge this guards
    // against; the dismissal callback still disposes it whenever it arrives,
    // and `finish` ignores a late answer to a run already abandoned.
    Timer(showTimeout, () => finish(RewardedAdResult.failed));
    try {
      await ad.show(onUserEarnedReward: (_, reward) => earned = true);
    } on Object catch (error) {
      debugPrint('Rewarded ad presentation failed: $error');
      ad.dispose();
      finish(RewardedAdResult.failed);
    }
    return result.future;
  }
}
