import 'package:flutter/foundation.dart';

/// The two families shown by the collection surface.
enum CatalogKind { character, item }

/// One, and only one, route by which a catalog entry becomes available.
///
/// [bundle] is a purchase the entry cannot start on its own: it arrives only
/// as part of a larger product, so its card explains where it comes from
/// instead of offering a price. Keeping it apart from [purchase] is what stops
/// a single decoration card from opening the checkout for a whole bundle.
enum CatalogUnlockMethod { included, purchase, rewardedAd, level, bundle }

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
    this.rewardedAdOncePerDay = false,
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
         !rewardedAdOncePerDay ||
             unlockMethod == CatalogUnlockMethod.rewardedAd,
       ),
       assert(
         unlockMethod == CatalogUnlockMethod.purchase ||
                 unlockMethod == CatalogUnlockMethod.bundle
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

  /// Whether this entry takes at most one rewarded view per local day.
  ///
  /// The special tier. It is not a price — three views cost the same whether
  /// they are spread or not — it is what makes the entry take three days, and
  /// it is the only reason [SobraStore] remembers a date per entry at all.
  final bool rewardedAdOncePerDay;
  final String? storeProductId;
}

/// Why a rewarded view cannot start for an entry right now.
///
/// Presentation only: the card needs to say something different for each, and
/// "no ad loaded" is not the same answer as "you are done for today". The
/// rules themselves live in [SobraStore].
enum RewardedAdBlock {
  /// The network has nothing to show. Ordinary, and usually temporary.
  noAdAvailable,

  /// The daily limit across every entry is spent.
  dailyCapReached,

  /// A once-per-day entry already took its view today.
  alreadyEarnedToday,
}

/// User-specific state resolved separately from the static catalog.
///
/// The preview screen builds this in memory. A later persistence step can load
/// the same shape from [SobraStore] without changing the screen or definitions.
@immutable
class CatalogEntryState {
  /// [localizedStorePrice] and [isPurchasing] are deliberately limited to
  /// [CatalogUnlockMethod.purchase]. A bundle entry has a store product id
  /// too, and letting either follow the id rather than the unlock method would
  /// put a whole bundle's price on one decoration card.
  CatalogEntryState({
    required this.entry,
    required this.isOwned,
    this.rewardedAdProgress = 0,
    this.localizedStorePrice,
    this.isPurchasing = false,
    this.rewardedAdBlock,
    this.isWatchingAd = false,
  }) : assert(
         !isWatchingAd ||
             (!isOwned &&
                 entry.unlockMethod == CatalogUnlockMethod.rewardedAd),
       ),
       assert(
         rewardedAdBlock == null ||
             entry.unlockMethod == CatalogUnlockMethod.rewardedAd,
       ),
       assert(rewardedAdProgress >= 0),
       assert(
         localizedStorePrice == null ||
             entry.unlockMethod == CatalogUnlockMethod.purchase,
       ),
       assert(
         !isPurchasing ||
             (!isOwned && entry.unlockMethod == CatalogUnlockMethod.purchase),
       );

  final CatalogEntry entry;
  final bool isOwned;
  final int rewardedAdProgress;

  /// Presentation-only price received from a store price source.
  final String? localizedStorePrice;

  /// Why a rewarded view cannot start, or null where one can.
  ///
  /// Null for every entry that is not unlocked by ads, and for an owned one:
  /// a finished run has nothing left to block.
  final RewardedAdBlock? rewardedAdBlock;

  /// Whether an ad run is working on this entry right now.
  ///
  /// Covers the fetch as well as the ad itself. That window is a network round
  /// trip spent on a card that would otherwise look untouched, and the
  /// purchase flow already learned what an unchanged control reads as.
  final bool isWatchingAd;

  /// Whether the store is working on this entry right now.
  ///
  /// Covers both the seconds a checkout sheet takes and the hours Play can
  /// hold a pending payment. The card has to say so either way: an entry that
  /// still reads COMPRAR after the user paid looks like the money went
  /// nowhere.
  final bool isPurchasing;
}
