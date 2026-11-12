import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../services/exit_native_ad_service.dart';
import '../theme/app_theme.dart';

/// Measured once before presentation. Neither load completion nor a changed
/// store can change this dialog's geometry or move its buttons.
class ExitDialogLayout {
  const ExitDialogLayout({
    required this.width,
    required this.padding,
    required this.titleHeight,
    required this.bodyHeight,
    required this.buttonHeight,
    required this.textScaler,
    required this.adSize,
  });

  final double width;
  final double padding;
  final double titleHeight;
  final double bodyHeight;
  final double buttonHeight;
  final TextScaler textScaler;
  final ExitAdSize? adSize;

  double heightFor(ExitAdSize? size) =>
      4 +
      44 +
      titleHeight +
      8 +
      bodyHeight +
      20 +
      buttonHeight +
      (size == null ? 0 : size.height + 32 + 2 + 16);

  static ExitDialogLayout measure(BuildContext context) {
    final media = MediaQuery.of(context);
    final l10n = AppLocalizations.of(context);
    final available = Size(
      media.size.width - media.padding.horizontal - media.viewInsets.horizontal,
      media.size.height - media.padding.vertical - media.viewInsets.vertical,
    );
    final width = math.min(368.0, math.max(0.0, available.width - 16));
    final padding = width >= 344 ? (width - 324) / 2 : 16.0;
    final contentWidth = math.max(1.0, width - 4 - padding * 2);
    double measure(String value, TextStyle style, double maxWidth) {
      final painter = TextPainter(
        text: TextSpan(text: value, style: style),
        textDirection: Directionality.of(context),
        textScaler: media.textScaler,
      )..layout(maxWidth: math.max(1, maxWidth));
      final height = painter.height.ceilToDouble();
      painter.dispose();
      return height;
    }

    final title = measure(l10n.exitAppTitle, exitTitleStyle, contentWidth);
    final body = measure(l10n.exitAppBody, exitBodyStyle, contentWidth);
    final buttonWidth = (contentWidth - 12) / 2 - 16;
    final buttons = math.max(
      52.0,
      24.0 +
          math.max(
            measure(l10n.cancel, exitButtonStyle, buttonWidth),
            measure(l10n.exitAppAction, exitButtonStyle, buttonWidth),
          ),
    );
    ExitDialogLayout layout(ExitAdSize? size) => ExitDialogLayout(
      width: width,
      padding: padding,
      titleHeight: title,
      bodyHeight: body,
      buttonHeight: buttons,
      textScaler: media.textScaler,
      adSize: size,
    );
    final base = layout(null);
    // Native template text belongs to the platform; avoid squeezing its
    // fixed rows at large accessibility scales. Keep the exit actions usable.
    if (contentWidth < ExitAdSize.width || media.textScaler.scale(16) > 22) {
      return base;
    }
    final maxHeight = math.min(available.height - 48, available.height * .85);
    for (final size in [ExitAdSize.medium, ExitAdSize.small]) {
      if (base.heightFor(size) <= maxHeight) return layout(size);
    }
    return base;
  }
}

TextStyle get exitTitleStyle => pixelText(size: 22, bold: true, height: 1.3);
TextStyle get exitBodyStyle =>
    pixelText(size: 14, color: AppColors.inkSoft, height: 1.4);
TextStyle get exitButtonStyle => pixelText(size: 16, bold: true, height: 1.3);

class ExitConfirmationDialog extends StatelessWidget {
  const ExitConfirmationDialog({
    super.key,
    required this.layout,
    required this.title,
    required this.body,
    required this.cancelLabel,
    required this.exitLabel,
    required this.adVisible,
    this.ad,
  });

  final ExitDialogLayout layout;
  final String title;
  final String body;
  final String cancelLabel;
  final String exitLabel;
  final ValueListenable<bool> adVisible;
  final ExitAdCreative? ad;

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: layout.textScaler),
      child: Dialog(
        insetPadding: const EdgeInsets.all(8),
        insetAnimationDuration: Duration.zero,
        backgroundColor: Colors.transparent,
        shape: const RoundedRectangleBorder(),
        child: SizedBox(
          width: layout.width,
          child: SingleChildScrollView(
            child: Container(
              key: const ValueKey('exit-dialog-frame'),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(color: AppColors.ink, width: 2),
                boxShadow: const [
                  BoxShadow(color: AppColors.ink, offset: Offset(3, 4)),
                ],
              ),
              padding: EdgeInsets.symmetric(
                horizontal: layout.padding,
                vertical: 22,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: layout.titleHeight,
                    child: Text(title, style: exitTitleStyle),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: layout.bodyHeight,
                    child: Text(body, style: exitBodyStyle),
                  ),
                  const SizedBox(height: 20),
                  if (ad case final creative?) ...[
                    Center(
                      child: SizedBox(
                        key: const ValueKey('exit-native-ad-slot'),
                        width: ExitAdSize.width,
                        height: creative.size.height,
                        child: ValueListenableBuilder<bool>(
                          valueListenable: adVisible,
                          child: creative.buildWidget(),
                          // Consent/entitlement revocation hides the ad but
                          // retains exactly the space the dialog opened with.
                          builder: (_, visible, child) =>
                              visible ? child! : const SizedBox.expand(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Divider(
                      height: 2,
                      thickness: 2,
                      color: AppColors.line,
                    ),
                    const SizedBox(height: 16),
                  ],
                  Row(
                    children: [
                      Expanded(child: _action(context, cancelLabel, false)),
                      const SizedBox(width: 12),
                      Expanded(child: _action(context, exitLabel, true)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _action(BuildContext context, String label, bool exit) => SizedBox(
    height: layout.buttonHeight,
    child: TextButton(
      key: ValueKey(exit ? 'exit-confirm' : 'exit-cancel'),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        backgroundColor: exit ? AppColors.teal : AppColors.surface,
        foregroundColor: exit ? Colors.white : AppColors.ink,
        shape: const RoundedRectangleBorder(
          side: BorderSide(color: AppColors.ink, width: 2),
        ),
        textStyle: exitButtonStyle,
      ),
      onPressed: () => Navigator.of(context).pop(exit),
      child: Text(label, textAlign: TextAlign.center),
    ),
  );
}
