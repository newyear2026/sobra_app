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
    DateTime Function() now = DateTime.now,
  }) : _canRequestAds = canRequestAds,
       _ad = PreloadedAd<RewardedAd>(now: now, dispose: (ad) => ad.dispose());

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
  final PreloadedAd<RewardedAd> _ad;
  Future<void>? _loading;

  @override
  bool get isReady => _canRequestAds() && _ad.fresh != null;

  @override
  Future<void> load() {
    if (!_canRequestAds() || _ad.fresh != null) return Future<void>.value();
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
              _ad.hold(ad);
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
    final ad = _ad.take();
    if (ad == null) return RewardedAdResult.failed;

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

/// One preloaded ad and the moment it arrived.
///
/// AdMob only promises a loaded rewarded ad for an hour. Past that, `show`
/// fails, and since the collection preloads at launch, somebody who opened it
/// an hour or more later had their first tap answered with "no ad" while the
/// stale ad still counted as ready. An ad old enough to be near the line is
/// disposed and reads as absent, so the next run fetches a fresh one instead.
@visibleForTesting
final class PreloadedAd<T extends Object> {
  PreloadedAd({
    required DateTime Function() now,
    required void Function(T ad) dispose,
    this.maxAge = const Duration(minutes: 50),
  }) : _now = now,
       _dispose = dispose;

  /// Short of the hour on purpose: the age is measured at the tap, and the ad
  /// still has to be presented after it.
  final Duration maxAge;

  final DateTime Function() _now;
  final void Function(T ad) _dispose;
  T? _ad;
  DateTime? _loadedAt;

  /// The held ad, or null when there is none or it has aged out.
  T? get fresh {
    final ad = _ad;
    final loadedAt = _loadedAt;
    if (ad == null || loadedAt == null) return null;
    if (_now().difference(loadedAt) < maxAge) return ad;
    _clear();
    _dispose(ad);
    return null;
  }

  void hold(T ad) {
    _ad = ad;
    _loadedAt = _now();
  }

  /// The fresh ad, handed over once.
  T? take() {
    final ad = fresh;
    _clear();
    return ad;
  }

  void _clear() {
    _ad = null;
    _loadedAt = null;
  }
}
