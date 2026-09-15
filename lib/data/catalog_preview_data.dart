import '../models/catalog_entry.dart';

/// Replaceable data used while the character and item lineup is still open.
///
/// Only Michi is final. Numbered entries intentionally avoid deciding the
/// future cats or room objects before their art and commercial plan are ready.
abstract final class CatalogPreviewData {
  static const characters = <CatalogEntry>[
    CatalogEntry(
      id: 'michi',
      name: 'Michi',
      kind: CatalogKind.character,
      unlockMethod: CatalogUnlockMethod.included,
      visual: CatalogVisual.michi,
      assetPath: 'assets/characters/michi/idle-8.png',
    ),
    CatalogEntry(
      id: 'character-02',
      name: 'Personaje 02',
      kind: CatalogKind.character,
      unlockMethod: CatalogUnlockMethod.purchase,
      visual: CatalogVisual.characterPlaceholder,
      storeProductId: 'sobra.character.02',
    ),
    CatalogEntry(
      id: 'character-03',
      name: 'Personaje 03',
      kind: CatalogKind.character,
      unlockMethod: CatalogUnlockMethod.rewardedAd,
      visual: CatalogVisual.characterPlaceholder,
      rewardedAdTarget: 2,
    ),
    CatalogEntry(
      id: 'character-04',
      name: 'Personaje 04',
      kind: CatalogKind.character,
      unlockMethod: CatalogUnlockMethod.purchase,
      visual: CatalogVisual.characterPlaceholder,
      storeProductId: 'sobra.character.04',
    ),
    CatalogEntry(
      id: 'character-05',
      name: 'Personaje 05',
      kind: CatalogKind.character,
      unlockMethod: CatalogUnlockMethod.rewardedAd,
      visual: CatalogVisual.characterPlaceholder,
      rewardedAdTarget: 2,
    ),
    CatalogEntry(
      id: 'character-06',
      name: 'Personaje 06',
      kind: CatalogKind.character,
      unlockMethod: CatalogUnlockMethod.purchase,
      visual: CatalogVisual.characterPlaceholder,
      storeProductId: 'sobra.character.06',
    ),
    CatalogEntry(
      id: 'character-07',
      name: 'Personaje 07',
      kind: CatalogKind.character,
      unlockMethod: CatalogUnlockMethod.purchase,
      visual: CatalogVisual.characterPlaceholder,
      storeProductId: 'sobra.character.07',
    ),
    CatalogEntry(
      id: 'character-08',
      name: 'Personaje 08',
      kind: CatalogKind.character,
      unlockMethod: CatalogUnlockMethod.rewardedAd,
      visual: CatalogVisual.characterPlaceholder,
      rewardedAdTarget: 3,
      rewardedAdOncePerDay: true,
    ),
    CatalogEntry(
      id: 'character-09',
      name: 'Personaje 09',
      kind: CatalogKind.character,
      unlockMethod: CatalogUnlockMethod.purchase,
      visual: CatalogVisual.characterPlaceholder,
      storeProductId: 'sobra.character.09',
    ),
    CatalogEntry(
      id: 'character-10',
      name: 'Personaje 10',
      kind: CatalogKind.character,
      unlockMethod: CatalogUnlockMethod.purchase,
      visual: CatalogVisual.characterPlaceholder,
      storeProductId: 'sobra.character.10',
    ),
  ];

  /// Seven level rewards and three rewarded-ad slots.
  ///
  /// The lamp is available from level 1. The level 5 and 8 positions mirror
  /// the selected collection mockup, while the remaining rewards spread the
  /// path through the level-10 progression.
  static const items = <CatalogEntry>[
    CatalogEntry(
      id: 'item-01',
      name: 'Objeto 01',
      kind: CatalogKind.item,
      unlockMethod: CatalogUnlockMethod.level,
      visual: CatalogVisual.lamp,
      requiredLevel: 1,
    ),
    CatalogEntry(
      id: 'item-02',
      name: 'Objeto 02',
      kind: CatalogKind.item,
      unlockMethod: CatalogUnlockMethod.level,
      visual: CatalogVisual.savings,
      requiredLevel: 5,
    ),
    CatalogEntry(
      id: 'item-03',
      name: 'Objeto 03',
      kind: CatalogKind.item,
      unlockMethod: CatalogUnlockMethod.rewardedAd,
      visual: CatalogVisual.plant,
      rewardedAdTarget: 1,
    ),
    CatalogEntry(
      id: 'item-04',
      name: 'Objeto 04',
      kind: CatalogKind.item,
      unlockMethod: CatalogUnlockMethod.level,
      visual: CatalogVisual.rug,
      requiredLevel: 8,
    ),
    CatalogEntry(
      id: 'item-05',
      name: 'Objeto 05',
      kind: CatalogKind.item,
      unlockMethod: CatalogUnlockMethod.rewardedAd,
      visual: CatalogVisual.frame,
      rewardedAdTarget: 1,
    ),
    CatalogEntry(
      id: 'item-06',
      name: 'Objeto 06',
      kind: CatalogKind.item,
      unlockMethod: CatalogUnlockMethod.level,
      visual: CatalogVisual.shelf,
      requiredLevel: 10,
    ),
    CatalogEntry(
      id: 'item-07',
      name: 'Objeto 07',
      kind: CatalogKind.item,
      unlockMethod: CatalogUnlockMethod.level,
      visual: CatalogVisual.chair,
      requiredLevel: 2,
    ),
    CatalogEntry(
      id: 'item-08',
      name: 'Objeto 08',
      kind: CatalogKind.item,
      unlockMethod: CatalogUnlockMethod.rewardedAd,
      visual: CatalogVisual.clock,
      rewardedAdTarget: 1,
    ),
    CatalogEntry(
      id: 'item-09',
      name: 'Objeto 09',
      kind: CatalogKind.item,
      unlockMethod: CatalogUnlockMethod.level,
      visual: CatalogVisual.trophy,
      requiredLevel: 3,
    ),
    CatalogEntry(
      id: 'item-10',
      name: 'Objeto 10',
      kind: CatalogKind.item,
      unlockMethod: CatalogUnlockMethod.level,
      visual: CatalogVisual.cushion,
      requiredLevel: 4,
    ),
    CatalogEntry(
      id: supporterDecorationId,
      name: 'Estrella',
      kind: CatalogKind.item,
      unlockMethod: CatalogUnlockMethod.bundle,
      visual: CatalogVisual.trophy,
      storeProductId: supporterBundleProductId,
    ),
  ];

