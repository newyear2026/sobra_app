import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'admob_config.dart';
import 'app_telemetry.dart';
import 'rewarded_ad_service.dart';

/// An SDK callback, or a load/show attempt. Only the impression stage means a
/// recorded view.
enum RewardedAdStage {
  loadRequested,
  loaded,
  loadFailed,
  showRequested,
  showed,
  impression,
  showFailed,
  rewardEarned,
  dismissed,
}

/// Fixed diagnostic categories. SDK messages and response IDs stay out of
/// Analytics, like all other free text in [AppTelemetry].
enum RewardedAdFailure {
  timeout,
  consentUnavailable,
  notReady,
  internalError,
  invalidRequest,
  networkError,
  noFill,
  appIdMissing,
  mediationNoFill,
  requestIdMismatch,
  invalidAdString,
  adReused,
  appNotForeground,
  mediationShowError,
  otherSdkError,
  platformError,
}

/// The Google Mobile Ads implementation behind the existing collection flow.
final class AdMobRewardedAdPort implements RewardedAdPort {
  AdMobRewardedAdPort({
    required bool Function() canRequestAds,
    this.loadTimeout = const Duration(seconds: 30),
    this.showTimeout = const Duration(minutes: 5),
    DateTime Function() now = DateTime.now,
  }) : _canRequestAds = canRequestAds,
       _ad = PreloadedAd<RewardedAd>(now: now, dispose: (ad) => ad.dispose());

  /// How long a request may go unanswered before it times out.
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
  Completer<void>? _loading;
  Timer? _loadTimer;

  @override
  bool get isReady => _canRequestAds() && _ad.fresh != null;

