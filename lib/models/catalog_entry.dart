import 'package:flutter/foundation.dart';

/// The two families shown by the collection surface.
enum CatalogKind { character, item }

/// One, and only one, route by which a catalog entry becomes available.
enum CatalogUnlockMethod { included, purchase, rewardedAd, level }

/// The visual slot a preview entry occupies until its final art is approved.
///
/// This is deliberately semantic rather than an [IconData]. The catalog stays
/// independent from Material, and a future asset pack can replace the preview
/// renderer without changing any unlock or store data.
enum CatalogVisual {
  michi,
  characterPlaceholder,
  lamp,
  savings,
  plant,
  rug,
  frame,
  shelf,
  chair,
  clock,
  trophy,
  cushion,
}

/// Static, remotely replaceable facts about one character or room item.
///
/// Real-money prices do not belong here. [storeProductId] is the stable lookup
/// key; StoreKit or Google Play Billing will later return the localized price
/// that the view displays.
@immutable
class CatalogEntry {
  const CatalogEntry({
    required this.id,
    required this.name,
    required this.kind,
    required this.unlockMethod,
    required this.visual,
    this.assetPath,
    this.requiredLevel,
    this.rewardedAdTarget,
    this.storeProductId,
  }) : assert(id != ''),
       assert(name != ''),
       assert(
         unlockMethod == CatalogUnlockMethod.level
             ? requiredLevel != null && requiredLevel > 0
             : requiredLevel == null,
       ),
       assert(
         unlockMethod == CatalogUnlockMethod.rewardedAd
             ? rewardedAdTarget != null && rewardedAdTarget > 0
             : rewardedAdTarget == null,
       ),
       assert(
         unlockMethod == CatalogUnlockMethod.purchase
             ? storeProductId != null && storeProductId != ''
             : storeProductId == null,
       );

  final String id;
  final String name;
  final CatalogKind kind;
  final CatalogUnlockMethod unlockMethod;
  final CatalogVisual visual;
  final String? assetPath;
  final int? requiredLevel;
  final int? rewardedAdTarget;
  final String? storeProductId;
}

/// User-specific state resolved separately from the static catalog.
///
/// The preview screen builds this in memory. A later persistence step can load
/// the same shape from [SobraStore] without changing the screen or definitions.
@immutable
class CatalogEntryState {
  CatalogEntryState({
    required this.entry,
    required this.isOwned,
    required this.isEquipped,
    this.rewardedAdProgress = 0,
    this.localizedStorePrice,
  }) : assert(!isEquipped || isOwned),
       assert(rewardedAdProgress >= 0),
       assert(
         localizedStorePrice == null ||
             entry.unlockMethod == CatalogUnlockMethod.purchase,
       );

  final CatalogEntry entry;
  final bool isOwned;
  final bool isEquipped;
  final int rewardedAdProgress;

  /// Presentation-only price received from a store price source.
  final String? localizedStorePrice;
}
