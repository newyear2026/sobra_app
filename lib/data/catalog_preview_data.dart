import '../models/catalog_entry.dart';
import '../models/room_design.dart';

/// Replaceable data used while the character and item lineup is still open.
///
/// Named companions are final. Numbered entries intentionally avoid deciding
/// the future characters or room objects before their art and commercial plan
/// are ready.
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
      id: 'poodle',
      name: 'Miru',
      kind: CatalogKind.character,
      unlockMethod: CatalogUnlockMethod.included,
      visual: CatalogVisual.poodle,
      assetPath: 'assets/characters/poodle/idle-8.png',
    ),
    // Earned with ads, and for good. Turning it into a purchase later would
    // make the launch revocation take it back from everyone who watched for
    // it, since that check reads the entry's current unlock method and finds
    // no payment on the account.
    CatalogEntry(
      id: 'schnauzer',
      name: 'Yoshi',
      kind: CatalogKind.character,
      unlockMethod: CatalogUnlockMethod.rewardedAd,
      visual: CatalogVisual.schnauzer,
      assetPath: 'assets/characters/schnauzer/idle-8.png',
      rewardedAdTarget: 2,
    ),
    CatalogEntry(
      id: 'guinea-pig',
      name: 'Cookie',
      kind: CatalogKind.character,
      unlockMethod: CatalogUnlockMethod.rewardedAd,
      visual: CatalogVisual.guineaPig,
      assetPath: 'assets/characters/guinea-pig/idle-8.png',
      rewardedAdTarget: 2,
    ),
    CatalogEntry(
      id: 'capybara',
      name: 'Tranqui',
      kind: CatalogKind.character,
      unlockMethod: CatalogUnlockMethod.purchase,
      visual: CatalogVisual.capybara,
      assetPath: 'assets/characters/capybara/idle-8.png',
      storeProductId: 'sobra.character.capybara',
    ),
    CatalogEntry(
      id: 'alpaca',
      name: 'Lana',
      kind: CatalogKind.character,
      unlockMethod: CatalogUnlockMethod.purchase,
      visual: CatalogVisual.alpaca,
      assetPath: 'assets/characters/alpaca/idle-8.png',
      storeProductId: 'sobra.character.alpaca',
    ),
    CatalogEntry(
      id: 'platypus',
      name: 'Pico',
      kind: CatalogKind.character,
      unlockMethod: CatalogUnlockMethod.purchase,
      visual: CatalogVisual.platypus,
      assetPath: 'assets/characters/platypus/idle-8.png',
      storeProductId: 'sobra.character.platypus',
    ),
    // In the pack and nowhere else, along with 04 and 06. Selling these
    // individually as well would charge twice for the overlap: a buyer who
    // takes one and later the pack pays for it in both, because
    // grantCatalogEntries drops ids already owned and no store refunds the
    // difference. Tranqui, Lana, Pico and 10 are what single purchases
    // are for, so the pack does not empty that shelf either.
    CatalogEntry(
      id: 'character-02',
      name: 'Personaje 02',
      kind: CatalogKind.character,
      unlockMethod: CatalogUnlockMethod.bundle,
      visual: CatalogVisual.characterPlaceholder,
      storeProductId: packProductId,
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
      unlockMethod: CatalogUnlockMethod.bundle,
      visual: CatalogVisual.characterPlaceholder,
      storeProductId: packProductId,
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
      unlockMethod: CatalogUnlockMethod.bundle,
      visual: CatalogVisual.characterPlaceholder,
      storeProductId: packProductId,
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
      id: 'character-10',
      name: 'Personaje 10',
      kind: CatalogKind.character,
      unlockMethod: CatalogUnlockMethod.purchase,
      visual: CatalogVisual.characterPlaceholder,
      storeProductId: 'sobra.character.10',
    ),
  ];

  /// Seven level rewards, three rewarded-ad slots and included room items.
  ///
  /// The lamp is available from level 1. The level 5 and 8 positions mirror
  /// the selected collection mockup, while the remaining rewards spread the
  /// path through the level-10 progression.
  static const items = <CatalogEntry>[
    CatalogEntry(
      id: RoomDecorAssets.rattanChairId,
      name: 'Sillón de ratán',
      kind: CatalogKind.item,
      unlockMethod: CatalogUnlockMethod.included,
      visual: CatalogVisual.chair,
      assetPath: RoomDecorAssets.rattanChair,
    ),
    CatalogEntry(
      id: RoomDecorAssets.floorLampId,
      name: 'Lámpara de pie',
      kind: CatalogKind.item,
      unlockMethod: CatalogUnlockMethod.included,
      visual: CatalogVisual.lamp,
      assetPath: RoomDecorAssets.floorLamp,
    ),
    CatalogEntry(
      id: RoomDecorAssets.wallClockId,
      name: 'Reloj de pared',
      kind: CatalogKind.item,
      unlockMethod: CatalogUnlockMethod.included,
      visual: CatalogVisual.clock,
      assetPath: RoomDecorAssets.wallClock,
    ),
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
      id: packDecorationId,
      name: 'Estrella',
      kind: CatalogKind.item,
      unlockMethod: CatalogUnlockMethod.bundle,
      visual: CatalogVisual.trophy,
      storeProductId: packProductId,
    ),
    // New room art follows the original reward lineup, preserving the order
    // of existing catalog cards and their established navigation positions.
    CatalogEntry(
      id: RoomDecorAssets.lowCabinetId,
      name: 'Low cabinet',
      kind: CatalogKind.item,
      unlockMethod: CatalogUnlockMethod.included,
      visual: CatalogVisual.shelf,
      assetPath: RoomDecorAssets.lowCabinet,
    ),
    CatalogEntry(
      id: RoomDecorAssets.petBedId,
      name: 'Pet bed',
      kind: CatalogKind.item,
      unlockMethod: CatalogUnlockMethod.included,
      visual: CatalogVisual.cushion,
      assetPath: RoomDecorAssets.petBed,
    ),
    CatalogEntry(
      id: RoomDecorAssets.savingsJarId,
      name: 'Savings jar',
      kind: CatalogKind.item,
      unlockMethod: CatalogUnlockMethod.included,
      visual: CatalogVisual.savings,
      assetPath: RoomDecorAssets.savingsJar,
    ),
    CatalogEntry(
      id: RoomDecorAssets.wallShelfId,
      name: 'Wall shelf',
      kind: CatalogKind.item,
      unlockMethod: CatalogUnlockMethod.included,
      visual: CatalogVisual.shelf,
      assetPath: RoomDecorAssets.wallShelf,
    ),
    CatalogEntry(
      id: RoomDecorAssets.terracottaPoufId,
      name: 'Terracotta pouf',
      kind: CatalogKind.item,
      unlockMethod: CatalogUnlockMethod.included,
      visual: CatalogVisual.cushion,
      assetPath: RoomDecorAssets.terracottaPouf,
    ),
    CatalogEntry(
      id: RoomDecorAssets.blueCreamRugId,
      name: 'Blue and cream rug',
      kind: CatalogKind.item,
      unlockMethod: CatalogUnlockMethod.included,
      visual: CatalogVisual.rug,
      assetPath: RoomDecorAssets.blueCreamRug,
    ),
    // The launch gift is granted by the app, not by Play Billing. Gift cards
    // remain hidden until owned so nobody sees an unobtainable locked item.
    CatalogEntry(
      id: RoomDecorAssets.launchSofaId,
      name: 'Sofá de terciopelo',
      kind: CatalogKind.item,
      unlockMethod: CatalogUnlockMethod.gift,
      visual: CatalogVisual.cushion,
      assetPath: RoomDecorAssets.launchSofa,
    ),
    CatalogEntry(
      id: RoomDecorAssets.launchTvId,
      name: 'Tele de historias',
      kind: CatalogKind.item,
      unlockMethod: CatalogUnlockMethod.gift,
      visual: CatalogVisual.shelf,
      assetPath: RoomDecorAssets.launchTv,
    ),
  ];

  /// Michi & Friends: three characters, one decoration, and ad removal.
  ///
  /// Both values outlive the name in front of them. The product id is what
  /// the store console registers and can never be reused once it is live;
  /// the decoration id is a key already written into saved owned sets.
  /// Renaming either is a migration, not an edit.
  static const packProductId = 'sobra.supporter.bundle';
  static const packDecorationId = 'supporter-decoration';

  /// Ad removal, stored beside catalog ids rather than as an entry of its own.
  ///
  /// Native ads read it so a pack buyer who arrived before the placement
  /// shipped does not have to be re-granted.
  ///
  /// Only the pack sells it. A standalone `sobra.ads.remove` was planned and
  /// dropped before launch: with a few native rows being the only general
  /// ads, removing them alone was too little to sell, and a second product
  /// beside the pack only split the choice.
  static const noAdsEntitlement = 'entitlement.no_ads';

  /// What one store product delivers, for products that deliver more than one
  /// thing — or one entitlement that is not a catalog entry.
  ///
  /// Only those products belong here. A product that maps to exactly one
  /// catalog entry is resolved by [entryForProductId] instead, and listing it
  /// twice would give the same purchase two answers.
  static const productEntitlements = <String, Set<String>>{
    packProductId: {
      'character-02',
      'character-04',
      'character-06',
      packDecorationId,
      noAdsEntitlement,
    },
  };

  /// Everything [storeProductId] delivers, or null where it is not a bundle.
  ///
  /// Callers must consult this *before* [entryForProductId]. Every entry the
  /// pack delivers exclusively carries its product id, so the single-entry
  /// lookup answers for the pack too — with whichever one it reaches first,
  /// while reporting that the delivery succeeded.
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
  ///
  /// Gifts are left out. They are never sold, and this set is also the list
  /// the launch revocation checks against Play — where a gift that was never
  /// paid for would read as a refund.
  static Set<String> get storeProductIds => {
    for (final entry in all)
      if (entry.storeProductId != null &&
          entry.unlockMethod != CatalogUnlockMethod.gift)
        entry.storeProductId!,
    ...productEntitlements.keys,
  };

  /// Whether the collection should show [entry] to someone who
  /// [isOwned] it or not.
  ///
  /// A gift nobody can still get is not shown locked. Everything else is,
  /// because each locked card says how to unlock it.
  static bool isListed(CatalogEntry entry, {required bool isOwned}) =>
      isOwned || entry.unlockMethod != CatalogUnlockMethod.gift;

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
///
/// Mirrors the prices meant for Play Console. Every single character is one
/// flat price, so none reads as lesser than another. The pack is the only
/// way to remove ads, and costs less than three single characters while
/// adding the star and ad removal on top.
final class PreviewCatalogPriceSource implements CatalogPriceSource {
  const PreviewCatalogPriceSource();

  @override
  String? localizedPriceFor(String storeProductId) => switch (storeProductId) {
    'sobra.character.capybara' => r'MX$ 39',
    'sobra.character.alpaca' => r'MX$ 39',
    'sobra.character.platypus' => r'MX$ 39',
    CatalogPreviewData.packProductId => r'MX$ 89',
    _ => null,
  };
}
