import 'package:flutter/material.dart';

import '../data/catalog_preview_data.dart';
import '../l10n/catalog_labels.dart';
import '../l10n/generated/app_localizations.dart';
import '../l10n/room_labels.dart';
import '../models/catalog_entry.dart';
import '../models/room_design.dart';
import '../state/sobra_store.dart';
import 'collection_screen.dart';
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

  /// Nothing to begin with: a preselected item lit its places before the
  /// user had chosen anything, and the room opened looking mid-edit.
  String? _selectedItemId;
  final Map<String, Map<RoomSlot, String>> _draftRooms = {};
  String? _draftRoomId;
  Map<RoomSlot, String> get _draft => _draftRooms[_draftRoomId]!;

  /// The character the room will keep, once Done is pressed.
  ///
  /// Staged like the placements rather than written on the tap. This screen
  /// promises Undo and Done, and a choice that took effect immediately would
  /// sit outside both — the user would press Undo, watch the lamp go back and
  /// the cat stay, and be right to call that broken.
  String? _draftCharacterId;

  final List<_DecorSnapshot> _history = [];
  bool _saving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final store = SobraScope.of(context);
    _draftRoomId ??= store.equippedRoomId;
    _draftRooms.putIfAbsent(
      _draftRoomId!,
      () => Map.of(store.roomDecorationsFor(_draftRoomId!)),
    );
    _draftCharacterId ??= store.characterId;
  }

  void _pushHistory() => _history.add(
    _DecorSnapshot(
      placementsByRoom: {
        for (final room in _draftRooms.entries) room.key: Map.of(room.value),
      },
      roomId: _draftRoomId!,
      characterId: _draftCharacterId!,
    ),
  );

  Future<void> _finish() async {
    if (_saving) return;
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final l10n = AppLocalizations.of(context);
    final store = SobraScope.of(context);
    final saved = await guardStoreWrite(messenger, l10n, () async {
      await store.saveRoomSelection(
        roomId: _draftRoomId!,
        placementsByRoom: _draftRooms,
      );
      if (_draftCharacterId != store.characterId) {
        await store.equipCharacter(
          CatalogPreviewData.characters.firstWhere(
            (entry) => entry.id == _draftCharacterId,
          ),
        );
      }
    });
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
    final previous = _history.removeLast();
    setState(() {
      _draftRooms
        ..clear()
        ..addAll({
          for (final room in previous.placementsByRoom.entries)
            room.key: Map.of(room.value),
        });
      _draftRoomId = previous.roomId;
      _draftCharacterId = previous.characterId;
      _selectedItemId = null;
    });
  }

  void _selectChoice(_RoomChoice choice) {
    if (choice.isLink) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const CollectionScreen(openedFromDecorate: true),
        ),
      );
      return;
    }
    final roomId = choice.roomId;
    if (roomId != null) {
      if (roomId == _draftRoomId) return;
      final store = SobraScope.of(context);
      setState(() {
        _pushHistory();
        _draftRoomId = roomId;
        _draftRooms.putIfAbsent(
          roomId,
          () => Map.of(store.roomDecorationsFor(roomId)),
        );
        _selectedItemId = null;
      });
      return;
    }
    final characterId = choice.characterId;
    if (characterId != null) {
      if (characterId == _draftCharacterId) return;
      setState(() {
        _pushHistory();
        _draftCharacterId = characterId;
      });
      return;
    }
    if (choice.surfaces.isEmpty) return;
    setState(() => _selectedItemId = choice.id);
  }

  /// Puts the selected item in [slot], or takes it out if it is already there.
  ///
  /// An item is in one place at a time, so placing it somewhere new moves it.
  /// Whatever [slot] held goes back to the drawer. The scene only offers
  /// slots of the item's surfaces; the check here is for a stale tap.
  void _place(RoomSlot slot) {
    final itemId = _selectedItemId;
    if (itemId == null ||
        !RoomDecorAssets.surfacesFor(itemId).contains(slot.surface)) {
      return;
    }
    setState(() {
      _pushHistory();
      if (_draft[slot] == itemId) {
        _draft.remove(slot);
        return;
      }
      _draft.removeWhere((_, placed) => placed == itemId);
      _draft[slot] = itemId;
    });
  }

  String _hint(AppLocalizations l10n, RoomTheme room) {
    if (_category == RoomDecorCategory.rooms) return l10n.roomChooseTheme;
    if (_category == RoomDecorCategory.characters) {
      return l10n.roomCharacterInstruction;
    }
    final itemId = _selectedItemId;
    final surfaces = itemId == null
        ? const <RoomSurface>[]
        : RoomDecorAssets.surfacesFor(itemId);
    if (surfaces.isEmpty) return l10n.roomInstruction;
    final count = room.slotsForItem(itemId!).length;
    if (_draft.containsValue(itemId)) {
      return count > 1 ? l10n.roomMoveOrRemove : l10n.roomTapToRemove;
    }
    if (surfaces.length > 1) return l10n.roomPickAny(count);
    return switch (surfaces.single) {
      RoomSurface.wall => l10n.roomPickWall(count),
      RoomSurface.floor => l10n.roomPickFloor(count),
      RoomSurface.tabletop => l10n.roomPickTabletop(count),
      RoomSurface.rug => l10n.roomPickRug(count),
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final store = SobraScope.of(context);
    final room = RoomThemes.byId(_draftRoomId!);
    final choices = _choicesFor(
      _category,
      l10n,
      store,
      _draftRoomId!,
      _draftCharacterId,
      _draft,
    );
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
                        roomId: room.id,
                        placements: _draft,
                        message: l10n.homeGoingWell,
                        showSlots: true,
                        selectedItemId: _selectedItemId,
                        characterId: _draftCharacterId,
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
                              _hint(l10n, room),
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
                        selectedRoomId: _draftRoomId!,
                        selectedCharacterId: _draftCharacterId,
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
    required this.selectedRoomId,
    required this.selectedCharacterId,
    required this.onCategoryChanged,
    required this.onChoiceTap,
  });

  final RoomDecorCategory category;
  final List<_RoomChoice> choices;
  final String? selectedItemId;
  final String selectedRoomId;
  final String? selectedCharacterId;
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
                  selected: choice.roomId != null
                      ? choice.roomId == selectedRoomId
                      : choice.characterId != null
                      ? choice.characterId == selectedCharacterId
                      : selectedItemId == choice.id,
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
  Widget build(BuildContext context) {
    if (choice.isLink) return _link(context);
    return Semantics(
      button: true,
      selected: selected,
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
                  color: AppColors.tealInk,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _link(BuildContext context) => Semantics(
    button: true,
    label: choice.label,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: AppColors.paperLight,
          border: Border.all(color: AppColors.line, width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            choice.preview,
            const SizedBox(height: 6),
            Text(
              choice.label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: pixelText(size: 11, bold: true, color: AppColors.muted),
            ),
          ],
        ),
      ),
    ),
  );
}

