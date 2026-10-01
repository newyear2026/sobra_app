import 'package:flutter/material.dart';

import '../data/catalog_preview_data.dart';
import '../l10n/generated/app_localizations.dart';
import '../services/purchase_service.dart';
import '../state/sobra_store.dart';
import '../theme/app_theme.dart';

/// Shows Los amigos de Michi before anything is charged.
///
/// Both ways into the pack open this: its row in Ajustes and a pack
/// character in the collection. Neither showed what the pack holds before —
/// the row was a line of names and a price, and a character's card showed
/// only that character — so somebody deciding on the pack never saw the
/// three friends together.
///
/// Answers true when the user chose to buy. The caller starts the checkout,
/// because each screen reports a failed purchase in its own way.
Future<bool> showPackOfferDialog(BuildContext context) async =>
    await showDialog<bool>(
      context: context,
      builder: (_) => const PackOfferDialog(),
    ) ??
    false;

class PackOfferDialog extends StatelessWidget {
  const PackOfferDialog({super.key});

  static const illustration = 'assets/pack/los-amigos-de-michi.webp';

  /// The illustration's own proportions, so it is never cropped or stretched.
  static const _illustrationAspect = 1672 / 941;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final store = SobraScope.of(context);
    // Null in a test or the design gallery. The dialog still shows the pack;
    // only the button waits for a store that can sell it.
    final purchases = PurchaseScope.maybeOf(context);
    const productId = CatalogPreviewData.packProductId;
    final owned = store.ownsPack;
    final buying = purchases?.isBuying(productId) ?? false;
    final price = purchases?.localizedPriceFor(productId);
    final buyLabel = owned
        ? l10n.settingsOwned
        : buying
        ? l10n.collectionPurchasing
        : price == null
        ? l10n.collectionBuy
        : l10n.packBuy(price);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      clipBehavior: Clip.hardEdge,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: _illustrationAspect,
                  child: Image.asset(
                    illustration,
                    fit: BoxFit.cover,
                    semanticLabel: l10n.packFriendNames,
                  ),
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: IconButton(
                    tooltip: l10n.cancel,
                    onPressed: () => Navigator.pop(context, false),
                    icon: const Icon(Icons.close, size: 20),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.surface,
                      foregroundColor: AppColors.ink,
                      minimumSize: const Size(36, 36),
                      padding: EdgeInsets.zero,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                        side: BorderSide(color: AppColors.ink, width: 2),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Container(height: 3, color: AppColors.ink),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.settingsPackName,
                      style: pixelText(size: 20, bold: true),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.packFriendNames,
                      style: pixelText(size: 14, color: AppColors.inkSoft),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      l10n.packIncludes,
                      style: pixelText(
                        size: 13,
                        bold: true,
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _IncludedLine(icon: Icons.pets, text: l10n.packFriendsLine),
                    _IncludedLine(icon: Icons.block, text: l10n.packNoAdsLine),
                    _IncludedLine(
                      icon: Icons.all_inclusive,
                      text: l10n.packOnceLine,
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(l10n.cancel),
                  ),
                  // Disabled until the store prices it: a button that
                  // answered nothing would read as broken, and a price this
                  // app made up could differ from the one Play charges.
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.cashSoft,
                      foregroundColor: AppColors.cashInk,
                      side: const BorderSide(
                        color: AppColors.cashInk,
                        width: 2,
                      ),
                    ),
                    onPressed: owned || buying || price == null
                        ? null
                        : () => Navigator.pop(context, true),
                    child: Text(buyLabel),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IncludedLine extends StatelessWidget {
  const _IncludedLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.blue),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: pixelText(size: 15, bold: true))),
        ],
      ),
    );
  }
}
