import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

import '../data/catalog_preview_data.dart';
import '../models/catalog_entry.dart';
import '../state/sobra_store.dart';

/// Why a purchase did not finish, in a form the view can word.
///
/// Mirrors [StoreFailure]: the plugin's own messages are English strings from
/// StoreKit and Play Billing, and showing one verbatim would make a platform
/// error code part of a Spanish interface. A cancellation is deliberately not
/// in here — the user meant to do that, and it is not a failure to report.
enum PurchaseFailure {
  /// The device cannot reach the store at all: no Play services, a child
  /// account with purchases disabled, or a build with no billing set up.
  storeUnavailable,

  /// The store answered, but the purchase itself came back as an error.
  purchaseRejected,

  /// A restore ran and found nothing to give back.
  nothingToRestore,

  /// The store delivered, but writing the entitlement to disk did not land.
  ///
  /// Recoverable rather than lost: the purchase is deliberately left
  /// uncompleted, so the store replays it on the next launch and it is granted
  /// then. Saying nothing here would leave somebody who just paid watching an
  /// entry that is still for sale.
  deliveryNotSaved,
}

/// What the store is able to do for this install right now.
enum StoreReadiness { checking, ready, unavailable }

/// The seam over the `in_app_purchase` plugin.
///
/// Exists so the purchase logic can be tested without a store: every method
/// here is one the plugin already offers, and [PluginPurchaseBackend] is the
/// only implementation that talks to a real one.
abstract interface class PurchaseBackend {
  Stream<List<PurchaseDetails>> get purchaseStream;
  Future<bool> isAvailable();
  Future<ProductDetailsResponse> queryProductDetails(Set<String> identifiers);
  Future<void> buyNonConsumable(ProductDetails product);
  Future<void> restorePurchases();
  Future<void> completePurchase(PurchaseDetails purchase);

  /// The products this store account holds as paid right now, or null when
  /// the store cannot say so with certainty.
  ///
  /// Null is what every failure and every platform without such a query must
  /// answer. An empty set is a claim that the account owns nothing, and it is
  /// acted on by taking purchases back.
  Future<Set<String>?> queryPaidProductIds();
}

/// The real store, reached through the plugin singleton.
final class PluginPurchaseBackend implements PurchaseBackend {
  PluginPurchaseBackend([InAppPurchase? plugin])
    : _plugin = plugin ?? InAppPurchase.instance;

  final InAppPurchase _plugin;

  /// The plugin's stream, with Play's pending purchases called pending.
  ///
  /// The Android plugin marks everything a restore returns as restored,
  /// including a cash payment still waiting at the shop. Passed on as is, that
  /// unpaid purchase would be granted on the next launch.
  @override
  Stream<List<PurchaseDetails>> get purchaseStream =>
      _plugin.purchaseStream.map(
        (purchases) => [
          for (final purchase in purchases)
            if (purchase is GooglePlayPurchaseDetails &&
                purchase.status == PurchaseStatus.restored &&
                purchase.billingClientPurchase.purchaseState ==
                    PurchaseStateWrapper.pending)
              purchase..status = PurchaseStatus.pending
            else
              purchase,
        ],
      );

  @override
  Future<bool> isAvailable() => _plugin.isAvailable();

  @override
  Future<ProductDetailsResponse> queryProductDetails(Set<String> identifiers) =>
      _plugin.queryProductDetails(identifiers);

  @override
  Future<void> buyNonConsumable(ProductDetails product) => _plugin
      .buyNonConsumable(purchaseParam: PurchaseParam(productDetails: product));

  @override
  Future<void> restorePurchases() => _plugin.restorePurchases();

  @override
  Future<void> completePurchase(PurchaseDetails purchase) =>
      _plugin.completePurchase(purchase);

  /// Asks Play Billing directly, which answers with each purchase's real
  /// state. Android only: StoreKit has no query that answers without the
  /// chance of a sign-in prompt, and there is no iOS build to ask it for.
  @override
  Future<Set<String>?> queryPaidProductIds() async {
    if (defaultTargetPlatform != TargetPlatform.android) return null;
    final response = await _plugin
        .getPlatformAddition<InAppPurchaseAndroidPlatformAddition>()
        .queryPastPurchases();
    if (response.error != null) return null;
    return {
      for (final purchase in response.pastPurchases)
        if (purchase.status == PurchaseStatus.purchased) purchase.productID,
    };
  }
}

