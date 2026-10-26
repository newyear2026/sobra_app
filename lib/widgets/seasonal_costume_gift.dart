import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../l10n/labels.dart';
import '../models/character_costume.dart';
import '../models/room_design.dart';
import '../screens/room_decorate_screen.dart';
import '../state/sobra_store.dart';
import '../theme/app_theme.dart';
import 'cat_sprite.dart';
import 'pixel_ui.dart';

/// One optional entry into the gift, on home and in the acquisition collection.
/// Receiving costumes does not auto-equip them or grant any base characters.
class SeasonalCostumeGiftBanner extends StatelessWidget {
  const SeasonalCostumeGiftBanner({super.key});

  Future<void> _open(BuildContext context) async {
    // Claiming removes the banner. Keep the route's navigator rather than the
    // banner's soon-to-be-unmounted context for the wardrobe continuation.
    final navigator = Navigator.of(context);
    final wardrobe = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.paperLight,
      shape: const RoundedRectangleBorder(
        side: BorderSide(color: AppColors.ink, width: 3),
      ),
      builder: (_) => const _SeasonalGiftSheet(),
    );
    if (!navigator.mounted || wardrobe != true) return;
    await navigator.push<void>(
      MaterialPageRoute(
        builder: (_) => const RoomDecorateScreen(
          initialCategory: RoomDecorCategory.characters,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = SobraScope.of(context);
    if (!store.canClaimSeasonalCostumes) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    return Semantics(
      button: true,
      child: InkWell(
        key: const ValueKey('seasonal-costume-gift'),
        onTap: () => _open(context),
        child: PixelCard(
          color: AppColors.cashSoft,
          borderColor: AppColors.cashInk,
          elevation: PixelElevation.none,
          child: Row(
            children: [
              const Icon(
                Icons.card_giftcard,
                color: AppColors.cashInk,
                size: 30,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.seasonalGiftTitle,
                      style: pixelText(size: 16, bold: true),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      l10n.seasonalGiftKeeps,
                      style: pixelText(size: 13, color: AppColors.cashInk),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      l10n.seasonalGiftView,
                      style: pixelText(
                        size: 13,
                        bold: true,
                        color: AppColors.tealInk,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: AppColors.cashInk),
            ],
          ),
        ),
      ),
    );
  }
}

class _SeasonalGiftSheet extends StatefulWidget {
  const _SeasonalGiftSheet();

  @override
  State<_SeasonalGiftSheet> createState() => _SeasonalGiftSheetState();
}

class _SeasonalGiftSheetState extends State<_SeasonalGiftSheet> {
  bool _busy = false;
  bool _closed = false;
  String? _error;

  Future<void> _claim() async {
    if (_busy) return;
    final store = SobraScope.of(context);
    final l10n = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final delivered = await store.claimSeasonalCostumes();
      if (mounted) {
        setState(
          () => _closed = !delivered && !store.hasClaimedSeasonalCostumes,
        );
      }
    } on Object catch (error) {
      if (mounted) setState(() => _error = describeStoreFailure(l10n, error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = SobraScope.of(context);
    final l10n = AppLocalizations.of(context);
    final claimed = store.hasClaimedSeasonalCostumes;
    final deadline = MaterialLocalizations.of(
      context,
    ).formatShortDate(CharacterCostumes.lastClaimDay);
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * .9,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(Icons.card_giftcard, color: AppColors.cashInk),
                  const Spacer(),
                  IconButton(
                    tooltip: MaterialLocalizations.of(
                      context,
                    ).closeButtonTooltip,
                    onPressed: () => Navigator.pop(context, false),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              Text(
                claimed ? l10n.seasonalGiftReceived : l10n.seasonalGiftTitle,
                style: pixelText(size: 26, bold: true),
              ),
              const SizedBox(height: 10),
              Text(l10n.seasonalGiftBody, style: pixelText(size: 15)),
              if (!claimed) ...[
                const SizedBox(height: 10),
                Text(
                  l10n.seasonalGiftDeadline(deadline),
                  style: pixelText(
                    size: 13,
                    color: AppColors.cashInk,
                    bold: true,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              LayoutBuilder(
                builder: (context, constraints) {
                  final width = ((constraints.maxWidth - 16) / 3).clamp(
                    50.0,
                    112.0,
                  );
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      for (final id in const ['poodle', 'michi', 'alpaca'])
                        CharacterSprite(
                          characterId: id,
                          costumeId: CharacterCostumes.forCharacter(
                            id,
                          ).single.id,
                          role: CharacterMotionRole.idle,
                          width: width,
                          animate: false,
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 8),
              Text(
                l10n.seasonalGiftPreview,
                textAlign: TextAlign.center,
                style: pixelText(size: 12, color: AppColors.muted),
              ),
              const SizedBox(height: 20),
              PixelCard(
                color: AppColors.cashSoft,
                borderColor: AppColors.cashInk,
                elevation: PixelElevation.none,
                child: Text(
                  l10n.seasonalGiftKeeps,
                  style: pixelText(
                    size: 16,
                    bold: true,
                    color: AppColors.cashInk,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                l10n.seasonalGiftLockedCharacters,
                style: pixelText(
                  size: 14,
                  color: AppColors.muted,
                  height: 1.45,
                ),
              ),
              if (_error != null || _closed) ...[
                const SizedBox(height: 14),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    _error ?? l10n.seasonalGiftClosed,
                    style: pixelText(size: 14, color: AppColors.dangerInk),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              PixelButton(
                key: const ValueKey('claim-seasonal-costumes'),
                maxLines: 2,
                label: claimed
                    ? l10n.seasonalGiftWardrobe
                    : l10n.seasonalGiftClaim(CharacterCostumes.all.length),
                onPressed: _busy || _closed
                    ? null
                    : claimed
                    ? () => Navigator.pop(context, true)
                    : _claim,
              ),
              if (_busy)
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
