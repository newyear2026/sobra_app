import 'dart:async';

import 'package:flutter/widgets.dart';

import '../models/catalog_entry.dart';
import '../state/sobra_store.dart';

/// How one rewarded ad ended.
///
/// Only [earned] pays. The network confirms a completed view separately from
/// the ad closing, and the difference is the whole point of the distinction:
/// an ad the user swiped away after two seconds also closes.
enum RewardedAdResult {
  /// The network confirmed a completed view.
  earned,

  /// The user closed the ad before it finished.
  dismissed,

  /// Nothing was shown — no ad loaded, or the network refused to present one.
  failed,
}

/// The seam over the rewarded-ad SDK.
///
/// Exists so the rules around ads — the daily cap, the progress, the
/// once-per-day tier — can be tested without a device. None of that logic can
/// run in a unit test with the SDK in the way: it reaches Android and iOS
/// through platform channels that a Dart VM test does not have, which would
/// leave "three views on three different days" as something only three days of
/// manual testing could check.
///
/// Every member mirrors something the SDK already offers, so the adapter over
/// `google_mobile_ads` stays a translation rather than a second implementation
/// of the rules.
abstract interface class RewardedAdPort {
  /// Whether an ad is loaded and can be shown right now.
  bool get isReady;

  /// Asks the network for the next ad.
  ///
  /// Never throws. A network that has nothing leaves [isReady] false, which is
  /// an ordinary state rather than an error: the button says so and the user
  /// carries on.
  Future<void> load();

  /// Shows the loaded ad and answers how it ended.
  ///
  /// Answers exactly once per call. An SDK that reports the same reward twice
  /// is the adapter's problem to collapse, so that nothing downstream has to
  /// defend against a duplicate.
  Future<RewardedAdResult> show();
}

/// What a rewarded-ad run did, from the caller's side.
enum RewardedAdOutcome {
  /// The view counted. [SobraStore.rewardedAdProgressFor] moved, and the entry
  /// may now be owned.
  counted,

  /// The user closed the ad early. Nothing moved.
  dismissed,

  /// No ad could be shown. Nothing moved.
  unavailable,

  /// Sobra's own rules refused the run before any ad was requested.
  notAllowed,
}

/// Runs rewarded ads for the collection, and only for the collection.
///
/// The one entry point, so the daily cap, the progress and the loading state
/// have a single owner. A second surface that showed its own ads would have to
/// re-implement all three and would eventually disagree with this one.
class RewardedAds extends ChangeNotifier {
  RewardedAds({required RewardedAdPort port, required SobraStore store})
    : _port = port,
      _store = store;

  final RewardedAdPort _port;
  final SobraStore _store;
  String? _busyEntryId;

  /// Whether an ad is loaded and waiting.
  bool get isReady => _port.isReady;

  /// The entry a run is working on, or null when nothing is running.
  ///
  /// Covers the fetch in front of the ad as well as the ad itself. That window
  /// is a network round trip on a card that otherwise looks untouched, which
  /// is long enough for somebody to tap again — and before this covered it,
  /// the second tap passed the guard and reached the network too.
  String? get busyEntryId => _busyEntryId;

  /// Whether a run is working right now.
  bool get isBusy => _busyEntryId != null;

  /// Preloads, so the first tap does not wait on the network.
  Future<void> prepare() async {
    if (_port.isReady || isBusy) return;
    await _port.load();
    notifyListeners();
  }

  /// Whether [entry] can be offered an ad at all.
  ///
  /// Sobra's rules only. A run that clears this can still come back
  /// [RewardedAdOutcome.unavailable] when the network has nothing.
  RewardedAdAvailability availabilityFor(CatalogEntry entry) =>
      _store.rewardedAdAvailabilityFor(entry);

  /// Shows one ad for [entry] and records it if the network confirms a view.
  ///
  /// Refuses while another ad is on screen. Two runs at once would spend one
  /// slot of the daily cap each while the user watched a single ad, and a
  /// double tap on a slow network is enough to cause it.
  Future<RewardedAdOutcome> watch(CatalogEntry entry) async {
    if (isBusy) return RewardedAdOutcome.notAllowed;
    if (availabilityFor(entry) != RewardedAdAvailability.available) {
      return RewardedAdOutcome.notAllowed;
    }

    // Claimed before the fetch, not after it. The fetch is the slow half, and
    // leaving it unguarded let a second tap start its own run.
    _busyEntryId = entry.id;
    notifyListeners();
    final RewardedAdResult result;
    try {
      if (!_port.isReady) {
        await _port.load();
        if (!_port.isReady) {
          return RewardedAdOutcome.unavailable;
        }
      }
      result = await _port.show();
    } finally {
      _busyEntryId = null;
      notifyListeners();
    }

    switch (result) {
      case RewardedAdResult.earned:
        // The store re-checks the same rules rather than trusting the check
        // above. The gap between them is a whole ad, and the day can turn over
        // inside it.
        final counted = await _store.recordRewardedAdView(entry);
        // Load the next one now, so the following tap opens immediately.
        unawaited(prepare());
        return counted
            ? RewardedAdOutcome.counted
            : RewardedAdOutcome.notAllowed;
      case RewardedAdResult.dismissed:
        unawaited(prepare());
        return RewardedAdOutcome.dismissed;
      case RewardedAdResult.failed:
        return RewardedAdOutcome.unavailable;
    }
  }
}

/// The port this build ships until the ad SDK is connected.
///
/// Answers the way a network with nothing to serve does, because that is
/// exactly what Sobra has right now: no ad unit, no SDK, no fill. Every card
/// says so honestly, and connecting ads later replaces this one object rather
/// than changing anything the collection does.
final class UnavailableRewardedAdPort implements RewardedAdPort {
  const UnavailableRewardedAdPort();

  @override
  bool get isReady => false;

  @override
  Future<void> load() async {}

  @override
  Future<RewardedAdResult> show() async => RewardedAdResult.failed;
}

/// Puts [RewardedAds] in the tree the way [PurchaseScope] does the store.
class RewardedAdScope extends InheritedNotifier<RewardedAds> {
  const RewardedAdScope({
    super.key,
    required RewardedAds ads,
    required super.child,
  }) : super(notifier: ads);

  /// The ads above [context], or null where there are none.
  ///
  /// Null is the normal answer in a test or a design preview. Callers show the
  /// catalog with its ad entries locked rather than refusing to build.
  static RewardedAds? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<RewardedAdScope>()?.notifier;
}
