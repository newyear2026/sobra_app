import '../models/catalog_entry.dart';
import '../models/room_design.dart';
import 'generated/app_localizations.dart';
import 'room_labels.dart';

/// Localized display name for provisional catalog slots.
///
/// Named companions keep their proper name in every language, so it lives on
/// the entry rather than in the ARB files. Numbered entries stay generic until
/// the character and room-item lineup is approved.
String catalogEntryDisplayName(AppLocalizations l10n, CatalogEntry entry) {
  if (_namedCharacterIds.contains(entry.id)) return entry.name;
  if (entry.kind == CatalogKind.room) {
    return roomThemeDisplayName(l10n, entry.id);
  }
  if (entry.id == RoomDecorAssets.rattanChairId) return l10n.roomRattanChair;
  if (entry.id == 'item-01') return l10n.roomFloorLamp;
  if (entry.id == 'item-05') return l10n.roomWallFrame;
  if (entry.id == RoomDecorAssets.floorLampId) return l10n.roomStandingLamp;
  if (entry.id == RoomDecorAssets.wallClockId) return l10n.roomWallClock;
  if (entry.id == RoomDecorAssets.lowCabinetId) return l10n.roomLowCabinet;
  if (entry.id == RoomDecorAssets.slimBookcaseId) return l10n.roomSlimBookcase;
  if (entry.id == RoomDecorAssets.roundSideTableId) {
    return l10n.roomRoundSideTable;
  }
  if (entry.id == RoomDecorAssets.petBedId) return l10n.roomPetBed;
  if (entry.id == RoomDecorAssets.savingsJarId) return l10n.roomSavingsJar;
  if (entry.id == RoomDecorAssets.wallShelfId) return l10n.roomWallShelf;
  if (entry.id == RoomDecorAssets.shelfBooksId) return l10n.roomShelfBooks;
  if (entry.id == RoomDecorAssets.trailingPlantId) {
    return l10n.roomTrailingPlant;
  }
  if (entry.id == RoomDecorAssets.terracottaPoufId) {
    return l10n.roomTerracottaPouf;
  }
  if (entry.id == RoomDecorAssets.blueCreamRugId) {
    return l10n.roomBlueCreamRug;
  }
  if (entry.id == RoomDecorAssets.launchSofaId) return l10n.roomLaunchSofa;
  if (entry.id == RoomDecorAssets.launchTvId) return l10n.roomLaunchTv;
  if (entry.id == RoomDecorAssets.ivorySofaId) return l10n.roomIvorySofa;
  if (entry.id == RoomDecorAssets.bronzeLanternLampId) {
    return l10n.roomBronzeLanternLamp;
  }
  final number = int.tryParse(entry.id.split('-').last) ?? 0;
  return entry.kind == CatalogKind.character
      ? l10n.collectionCharacterPlaceholder(number)
      : l10n.collectionItemPlaceholder(number);
}

const _namedCharacterIds = {
  'michi',
  'poodle',
  'schnauzer',
  'guinea-pig',
  'quokka',
  'capybara',
  'alpaca',
  'platypus',
  'rabbit',
  'raccoon',
  'maltese',
};
