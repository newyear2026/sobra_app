import '../data/catalog_preview_data.dart';
import '../models/catalog_entry.dart';
import '../models/room_design.dart';
import 'generated/app_localizations.dart';

/// Localized display name for provisional catalog slots.
///
/// Named companions keep their proper name in every language, so it lives on
/// the entry rather than in the ARB files. Numbered entries stay generic until
/// the character and room-item lineup is approved.
String catalogEntryDisplayName(AppLocalizations l10n, CatalogEntry entry) {
  if (_namedCharacterIds.contains(entry.id)) return entry.name;
  if (entry.id == RoomDecorAssets.rattanChairId) return l10n.roomRattanChair;
  if (entry.id == RoomDecorAssets.floorLampId) return l10n.roomStandingLamp;
  if (entry.id == RoomDecorAssets.wallClockId) return l10n.roomWallClock;
  if (entry.id == RoomDecorAssets.lowCabinetId) return l10n.roomLowCabinet;
  if (entry.id == RoomDecorAssets.petBedId) return l10n.roomPetBed;
  if (entry.id == RoomDecorAssets.savingsJarId) return l10n.roomSavingsJar;
  if (entry.id == RoomDecorAssets.wallShelfId) return l10n.roomWallShelf;
  if (entry.id == RoomDecorAssets.terracottaPoufId) {
    return l10n.roomTerracottaPouf;
  }
  if (entry.id == RoomDecorAssets.blueCreamRugId) {
    return l10n.roomBlueCreamRug;
  }
  // Named rather than numbered, like the companions. Parsing a number out of this id
  // would answer zero and put "Item 0" on the card.
  if (entry.id == CatalogPreviewData.packDecorationId) {
    return l10n.collectionPackDecoration;
  }
  if (entry.id == RoomDecorAssets.launchSofaId) return l10n.roomLaunchSofa;
  if (entry.id == RoomDecorAssets.launchTvId) return l10n.roomLaunchTv;
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
  'capybara',
  'alpaca',
  'platypus',
};
