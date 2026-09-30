import '../models/catalog_entry.dart';
import '../models/room_design.dart';

/// Replaceable data used while the character and item lineup is still open.
///
/// Named companions are final. Numbered entries intentionally avoid deciding
/// the future characters or room objects before their art and commercial plan
/// are ready.
abstract final class CatalogPreviewData {
  static const characters = <CatalogEntry>[
    // The two starters. Onboarding hands over the one the user picks; the
    // other waits at the door until three recorded days or two rewarded ads,
    // whichever comes first. Ad-unlocked for everyone else's sake: the card,
    // the progress and the revocation rules are the rewarded-ad ones.
    CatalogEntry(
      id: 'michi',
      name: 'Michi',
      kind: CatalogKind.character,
      unlockMethod: CatalogUnlockMethod.rewardedAd,
      visual: CatalogVisual.michi,
      assetPath: 'assets/characters/michi/idle-8.png',
      rewardedAdTarget: 2,
    ),
    CatalogEntry(
      id: 'poodle',
      name: 'Miru',
      kind: CatalogKind.character,
      unlockMethod: CatalogUnlockMethod.rewardedAd,
      visual: CatalogVisual.poodle,
      assetPath: 'assets/characters/poodle/idle-8.png',
      rewardedAdTarget: 2,
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
    // Los amigos de Michi: sold one by one and together in the pack.
    // Somebody who owns one and then buys the pack pays for that one twice —
    // grantCatalogEntries drops ids already owned and Play refunds nothing —
    // so the pack dialog names what the buyer already has before they pay.
    // Kept together so the collection reads them as one set.
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
      id: 'raccoon',
      name: 'Bandi',
      kind: CatalogKind.character,
      unlockMethod: CatalogUnlockMethod.purchase,
      visual: CatalogVisual.raccoon,
      assetPath: 'assets/characters/raccoon/idle-8.png',
      storeProductId: 'sobra.character.raccoon',
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
    CatalogEntry(
      id: 'rabbit',
      name: 'Bunny',
      kind: CatalogKind.character,
      unlockMethod: CatalogUnlockMethod.purchase,
      visual: CatalogVisual.rabbit,
      assetPath: 'assets/characters/rabbit/idle-8.png',
      storeProductId: 'sobra.character.rabbit',
    ),
    CatalogEntry(
      id: 'quokka',
      name: 'Quokka',
      kind: CatalogKind.character,
      unlockMethod: CatalogUnlockMethod.rewardedAd,
      visual: CatalogVisual.quokka,
      assetPath: 'assets/characters/quokka/idle-8.png',
      rewardedAdTarget: 2,
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
      id: 'character-05',
      name: 'Personaje 05',
      kind: CatalogKind.character,
      unlockMethod: CatalogUnlockMethod.rewardedAd,
      visual: CatalogVisual.characterPlaceholder,
      rewardedAdTarget: 2,
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

  /// Room decorations: two to start, one per level from 2 to 10, and small
  /// pieces for one rewarded ad.
  ///
  /// Only art that exists is listed. Numbered placeholder cards were dropped
  /// before launch: a reward is an id people keep, so it should name a real
  /// piece rather than a slot waiting for one.
  ///
  /// Levels hand out the furniture in the order a room fills: light first,
  /// then the jar, a cabinet for it to stand on, the pet bed, and the sofa
  /// last. Rewards are derived from the level, so moving one *down* reaches
  /// everyone already there while moving one *up* takes it away — installs
  /// that had these pieces free keep them through [SobraStore]'s
  /// grandfathering instead.
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
      id: RoomDecorAssets.wallClockId,
      name: 'Reloj de pared',
      kind: CatalogKind.item,
      unlockMethod: CatalogUnlockMethod.included,
      visual: CatalogVisual.clock,
      assetPath: RoomDecorAssets.wallClock,
    ),
    CatalogEntry(
      id: RoomDecorAssets.floorLampId,
      name: 'Lámpara de pie',
      kind: CatalogKind.item,
      unlockMethod: CatalogUnlockMethod.level,
      visual: CatalogVisual.lamp,
      assetPath: RoomDecorAssets.floorLamp,
      requiredLevel: 2,
    ),
    CatalogEntry(
      id: RoomDecorAssets.savingsJarId,
      name: 'Savings jar',
      kind: CatalogKind.item,
      unlockMethod: CatalogUnlockMethod.level,
      visual: CatalogVisual.savings,
      assetPath: RoomDecorAssets.savingsJar,
      requiredLevel: 3,
    ),
    CatalogEntry(
      id: RoomDecorAssets.lowCabinetId,
      name: 'Low cabinet',
      kind: CatalogKind.item,
      unlockMethod: CatalogUnlockMethod.level,
      visual: CatalogVisual.shelf,
      assetPath: RoomDecorAssets.lowCabinet,
      requiredLevel: 4,
    ),
    CatalogEntry(
      id: RoomDecorAssets.petBedId,
      name: 'Pet bed',
      kind: CatalogKind.item,
      unlockMethod: CatalogUnlockMethod.level,
      visual: CatalogVisual.cushion,
      assetPath: RoomDecorAssets.petBed,
      requiredLevel: 5,
    ),
    CatalogEntry(
      id: RoomDecorAssets.roundSideTableId,
      name: 'Round side table',
      kind: CatalogKind.item,
      unlockMethod: CatalogUnlockMethod.level,
      visual: CatalogVisual.shelf,
      assetPath: RoomDecorAssets.roundSideTable,
      requiredLevel: 6,
    ),
    CatalogEntry(
      id: RoomDecorAssets.terracottaPoufId,
      name: 'Terracotta pouf',
      kind: CatalogKind.item,
      unlockMethod: CatalogUnlockMethod.level,
      visual: CatalogVisual.cushion,
      assetPath: RoomDecorAssets.terracottaPouf,
      requiredLevel: 7,
    ),
    CatalogEntry(
      id: RoomDecorAssets.blueCreamRugId,
      name: 'Blue and cream rug',
      kind: CatalogKind.item,
      unlockMethod: CatalogUnlockMethod.level,
      visual: CatalogVisual.rug,
      assetPath: RoomDecorAssets.blueCreamRug,
      requiredLevel: 8,
    ),
    CatalogEntry(
      id: RoomDecorAssets.slimBookcaseId,
      name: 'Slim bookcase',
      kind: CatalogKind.item,
      unlockMethod: CatalogUnlockMethod.level,
      visual: CatalogVisual.shelf,
      assetPath: RoomDecorAssets.slimBookcase,
      requiredLevel: 9,
    ),
    CatalogEntry(
      id: RoomDecorAssets.ivorySofaId,
      name: 'Sofá marfil',
      kind: CatalogKind.item,
      unlockMethod: CatalogUnlockMethod.level,
      visual: CatalogVisual.cushion,
      assetPath: RoomDecorAssets.ivorySofa,
      requiredLevel: 10,
    ),
    // The desk lamp and the frame keep their early ids: both may already be
    // written into saved rooms and rewarded-ad progress.
    CatalogEntry(
      id: 'item-01',
      name: 'Lámpara verde',
      kind: CatalogKind.item,
      unlockMethod: CatalogUnlockMethod.rewardedAd,
      visual: CatalogVisual.lamp,
      assetPath: RoomDecorAssets.lamp,
      rewardedAdTarget: 1,
    ),
    CatalogEntry(
      id: 'item-05',
      name: 'Cuadro',
      kind: CatalogKind.item,
      unlockMethod: CatalogUnlockMethod.rewardedAd,
      visual: CatalogVisual.frame,
      assetPath: RoomDecorAssets.wallFrame,
      rewardedAdTarget: 1,
    ),
    CatalogEntry(
      id: RoomDecorAssets.bronzeLanternLampId,
      name: 'Lámpara de bronce',
      kind: CatalogKind.item,
      unlockMethod: CatalogUnlockMethod.rewardedAd,
      visual: CatalogVisual.lamp,
      assetPath: RoomDecorAssets.bronzeLanternLamp,
      rewardedAdTarget: 1,
    ),
    CatalogEntry(
      id: RoomDecorAssets.wallShelfId,
      name: 'Wall shelf',
      kind: CatalogKind.item,
      unlockMethod: CatalogUnlockMethod.rewardedAd,
      visual: CatalogVisual.shelf,
      assetPath: RoomDecorAssets.wallShelf,
      rewardedAdTarget: 1,
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

  /// The companions offered at onboarding, in the order the cards appear.
  ///
  /// Saved ids: the starter a user picked is stored by these, so renaming one
  /// is a migration.
  static const starterIds = ['michi', 'poodle'];

  /// Days with something recorded that bring the waiting starter over.
  ///
  /// Counted, not consecutive: a missed day in the first week must not send
  /// somebody back to zero before they have formed the habit this is for.
  static const starterRecordedDaysTarget = 3;

  static bool isStarter(String id) => starterIds.contains(id);

  /// Decorations every install owned before they became level and ad
  /// rewards, kept for the installs that already had them.
  ///
  /// Saved ids: a room may hold any of these, so the list only ever grows.
  /// The desk lamp was the level-1 reward, which reached everybody.
  static const formerlyFreeItemIds = {
    RoomDecorAssets.floorLampId,
    RoomDecorAssets.lowCabinetId,
    RoomDecorAssets.slimBookcaseId,
    RoomDecorAssets.roundSideTableId,
    RoomDecorAssets.petBedId,
    RoomDecorAssets.savingsJarId,
    RoomDecorAssets.wallShelfId,
    RoomDecorAssets.terracottaPoufId,
    RoomDecorAssets.blueCreamRugId,
    RoomDecorAssets.ivorySofaId,
    RoomDecorAssets.bronzeLanternLampId,
    'item-01',
  };

  /// Los amigos de Michi: Tranqui, Lana and Bandi, and ad removal.
  ///
  /// The product id outlives the name in front of it. It is what the store
  /// console registers and can never be reused once it is live, so renaming
  /// the pack is a copy change, never a new id.
  static const packProductId = 'sobra.supporter.bundle';

  /// The characters the pack delivers, in the order the pack shows them.
  ///
  /// A "Estrella de Michi" decoration was planned beside them and dropped
  /// before launch for having no art and nowhere in the room to go. A later
  /// bonus can still be added to [productEntitlements]: the launch restore
  /// replays the pack on every start and grants whatever it now lists, so
  /// people who already bought it receive the addition too.
  static const packCharacterIds = ['capybara', 'alpaca', 'raccoon'];

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
    packProductId: {...packCharacterIds, noAdsEntitlement},
  };

  /// Everything [storeProductId] delivers, or null where it is not a bundle.
  ///
  /// Callers must consult this *before* [entryForProductId]. No entry
  /// carries the pack's id today, but one sold only inside a pack would, and
  /// the single-entry lookup would then answer for the pack with whichever
  /// one it reached first — while reporting that the delivery succeeded.
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
/// way to remove ads, and costs less than three single characters would
/// while adding ad removal on top.
final class PreviewCatalogPriceSource implements CatalogPriceSource {
  const PreviewCatalogPriceSource();

  @override
  String? localizedPriceFor(String storeProductId) => switch (storeProductId) {
    'sobra.character.capybara' => r'MX$ 39',
    'sobra.character.alpaca' => r'MX$ 39',
    'sobra.character.raccoon' => r'MX$ 39',
    'sobra.character.platypus' => r'MX$ 39',
    'sobra.character.rabbit' => r'MX$ 39',
    CatalogPreviewData.packProductId => r'MX$ 89',
    _ => null,
  };
}