  @override
  Future<void> load() {
    if (!_canRequestAds() || _ad.fresh != null) return Future<void>.value();
    final inFlight = _loading;
    if (inFlight != null) return inFlight.future;

    final completer = Completer<void>();
    _loading = completer;
    // Clears `_loading` as well as answering the caller, so a silent request
    // costs one wait rather than every wait after it.
    _loadTimer = Timer(
      loadTimeout,
      () => _failLoad(completer, RewardedAdFailure.timeout),
    );
    _record(RewardedAdStage.loadRequested);
    try {
      RewardedAd.load(
        adUnitId: AdMobConfig.rewardedAdUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            // A timed-out request can still answer after a retry has started.
            // Its ad must not replace the retry's slot or clear its timer.
            if (!_finishLoad(completer)) {
              ad.dispose();
              return;
            }
            if (_canRequestAds()) {
              _ad.hold(ad);
              _record(RewardedAdStage.loaded);
            } else {
              ad.dispose();
              _record(
                RewardedAdStage.loadFailed,
                reason: RewardedAdFailure.consentUnavailable,
              );
            }
          },
          onAdFailedToLoad: (error) {
            _failLoad(completer, _loadFailure(error), error: error);
          },
        ),
      ).catchError((Object error) {
        _failLoad(completer, RewardedAdFailure.platformError);
      });
    } on Object {
      _failLoad(completer, RewardedAdFailure.platformError);
    }
    return completer.future;
  }

  bool _finishLoad(Completer<void> completer) {
    if (!identical(_loading, completer)) return false;
    _loadTimer?.cancel();
    _loadTimer = null;
    _loading = null;
    completer.complete();
    return true;
  }

  void _failLoad(
    Completer<void> completer,
    RewardedAdFailure reason, {
    AdError? error,
  }) {
    if (!_finishLoad(completer)) return;
    _record(RewardedAdStage.loadFailed, reason: reason, error: error);
  }

  @override
  Future<RewardedAdResult> show() {
    _record(RewardedAdStage.showRequested);
    if (!_canRequestAds()) {
      _record(
        RewardedAdStage.showFailed,
        reason: RewardedAdFailure.consentUnavailable,
      );
      return Future.value(RewardedAdResult.failed);
    }
    final ad = _ad.take();
    if (ad == null) {
      _record(RewardedAdStage.showFailed, reason: RewardedAdFailure.notReady);
      return Future.value(RewardedAdResult.failed);
    }

    final result = Completer<RewardedAdResult>();
    var earned = false;
    var disposed = false;
    Timer? timer;
    final recorded = <RewardedAdStage>{};
    void recordOnce(RewardedAdStage stage) {
      if (recorded.add(stage)) _record(stage);
    }

    void disposeAd() {
      if (disposed) return;
      disposed = true;
      ad.dispose();
    }

    void finish(
      RewardedAdResult value, {
      RewardedAdFailure? reason,
      AdError? error,
    }) {
      if (result.isCompleted) return;
      timer?.cancel();
      if (reason != null) {
        _record(RewardedAdStage.showFailed, reason: reason, error: error);
      }
      result.complete(value);
    }

    ad.fullScreenContentCallback = FullScreenContentCallback<RewardedAd>(
      onAdShowedFullScreenContent: (_) => recordOnce(RewardedAdStage.showed),
      onAdImpression: (_) => recordOnce(RewardedAdStage.impression),
      onAdDismissedFullScreenContent: (ad) {
        disposeAd();
        recordOnce(RewardedAdStage.dismissed);
        finish(earned ? RewardedAdResult.earned : RewardedAdResult.dismissed);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        disposeAd();
        finish(
          RewardedAdResult.failed,
          reason: _showFailure(error),
          error: error,
        );
      },
    );
    // Deliberately does not dispose. The ad may still be on screen, and
    // tearing it down under the user is worse than the wedge this guards
    // against; the dismissal callback still disposes it whenever it arrives,
    // and `finish` ignores a late answer to a run already abandoned.
    timer = Timer(
      showTimeout,
      () => finish(RewardedAdResult.failed, reason: RewardedAdFailure.timeout),
    );
    try {
      // Do not wait on the platform channel before returning the result:
      // the timer must also free a run whose platform call never answers.
      unawaited(
        ad
            .show(
              onUserEarnedReward: (_, reward) {
                earned = true;
                recordOnce(RewardedAdStage.rewardEarned);
              },
            )
            .catchError((Object error) {
              disposeAd();
              finish(
                RewardedAdResult.failed,
                reason: RewardedAdFailure.platformError,
              );
            }),
      );
    } on Object {
      disposeAd();
      finish(RewardedAdResult.failed, reason: RewardedAdFailure.platformError);
    }
    return result.future;
  }

  void _record(
    RewardedAdStage stage, {
    RewardedAdFailure? reason,
    AdError? error,
  }) {
    debugPrint(
      'Rewarded ad ${stage.name}'
      '${reason == null ? '' : ': ${reason.name}'}'
      '${error == null ? '' : ' (SDK ${error.domain}/${error.code})'}',
    );
    unawaited(
      AppTelemetry.instance.event(TelemetryEvent.rewardedAdLifecycle, {
        'stage': stage,
        'reason': ?reason,
      }),
    );
  }

  // Android is the supported AdMob platform. Codes from another domain must
  // not be mistaken for Google's codes with the same number.
  static RewardedAdFailure _loadFailure(AdError error) {
    if (error.domain != 'com.google.android.gms.ads') {
      return RewardedAdFailure.otherSdkError;
    }
    return switch (error.code) {
      0 => RewardedAdFailure.internalError,
      1 => RewardedAdFailure.invalidRequest,
      2 => RewardedAdFailure.networkError,
      3 => RewardedAdFailure.noFill,
      8 => RewardedAdFailure.appIdMissing,
      9 => RewardedAdFailure.mediationNoFill,
      10 => RewardedAdFailure.requestIdMismatch,
      11 => RewardedAdFailure.invalidAdString,
      _ => RewardedAdFailure.otherSdkError,
    };
  }

  static RewardedAdFailure _showFailure(AdError error) {
    if (error.domain != 'com.google.android.gms.ads') {
      return RewardedAdFailure.otherSdkError;
    }
    return switch (error.code) {
      0 => RewardedAdFailure.internalError,
      1 => RewardedAdFailure.adReused,
      2 => RewardedAdFailure.notReady,
      3 => RewardedAdFailure.appNotForeground,
      4 => RewardedAdFailure.mediationShowError,
      _ => RewardedAdFailure.otherSdkError,
    };
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
