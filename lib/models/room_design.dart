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
  floorRight(RoomSurface.floor),
  // Added after the original slots so old saved slot names remain stable.
  floorCenter(RoomSurface.floor),
  floorAccent(RoomSurface.floor),
  floorCabinet(RoomSurface.floor),
  // Added at the end so names of existing saved placements stay unchanged.
  floorSofa(RoomSurface.floor),
  cabinetTop(RoomSurface.tabletop),
  cabinetTopRight(RoomSurface.tabletop),
  sideTableTop(RoomSurface.tabletop);

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
  /// loads to cover-fit it. The scene layout aligns decor to the landmarks in
  /// each illustration.
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
  List<RoomSlot> slotsForItem(
    String itemId, {
    Map<RoomSlot, String>? placements,
  }) {
    bool available(RoomSlot slot) {
      if (!slots.contains(slot)) return false;
      final onCabinetOrBookcase =
          placements == null ||
          placements[RoomSlot.floorCabinet] == RoomDecorAssets.lowCabinetId ||
          placements[RoomSlot.floorCabinet] == RoomDecorAssets.slimBookcaseId;
      final onSideTable =
          placements == null ||
          placements[RoomSlot.floorRight] == RoomDecorAssets.roundSideTableId;
      return switch (slot) {
        RoomSlot.cabinetTop =>
          itemId == RoomDecorAssets.savingsJarId && onCabinetOrBookcase,
        RoomSlot.cabinetTopRight =>
          (itemId == RoomDecorAssets.defaultTablePlantId ||
                  itemId == 'item-03') &&
              onCabinetOrBookcase,
        RoomSlot.sideTableTop =>
          (itemId == RoomDecorAssets.savingsJarId ||
                  itemId == RoomDecorAssets.defaultTablePlantId ||
                  itemId == 'item-03') &&
              onSideTable,
        _ => true,
      };
    }

    final suggested = RoomDecorAssets.suggestedSlotsFor(itemId);
    if (suggested != null) {
      return [
        for (final slot in suggested)
          if (available(slot)) slot,
      ];
    }
    return [
      for (final surface in RoomDecorAssets.surfacesFor(itemId))
        for (final slot in slotsFor(surface))
          if (available(slot)) slot,
    ];
  }
}

abstract final class RoomThemes {
  static const casaClaraId = 'casa-clara';
  static const casaJardinId = 'casa-jardin';
  static const casaDePlayaId = 'casa-de-playa';
  static const casaTorreId = 'casa-torre';
  static const casaMontanaId = 'casa-montana';
  static const casaInvernaderoId = 'casa-invernadero';
  static const casaClaraPreviewAsset =
      'assets/rooms/casa_clara/background_preview_empty.png';
  static const casaClaraPortraitAsset =
      'assets/rooms/casa_clara/background_portrait_empty.png';
  static const emptyRoomSlots = <RoomSlot>[
    RoomSlot.rug,
    RoomSlot.wallLeft,
    RoomSlot.wallCenter,
    RoomSlot.floorLeft,
    RoomSlot.floorRight,
    RoomSlot.floorCenter,
    RoomSlot.floorAccent,
    RoomSlot.floorCabinet,
    RoomSlot.floorSofa,
    RoomSlot.cabinetTop,
    RoomSlot.cabinetTopRight,
    RoomSlot.sideTableTop,
  ];
  // Broad windows and glass walls leave no clear wall for hanging decorations.
  // Cabinets and side tables still bring their own places for small props.
  static const panoramicRoomSlots = <RoomSlot>[
    RoomSlot.rug,
    RoomSlot.floorLeft,
    RoomSlot.floorRight,
    RoomSlot.floorCenter,
    RoomSlot.floorAccent,
    RoomSlot.floorCabinet,
    RoomSlot.floorSofa,
    RoomSlot.cabinetTop,
    RoomSlot.cabinetTopRight,
    RoomSlot.sideTableTop,
  ];

  static const casaClara = RoomTheme(
    id: casaClaraId,
    previewAsset: casaClaraPreviewAsset,
    previewSize: Size(1536, 1024),
    portraitAsset: casaClaraPortraitAsset,
    portraitSize: Size(1024, 1536),
    slots: RoomSlot.values,
    defaultPlacements: RoomDecorAssets.defaultPlacements,
  );