/// One step of the decorate screen's Undo stack.
///
/// Room, character and placements are staged together until Done.
class _DecorSnapshot {
  const _DecorSnapshot({
    required this.placementsByRoom,
    required this.roomId,
    required this.characterId,
  });

  final Map<String, Map<RoomSlot, String>> placementsByRoom;
  final String roomId;
  final String characterId;
}

class _RoomChoice {
  const _RoomChoice({
    required this.id,
    required this.label,
    required this.status,
    required this.preview,
    this.surfaces = const [],
    this.roomId,
    this.characterId,
  }) : isLink = false;

  /// The tile that leaves for the collection.
  ///
  /// The drawer shows only what the user already owns, so nothing in it can be
  /// bought or unlocked. This is the one door out, sitting last in the
  /// category rather than appearing as a price on something they cannot have.
  const _RoomChoice.link({required this.label})
    : id = linkId,
      status = '',
      preview = const Icon(Icons.add, size: 26, color: AppColors.muted),
      surfaces = const [],
      roomId = null,
      characterId = null,
      isLink = true;

  static const linkId = '__collection__';

  final String id;
  final String label;
  final String status;
  final Widget preview;

  /// Where a decoration can go; empty for rooms, characters and the link.
  final List<RoomSurface> surfaces;

  /// Set on a theme tile; themes are staged rather than placed in a slot.
  final String? roomId;

  /// Set on character tiles, which are equipped rather than put in a slot.
  final String? characterId;

  final bool isLink;
}

