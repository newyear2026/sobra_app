import 'package:flutter/material.dart';

import '../data/catalog_preview_data.dart';
import '../l10n/catalog_labels.dart';
import '../l10n/generated/app_localizations.dart';
import '../l10n/labels.dart';
import '../models/catalog_entry.dart';
import '../services/purchase_service.dart';
import '../state/sobra_store.dart';
import '../theme/app_theme.dart';
import '../widgets/cat_sprite.dart';
import '../widgets/character_room.dart';
import '../widgets/pixel_ui.dart';

class CollectionScreen extends StatefulWidget {
  const CollectionScreen({
    super.key,
    this.priceSource = const PreviewCatalogPriceSource(),
  });

  /// Used only where no [PurchaseScope] sits above this screen — a test, or
  /// the debug design gallery. The running app puts the live store there, and
  /// its prices win: they are the ones the user will actually be charged.
  final CatalogPriceSource priceSource;

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> {
  CatalogKind _selectedKind = CatalogKind.character;

  /// Watched rather than polled.
  ///
  /// [SobraPurchases.buy] returns the moment the store sheet is open, so a
  /// rejection — which arrives later, on the purchase stream — is not there to
  /// read when the call comes back. Reading it then reported nothing at all
  /// for the one case that matters: the user who tried to pay and could not.
  SobraPurchases? _purchases;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final purchases = PurchaseScope.maybeOf(context);
    if (identical(purchases, _purchases)) return;
    _purchases?.removeListener(_onPurchasesChanged);
    _purchases = purchases;
    _purchases?.addListener(_onPurchasesChanged);
  }

  @override
  void dispose() {
    _purchases?.removeListener(_onPurchasesChanged);
    super.dispose();
  }

  void _onPurchasesChanged() {
    if (!mounted) return;
    final failure = _purchases?.takeFailure();
    if (failure == null) return;
    _showNotice(describePurchaseFailure(AppLocalizations.of(context), failure));
  }

  CatalogEntryState _stateFor(
    CatalogEntry entry,
    SobraStore store,
    CatalogPriceSource prices,
    bool Function(String)? buying,
  ) {
    final isOwned = store.ownsCatalogEntry(entry);
    final productId = entry.storeProductId;
    return CatalogEntryState(
      entry: entry,
      isOwned: isOwned,
      isEquipped: isOwned && store.equippedIdFor(entry.kind) == entry.id,
      rewardedAdProgress: store.rewardedAdProgressFor(entry.id),
      localizedStorePrice: productId == null
          ? null
          : prices.localizedPriceFor(productId),
      isPurchasing:
          !isOwned && productId != null && (buying?.call(productId) ?? false),
    );
  }

  Future<void> _performPrimaryAction(CatalogEntryState state) async {
    final l10n = AppLocalizations.of(context);
    // Read before any await: this route can be popped while a write or a
    // checkout is in flight, and looking the scope up afterwards would be a
    // use of a dead context rather than of the store the user acted on.
    final store = SobraScope.of(context);
    final purchases = PurchaseScope.maybeOf(context);

    if (!state.isOwned) {
      if (state.entry.unlockMethod == CatalogUnlockMethod.purchase &&
          purchases != null) {
        // Nothing to report here. What comes back from the store arrives on
        // the stream, and [_onPurchasesChanged] is what says so.
        await purchases.buy(state.entry);
        return;
      }
      // Rewarded ads have no provider yet, and a purchase with no store above
      // this screen is the design gallery rather than the app.
      _showNotice(l10n.collectionPreviewActionNotice);
      return;
    }

    await store.equipCatalogEntry(state.entry);
    if (!mounted) return;
    _showNotice(
      l10n.collectionEquippedNotice(catalogEntryDisplayName(l10n, state.entry)),
    );
  }

