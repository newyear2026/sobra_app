import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/generated/app_localizations.dart';
import '../services/startup_launch.dart';
import '../theme/app_theme.dart';
import '../widgets/coin_loading_animation.dart';

/// One centered cat, matching Android's launch surface. No second splash layout.
class StartupScreen extends StatelessWidget {
  const StartupScreen({
    super.key,
    this.reducedMotion = false,
    this.failed = false,
    this.onRetry,
    this.launchState,
  });

  static const background = Color(0xFFCFEEEB);
  static const artSize = 144.0;
  static const overlayStyle = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
    systemNavigationBarColor: background,
    systemNavigationBarIconBrightness: Brightness.dark,
  );

  final bool reducedMotion;
  final bool failed;
  final VoidCallback? onRetry;
  final StartupLaunchState? launchState;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final still = reducedMotion || MediaQuery.disableAnimationsOf(context);
    Widget cat() => CoinLoadingAnimation(
      reducedMotion: still || failed,
      startedAt: launchState?.startedAt,
    );
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: Scaffold(
        backgroundColor: background,
        resizeToAvoidBottomInset: false,
        body: failed
            ? SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox.square(dimension: artSize, child: cat()),
                        const SizedBox(height: 24),
                        Semantics(
                          liveRegion: true,
                          child: Text(
                            l10n.startupFailed,
                            textAlign: TextAlign.center,
                            style: pixelText(size: 14, bold: true, height: 1.4),
                          ),
                        ),
                        TextButton(
                          onPressed: onRetry,
                          child: Text(l10n.recoveryRetry),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            : Semantics(
                label: l10n.startupLoading,
                liveRegion: true,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final size = math.max(
                      0.0,
                      math.min(
                        artSize,
                        math.min(constraints.maxWidth, constraints.maxHeight),
                      ),
                    );
                    final bounds = launchState?.bounds;
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        if (bounds != null)
                          Positioned.fromRect(rect: bounds, child: cat())
                        else
                          Center(
                            child: SizedBox.square(
                              dimension: size,
                              child: cat(),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
      ),
    );
  }
}
