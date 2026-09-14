import 'package:flutter/material.dart';

import '../data/catalog_preview_data.dart';
import '../l10n/catalog_labels.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/catalog_entry.dart';
import '../models/room_design.dart';
import '../state/sobra_store.dart';
import '../theme/app_theme.dart';
import '../widgets/cat_sprite.dart';
import '../widgets/pixel_ui.dart';
import '../widgets/room_scene.dart';

class RoomDecorateScreen extends StatefulWidget {
  const RoomDecorateScreen({super.key});

  @override
  State<RoomDecorateScreen> createState() => _RoomDecorateScreenState();
}

class _RoomDecorateScreenState extends State<RoomDecorateScreen> {
  RoomDecorCategory _category = RoomDecorCategory.furniture;
  String? _selectedItemId = 'item-01';
  Map<RoomSlot, String>? _draft;
  final List<Map<RoomSlot, String>> _history = [];
  bool _saving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _draft ??= Map.of(SobraScope.of(context).roomDecorationsFor());
  }

  Future<void> _finish() async {
    if (_saving) return;
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final l10n = AppLocalizations.of(context);
    final saved = await guardStoreWrite(
      messenger,
      l10n,
      () => SobraScope.of(context).saveRoomDecorations(_draft!),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (!saved) return;
    navigator.pop();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.roomSaved)));
  }

  void _undo() {
    if (_history.isEmpty) return;
    setState(() {
      _draft = _history.removeLast();
    });
  }

  void _selectChoice(_RoomChoice choice) {
    if (!choice.owned) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(choice.status)));
      return;
    }
    if (choice.slot == null) return;
    setState(() => _selectedItemId = choice.id);
  }

  void _place(RoomSlot slot) {
    final itemId = _selectedItemId;
    final itemSlot = itemId == null
        ? null
        : RoomDecorAssets.slotForItemId(itemId);
    if (itemId == null || itemSlot != slot) {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.roomInstruction)));
      return;
    }
    if (_draft![slot] == itemId) return;
    setState(() {
      _history.add(Map.of(_draft!));
      _draft![slot] = itemId;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final store = SobraScope.of(context);
    final choices = _choicesFor(_category, l10n, store);
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final drawerHeight = (constraints.maxHeight * .43).clamp(
                  286.0,
                  370.0,
                );
                return Column(
                  children: [
                    _DecorateTopBar(
                      title: l10n.roomDecorateTitle,
                      backLabel: l10n.back,
                      undoLabel: l10n.undo,
                      doneLabel: l10n.roomDone,
                      canUndo: _history.isNotEmpty,
                      saving: _saving,
                      onBack: () => Navigator.of(context).pop(),
                      onUndo: _undo,
                      onDone: _finish,
                    ),
                    Expanded(
                      child: RoomScene(
                        variant: RoomSceneVariant.immersive,
                        placements: _draft!,
                        message: l10n.homeGoingWell,
                        showSlots: true,
                        selectedItemId: _selectedItemId,
                        onSlotTap: _place,
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      color: AppColors.tealSoft,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.info_outline,
                            size: 20,
                            color: AppColors.tealInk,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              l10n.roomInstruction,
                              textAlign: TextAlign.center,
                              style: pixelText(
                                size: 13,
                                bold: true,
                                color: AppColors.tealInk,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: drawerHeight,
                      child: _DecorDrawer(
                        category: _category,
                        choices: choices,
                        selectedItemId: _selectedItemId,
                        onCategoryChanged: (category) {
                          setState(() {
                            _category = category;
                            _selectedItemId = null;
                          });
                        },
                        onChoiceTap: _selectChoice,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _DecorateTopBar extends StatelessWidget {
  const _DecorateTopBar({
    required this.title,
    required this.backLabel,
    required this.undoLabel,
    required this.doneLabel,
    required this.canUndo,
    required this.saving,
    required this.onBack,
    required this.onUndo,
    required this.onDone,
  });

  final String title;
  final String backLabel;
  final String undoLabel;
  final String doneLabel;
  final bool canUndo;
  final bool saving;
  final VoidCallback onBack;
  final VoidCallback onUndo;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(8, 8, 12, 10),
    child: Row(
      children: [
        IconButton(
          tooltip: backLabel,
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back, size: 28),
          color: AppColors.ink,
        ),
        Expanded(
          child: Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 1,
            style: pixelText(size: 20, bold: true),
          ),
        ),
        IconButton(
          tooltip: undoLabel,
          onPressed: canUndo ? onUndo : null,
          icon: const Icon(Icons.undo, size: 24),
          color: AppColors.ink,
        ),
        PixelButton(
          label: doneLabel,
          expand: false,
          onPressed: saving ? null : onDone,
        ),
      ],
    ),
  );
}

class _DecorDrawer extends StatelessWidget {
  const _DecorDrawer({
    required this.category,
    required this.choices,
    required this.selectedItemId,
    required this.onCategoryChanged,
    required this.onChoiceTap,
  });

  final RoomDecorCategory category;
  final List<_RoomChoice> choices;
  final String? selectedItemId;
  final ValueChanged<RoomDecorCategory> onCategoryChanged;
  final ValueChanged<_RoomChoice> onChoiceTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      decoration: const BoxDecoration(
        color: AppColors.paperLight,
        border: Border(top: BorderSide(color: AppColors.ink, width: 3)),
      ),
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final item in RoomDecorCategory.values) ...[
                  _CategoryButton(
                    label: _categoryLabel(l10n, item),
                    selected: item == category,
                    onTap: () => onCategoryChanged(item),
                  ),
                  if (item != RoomDecorCategory.values.last)
                    const SizedBox(width: 6),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.only(bottom: 14),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: .82,
              ),
              itemCount: choices.length,
              itemBuilder: (context, index) {
                final choice = choices[index];
                return _RoomChoiceTile(
                  choice: choice,
                  selected: selectedItemId == choice.id,
                  onTap: () => onChoiceTap(choice),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryButton extends StatelessWidget {
  const _CategoryButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: label,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minWidth: 76, minHeight: 44),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.teal : AppColors.surface,
          border: Border.all(color: AppColors.ink, width: 2.5),
        ),
        child: Text(
          label,
          style: pixelText(
            size: 13,
            bold: true,
            color: selected ? Colors.white : AppColors.ink,
          ),
        ),
      ),
    ),
  );
}

class _RoomChoiceTile extends StatelessWidget {
  const _RoomChoiceTile({
    required this.choice,
    required this.selected,
    required this.onTap,
  });

  final _RoomChoice choice;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    enabled: choice.owned,
    label: '${choice.label}, ${choice.status}',
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: selected ? AppColors.tealSoft : AppColors.surface,
          border: Border.all(
            color: selected ? AppColors.teal : AppColors.line,
            width: selected ? 3 : 2,
          ),
        ),
        child: Column(
          children: [
            Expanded(child: choice.preview),
            const SizedBox(height: 4),
            Text(
              choice.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: pixelText(size: 12, bold: true),
            ),
            const SizedBox(height: 3),
            Text(
              choice.status,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: pixelText(
                size: 12,
                bold: true,
                color: choice.owned ? AppColors.tealInk : AppColors.muted,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _RoomChoice {
  const _RoomChoice({
    required this.id,
    required this.label,
    required this.status,
    required this.owned,
    required this.preview,
    this.slot,
  });

  final String id;
  final String label;
  final String status;
  final bool owned;
  final Widget preview;
  final RoomSlot? slot;
}

List<_RoomChoice> _choicesFor(
  RoomDecorCategory category,
  AppLocalizations l10n,
  SobraStore store,
) {
  if (category == RoomDecorCategory.rooms) {
    return [
      _RoomChoice(
        id: RoomThemes.casaClaraId,
        label: l10n.roomThemeCasaClara,
        status: l10n.collectionEquipped,
        owned: true,
        preview: Image.asset(
          RoomThemes.casaClaraPreviewAsset,
          fit: BoxFit.cover,
          excludeFromSemantics: true,
        ),
      ),
    ];
  }
  if (category == RoomDecorCategory.cats) {
    return [
      _RoomChoice(
        id: 'michi',
        label: 'Michi',
        status: l10n.collectionEquipped,
        owned: true,
        preview: const Center(
          child: CatSprite(motion: CatMotion.idle, width: 72, animate: false),
        ),
      ),
    ];
  }

  final choices = <_RoomChoice>[];
  if (category == RoomDecorCategory.wallAndFloor) {
    choices.add(
      _assetChoice(
        id: RoomDecorAssets.defaultRugId,
        label: l10n.roomDefaultRug,
        asset: RoomDecorAssets.rug,
        slot: RoomSlot.rug,
        status: l10n.collectionOwned,
      ),
    );
  }
  if (category == RoomDecorCategory.props) {
    choices.add(
      _assetChoice(
        id: RoomDecorAssets.defaultTablePlantId,
        label: l10n.roomTablePlant,
        asset: RoomDecorAssets.tablePlant,
        slot: RoomSlot.tabletop,
        status: l10n.collectionOwned,
      ),
    );
  }

  for (final entry in CatalogPreviewData.items) {
    if (RoomDecorAssets.assetFor(entry.id) == null ||
        RoomDecorAssets.categoryForItemId(entry.id) != category) {
      continue;
    }
    final owned = store.ownsCatalogEntry(entry);
    choices.add(
      _assetChoice(
        id: entry.id,
        label: _itemLabel(l10n, entry),
        asset: RoomDecorAssets.assetFor(entry.id)!,
        slot: RoomDecorAssets.slotForCatalogEntry(entry)!,
        status: owned ? l10n.collectionOwned : _lockedLabel(l10n, entry),
        owned: owned,
      ),
    );
  }
  return choices;
}

_RoomChoice _assetChoice({
  required String id,
  required String label,
  required String asset,
  required RoomSlot slot,
  required String status,
  bool owned = true,
}) => _RoomChoice(
  id: id,
  label: label,
  status: status,
  owned: owned,
  slot: slot,
  preview: Padding(
    padding: const EdgeInsets.all(4),
    child: Image.asset(asset, fit: BoxFit.contain, excludeFromSemantics: true),
  ),
);

String _categoryLabel(AppLocalizations l10n, RoomDecorCategory category) =>
    switch (category) {
      RoomDecorCategory.rooms => l10n.roomCategoryRooms,
      RoomDecorCategory.furniture => l10n.roomCategoryFurniture,
      RoomDecorCategory.wallAndFloor => l10n.roomCategoryWallFloor,
      RoomDecorCategory.props => l10n.roomCategoryProps,
      RoomDecorCategory.cats => l10n.roomCategoryCats,
    };

String _itemLabel(AppLocalizations l10n, CatalogEntry entry) =>
    switch (entry.id) {
      'item-01' => l10n.roomFloorLamp,
      'item-03' => l10n.roomTablePlant,
      'item-04' => l10n.roomDefaultRug,
      'item-05' => l10n.roomWallFrame,
      _ => catalogEntryDisplayName(l10n, entry),
    };

String _lockedLabel(AppLocalizations l10n, CatalogEntry entry) =>
    switch (entry.unlockMethod) {
      CatalogUnlockMethod.level => l10n.collectionLevel(entry.requiredLevel!),
      CatalogUnlockMethod.rewardedAd => l10n.collectionWatchAd,
      CatalogUnlockMethod.purchase => l10n.collectionBuy,
      CatalogUnlockMethod.included => l10n.collectionOwned,
    };
