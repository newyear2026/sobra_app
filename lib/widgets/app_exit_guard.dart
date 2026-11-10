import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/native_ad_slot.dart';
import '../services/admob_config.dart';
import '../services/admob_consent_service.dart';
import '../services/admob_exit_native_ad_loader.dart';
import '../services/exit_native_ad_service.dart';
import '../state/sobra_store.dart';
import 'exit_confirmation_dialog.dart';

/// Installed only on the shell's root route. Pushed screens and other dialogs
/// retain their normal back behavior. The application owns Android exit.
class AppExitGuard extends StatefulWidget {
  const AppExitGuard({super.key, required this.child, this.ads, this.adLoader})
    : assert(ads == null || adLoader == null);
  final Widget child;
  final ExitNativeAds? ads;
  final ExitAdLoader? adLoader;

  @override
  State<AppExitGuard> createState() => _AppExitGuardState();
}

class _AppExitGuardState extends State<AppExitGuard>
    with WidgetsBindingObserver {
  SobraStore? _store;
  AdMobConsentController? _consent;
  ExitNativeAds? _ads;
  ExitDialogLayout? _layout;
  ValueNotifier<bool>? _adVisible;
  bool _dialogOpen = false;
  bool _leaving = false;
  bool _foreground = true;

  bool get _android =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  bool get _allowed =>
      AdMobConfig.isSupported &&
      (_consent?.canRequestAds ?? false) &&
      !(_store?.ownsNoAds ?? true);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final store = SobraScope.of(context);
    if (!identical(store, _store)) {
      _store?.removeListener(_sync);
      if (widget.ads == null) _ads?.dispose();
      _store = store..addListener(_sync);
      _ads =
          widget.ads ??
          ExitNativeAds(
            load: widget.adLoader ?? loadExitNativeAd,
            now: () => store.currentMoment,
            onImpression: () {
              if (!store.ownsNoAds) unawaited(_saveImpression(store));
            },
          );
    }
    final consent = AdMobConsentScope.maybeOf(context);
    if (!identical(consent, _consent)) {
      _consent?.removeListener(_sync);
      _consent = consent?..addListener(_sync);
    }
    _layout = ExitDialogLayout.measure(context);
    _sync();
  }

  Future<void> _saveImpression(SobraStore store) async {
    try {
      await store.recordNativeAdImpression(NativeAdSlot.exit);
    } on Object {
      // The SDK impression already happened. ExitNativeAds retains its
      // session cooldown even if disk storage is temporarily unavailable.
      debugPrint('Exit native impression could not be saved');
    }
  }

  void _sync() {
    _ads?.configure(size: _layout?.adSize, enabled: _foreground && _allowed);
    if (!_allowed && _adVisible?.value == true) _adVisible!.value = false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // An advertiser destination must not insert another ad on return.
    if (state == AppLifecycleState.resumed) {
      _foreground = true;
      _sync();
    } else if (state == AppLifecycleState.paused) {
      _foreground = false;
      _sync();
    }
  }

  Future<void> _confirmExit() async {
    if (_dialogOpen ||
        _leaving ||
        !(ModalRoute.of(context)?.isCurrent ?? false)) {
      return;
    }
    _dialogOpen = true;
    final layout = ExitDialogLayout.measure(context);
    _layout = layout;
    // No request is started by the back press: configure/preload happens as
    // dependencies change. Only a matching, already-loaded creative is used.
    final ads = _ads;
    final ad = ads?.beginPresentation(
      canShow:
          _allowed &&
          (_store?.nativeAdIntervalElapsed(
                NativeAdSlot.exit,
                ExitNativeAds.impressionInterval,
              ) ??
              false),
    );
    final usableAd = ad?.size == layout.adSize ? ad : null;
    if (usableAd == null) ad?.dispose();
    final visible = ValueNotifier(true);
    _adVisible = visible;
    final l10n = AppLocalizations.of(context);
    final route = DialogRoute<bool>(
      context: context,
      barrierColor: const Color(0x99242B4A),
      builder: (_) => ExitConfirmationDialog(
        layout: layout,
        title: l10n.exitAppTitle,
        body: l10n.exitAppBody,
        cancelLabel: l10n.cancel,
        exitLabel: l10n.exitAppAction,
        adVisible: visible,
        ad: usableAd,
      ),
    );
    try {
      final exit = await Navigator.of(context).push(route);
      // Platform views remain alive throughout the reverse transition.
      await route.completed;
      if (exit == true && mounted) {
        _leaving = true;
        await SystemNavigator.pop();
      }
    } finally {
      usableAd?.dispose();
      _adVisible = null;
      visible.dispose();
      _dialogOpen = false;
      if (mounted && !_leaving) {
        _sync();
        ads?.endPresentation();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _store?.removeListener(_sync);
    _consent?.removeListener(_sync);
    if (widget.ads == null) _ads?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope<Object?>(
    canPop: !_android,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop && _android) unawaited(_confirmExit());
    },
    child: widget.child,
  );
}