/// Sobra's side of the store: prices to show, purchases to start, and
/// entitlements to hand to [SobraStore].
///
/// Every catalog entry sold here is a non-consumable. That is what makes a
/// reinstall recoverable without an account of our own — the platform keeps
/// the purchase against the user's store account and replays it on request.
class SobraPurchases extends ChangeNotifier implements CatalogPriceSource {
  SobraPurchases({
    required PurchaseBackend backend,
    required SobraStore store,
    this.restoreOnStart = true,
    this.restoreGrace = const Duration(seconds: 6),
    this.checkoutTimeout = const Duration(minutes: 3),
  }) : _backend = backend,
       _store = store;

  final PurchaseBackend _backend;
  final SobraStore _store;

  /// Whether [start] asks the store to replay past purchases by itself.
  ///
  /// True on Android, where a restore is a silent query against the Play
  /// account. It must be false on iOS: a StoreKit restore can raise an App
  /// Store sign-in prompt, and one appearing unprompted at launch reads as the
  /// app demanding a login — which is the single thing this design avoids.
  /// There it belongs behind the Ajustes row instead.
  final bool restoreOnStart;

  /// How long [restore] waits for the store to replay before concluding there
  /// is nothing to replay.
  ///
  /// `restorePurchases` returns as soon as the request has been made; what it
  /// finds arrives afterwards on [PurchaseBackend.purchaseStream]. Reading the
  /// result the instant the call returns therefore always reads "nothing",
  /// which is how a restore that worked perfectly would tell the user it had
  /// failed. Long enough for a slow network, short enough that a genuinely
  /// empty account is not left waiting.
  final Duration restoreGrace;

  /// How long a card may say the store is working before it goes back to
  /// offering the purchase.
  ///
  /// Every ordinary end to a checkout arrives on the purchase stream, but not
  /// every end is ordinary: a sheet dismissed with a swipe, or a process
  /// killed behind it, can leave nothing to arrive. Without a deadline the
  /// entry reads as mid-purchase until the app is restarted, and the one
  /// control that would fix it is the one that has been disabled.
  ///
  /// Only checkouts expire. A purchase Play has actually taken and is holding
  /// is tracked separately and waits as long as Play does.
  final Duration checkoutTimeout;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  final Map<String, ProductDetails> _products = {};

  /// Products whose checkout the app opened, against the timer that gives up
  /// on each.
  final Map<String, Timer> _checkingOut = {};

  /// Products Play has taken payment for and not yet cleared — a cash payment
  /// at a shop, or a parent still to approve it. These do not expire.
  final Set<String> _pending = {};
  StoreReadiness _readiness = StoreReadiness.checking;
  PurchaseFailure? _pendingFailure;
  bool _restoreGrantedSomething = false;
  bool _refreshing = false;

  /// Ids the store delivered since launch, which a revocation must not touch.
  ///
  /// Play's list of paid products is read once, and a checkout can finish
  /// while that answer is on its way. Without this, a purchase completing in
  /// the same seconds would be granted and then taken straight back.
  final Set<String> _deliveredThisRun = {};
  Completer<void>? _awaitingRestore;

  StoreReadiness get readiness => _readiness;

  /// True while the store is working on [productId].
  bool isBuying(String productId) =>
      _checkingOut.containsKey(productId) || _pending.contains(productId);

  /// True while any purchase is in flight, so one tap cannot start a second.
  bool get isBusy => _checkingOut.isNotEmpty || _pending.isNotEmpty;

  @override
  String? localizedPriceFor(String storeProductId) =>
      _products[storeProductId]?.price;

  /// The failure to show, cleared as it is read.
  ///
  /// Read-once like [SobraStore.takePendingXpNotice], so a rebuild for an
  /// unrelated reason cannot show the same error a second time.
  ///
  /// Carries only what the purchase stream raises on its own — the failures
  /// that arrive with no call still waiting for them. A restore answers its
  /// caller directly instead; see [restore].
  PurchaseFailure? takeFailure() {
    final failure = _pendingFailure;
    _pendingFailure = null;
    return failure;
  }

