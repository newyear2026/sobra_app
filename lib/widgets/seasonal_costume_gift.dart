import 'package:flutter/material.dart';

import '../l10n/costume_labels.dart';
import '../l10n/generated/app_localizations.dart';
import '../l10n/labels.dart';
import '../models/character_costume.dart';
import '../models/room_design.dart';
import '../screens/room_decorate_screen.dart';
import '../state/sobra_store.dart';
import '../theme/app_theme.dart';
import 'cat_sprite.dart';
import 'pixel_ui.dart';

/// Opens the gift sheet and, if the user asks to try the costumes on, the
/// wardrobe after it. Shared by the home banner and the 1.0.16 release card.
Future<void> openSeasonalCostumeGift(BuildContext context) async {
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

/// One optional entry into the gift, on home and in the acquisition collection.
/// Receiving costumes does not auto-equip them or grant any base characters.
class SeasonalCostumeGiftBanner extends StatelessWidget {
  const SeasonalCostumeGiftBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final store = SobraScope.of(context);
    if (!store.canClaimSeasonalCostumes) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    return Semantics(
      button: true,
      child: InkWell(
        key: const ValueKey('seasonal-costume-gift'),
        onTap: () => openSeasonalCostumeGift(context),
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
    final outfits = CharacterCostumes.all
        .where((costume) => store.ownsCharacter(costume.characterId))
        .toList(growable: false);
    final deadline = MaterialLocalizations.of(
      context,
    ).formatShortMonthDay(CharacterCostumes.lastClaimDay);
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * .9,
        ),
        child: SingleChildScrollView(
          key: const ValueKey('seasonal-gift-scroll'),
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
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
                style: pixelText(size: 30, bold: true, height: 1.15),
              ),
              if (!claimed) ...[
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.schedule,
                      size: 20,
                      color: AppColors.cashInk,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.seasonalGiftDeadline(deadline),
                        style: pixelText(
                          size: 16,
                          color: AppColors.cashInk,
                          bold: true,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              Text(
                l10n.seasonalGiftPreview,
                style: pixelText(size: 22, bold: true, height: 1.2),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.seasonalGiftBody,
                style: pixelText(size: 14, color: AppColors.muted, height: 1.3),
              ),
              for (final costume in outfits) ...[
                _OwnedCostumeGiftRow(costume: costume),
                const Divider(height: 1, color: AppColors.line),
              ],
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.card_giftcard,
                    size: 40,
                    color: AppColors.cashInk,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.seasonalGiftStorageTitle(
                            CharacterCostumes.all.length,
                          ),
                          style: pixelText(size: 17, bold: true, height: 1.2),
                        ),
                        if (outfits.length < CharacterCostumes.all.length) ...[
                          const SizedBox(height: 5),
                          Text(
                            l10n.seasonalGiftLockedCharacters,
                            style: pixelText(
                              size: 14,
                              color: AppColors.muted,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
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
              const SizedBox(height: 12),
              PixelButton(
                key: const ValueKey('claim-seasonal-costumes'),
                maxLines: 3,
                label: claimed
                    ? l10n.seasonalGiftWardrobe
                    : l10n.seasonalGiftClaim,
                onPressed: _busy || _closed
                    ? null
                    : claimed
                    ? () => Navigator.pop(context, true)
                    : _claim,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.seasonalGiftKeeps,
                textAlign: TextAlign.center,
                style: pixelText(size: 13, color: AppColors.muted, height: 1.3),
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

class _OwnedCostumeGiftRow extends StatelessWidget {
  const _OwnedCostumeGiftRow({required this.costume});

  final CharacterCostume costume;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final name = CharacterCatalog.require(costume.characterId).displayName;
    return Padding(
      key: ValueKey('seasonal-gift-character-${costume.characterId}'),
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = (constraints.maxWidth * .28).clamp(64.0, 96.0);
          return Row(
            children: [
              SizedBox(
                width: width + 16,
                child: Center(
                  child: ExcludeSemantics(
                    child: CharacterSprite(
                      characterId: costume.characterId,
                      costumeId: costume.id,
                      role: CharacterMotionRole.idle,
                      width: width,
                      animate: false,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: pixelText(size: 19, bold: true, height: 1.2),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      costumeDisplayName(l10n, costume.id),
                      style: pixelText(
                        size: 17,
                        bold: true,
                        color: AppColors.cashInk,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      l10n.seasonalGiftReady,
                      style: pixelText(
                        size: 14,
                        color: AppColors.muted,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
