import 'catalog_entry.dart';

/// Stable anchors shared by every hybrid room theme.
///
/// A theme can draw its identity-defining furniture into the background, but
/// these four places stay available for personalisation. Keeping the anchors
/// semantic means a future room can move them without changing saved data.
enum RoomSlot { rug, floorRight, wallCenter, tabletop }

enum RoomDecorCategory { rooms, furniture, wallAndFloor, props, cats }

abstract final class RoomThemes {
  static const casaClaraId = 'casa-clara';
  static const casaClaraPreviewAsset =
      'assets/rooms/casa_clara/hybrid_background.png';
  static const casaClaraPortraitAsset =
      'assets/rooms/casa_clara/hybrid_background_portrait.png';

  static Map<RoomSlot, String> defaultPlacementsFor(String roomId) =>
      roomId == casaClaraId
      ? RoomDecorAssets.defaultPlacements
      : const <RoomSlot, String>{};
}

abstract final class RoomDecorAssets {
  static const defaultRugId = 'casa-clara-default-rug';
  static const defaultTablePlantId = 'casa-clara-default-table-plant';

  static const rug = 'assets/rooms/casa_clara/items/rug.png';
  static const lamp = 'assets/rooms/casa_clara/items/lamp.png';
  static const tablePlant = 'assets/rooms/casa_clara/items/table_plant.png';
  static const wallFrame = 'assets/rooms/casa_clara/items/wall_frame.png';

  static const defaultPlacements = <RoomSlot, String>{
    RoomSlot.rug: defaultRugId,
    RoomSlot.tabletop: defaultTablePlantId,
  };

  static String? assetFor(String id) => switch (id) {
    defaultRugId || 'item-04' => rug,
    defaultTablePlantId || 'item-03' => tablePlant,
    'item-01' => lamp,
    'item-05' => wallFrame,
    _ => null,
  };

  static RoomSlot? slotForItemId(String id) => switch (id) {
    defaultRugId || 'item-04' => RoomSlot.rug,
    defaultTablePlantId || 'item-03' => RoomSlot.tabletop,
    'item-01' => RoomSlot.floorRight,
    'item-05' => RoomSlot.wallCenter,
    _ => null,
  };

  static RoomSlot? slotForCatalogEntry(CatalogEntry entry) =>
      slotForItemId(entry.id);

  static RoomDecorCategory categoryForItemId(String id) => switch (id) {
    'item-01' => RoomDecorCategory.furniture,
    defaultRugId || 'item-04' || 'item-05' => RoomDecorCategory.wallAndFloor,
    defaultTablePlantId || 'item-03' => RoomDecorCategory.props,
    _ => RoomDecorCategory.props,
  };
}
