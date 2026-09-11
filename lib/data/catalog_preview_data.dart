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
      rewardedAdTarget: 3,
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
      rewardedAdTarget: 3,
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
  ];

  static List<CatalogEntry> forKind(CatalogKind kind) =>
      kind == CatalogKind.character ? characters : items;

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