  /// Connects to the store, loads prices, and replays past purchases.
  ///
  /// Never throws. A store that cannot be reached leaves the catalog showing
  /// its entries without prices, which is a worse screen than the one with
  /// them and a far better one than no app at all.
  Future<void> start() async {
    _subscription ??= _backend.purchaseStream.listen(
      _handlePurchases,
      onError: (Object _) => _report(PurchaseFailure.purchaseRejected),
    );
    bool available;
    try {
      available = await _backend.isAvailable();
    } on Object {
      available = false;
    }
    if (!available) {
      _readiness = StoreReadiness.unavailable;
      notifyListeners();
      return;
    }
    _readiness = StoreReadiness.ready;
    await _loadPrices();
    if (restoreOnStart) {
      // Deliberately not surfacing "nothing to restore" here: at launch the
      // user did not ask, and most launches legitimately restore nothing.
      try {
        await _backend.restorePurchases();
      } on Object {
        // A launch restore that fails changes nothing the user can see. The
        // Ajustes row is where a restore reports on itself.
      }
      await _takeBackWhatIsNoLongerPaid();
    }
    notifyListeners();
  }

  /// Replays purchases again when the app comes back to the foreground.
  ///
  /// Catches what was bought outside the app while it sat in the background:
  /// for example, a promo code redeemed in the Play Store. Play does not
  /// announce it to a running app, so without asking it would
  /// wait for the next cold start — which can be days on a phone that keeps
  /// the app alive.
  ///
  /// Only replays; the revocation stays a launch-time check. Silent like the
  /// launch restore, and skipped while a checkout is open: the Play sheet is
  /// itself a trip to the background, and the purchase it returns with is
  /// already on its way down the stream.
  Future<void> refreshOnResume() async {
    if (!restoreOnStart ||
        _readiness != StoreReadiness.ready ||
        _checkingOut.isNotEmpty ||
        _refreshing) {
      return;
    }
    _refreshing = true;
    try {
      await _backend.restorePurchases();
    } on Object {
      // Nothing the user asked for failed. The next resume asks again.
    } finally {
      _refreshing = false;
    }
  }

  /// Revokes purchases the store account no longer holds as paid.
  ///
  /// A refund, a chargeback, or a cash payment that expired unpaid all look
  /// the same from here: the product is gone from Play's list. Nothing about
  /// it reaches the purchase stream, so without asking, the entry would stay
  /// unlocked on this phone for good.
  ///
  /// Reversible by design. Play's list is per account, so a phone signed into
  /// a different Play account loses the entries here too — and the launch
  /// restore gives them back the moment the paying account is back.
  ///
  /// Silent on purpose. The user who asked for the refund knows why, and a
  /// message would be the app arguing with them.
  Future<void> _takeBackWhatIsNoLongerPaid() async {
    Set<String>? paid;
    try {
      paid = await _backend.queryPaidProductIds();
    } on Object {
      paid = null;
    }
    // No answer is not an empty answer. Taking purchases back on a failed
    // query would strip a paying user every time they launched offline.
    if (paid == null) return;
    final stillPaidFor = {
      for (final productId in paid) ..._deliveredBy(productId),
    };
    final revoked =
        {
            for (final productId in CatalogPreviewData.storeProductIds)
              if (!paid.contains(productId)) ..._deliveredBy(productId),
          }
          ..removeAll(stillPaidFor)
          ..removeAll(_deliveredThisRun);
    revoked.retainWhere(_onlyEverSold);
    if (revoked.isEmpty) return;
    try {
      await _store.revokeCatalogEntries(revoked);
    } on Object catch (error) {
      // Left for the next launch, which asks again and finds the same answer.
      debugPrint('Sobra: could not save the revocation of $revoked: $error');
    }
  }

  /// Every id [productId] can have been recorded under in the owned set.
  ///
  /// The raw product id is included because [_grant] falls back to it for a
  /// product a build could not map, and [SobraStore.ownsCatalogEntry] still
  /// reads that id as owning the entry.
  static Set<String> _deliveredBy(String productId) => {
    ...?CatalogPreviewData.entitlementsForProductId(productId),
    CatalogPreviewData.entryForProductId(productId)?.id ?? productId,
    productId,
  };

  /// Whether [id] can only ever have come from the store.
  ///
  /// An entry that can also be earned with ads must not be taken back on the
  /// strength of a refund for something else: the user may have watched for
  /// it. Ids outside the catalog — ad removal, raw product ids — are sold
  /// only. Gifts are not: nobody paid for them, so there is no refund to
  /// follow.
  static bool _onlyEverSold(String id) {
    final entry = CatalogPreviewData.all
        .where((candidate) => candidate.id == id)
        .firstOrNull;
    return entry == null ||
        entry.unlockMethod == CatalogUnlockMethod.purchase ||
        entry.unlockMethod == CatalogUnlockMethod.bundle;
  }

