import 'package:flutter_test/flutter_test.dart';
import 'package:sobra_app/models/room_design.dart';

void main() {
  test('panoramic rooms let supported small props sit on furniture', () {
    for (final room in [
      RoomThemes.casaTorre,
      RoomThemes.casaMontana,
      RoomThemes.casaInvernadero,
    ]) {
      expect(room.slotsForItem(RoomDecorAssets.wallClockId), isEmpty);
      expect(
        room.slotsForItem(
          RoomDecorAssets.defaultTablePlantId,
          placements: const {},
        ),
        isEmpty,
      );

      final cabinetPlacements = {
        RoomSlot.floorCabinet: RoomDecorAssets.lowCabinetId,
        RoomSlot.cabinetTop: RoomDecorAssets.savingsJarId,
        RoomSlot.cabinetTopRight: RoomDecorAssets.defaultTablePlantId,
      };
      expect(
        room.slotsForItem(
          RoomDecorAssets.defaultTablePlantId,
          placements: cabinetPlacements,
        ),
        contains(RoomSlot.cabinetTopRight),
      );
      expect(
        fitPlacementsToRoom(room, cabinetPlacements),
        containsPair(
          RoomSlot.cabinetTopRight,
          RoomDecorAssets.defaultTablePlantId,
        ),
      );

      final tablePlacements = {
        RoomSlot.floorRight: RoomDecorAssets.roundSideTableId,
        RoomSlot.sideTableTop: RoomDecorAssets.defaultTablePlantId,
      };
      expect(
        room.slotsForItem(
          RoomDecorAssets.defaultTablePlantId,
          placements: tablePlacements,
        ),
        contains(RoomSlot.sideTableTop),
      );
      expect(
        fitPlacementsToRoom(room, tablePlacements),
        containsPair(
          RoomSlot.sideTableTop,
          RoomDecorAssets.defaultTablePlantId,
        ),
      );
    }
  });
}
