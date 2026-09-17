import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../services/admob_config.dart';
import '../services/native_ad_service.dart';
import '../theme/app_theme.dart';

/// A small Google native template styled to sit between ledger rows.
class SobraNativeAd extends StatefulWidget {
  const SobraNativeAd({super.key, required this.controller});

  final NativeAds controller;

  @override
  State<SobraNativeAd> createState() => _SobraNativeAdState();
}

class _SobraNativeAdState extends State<SobraNativeAd> {
  NativeAd? _ad;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    if (!AdMobConfig.isSupported || !widget.controller.canOffer) return;
    late final NativeAd ad;
    ad = NativeAd(
      adUnitId: AdMobConfig.nativeAdUnitId,
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (_) {
          if (!mounted || !widget.controller.shouldPlace) {
            ad.dispose();
            return;
          }
          setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('Native ad did not load: ${error.message}');
          ad.dispose();
        },
        onAdImpression: (_) => widget.controller.recordImpression(),
      ),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.small,
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
          textColor: Colors.white,
          backgroundColor: AppColors.teal,
          size: 13,
        ),
      ),
    );
    _ad = ad;
    ad.load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    if (!_loaded || ad == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: ConstrainedBox(
          // Google's small template is specified for 320–400 logical pixels.
          constraints: const BoxConstraints(maxWidth: 400),
          child: Container(
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.paperLight,
              border: Border.all(color: AppColors.ink, width: 2.5),
            ),
            child: AdWidget(ad: ad),
          ),
        ),
      ),
    );
  }
}