  Future<void> _loadPrices() async {
    final ids = CatalogPreviewData.storeProductIds;
    if (ids.isEmpty) return;
    try {
      final response = await _backend.queryProductDetails(ids);
      _products
        ..clear()
        ..addEntries(
          response.productDetails.map(
            (product) => MapEntry(product.id, product),
          ),
        );
      // `notFoundIDs` is not an error worth showing. It is what a build whose
      // catalog runs ahead of the Play Console listing looks like, and the
      // entry simply shows no price until the listing catches up.
      if (response.notFoundIDs.isNotEmpty) {
        debugPrint('Sobra: store has no listing for ${response.notFoundIDs}');
      }
    } on Object catch (error) {
      debugPrint('Sobra: could not load prices: $error');
    }
  }

  /// Starts the purchase of [entry].
  ///
  /// Returns without doing anything for an entry that is not sold, already
  /// owned, or already being bought — a second tap on a slow store must not
  /// open a second checkout.
  ///
  /// A bundle entry is not sold, whatever product id it carries. The id names
  /// the bundle it arrives in rather than a price for this one item, and
  /// buying from its card would charge for the whole bundle from a single
  /// decoration. The bundle is sold by the row that describes it.
  Future<void> buy(CatalogEntry entry) async {
    final productId = entry.storeProductId;
    if (entry.unlockMethod != CatalogUnlockMethod.purchase) return;
    if (productId == null || _store.ownsCatalogEntry(entry)) return;
    await buyProduct(productId);
  }

  /// Starts the purchase of a store product that is not a catalog card.
  ///
  /// The pack and the standalone ad-removal product live here. Their cards
  /// are settings rows, not collection entries, and [buy] would refuse them
  /// for not being [CatalogUnlockMethod.purchase].
  ///
  /// Returns without doing anything when every entitlement is already owned
  /// or a checkout for the same id is already open.
  Future<void> buyProduct(String productId) async {
    if (_alreadyOwnsProduct(productId) || isBuying(productId)) return;
    final product = _products[productId];
    if (product == null) {
      _report(PurchaseFailure.storeUnavailable);
      return;
    }
    _checkingOut[productId] = Timer(checkoutTimeout, () {
      _checkingOut.remove(productId);
      notifyListeners();
    });
    notifyListeners();
    try {
      await _backend.buyNonConsumable(product);
    } on Object {
      _endCheckout(productId);
      _report(PurchaseFailure.purchaseRejected);
    }
  }

  bool _alreadyOwnsProduct(String productId) {
    final entitlements = CatalogPreviewData.entitlementsForProductId(productId);
    if (entitlements != null) {
      return entitlements.every(_store.ownedCatalogIds.contains);
    }
    final entry = CatalogPreviewData.entryForProductId(productId);
    return entry != null && _store.ownsCatalogEntry(entry);
  }

  void _endCheckout(String productId) =>
      _checkingOut.remove(productId)?.cancel();

  /// Replays what this store account already owns, answering with how it went.
  ///
  /// Returns its outcome rather than leaving it in [takeFailure], so that the
  /// row which asked is the one that reports. The catalog screen watches that
  /// queue for purchases arriving on their own and stays mounted behind
  /// Ajustes while a restore runs — it would otherwise consume the answer to
  /// a question it never asked.
  ///
  /// Null means purchases came back. Unlike the restore [start] runs, an empty
  /// result is worth saying here: this one the user asked for, and a button
  /// that answers nothing at all reads as broken.
  Future<PurchaseFailure?> restore() async {
    _restoreGrantedSomething = false;
    // Opened before the request, not after it. The replay can reach the stream
    // while `restorePurchases` is still returning, and a window opened
    // afterwards races that grant: lose the race and an account full of
    // purchases sits out the whole grace period to be told it has none.
    final waiting = _awaitingRestore = Completer<void>();
    try {
      await _backend.restorePurchases();
    } on Object {
      _awaitingRestore = null;
      return PurchaseFailure.storeUnavailable;
    }
    // Waits for the replay rather than for the request. The first grant ends
    // the wait early, so an account with purchases answers as fast as the
    // store does and only an empty one spends the whole grace period.
    await Future.any([waiting.future, Future<void>.delayed(restoreGrace)]);
    _awaitingRestore = null;
    return _restoreGrantedSomething ? null : PurchaseFailure.nothingToRestore;
  }

