import 'dart:ui' show Size;

import 'catalog_entry.dart';

/// What a decoration stands on, hangs from or lies across.
///
/// An item names the surfaces it can go on and nothing more; the room decides
/// how many places of each surface it has and where they are. That is what
/// lets one frame hang on either wall, and a later room offer three walls
/// without the frame knowing.
enum RoomSurface { wall, floor, tabletop, rug }

/// Named places a room can offer, each on one [RoomSurface].
///
/// Saved placements are keyed by these names, so a name never changes once
/// shipped: `rug`, `floorRight`, `wallCenter` and `tabletop` predate the
/// surfaces and are already in people's saved rooms. A room lists the ones it
/// has in [RoomTheme.slots]; where each one sits is the scene's business.
enum RoomSlot {
  rug(RoomSurface.rug),
  wallLeft(RoomSurface.wall),
  wallCenter(RoomSurface.wall),
  tabletop(RoomSurface.tabletop),
  floorLeft(RoomSurface.floor),
  floorRight(RoomSurface.floor);

  const RoomSlot(this.surface);

  final RoomSurface surface;
}

/// The shelves the decorate drawer is divided into.
///
/// These name what a thing *is*, never what species it is. A per-animal
/// shelf would add a tab for every character pack and leave most of them
/// holding one entry.
enum RoomDecorCategory { rooms, furniture, wallAndFloor, props, characters }

/// A background and the places it offers for decorations.
class RoomTheme {
  const RoomTheme({
    required this.id,
    required this.previewAsset,
    required this.previewSize,
    required this.portraitAsset,
    required this.portraitSize,
    required this.slots,
    this.defaultPlacements = const {},
  });

  final String id;
  final String previewAsset;
  final String portraitAsset;

  /// Each background's size in pixels, which the scene needs before the image
  /// loads: to know how cover-fitting will crop it, and how large a stage
  /// pixel is on screen. Both images share one pixel scale.
  final Size previewSize;
  final Size portraitSize;

  /// Every place this room has, in the order the decorator counts them.
  final List<RoomSlot> slots;

  /// What fills a slot the user has never touched.
  final Map<RoomSlot, String> defaultPlacements;

  /// The places in this room that take [surface].
  List<RoomSlot> slotsFor(RoomSurface surface) => [
    for (final slot in slots)
      if (slot.surface == surface) slot,
  ];

  /// Every place [itemId] can go, its preferred surface first.
  List<RoomSlot> slotsForItem(String itemId) => [
    for (final surface in RoomDecorAssets.surfacesFor(itemId))
      ...slotsFor(surface),
  ];
}

abstract final class RoomThemes {
  static const casaClaraId = 'casa-clara';
  static const casaJardinId = 'casa-jardin';
  static const casaDePlayaId = 'casa-de-playa';
  static const casaClaraPreviewAsset =
      'assets/rooms/casa_clara/hybrid_background.png';
  static const casaClaraPortraitAsset =
      'assets/rooms/casa_clara/hybrid_background_portrait.png';
  static const emptyRoomSlots = <RoomSlot>[
    RoomSlot.rug,
    RoomSlot.wallLeft,
    RoomSlot.wallCenter,
    RoomSlot.floorLeft,
    RoomSlot.floorRight,
  ];

  static const casaClara = RoomTheme(
    id: casaClaraId,
    previewAsset: casaClaraPreviewAsset,
    previewSize: Size(1774, 887),
    portraitAsset: casaClaraPortraitAsset,
    portraitSize: Size(1024, 1536),
    slots: RoomSlot.values,
    defaultPlacements: RoomDecorAssets.defaultPlacements,
  );

  static const casaJardin = RoomTheme(
    id: casaJardinId,
    previewAsset: 'assets/rooms/casa_jardin/background_preview.png',
    previewSize: Size(1536, 1024),
    portraitAsset: 'assets/rooms/casa_jardin/background_portrait.png',
    portraitSize: Size(1024, 1536),
    slots: emptyRoomSlots,
    defaultPlacements: RoomDecorAssets.emptyRoomDefaults,
  );

  static const casaDePlaya = RoomTheme(
    id: casaDePlayaId,
    previewAsset: 'assets/rooms/casa_de_playa/background_preview.png',
    previewSize: Size(1536, 1024),
    portraitAsset: 'assets/rooms/casa_de_playa/background_portrait.png',
    portraitSize: Size(1024, 1536),
    slots: emptyRoomSlots,
    defaultPlacements: RoomDecorAssets.emptyRoomDefaults,
  );

  static const all = <RoomTheme>[casaClara, casaJardin, casaDePlaya];
  static const _all = {
    casaClaraId: casaClara,
    casaJardinId: casaJardin,
    casaDePlayaId: casaDePlaya,
  };

  static bool contains(String roomId) => _all.containsKey(roomId);

  /// The room saved as [roomId], or Casa clara for an id this build lacks.
  static RoomTheme byId(String roomId) => _all[roomId] ?? casaClara;

  static Map<RoomSlot, String> defaultPlacementsFor(String roomId) =>
      _all[roomId]?.defaultPlacements ?? const <RoomSlot, String>{};
}

abstract final class RoomDecorAssets {
  static const defaultRugId = 'casa-clara-default-rug';
  static const defaultTablePlantId = 'casa-clara-default-table-plant';
  static const rattanChairId = 'starter-rattan-chair';
  static const floorLampId = 'starter-floor-lamp';
  static const wallClockId = 'starter-wall-clock';