  static const casaJardin = RoomTheme(
    id: casaJardinId,
    previewAsset: 'assets/rooms/casa_jardin/background_preview_aligned.png',
    previewSize: Size(1536, 1024),
    portraitAsset: 'assets/rooms/casa_jardin/background_portrait.png',
    portraitSize: Size(1024, 1536),
    slots: emptyRoomSlots,
    defaultPlacements: RoomDecorAssets.emptyRoomDefaults,
  );

  static const casaDePlaya = RoomTheme(
    id: casaDePlayaId,
    previewAsset: 'assets/rooms/casa_de_playa/background_preview_aligned.png',
    previewSize: Size(1536, 1024),
    portraitAsset: 'assets/rooms/casa_de_playa/background_portrait.png',
    portraitSize: Size(1024, 1536),
    slots: emptyRoomSlots,
    defaultPlacements: RoomDecorAssets.emptyRoomDefaults,
  );

  static const casaTorre = RoomTheme(
    id: casaTorreId,
    previewAsset: 'assets/rooms/casa_torre/background_preview.png',
    previewSize: Size(1536, 1024),
    portraitAsset: 'assets/rooms/casa_torre/background_portrait_unlit.png',
    portraitSize: Size(1024, 1536),
    slots: panoramicRoomSlots,
    defaultPlacements: RoomDecorAssets.emptyRoomDefaults,
  );

  static const casaMontana = RoomTheme(
    id: casaMontanaId,
    previewAsset: 'assets/rooms/casa_montana/background_preview.png',
    previewSize: Size(1536, 1024),
    portraitAsset: 'assets/rooms/casa_montana/background_portrait_unlit.png',
    portraitSize: Size(1024, 1536),
    slots: panoramicRoomSlots,
    defaultPlacements: RoomDecorAssets.emptyRoomDefaults,
  );

  static const casaInvernadero = RoomTheme(
    id: casaInvernaderoId,
    previewAsset: 'assets/rooms/casa_invernadero/background_preview.png',
    previewSize: Size(1536, 1024),
    portraitAsset:
        'assets/rooms/casa_invernadero/background_portrait_unlit.png',
    portraitSize: Size(1024, 1536),
    slots: panoramicRoomSlots,
    defaultPlacements: RoomDecorAssets.emptyRoomDefaults,
  );