/// What the drawer offers for [category]: owned things, and a way to get more.
///
/// Nothing locked appears here. The drawer used to list what the user did not
/// have under a label reading "buy" or "watch an ad" — neither of which this
/// screen can do. Tapping one repeated the label in a snackbar and stopped, so
/// it read as a broken button. Acquiring belongs to the collection, and the
/// last tile goes there.
List<_RoomChoice> _choicesFor(
  RoomDecorCategory category,
  AppLocalizations l10n,
  SobraStore store,
  String chosenRoomId,
  String? chosenCharacterId,
  Map<RoomSlot, String> placements,
) {
  final choices = <_RoomChoice>[];
  final room = RoomThemes.byId(chosenRoomId);
  String decorStatus(String id) =>
      placements.containsValue(id) ? l10n.roomPlaced : l10n.collectionOwned;

  if (category == RoomDecorCategory.rooms) {
    // All three themes are available from the start. Each has its own saved
    // arrangement, so switching the draft room does not move its furniture.
    return [
      for (final room in RoomThemes.all)
        _RoomChoice(
          id: room.id,
          roomId: room.id,
          label: roomThemeDisplayName(l10n, room.id),
          status: room.id == chosenRoomId
              ? l10n.collectionEquipped
              : l10n.collectionOwned,
          preview: Image.asset(
            room.previewAsset,
            fit: BoxFit.cover,
            excludeFromSemantics: true,
          ),
        ),
    ];
  }

  if (category == RoomDecorCategory.characters) {
    for (final entry in CatalogPreviewData.characters) {
      if (!store.ownsCatalogEntry(entry)) continue;
      choices.add(
        _RoomChoice(
          id: entry.id,
          characterId: entry.id,
          label: catalogEntryDisplayName(l10n, entry),
          status: entry.id == chosenCharacterId
              ? l10n.collectionEquipped
              : l10n.collectionOwned,
          preview: _characterPreview(entry),
        ),
      );
    }
    return choices..add(_RoomChoice.link(label: l10n.roomMoreInCollection));
  }

  if (category == RoomDecorCategory.wallAndFloor) {
    choices.add(
      _assetChoice(
        id: RoomDecorAssets.defaultRugId,
        label: l10n.roomDefaultRug,
        asset: RoomDecorAssets.rug,
        status: decorStatus(RoomDecorAssets.defaultRugId),
      ),
    );
  }
  if (category == RoomDecorCategory.props) {
    choices.add(
      _assetChoice(
        id: RoomDecorAssets.defaultTablePlantId,
        label: l10n.roomTablePlant,
        asset: RoomDecorAssets.tablePlant,
        status: decorStatus(RoomDecorAssets.defaultTablePlantId),
      ),
    );
  }

  for (final entry in CatalogPreviewData.items) {
    if (RoomDecorAssets.assetFor(entry.id) == null ||
        RoomDecorAssets.categoryForItemId(entry.id) != category ||
        room.slotsForItem(entry.id).isEmpty ||
        !store.ownsCatalogEntry(entry)) {
      continue;
    }
    choices.add(
      _assetChoice(
        id: entry.id,
        label: _itemLabel(l10n, entry),
        asset: RoomDecorAssets.assetFor(entry.id)!,
        status: decorStatus(entry.id),
      ),
    );
  }
  return choices..add(_RoomChoice.link(label: l10n.roomMoreInCollection));
}

/// Final character packs render their own art; the rest stay placeholders.
///
/// The character registry is the source of truth for whether final sprite art
/// exists, so placeholder catalog entries remain cheap icons.
Widget _characterPreview(CatalogEntry entry) => Center(
  child: CharacterCatalog.all.containsKey(entry.id)
      ? CharacterSprite(
          characterId: entry.id,
          role: CharacterMotionRole.idle,
          width: 72,
          animate: false,
          semanticLabel: entry.name,
        )
      : const Icon(Icons.pets_outlined, size: 34, color: AppColors.muted),
);

_RoomChoice _assetChoice({
  required String id,
  required String label,
  required String asset,
  required String status,
}) => _RoomChoice(
  id: id,
  label: label,
  status: status,
  surfaces: RoomDecorAssets.surfacesFor(id),
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
      RoomDecorCategory.characters => l10n.roomCategoryCharacters,
    };

String _itemLabel(AppLocalizations l10n, CatalogEntry entry) =>
    switch (entry.id) {
      'item-01' => l10n.roomFloorLamp,
      'item-03' => l10n.roomTablePlant,
      'item-04' => l10n.roomDefaultRug,
      'item-05' => l10n.roomWallFrame,
      _ => catalogEntryDisplayName(l10n, entry),
    };