  /// Saved in place of an item for a slot the user emptied.
  ///
  /// Only needed where the room has a default: a slot missing from the saved
  /// map falls back to that default, so "nothing here" has to be written
  /// down. Never shown and never owned.
  static const clearedId = '';

  static const rug = 'assets/rooms/casa_clara/items/rug.png';
  static const lamp = 'assets/rooms/casa_clara/items/lamp.png';
  static const tablePlant = 'assets/rooms/casa_clara/items/table_plant.png';
  static const wallFrame = 'assets/rooms/casa_clara/items/wall_frame.png';
  static const rattanChair = 'assets/rooms/shared_items/rattan_chair.png';
  static const floorLamp = 'assets/rooms/shared_items/floor_lamp.png';
  static const wallClock = 'assets/rooms/shared_items/wall_clock.png';

  static const defaultPlacements = <RoomSlot, String>{
    RoomSlot.rug: defaultRugId,
    RoomSlot.tabletop: defaultTablePlantId,
  };

  /// New empty themes have no painted-in table to support a tabletop plant.
  static const emptyRoomDefaults = <RoomSlot, String>{
    RoomSlot.rug: defaultRugId,
    RoomSlot.floorLeft: defaultTablePlantId,
  };

  static String? assetFor(String id) => switch (id) {
    defaultRugId || 'item-04' => rug,
    defaultTablePlantId || 'item-03' => tablePlant,
    rattanChairId => rattanChair,
    floorLampId => floorLamp,
    wallClockId => wallClock,
    'item-01' => lamp,
    'item-05' => wallFrame,
    _ => null,
  };

  /// Where [id] can go, preferred first; empty for anything that is not a
  /// room decoration.
  ///
  /// The small plant is at home on a table or the floor, so a room without a
  /// table still has somewhere for it. The lamp is a desk lamp and goes only
  /// on a table: it used to stand on the floor by the window, where it read
  /// as a table lamp dropped on the boards.
  static List<RoomSurface> surfacesFor(String id) => switch (id) {
    defaultRugId || 'item-04' => const [RoomSurface.rug],
    defaultTablePlantId ||
    'item-03' => const [RoomSurface.tabletop, RoomSurface.floor],
    rattanChairId || floorLampId => const [RoomSurface.floor],
    wallClockId => const [RoomSurface.wall],
    'item-01' => const [RoomSurface.tabletop],
    'item-05' => const [RoomSurface.wall],
    _ => const [],
  };

  static List<RoomSurface> surfacesForCatalogEntry(CatalogEntry entry) =>
      surfacesFor(entry.id);

  /// How tall [id] is drawn, in background pixels, including the image's
  /// transparent margin; null for a rug, which fills its slot instead.
  ///
  /// An item keeps this size on every surface. Stretching it to the slot
  /// made the size depend on where it stood: a small plant on a floor slot
  /// meant for a chair came out as tall as the chair.
  static double? stageHeightFor(String id) => switch (id) {
    defaultTablePlantId || 'item-03' || 'item-01' => 103,
    'item-05' => 128,
    rattanChairId => 250,
    floorLampId => 270,
    wallClockId => 128,
    _ => null,
  };

  static RoomDecorCategory categoryForItemId(String id) => switch (id) {
    'item-01' => RoomDecorCategory.furniture,
    defaultRugId || 'item-04' || 'item-05' => RoomDecorCategory.wallAndFloor,
    defaultTablePlantId || 'item-03' => RoomDecorCategory.props,
    rattanChairId || floorLampId => RoomDecorCategory.furniture,
    wallClockId => RoomDecorCategory.wallAndFloor,
    _ => RoomDecorCategory.props,
  };
}

/// Puts every item in [placements] somewhere [room] lets it stand.
///
/// Saved rooms predate surfaces, and an item may have changed surface since
/// it was placed — the lamp was saved on the floor and now belongs on the
/// table. Anything in a slot it cannot take moves to a free slot it can,
/// preferred surface first, taking the first such slot when none is free,
/// since the user chose it and the default it displaces did not. Unknown items, slots the room
/// does not have and repeats of an item already placed are dropped. Cleared
/// markers stay where they are.
Map<RoomSlot, String> fitPlacementsToRoom(
  RoomTheme room,
  Map<RoomSlot, String> placements,
) {
  final fitted = <RoomSlot, String>{};
  final misplaced = <String>[];
  for (final slot in room.slots) {
    final itemId = placements[slot];
    if (itemId == null) continue;
    if (itemId == RoomDecorAssets.clearedId) {
      fitted[slot] = itemId;
      continue;
    }
    if (fitted.containsValue(itemId) || misplaced.contains(itemId)) continue;
    final surfaces = RoomDecorAssets.surfacesFor(itemId);
    if (surfaces.isEmpty) continue;
    if (surfaces.contains(slot.surface)) {
      fitted[slot] = itemId;
    } else {
      misplaced.add(itemId);
    }
  }
  for (final itemId in misplaced) {
    if (fitted.containsValue(itemId)) continue;
    final candidates = room.slotsForItem(itemId);
    if (candidates.isEmpty) continue;
    final free = candidates.where((slot) {
      final current = fitted[slot];
      return current == null || current == RoomDecorAssets.clearedId;
    });
    fitted[free.isEmpty ? candidates.first : free.first] = itemId;
  }
  return fitted;
}
