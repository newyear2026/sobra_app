import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../theme/app_theme.dart';
import '../widgets/pixel_ui.dart';

/// The first screen of a new install: what Sobrita does, that it needs no
/// account, and one button.
///
/// It sits where the Google account offer used to. That offer promised a
/// sign-in that did not exist, so it went; but the prologue behind it opens
/// on a rainy night and a sound at the door, and starting an app straight
/// into a story felt like being dropped in mid-scene. This is the doorstep.
///
/// It deliberately does not repeat the prologue's title page — the name in
/// big type and the tagline are that page's job. This one says what the app
/// is for and what it keeps, which is the question somebody has before they
/// agree to a story.
///
/// [LoginScreen] stays in the tree for the Drive backup that will replace the
/// account idea after launch; its art is shared with this screen.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key, required this.onStart});

  final VoidCallback onStart;

  /// The art's own pixel width. Everything drawn over it is placed in these
  /// units, so the wordmark lands on the same patch of sky at any width.
  static const _artWidth = 853.0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: ColoredBox(
            color: AppColors.surface,
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final scale = constraints.maxWidth / _artWidth;
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _Hero(scale: scale, name: l10n.appName),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    l10n.onboardingPromise,
                                    style: pixelText(
                                      size: 30,
                                      bold: true,
                                      height: 1.12,
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Padding(
                                        padding: EdgeInsets.only(top: 2),
                                        child: Icon(
                                          Icons.lock_outline,
                                          size: 17,
                                          color: AppColors.teal,
                                        ),
                                      ),
                                      const SizedBox(width: 7),
                                      Expanded(
                                        child: Text(
                                          l10n.onboardingNoAccount,
                                          style: pixelText(
                                            size: 15,
                                            color: AppColors.inkSoft,
                                            height: 1.45,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            // Same inset as the prologue's buttons, so the one
                            // under the thumb does not jump on the next page.
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                20,
                                16,
                                20,
                                18,
                              ),
                              child: PixelButton(
                                label: l10n.onboardingStart,
                                onPressed: onStart,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Michi on the way in, with the app's name in the sky above.
///
/// The name is type rather than part of the picture. The art used to carry
/// it as pixels, and the rename to Sobrita left the old name painted there.
class _Hero extends StatelessWidget {
  const _Hero({required this.scale, required this.name});

  final double scale;
  final String name;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: WelcomeScreen._artWidth / 800,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/login/michi-device-transfer-hero.png',
            fit: BoxFit.cover,
            filterQuality: FilterQuality.none,
            excludeFromSemantics: true,
          ),
          Positioned(
            left: 56 * scale,
            top: 66 * scale,
            child: Semantics(
              header: true,
              child: Text(
                name,
                // Part of the picture, so it scales with the picture rather
                // than with the reader's text size, which would push it off
                // the sky and into the clouds.
                textScaler: TextScaler.noScaling,
                style: pixelText(size: 78 * scale, bold: true),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
