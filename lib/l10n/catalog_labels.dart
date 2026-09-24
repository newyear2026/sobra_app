import '../data/catalog_preview_data.dart';
import '../models/catalog_entry.dart';
import '../models/room_design.dart';
import 'generated/app_localizations.dart';

/// Localized display name for provisional catalog slots.
///
/// Michi already has a final proper name. Numbered entries stay generic until
/// the character and room-item lineup is approved.
String catalogEntryDisplayName(AppLocalizations l10n, CatalogEntry entry) {
  if (entry.id == 'michi') return entry.name;
  if (entry.id == 'poodle') return l10n.prologuePoodleName;
  if (entry.id == RoomDecorAssets.rattanChairId) return l10n.roomRattanChair;
  if (entry.id == RoomDecorAssets.floorLampId) return l10n.roomStandingLamp;
  if (entry.id == RoomDecorAssets.wallClockId) return l10n.roomWallClock;
  // Named rather than numbered, like Michi. Parsing a number out of this id
  // would answer zero and put "Item 0" on the card.
  if (entry.id == CatalogPreviewData.packDecorationId) {
    return l10n.collectionPackDecoration;
  }
  final number = int.tryParse(entry.id.split('-').last) ?? 0;
  return entry.kind == CatalogKind.character
      ? l10n.collectionCharacterPlaceholder(number)
      : l10n.collectionItemPlaceholder(number);
}
