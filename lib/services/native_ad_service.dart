import 'dart:async';

import 'package:flutter/widgets.dart';

import '../state/sobra_store.dart';

/// Applies Sobra's placement rules independently of the ad SDK widget.
class NativeAds extends ChangeNotifier {
  NativeAds({
    required SobraStore store,
    this.maxImpressionsPerDay = 2,
    this.graceDays = 7,
  }) : _store = store;

  final SobraStore _store;
  final int maxImpressionsPerDay;
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
      _store.nativeAdImpressionsToday < maxImpressionsPerDay;

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

  /// One visit starts only on a real transition into the transactions tab.
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
  /// unspent locally — the next visit would then serve past the daily limit
  /// this method exists to keep. The only thing refused is a second callback
  /// for the same visit; the day and the cap are settled by the store, which
  /// checks both again before it writes.
  void recordImpression() {
    if (_impressionThisVisit || _ownsNoAds) return;
    _impressionThisVisit = true;
    notifyListeners();
    unawaited(_saveImpression());
  }

  Future<void> _saveImpression() async {
    try {
      await _store.recordNativeAdImpression(maxPerDay: maxImpressionsPerDay);
    } on Object {
      // The network impression already happened, so it must stay spent for
      // this visit even when local storage is temporarily unavailable.
    }
  }
}

class NativeAdScope extends InheritedNotifier<NativeAds> {
  const NativeAdScope({super.key, required NativeAds ads, required super.child})
    : super(notifier: ads);

  static NativeAds? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<NativeAdScope>()?.notifier;
}