  static const all = <RoomTheme>[
    casaClara,
    casaJardin,
    casaDePlaya,
    casaTorre,
    casaMontana,
    casaInvernadero,
  ];
  static const _all = {
    casaClaraId: casaClara,
    casaJardinId: casaJardin,
    casaDePlayaId: casaDePlaya,
    casaTorreId: casaTorre,
    casaMontanaId: casaMontana,
    casaInvernaderoId: casaInvernadero,
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
  static const lowCabinetId = 'decor-low-cabinet';
  static const slimBookcaseId = 'decor-slim-bookcase';
  static const roundSideTableId = 'decor-round-side-table';
  static const petBedId = 'decor-pet-bed';
  static const savingsJarId = 'decor-savings-jar';
  static const wallShelfId = 'decor-wall-shelf';
  static const terracottaPoufId = 'decor-terracotta-pouf';
  static const blueCreamRugId = 'decor-blue-cream-rug';
  static const launchSofaId = 'launch-sofa';
  static const launchTvId = 'launch-tv';
  static const ivorySofaId = 'decor-ivory-sofa';
  static const bronzeLanternLampId = 'decor-bronze-lantern-lamp';

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
  static const lowCabinet = 'assets/rooms/shared_items/low_cabinet_empty.png';
  static const slimBookcase = 'assets/rooms/shared_items/slim_bookcase.png';
  static const roundSideTable =
      'assets/rooms/shared_items/round_side_table.png';
  static const petBed = 'assets/rooms/shared_items/pet_bed.png';
  static const savingsJar = 'assets/rooms/shared_items/savings_jar.png';
  static const wallShelf = 'assets/rooms/shared_items/wall_shelf.png';
  static const terracottaPouf = 'assets/rooms/shared_items/terracotta_pouf.png';
  static const blueCreamRug = 'assets/rooms/shared_items/blue_cream_rug.png';
  static const launchSofa = 'assets/rooms/shared_items/launch_sofa.png';
  static const ivorySofa = 'assets/rooms/shared_items/ivory_sofa.png';
  static const bronzeLanternLamp =
      'assets/rooms/shared_items/bronze_lantern_lamp.png';
  static const launchTvBase = 'assets/rooms/shared_items/launch_tv_base.png';
  static const launchTv = 'assets/rooms/shared_items/launch_tv_telenovela.png';
  static const launchTvBlink =
      'assets/rooms/shared_items/launch_tv_telenovela_blink.png';
  static const launchTvSoccer =
      'assets/rooms/shared_items/launch_tv_soccer.png';
  static const launchTvSoccerAlt =
      'assets/rooms/shared_items/launch_tv_soccer_alt.png';

  static const defaultPlacements = <RoomSlot, String>{
    RoomSlot.rug: defaultRugId,
    RoomSlot.tabletop: defaultTablePlantId,
  };

  /// Empty themes begin without tabletop furniture. The plant remains owned
  /// and can be placed after the user adds a cabinet.
  static const emptyRoomDefaults = <RoomSlot, String>{
    RoomSlot.rug: defaultRugId,
  };

  static String? assetFor(String id) => switch (id) {
    defaultRugId || 'item-04' => rug,
    defaultTablePlantId || 'item-03' => tablePlant,
    rattanChairId => rattanChair,
    floorLampId => floorLamp,
    wallClockId => wallClock,
    lowCabinetId => lowCabinet,
    slimBookcaseId => slimBookcase,
    roundSideTableId => roundSideTable,
    petBedId => petBed,
    savingsJarId => savingsJar,
    wallShelfId => wallShelf,
    terracottaPoufId => terracottaPouf,
    blueCreamRugId => blueCreamRug,
    launchSofaId => launchSofa,
    launchTvId => launchTv,
    ivorySofaId => ivorySofa,
    bronzeLanternLampId => bronzeLanternLamp,
    'item-01' => lamp,
    'item-05' => wallFrame,
    _ => null,
  };

  /// Where [id] can go, preferred first; empty for anything that is not a
  /// room decoration.
  ///
  /// Small tabletop props need a supporting surface. A room without one can
  /// still show them in the drawer until the user adds the cabinet. The lamp
  /// also stays off the floor, where it read as dropped on the boards.
  static List<RoomSurface> surfacesFor(String id) => switch (id) {
    defaultRugId || 'item-04' => const [RoomSurface.rug],
    defaultTablePlantId || 'item-03' => const [RoomSurface.tabletop],
    rattanChairId || floorLampId => const [RoomSurface.floor],
    wallClockId => const [RoomSurface.wall],
    lowCabinetId ||
    slimBookcaseId ||
    roundSideTableId ||
    petBedId ||
    terracottaPoufId => const [RoomSurface.floor],
    launchSofaId ||
    launchTvId ||
    ivorySofaId ||
    bronzeLanternLampId => const [RoomSurface.floor],
    savingsJarId => const [RoomSurface.tabletop],
    wallShelfId => const [RoomSurface.wall],
    blueCreamRugId => const [RoomSurface.rug],
    'item-01' => const [RoomSurface.tabletop],
    'item-05' => const [RoomSurface.wall],
    _ => const [],
  };

  static List<RoomSurface> surfacesForCatalogEntry(CatalogEntry entry) =>
      surfacesFor(entry.id);

  /// Each new decoration lights only the places where its proportions make
  /// sense. A jar rests on Casa clara's sill or on a placed cabinet, never
  /// directly on the floor. A pet bed sits beside the character.
  static List<RoomSlot>? suggestedSlotsFor(String id) => switch (id) {
    rattanChairId ||
    floorLampId ||
    bronzeLanternLampId => const [RoomSlot.floorLeft, RoomSlot.floorRight],
    defaultTablePlantId || 'item-03' => const [
      RoomSlot.cabinetTopRight,
      RoomSlot.sideTableTop,
      RoomSlot.tabletop,
    ],
    lowCabinetId => const [RoomSlot.floorCabinet],
    slimBookcaseId => const [RoomSlot.floorCabinet],
    roundSideTableId => const [RoomSlot.floorRight],
    launchSofaId || ivorySofaId => const [RoomSlot.floorSofa],
    launchTvId => const [RoomSlot.floorCabinet],
    petBedId => const [RoomSlot.floorCenter],
    savingsJarId => const [
      RoomSlot.cabinetTop,
      RoomSlot.sideTableTop,
      RoomSlot.tabletop,
    ],
    wallShelfId => const [RoomSlot.wallLeft, RoomSlot.wallCenter],
    terracottaPoufId => const [RoomSlot.floorRight],
    blueCreamRugId => const [RoomSlot.rug],
    _ => null,
  };

  /// How tall [id] is drawn, in background pixels, including the image's
  /// transparent margin; null for a rug, which fills its slot instead.
  ///
  /// An item keeps this size on every surface. Stretching it to the slot
  /// made the size depend on where it stood: a small plant on a floor slot
  /// meant for a chair came out as tall as the chair.
  ///
  /// The stage is about 300 px to the metre at the wall: Casa clara's
  /// painted armchair, some 85 cm, is 250 px. The shared items are cropped
  /// to the object, so their figure is the height you see — a chair of about
  /// 85 cm, a floor lamp of about 1.45 m, a clock about 33 cm across. They
  /// first came in at half that and read as doll's-house furniture. The
  /// Casa clara items still carry their margin and were sized with it.
  static double? stageHeightFor(String id) => switch (id) {
    defaultTablePlantId || 'item-03' || 'item-01' => 103,
    'item-05' => 128,
    rattanChairId => 255,
    floorLampId => 430,
    wallClockId => 100,
    lowCabinetId => 240,
    slimBookcaseId => 430,
    roundSideTableId => 215,
    petBedId => 170,
    savingsJarId => 105,
    wallShelfId => 175,
    terracottaPoufId => 170,
    launchSofaId => 285,
    launchTvId => 285,
    ivorySofaId => 240,
    bronzeLanternLampId => 480,
    _ => null,
  };

  static RoomDecorCategory categoryForItemId(String id) => switch (id) {
    'item-01' => RoomDecorCategory.furniture,
    defaultRugId || 'item-04' || 'item-05' => RoomDecorCategory.wallAndFloor,
    defaultTablePlantId || 'item-03' => RoomDecorCategory.props,
    rattanChairId || floorLampId => RoomDecorCategory.furniture,
    wallClockId => RoomDecorCategory.wallAndFloor,
    lowCabinetId ||
    slimBookcaseId ||
    roundSideTableId ||
    petBedId ||
    terracottaPoufId => RoomDecorCategory.furniture,
    launchSofaId ||
    launchTvId ||
    ivorySofaId ||
    bronzeLanternLampId => RoomDecorCategory.furniture,
    savingsJarId => RoomDecorCategory.props,
    wallShelfId || blueCreamRugId => RoomDecorCategory.wallAndFloor,
    _ => RoomDecorCategory.props,
  };

  static bool isSofa(String? id) => id == launchSofaId || id == ivorySofaId;

  static bool isFloorLamp(String? id) =>
      id == floorLampId || id == bronzeLanternLampId;
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
    final allowedSlots = room.slotsForItem(itemId, placements: placements);
    if (allowedSlots.isEmpty) continue;
    if (allowedSlots.contains(slot)) {
      fitted[slot] = itemId;
    } else {
      misplaced.add(itemId);
    }
  }
  for (final itemId in misplaced) {
    if (fitted.containsValue(itemId)) continue;
    final candidates = room.slotsForItem(itemId, placements: fitted);
    if (candidates.isEmpty) continue;
    final free = candidates.where((slot) {
      final current = fitted[slot];
      return current == null || current == RoomDecorAssets.clearedId;
    });
    fitted[free.isEmpty ? candidates.first : free.first] = itemId;
  }
  return fitted;
}
