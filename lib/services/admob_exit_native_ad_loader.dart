import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../theme/app_theme.dart';
import 'admob_config.dart';
import 'exit_native_ad_service.dart';

const _smallAdChannel = MethodChannel('com.sobra.app/exit_native_ads');
int _requestSequence = 0;

/// Native templates are selected at load time, not resized while on screen.
Future<ExitAdCreative?> loadExitNativeAd(
  ExitAdSize size,
  VoidCallback onImpression,
) async {
  final adUnitId = AdMobConfig.exitNativeAdUnitId.trim();
  if (adUnitId.isEmpty) return null;
  final result = Completer<ExitAdCreative?>();
  final token = size == ExitAdSize.small ? '${++_requestSequence}' : null;
  late final _AdMobExitCreative creative;
  Timer? timeout;
  void fail() {
    timeout?.cancel();
    creative.dispose();
    if (!result.isCompleted) result.complete(null);
  }

  final style = NativeTemplateStyle(
    templateType: size == ExitAdSize.medium
        ? TemplateType.medium
        : TemplateType.small,
    mainBackgroundColor: AppColors.paperLight,
    primaryTextStyle: NativeTemplateTextStyle(
      textColor: AppColors.ink,
      size: 15,
    ),
    secondaryTextStyle: NativeTemplateTextStyle(
      textColor: AppColors.inkSoft,
      size: 12,
    ),
    tertiaryTextStyle: NativeTemplateTextStyle(
      textColor: AppColors.muted,
      size: 12,
    ),
    callToActionTextStyle: NativeTemplateTextStyle(
      textColor: const Color(0xFFFFFFFF),
      backgroundColor: AppColors.teal,
      size: 13,
    ),
  );
  final ad = NativeAd(
    adUnitId: adUnitId,
    request: const AdRequest(),
    factoryId: token == null ? null : 'sobra_exit_small',
    nativeTemplateStyle: token == null ? style : null,
    customOptions: token == null
        ? null
        : {'requestToken': token, 'templateStyle': style},
    listener: NativeAdListener(
      onAdLoaded: (_) async {
        if (result.isCompleted) return;
        if (token != null) {
          try {
            final compatible = await _smallAdChannel.invokeMethod<bool>(
              'isCompatible',
              token,
            );
            if (compatible != true) {
              debugPrint('Exit native small: incompatible creative omitted');
              fail();
              return;
            }
          } on Object {
            fail();
            return;
          }
        }
        timeout?.cancel();
        if (result.isCompleted) {
          creative.dispose();
        } else {
          result.complete(creative);
        }
      },
      onAdFailedToLoad: (_, error) {
        debugPrint('Exit native ad failed: ${error.message}');
        fail();
      },
      onAdImpression: (_) => onImpression(),
    ),
  );
  creative = _AdMobExitCreative(ad, size, token);
  timeout = Timer(const Duration(seconds: 15), fail);
  unawaited(() async {
    try {
      if (token != null) {
        await _smallAdChannel.invokeMethod<void>('prepare', token);
      }
      if (!result.isCompleted) await ad.load();
    } on Object {
      fail();
    }
  }());
  return result.future;
}

class _AdMobExitCreative implements ExitAdCreative {
  _AdMobExitCreative(this.ad, this.size, this.token);
  final NativeAd ad;
  final String? token;
  @override
  final ExitAdSize size;
  bool _disposed = false;

  @override
  Widget buildWidget() => AdWidget(ad: ad);

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    unawaited(ad.dispose());
    if (token != null) {
      unawaited(
        _smallAdChannel
            .invokeMethod<void>('dispose', token)
            .catchError((Object _) {}),
      );
    }
  }
}