  void _showNotice(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openDetails(CatalogEntryState state) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => _CatalogDetailDialog(
        state: state,
        onPrimary: _canAct(state)
            ? () {
                Navigator.pop(dialogContext);
                _performPrimaryAction(state);
              }
            : null,
      ),
    );
  }

  bool _canAct(CatalogEntryState state) {
    if (state.isOwned) return !state.isEquipped;
    // A second tap during a checkout cannot open a second one, so the control
    // stops looking live rather than accepting a tap and doing nothing.
    if (state.isPurchasing) return false;
    return state.entry.unlockMethod != CatalogUnlockMethod.level;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final store = SobraScope.of(context);
    final purchases = PurchaseScope.maybeOf(context);
    final prices = purchases ?? widget.priceSource;
    final xp = store.xpProgress;
    final entries = CatalogPreviewData.forKind(_selectedKind);
    final states = [
      for (final entry in entries)
        _stateFor(entry, store, prices, purchases?.isBuying),
    ];
    final ownedCount = states.where((state) => state.isOwned).length;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: CustomScrollView(
              key: const PageStorageKey('collection-scroll'),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
                  sliver: SliverList.list(
                    children: [
                      _CollectionHeader(
                        title: l10n.collectionTitle,
                        onBack: Navigator.of(context).canPop()
                            ? () => Navigator.of(context).pop()
                            : null,
                        level: xp.level,
                        current: xp.currentLevelXp,
                        target: xp.targetLevelXp,
                        isMaxLevel: xp.isMaxLevel,
                      ),
                      const SizedBox(height: 18),
                      _CatalogTabs(
                        selected: _selectedKind,
                        onChanged: (kind) {
                          if (_selectedKind != kind) {
                            setState(() => _selectedKind = kind);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _SummaryPanel(
                              icon: _selectedKind == CatalogKind.character
                                  ? Icons.pets
                                  : Icons.chair_outlined,
                              text: l10n.collectionOwnedCount(
                                ownedCount,
                                states.length,
                              ),
                              bold: true,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _SummaryPanel(
                              icon: _selectedKind == CatalogKind.character
                                  ? Icons.auto_awesome_outlined
                                  : Icons.home_outlined,
                              text: _selectedKind == CatalogKind.character
                                  ? l10n.collectionCharactersHint
                                  : l10n.collectionItemsHint,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          mainAxisExtent: 236,
                        ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _CatalogCard(
                        state: states[index],
                        onTap: () => _openDetails(states[index]),
                      ),
                      childCount: states.length,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CollectionHeader extends StatelessWidget {
  const _CollectionHeader({
    required this.title,
    required this.onBack,
    required this.level,
    required this.current,
    required this.target,
    required this.isMaxLevel,
  });

  final String title;
  final VoidCallback? onBack;
  final int level;
  final int current;
  final int target;
  final bool isMaxLevel;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      SizedBox(
        height: 70,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 400;
            final artWidth = compact ? 96.0 : 176.0;
            return Row(
              children: [
                if (onBack != null)
                  IconButton(
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back, size: 26),
                    color: AppColors.ink,
                    tooltip: AppLocalizations.of(context).back,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(width: 40),
                  ),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: pixelText(
                      size: compact && onBack != null ? 25 : 31,
                      bold: true,
                    ),
                  ),
                ),
                SizedBox(width: compact ? 8 : 12),
                Container(
                  width: artWidth,
                  decoration: BoxDecoration(
                    color: AppColors.paperLight,
                    border: Border.all(color: AppColors.ink, width: 2.5),
                  ),
                  child: ClipRect(
                    child: Image.asset(
                      CharacterRoom.casaClaraBackgroundAsset,
                      fit: BoxFit.cover,
                      alignment: Alignment.centerRight,
                      excludeFromSemantics: true,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      const SizedBox(height: 8),
      Row(
        children: [
          _LevelBadge(level: level),
          const SizedBox(width: 10),
          Expanded(
            child: _XpLine(
              current: current,
              target: target,
              isMaxLevel: isMaxLevel,
            ),
          ),
        ],
      ),
    ],
  );
}

class _LevelBadge extends StatelessWidget {
  const _LevelBadge({required this.level});

  final int level;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: AppColors.surface,
      border: Border.all(color: AppColors.ink, width: 2.5),
    ),
    child: Text(
      AppLocalizations.of(context).collectionLevel(level),
      style: pixelText(size: 13, bold: true),
    ),
  );
}

class _XpLine extends StatelessWidget {
  const _XpLine({
    required this.current,
    required this.target,
    required this.isMaxLevel,
  });

  final int current;
  final int target;
  final bool isMaxLevel;

  @override
  Widget build(BuildContext context) {
    final value = isMaxLevel || target <= 0 ? 1.0 : current / target;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedProgress(value: value),
        const SizedBox(height: 3),
        Text(
          isMaxLevel
              ? AppLocalizations.of(context).xpMaxLevel
              : '$current / $target XP',
          textAlign: TextAlign.end,
          style: pixelText(size: 12, bold: true, color: AppColors.muted),
        ),
      ],
    );
  }
}

class _CatalogTabs extends StatelessWidget {
  const _CatalogTabs({required this.selected, required this.onChanged});

  final CatalogKind selected;
  final ValueChanged<CatalogKind> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.ink, width: 2.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: _CatalogTab(
              label: l10n.collectionCharacters.toUpperCase(),
              selected: selected == CatalogKind.character,
              onTap: () => onChanged(CatalogKind.character),
            ),
          ),
          Container(width: 2.5, height: 48, color: AppColors.ink),
          Expanded(
            child: _CatalogTab(
              label: l10n.collectionItems.toUpperCase(),
              selected: selected == CatalogKind.item,
              onTap: () => onChanged(CatalogKind.item),
            ),
          ),
        ],
      ),
    );
  }
}

class _CatalogTab extends StatelessWidget {
  const _CatalogTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    button: true,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: ColoredBox(
        color: selected ? AppColors.teal : AppColors.surface,
        child: SizedBox(
          height: 48,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: pixelText(
                    size: 15,
                    bold: true,
                    color: selected ? Colors.white : AppColors.ink,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _SummaryPanel extends StatelessWidget {
  const _SummaryPanel({
    required this.icon,
    required this.text,
    this.bold = false,
  });

  final IconData icon;
  final String text;
  final bool bold;

  @override
  Widget build(BuildContext context) => Container(
    height: 62,
    padding: const EdgeInsets.symmetric(horizontal: 10),
    decoration: const BoxDecoration(color: AppColors.paperLight),
    child: Row(
      children: [
        Icon(icon, color: AppColors.tealInk, size: 24),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: pixelText(size: bold ? 16 : 12, bold: bold, height: 1.15),
          ),
        ),
      ],
    ),
  );
}

class _CatalogCard extends StatelessWidget {
  const _CatalogCard({required this.state, required this.onTap});

  final CatalogEntryState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tones = _CatalogTones.forState(state);
    final l10n = AppLocalizations.of(context);
    return Semantics(
      button: true,
      label: catalogEntryDisplayName(l10n, state.entry),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(
              color: state.isEquipped ? AppColors.teal : AppColors.line,
              width: state.isEquipped ? 3 : 2.5,
            ),
          ),
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(child: _CatalogPreview(entry: state.entry)),
                    if (state.isEquipped)
                      const Positioned(
                        right: 0,
                        top: 0,
                        child: _CornerBadge(
                          icon: Icons.check,
                          color: AppColors.teal,
                        ),
                      )
                    else if (!state.isOwned &&
                        state.entry.unlockMethod == CatalogUnlockMethod.level)
                      const Positioned(
                        right: 0,
                        top: 0,
                        child: _CornerBadge(
                          icon: Icons.lock,
                          color: AppColors.ink,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                catalogEntryDisplayName(l10n, state.entry),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: pixelText(size: 14, bold: true),
              ),
              if (state.localizedStorePrice != null) ...[
                const SizedBox(height: 4),
                Text(
                  state.localizedStorePrice!,
                  style: pixelText(
                    size: 12,
                    bold: true,
                    color: AppColors.cashInk,
                  ),
                ),
              ] else
                const SizedBox(height: 20),
              const SizedBox(height: 5),
              Container(
                width: double.infinity,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: tones.background,
                  border: Border.all(color: tones.foreground, width: 2),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (tones.icon != null) ...[
                          Icon(tones.icon, color: tones.foreground, size: 17),
                          const SizedBox(width: 5),
                        ],
                        Text(
                          _cardActionLabel(l10n, state),
                          style: pixelText(
                            size: 12,
                            bold: true,
                            color: tones.foreground,
                          ),
                        ),
                      ],
                    ),
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

class _CatalogPreview extends StatelessWidget {
  const _CatalogPreview({required this.entry});

  final CatalogEntry entry;

  @override
  Widget build(BuildContext context) {
    if (entry.visual == CatalogVisual.michi) {
      return const Center(
        child: CharacterSprite(
          characterId: 'michi',
          role: CharacterMotionRole.idle,
          width: 104,
          animate: false,
          semanticLabel: 'Michi',
        ),
      );
    }
    final icon = switch (entry.visual) {
      CatalogVisual.characterPlaceholder => Icons.pets_outlined,
      CatalogVisual.lamp => Icons.lightbulb_outline,
      CatalogVisual.savings => Icons.savings_outlined,
      CatalogVisual.plant => Icons.local_florist,
      CatalogVisual.rug => Icons.texture,
      CatalogVisual.frame => Icons.photo_outlined,
      CatalogVisual.shelf => Icons.shelves,
      CatalogVisual.chair => Icons.chair_outlined,
      CatalogVisual.clock => Icons.schedule,
      CatalogVisual.trophy => Icons.emoji_events_outlined,
      CatalogVisual.cushion => Icons.weekend_outlined,
      CatalogVisual.michi => Icons.pets,
    };
    final tint = entry.kind == CatalogKind.character
        ? AppColors.violetSoft
        : AppColors.cashSoft;
    final foreground = entry.kind == CatalogKind.character
        ? AppColors.violet
        : AppColors.cashInk;
    return Center(
      child: Container(
        width: 88,
        height: 88,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: tint,
          border: Border.all(color: AppColors.ink, width: 2.5),
        ),
        child: Icon(icon, color: foreground, size: 48),
      ),
    );
  }
}

class _CornerBadge extends StatelessWidget {
  const _CornerBadge({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 32,
    height: 32,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: color,
      border: Border.all(color: AppColors.surface, width: 2),
    ),
    child: Icon(icon, color: Colors.white, size: 18),
  );
}

class _CatalogDetailDialog extends StatelessWidget {
  const _CatalogDetailDialog({required this.state, required this.onPrimary});

  final CatalogEntryState state;
  final VoidCallback? onPrimary;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
      contentPadding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
      actionsPadding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
      title: Row(
        children: [
          Expanded(child: Text(catalogEntryDisplayName(l10n, state.entry))),
          IconButton(
            tooltip: l10n.cancel,
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
      content: SizedBox(
        width: 330,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 132, child: _CatalogPreview(entry: state.entry)),
            const SizedBox(height: 12),
            Text(
              l10n.collectionHowToGet,
              style: pixelText(size: 13, bold: true, color: AppColors.muted),
            ),
            const SizedBox(height: 4),
            Text(
              _unlockDescription(l10n, state),
              style: pixelText(size: 15, bold: true),
            ),
          ],
        ),
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: onPrimary,
          child: Text(_dialogActionLabel(l10n, state)),
        ),
      ],
    );
  }
}

