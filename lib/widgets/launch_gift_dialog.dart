import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/room_design.dart';
import '../theme/app_theme.dart';
import 'pixel_ui.dart';

Future<bool> showLaunchGiftDialog(BuildContext context) async =>
    await showDialog<bool>(
      context: context,
      barrierColor: const Color(0x99242B4A),
      builder: (context) => const _LaunchGiftDialog(),
    ) ??
    false;

class _LaunchGiftDialog extends StatelessWidget {
  const _LaunchGiftDialog();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: PixelCard(
        elevation: PixelElevation.hero,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.launchGiftTitle, style: pixelText(size: 19, bold: true)),
            const SizedBox(height: 10),
            Text(l10n.launchGiftBody, style: pixelText(size: 13, height: 1.5)),
            const SizedBox(height: 15),
            _GiftRow(
              asset: RoomDecorAssets.launchSofa,
              name: l10n.roomLaunchSofa,
            ),
            const SizedBox(height: 8),
            _GiftRow(asset: RoomDecorAssets.launchTv, name: l10n.roomLaunchTv),
            const SizedBox(height: 17),
            PixelButton(
              label: l10n.launchGiftGoToRoom,
              onPressed: () => Navigator.of(context).pop(true),
            ),
            const SizedBox(height: 5),
            PixelButton(
              label: l10n.launchGiftLater,
              variant: PixelButtonVariant.secondary,
              onPressed: () => Navigator.of(context).pop(false),
            ),
          ],
        ),
      ),
    );
  }
}

class _GiftRow extends StatelessWidget {
  const _GiftRow({required this.asset, required this.name});

  final String asset;
  final String name;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: AppColors.paperLight,
      border: Border.all(color: AppColors.line, width: 2),
    ),
    child: Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          SizedBox(
            width: 92,
            height: 68,
            child: Image.asset(
              asset,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.none,
              excludeFromSemantics: true,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(child: Text(name, style: pixelText(size: 14, bold: true))),
        ],
      ),
    ),
  );
}