  /// The supporter product, and the only entry that arrives exclusively in it.
  static const supporterBundleProductId = 'sobra.supporter.bundle';
  static const supporterDecorationId = 'supporter-decoration';

  /// Ad removal, stored beside catalog ids rather than as an entry of its own.
  ///
  /// Nothing reads it yet — general ads do not exist before the native
  /// placement ships. It is granted now so that supporters who bought before
  /// then do not have to be re-granted afterwards, and so the entitlement is
  /// carried by the same restore that carries their characters.
  static const noAdsEntitlement = 'entitlement.no_ads';

  /// What one store product delivers, for products that deliver more than one
  /// thing.
  ///
  /// Only bundles belong here. A product that maps to exactly one entry is
  /// resolved by [entryForProductId] instead, and listing it twice would give
  /// the same purchase two answers.
  static const productEntitlements = <String, Set<String>>{
    supporterBundleProductId: {
      'character-02',
      'character-04',
      'character-06',
      supporterDecorationId,
      noAdsEntitlement,
    },
  };

  /// Everything [storeProductId] delivers, or null where it is not a bundle.
  ///
  /// Callers must consult this *before* [entryForProductId]. A bundle's
  /// product id also sits on the one entry that is exclusive to it, so the
  /// single-entry lookup answers for a bundle too — with one item out of
  /// several, while reporting that the delivery succeeded.
  static Set<String>? entitlementsForProductId(String storeProductId) =>
      productEntitlements[storeProductId];

  static List<CatalogEntry> forKind(CatalogKind kind) =>
      kind == CatalogKind.character ? characters : items;

  /// Every entry this build ships, characters first.
  static List<CatalogEntry> get all => [...characters, ...items];

  /// The entry a store product id belongs to, or null where this build has
  /// none for it.
  ///
  /// Null is an ordinary answer rather than an error. A store restore replays
  /// everything the account ever bought, including products from a lineup this
  /// build has since dropped, and the caller keeps those ids rather than
  /// discarding what the user paid for.
  static CatalogEntry? entryForProductId(String storeProductId) {
    for (final entry in all) {
      if (entry.storeProductId == storeProductId) return entry;
    }
    return null;
  }

  /// Every product id the store should be asked to price.
  ///
  /// Bundle ids are unioned in rather than left to the entries: a bundle that
  /// contains only characters names no entry of its own, and a product the
  /// store was never asked about has no price and cannot be bought.
  static Set<String> get storeProductIds => {
    for (final entry in all)
      if (entry.storeProductId != null) entry.storeProductId!,
    ...productEntitlements.keys,
  };

  static bool isUnlockedAtLevel(CatalogEntry entry, int playerLevel) =>
      entry.unlockMethod == CatalogUnlockMethod.level &&
      playerLevel >= entry.requiredLevel!;

  /// Level rewards available to a user now, derived from XP every time.
  ///
  /// Nothing is copied into a separate ownership list, so an existing install
  /// receives all eligible items immediately after updating the app.
  static List<CatalogEntry> levelItemsUnlockedAt(int playerLevel) => [
    for (final entry in items)
      if (isUnlockedAtLevel(entry, playerLevel)) entry,
  ];

  /// Rewards crossed by one XP award, including multi-level jumps.
  static List<CatalogEntry> levelItemsUnlockedBetween({
    required int previousLevel,
    required int currentLevel,
  }) => [
    for (final entry in items)
      if (entry.unlockMethod == CatalogUnlockMethod.level &&
          entry.requiredLevel! > previousLevel &&
          entry.requiredLevel! <= currentLevel)
        entry,
  ];
}

/// Boundary used by the screen instead of storing a peso amount in catalog
/// definitions. The production implementation can call StoreKit/Play Billing.
abstract interface class CatalogPriceSource {
  String? localizedPriceFor(String storeProductId);
}

/// Temporary store response for the visual prototype only.
final class PreviewCatalogPriceSource implements CatalogPriceSource {
  const PreviewCatalogPriceSource();

  @override
  String? localizedPriceFor(String storeProductId) => switch (storeProductId) {
    'sobra.character.02' || 'sobra.character.07' => r'MX$ 79',
    'sobra.character.04' || 'sobra.character.09' => r'MX$ 99',
    'sobra.character.06' || 'sobra.character.10' => r'MX$ 129',
    _ => null,
  };
}