class _CatalogTones {
  const _CatalogTones(this.background, this.foreground, [this.icon]);

  final Color background;
  final Color foreground;
  final IconData? icon;

  factory _CatalogTones.forState(CatalogEntryState state) {
    if (state.isEquipped) {
      return const _CatalogTones(
        AppColors.tealSoft,
        AppColors.tealInk,
        Icons.check,
      );
    }
    if (state.isOwned) {
      return const _CatalogTones(AppColors.tealSoft, AppColors.tealInk);
    }
    return switch (state.entry.unlockMethod) {
      CatalogUnlockMethod.purchase => const _CatalogTones(
        AppColors.cashSoft,
        AppColors.cashInk,
      ),
      CatalogUnlockMethod.rewardedAd => const _CatalogTones(
        AppColors.violetSoft,
        AppColors.violet,
        Icons.play_arrow,
      ),
      CatalogUnlockMethod.level => const _CatalogTones(
        AppColors.blueSoft,
        AppColors.blue,
        Icons.lock,
      ),
      CatalogUnlockMethod.included => const _CatalogTones(
        AppColors.tealSoft,
        AppColors.tealInk,
      ),
    };
  }
}

String _cardActionLabel(AppLocalizations l10n, CatalogEntryState state) {
  if (state.isPurchasing) return l10n.collectionPurchasing;
  if (state.isEquipped) return l10n.collectionEquipped;
  if (state.isOwned) {
    return state.entry.kind == CatalogKind.item
        ? l10n.collectionOwned
        : l10n.collectionEquip;
  }
  return switch (state.entry.unlockMethod) {
    CatalogUnlockMethod.purchase => l10n.collectionBuy,
    CatalogUnlockMethod.rewardedAd =>
      state.entry.kind == CatalogKind.character
          ? l10n.collectionAdProgress(
              state.rewardedAdProgress,
              state.entry.rewardedAdTarget!,
            )
          : l10n.collectionWatchAd,
    CatalogUnlockMethod.level => l10n.collectionLevel(
      state.entry.requiredLevel!,
    ),
    CatalogUnlockMethod.included => l10n.collectionOwned,
  };
}