  Future<void> _handlePurchases(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          // Play has the payment and has not cleared it. The entry stays
          // locked and the card keeps saying so rather than claiming a
          // delivery that has not happened, for as long as Play takes.
          _endCheckout(purchase.productID);
          _pending.add(purchase.productID);
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          _endCheckout(purchase.productID);
          _pending.remove(purchase.productID);
          final delivered = await _grant(
            purchase.productID,
            fromRestore: purchase.status == PurchaseStatus.restored,
          );
          if (!delivered) {
            // Left uncompleted on purpose, so the store replays it and the
            // next launch can write what this one could not. Telling the user
            // is the part that used to be missing: the save threw, the error
            // escaped an async stream handler where nothing was listening,
            // and somebody who had just paid saw an entry still for sale.
            _pendingFailure = PurchaseFailure.deliveryNotSaved;
            continue;
          }
        case PurchaseStatus.error:
          _endCheckout(purchase.productID);
          _pending.remove(purchase.productID);
          _pendingFailure = PurchaseFailure.purchaseRejected;
        case PurchaseStatus.canceled:
          // The user backed out. That is an answer, not a fault, and saying
          // anything about it would be scolding them for using the cancel
          // button.
          _endCheckout(purchase.productID);
          _pending.remove(purchase.productID);
      }
      if (purchase.pendingCompletePurchase) {
        // Strictly after the grant above. Completing first and failing to
        // grant would leave the store certain the product was delivered while
        // the user has nothing; this way the worst case is a purchase replayed
        // on the next launch and granted again, which is harmless because
        // granting the same id twice is a no-op.
        await _backend.completePurchase(purchase);
      }
    }
    notifyListeners();
  }

  /// Writes the entitlement, under the catalog ids where they are known.
  ///
  /// Bundles are resolved first, and that order is load-bearing. A bundle's
  /// product id also sits on the one entry sold exclusively inside it, so
  /// [CatalogPreviewData.entryForProductId] answers for a bundle as well — with
  /// a single decoration, while returning true. Somebody who paid for the
  /// supporter bundle would have been told the delivery worked and received one
  /// item out of five.
  ///
  /// Falls back to the raw product id so a purchase from a lineup this build
  /// no longer ships survives in the saved state. [SobraStore.ownsCatalogEntry]
  /// matches on both, so a later build that restores the entry finds it owned.
  ///
  /// Returns whether the write landed. The in-memory state is left as the
  /// store put it rather than rolled back — every other mutation in the app
  /// is optimistic the same way, and here the optimism turns out to be right:
  /// an undelivered purchase is replayed and granted on the next launch.
  ///
  /// Only a grant that came from a restore answers [restore], so a purchase
  /// completing while a restore happens to be waiting cannot make an account
  /// with nothing in it report that something came back.
  Future<bool> _grant(String productId, {required bool fromRestore}) async {
    final ids =
        CatalogPreviewData.entitlementsForProductId(productId) ??
        {CatalogPreviewData.entryForProductId(productId)?.id ?? productId};
    _deliveredThisRun.addAll(ids);
    try {
      await _store.grantCatalogEntries(ids);
    } on Object catch (error) {
      debugPrint('Sobra: could not save the purchase of $productId: $error');
      return false;
    }
    if (fromRestore) {
      _restoreGrantedSomething = true;
      if (_awaitingRestore?.isCompleted == false) _awaitingRestore!.complete();
    }
    return true;
  }

  void _report(PurchaseFailure failure) {
    _pendingFailure = failure;
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    _subscription = null;
    for (final timer in _checkingOut.values) {
      timer.cancel();
    }
    _checkingOut.clear();
    super.dispose();
  }
}

/// Puts [SobraPurchases] in the tree the way [SobraScope] does the store.
class PurchaseScope extends InheritedNotifier<SobraPurchases> {
  const PurchaseScope({
    super.key,
    required SobraPurchases purchases,
    required super.child,
  }) : super(notifier: purchases);

  /// The purchases above [context], or null where there are none.
  ///
  /// Null is the normal answer in a test or a design preview, and callers show
  /// the catalog without live prices rather than refusing to build.
  static SobraPurchases? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PurchaseScope>()?.notifier;
}
