import 'dart:async';

import 'package:flutter/widgets.dart';

import '../state/sobra_store.dart';

/// Where a native slot sits. Each has its own AdMob unit, so the console
/// reports them apart, and its own visits; the gap between impressions is
/// kept in the store and shared by all of them.
enum NativeAdPlacement {
  /// Movimientos, under the third row.
  ledger,

  /// Presupuesto, under the last category.
  budget,
}

/// Applies Sobra's placement rules independently of the ad SDK widget.
class NativeAds extends ChangeNotifier {
  NativeAds({
    required SobraStore store,
    this.placement = NativeAdPlacement.ledger,
    this.minInterval = const Duration(minutes: 5),
    this.graceDays = 7,
  }) : _store = store;

  final SobraStore _store;
  final NativeAdPlacement placement;

  /// The least time between two native impressions.
  ///
  /// A gap rather than a daily cap. A cap of two let both ads land a minute
  /// apart and then left the rest of the day empty; a gap keeps tab flipping
  /// from serving one after another while a ledger opened again later in the
  /// day still has a place for one. One per visit still applies on top.
  final Duration minInterval;
  final int graceDays;

  bool _sdkReady = false;
  bool _visitActive = false;
  bool _impressionThisVisit = false;
  int _visitId = 0;

  int get visitId => _visitId;

  bool get _ownsNoAds => _store.ownsNoAds;

  bool get canOffer =>
      _sdkReady &&
      _visitActive &&
      !_impressionThisVisit &&
      !_ownsNoAds &&
      _store.nativeAdGraceComplete(graceDays) &&
      _store.nativeAdIntervalElapsed(minInterval);

  /// Keeps an already-impressed card visible until the user leaves the tab.
  bool get shouldPlace =>
      _sdkReady &&
      _visitActive &&
      !_ownsNoAds &&
      (_impressionThisVisit || canOffer);

  void setSdkReady(bool value) {
    if (_sdkReady == value) return;
    _sdkReady = value;
    notifyListeners();
  }

  /// One visit starts only on a real transition into this placement's tab.
  void startVisit() {
    _visitActive = true;
    _impressionThisVisit = false;
    _visitId++;
    notifyListeners();
  }

  void endVisit() {
    if (!_visitActive) return;
    _visitActive = false;
    notifyListeners();
  }

  /// Counts only Google's actual impression callback, never insertion/load.
  ///
  /// Deliberately not gated on [canOffer]. An impression that arrives as the
  /// user leaves the tab would find `_visitActive` already cleared by
  /// [endVisit], and dropping it here would let a view Google has counted go
  /// unrecorded locally — the next visit would then serve inside the gap
  /// this method exists to keep. The only thing refused is a second callback
  /// for the same visit.
  void recordImpression() {
    if (_impressionThisVisit || _ownsNoAds) return;
    _impressionThisVisit = true;
    notifyListeners();
    unawaited(_saveImpression());
  }

  Future<void> _saveImpression() async {
    try {
      await _store.recordNativeAdImpression();
    } on Object {
      // The network impression already happened, so it must stay spent for
      // this visit even when local storage is temporarily unavailable.
    }
  }
}

/// The Movimientos slot.
class NativeAdScope extends InheritedNotifier<NativeAds> {
  const NativeAdScope({super.key, required NativeAds ads, required super.child})
    : super(notifier: ads);

  static NativeAds? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<NativeAdScope>()?.notifier;
}

/// The Presupuesto slot. A separate type so each tab finds its own
/// controller without the other's notifications rebuilding it.
class BudgetNativeAdScope extends InheritedNotifier<NativeAds> {
  const BudgetNativeAdScope({
    super.key,
    required NativeAds ads,
    required super.child,
  }) : super(notifier: ads);

  static NativeAds? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<BudgetNativeAdScope>()
      ?.notifier;
}