String _dialogActionLabel(AppLocalizations l10n, CatalogEntryState state) {
  if (state.isPurchasing) return l10n.collectionPurchasing;
  if (state.isEquipped) return l10n.collectionEquipped;
  if (state.isOwned) return l10n.collectionEquip;
  return switch (state.entry.unlockMethod) {
    CatalogUnlockMethod.purchase => l10n.collectionBuy,
    CatalogUnlockMethod.rewardedAd => l10n.collectionWatchAd,
    CatalogUnlockMethod.level => l10n.collectionLevel(
      state.entry.requiredLevel!,
    ),
    CatalogUnlockMethod.included => l10n.collectionOwned,
  };
}

String _unlockDescription(AppLocalizations l10n, CatalogEntryState state) {
  if (state.isOwned) return l10n.collectionAlreadyOwned;
  return switch (state.entry.unlockMethod) {
    CatalogUnlockMethod.included => l10n.collectionIncludedUnlock,
    CatalogUnlockMethod.purchase => l10n.collectionPurchaseUnlock(
      state.localizedStorePrice ?? l10n.collectionStorePricePending,
    ),
    CatalogUnlockMethod.rewardedAd => l10n.collectionAdUnlock(
      state.rewardedAdProgress,
      state.entry.rewardedAdTarget!,
    ),
    CatalogUnlockMethod.level => l10n.collectionLevelUnlock(
      state.entry.requiredLevel!,
    ),
  };
}
