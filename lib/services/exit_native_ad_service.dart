import 'dart:async';

import 'package:flutter/widgets.dart';

enum ExitAdSize {
  small(100),
  medium(350);

  const ExitAdSize(this.height);
  final double height;
  static const double width = 320;
}

/// A single loaded creative. Ownership passes from the cache to the dialog.
abstract class ExitAdCreative {
  ExitAdSize get size;
  Widget buildWidget();
  void dispose();
}

typedef ExitAdLoader =
    Future<ExitAdCreative?> Function(
      ExitAdSize size,
      VoidCallback onImpression,
    );

/// Preloads one selected template. Opening a dialog only takes a snapshot;
/// it never waits for a request or subscribes the dialog to load completion.
class ExitNativeAds {
  ExitNativeAds({
    required ExitAdLoader load,
    required VoidCallback onImpression,
    DateTime Function()? now,
    this.maxAge = const Duration(hours: 1),
    this.retryDelay = const Duration(minutes: 1),
  }) : _load = load,
       _onImpression = onImpression,
       _now = now ?? DateTime.now;

  final ExitAdLoader _load;
  final VoidCallback _onImpression;
  final DateTime Function() _now;
  final Duration maxAge;
  final Duration retryDelay;
  static const impressionInterval = Duration(minutes: 5);
  ExitAdSize? _size;
  ExitAdCreative? _ready;
  DateTime? _loadedAt;
  DateTime? _lastImpressionAt;
  DateTime? _retryAt;
  Timer? _retryTimer;
  int _generation = 0;
  bool _enabled = false;
  bool _loading = false;
  bool _presenting = false;
  bool _disposed = false;

  void configure({required ExitAdSize? size, required bool enabled}) {
    if (_disposed) return;
    if (_size != size || _enabled != enabled) {
      _generation++;
      _loading = false;
      _discardReady();
      _retryTimer?.cancel();
      _retryAt = null;
      _size = size;
      _enabled = enabled;
    }
    _prepare();
  }

  bool get _fresh {
    final loaded = _loadedAt;
    if (loaded == null) return false;
    final age = _now().difference(loaded);
    return !age.isNegative && age < maxAge;
  }

  /// Keep the current session's gap even if the shared store cannot persist
  /// the SDK impression. The caller still checks the shared placement gap.
  bool get _impressionIntervalElapsed {
    final last = _lastImpressionAt;
    if (last == null) return true;
    final now = _now();
    // Match the shared store's clock-correction policy.
    return last.isAfter(now) || now.difference(last) >= impressionInterval;
  }

  /// Null is final for this presentation, even if an in-flight load finishes.
  ExitAdCreative? beginPresentation({required bool canShow}) {
    if (_disposed || _presenting) return null;
    _presenting = true;
    if (!_fresh) _discardReady();
    if (!_enabled || !canShow || !_impressionIntervalElapsed) return null;
    final ad = _ready;
    _ready = null;
    _loadedAt = null;
    return ad;
  }

  void endPresentation() {
    if (_disposed) return;
    _presenting = false;
    _prepare();
  }

  void _prepare() {
    if (_disposed || !_enabled || _size == null || _presenting || _loading) {
      return;
    }
    if (_ready != null && !_fresh) _discardReady();
    if (_ready != null) return;
    final retryAt = _retryAt;
    if (retryAt != null && _now().isBefore(retryAt)) return;
    _loading = true;
    unawaited(_request(_generation, _size!));
  }

  Future<void> _request(int generation, ExitAdSize size) async {
    var impressed = false;
    ExitAdCreative? ad;
    try {
      ad = await _load(size, () {
        if (impressed) return;
        impressed = true;
        _lastImpressionAt = _now();
        _onImpression();
      });
    } on Object catch (error) {
      debugPrint('Exit native ad unavailable: $error');
    }
    if (_disposed || generation != _generation) {
      ad?.dispose();
      return;
    }
    _loading = false;
    if (ad != null && ad.size == size) {
      _ready = ad;
      _loadedAt = _now();
    } else {
      ad?.dispose();
      _retryAt = _now().add(retryDelay);
      _retryTimer?.cancel();
      _retryTimer = Timer(retryDelay, _prepare);
    }
  }

  void _discardReady() {
    _ready?.dispose();
    _ready = null;
    _loadedAt = null;
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _generation++;
    _retryTimer?.cancel();
    _discardReady();
  }
}
