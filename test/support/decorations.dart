import 'package:sobra_app/data/catalog_preview_data.dart';
import 'package:sobra_app/models/catalog_entry.dart';
import 'package:sobra_app/state/sobra_store.dart';

/// Owns every room decoration that levels or rewarded ads unlock.
///
/// For tests about placing things, where how an item was earned is beside
/// the point. Gifts and launch gifts stay out: nobody has them by default.
Future<void> ownAllDecorations(SobraStore store) => store.grantCatalogEntries({
  for (final entry in CatalogPreviewData.items)
    if (entry.unlockMethod == CatalogUnlockMethod.level ||
        entry.unlockMethod == CatalogUnlockMethod.rewardedAd)
      entry.id,
});

/// Owns every room, for tests about a room rather than about unlocking one.
Future<void> ownAllRooms(SobraStore store) => store.grantCatalogEntries({
  for (final entry in CatalogPreviewData.rooms)
    if (!store.ownsCatalogEntry(entry)) entry.id,
});

/// Owns every decoration and every room, for tests about arranging a room.
Future<void> ownEverything(SobraStore store) async {
  await ownAllDecorations(store);
  await ownAllRooms(store);
}
