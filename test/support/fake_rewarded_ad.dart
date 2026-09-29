import 'dart:async';

import 'package:sobra_app/services/rewarded_ad_service.dart';

/// A rewarded-ad network that answers from a script the test writes.
///
/// The SDK reaches Android and iOS through platform channels a unit test does
/// not have, so this is what lets the rules around ads be checked at all: a
/// dismissed ad, a network with nothing to serve, and three views on three
/// different days are one line each here and a day of manual testing each on a
/// device.
class FakeRewardedAdPort implements RewardedAdPort {
  /// What each successive [show] answers, in order.
  ///
  /// A script that runs out keeps answering with its last entry, so a test
  /// that only cares about earning writes `[RewardedAdResult.earned]` once.
  List<RewardedAdResult> script = [RewardedAdResult.earned];

  /// Whether [load] finds an ad. False is the ordinary no-fill case.
  bool fills = true;

  /// Whether [load] and [show] answer at all.
  ///
  /// A network that goes silent rather than failing: the SDK was never
  /// initialised, the platform channel went away, the ad process died. The
  /// callbacks simply never arrive, and nothing downstream can tell that from
  /// an ad still loading.
  bool answers = true;

  int loads = 0;
  int shows = 0;

  bool _ready = false;

  @override
  bool get isReady => _ready;

  @override
  Future<void> load() {
    loads++;
    if (!answers) return Completer<void>().future;
    _ready = fills;
    return Future<void>.value();
  }

  @override
  Future<RewardedAdResult> show() async {
    shows++;
    if (!answers) return Completer<RewardedAdResult>().future;
    final result = shows <= script.length ? script[shows - 1] : script.last;
    // One ad per load, the way the SDK works: a shown ad is spent and the next
    // one has to be fetched.
    _ready = false;
    return result;
  }
}
