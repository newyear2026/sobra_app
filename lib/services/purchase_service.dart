import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

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
}

/// The real store, reached through the plugin singleton.
final class PluginPurchaseBackend implements PurchaseBackend {
  PluginPurchaseBackend([InAppPurchase? plugin])
    : _plugin = plugin ?? InAppPurchase.instance;

  final InAppPurchase _plugin;

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _plugin.purchaseStream;

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

  StreamSubscription<List<PurchaseDetails>>? _subscription;
  final Map<String, ProductDetails> _products = {};
  final Set<String> _inFlight = {};
  StoreReadiness _readiness = StoreReadiness.checking;
  PurchaseFailure? _pendingFailure;
  bool _restoreGrantedSomething = false;
  Completer<void>? _awaitingRestore;

  StoreReadiness get readiness => _readiness;

  /// True while the store is working on [productId].
  bool isBuying(String productId) => _inFlight.contains(productId);

  /// True while any purchase is in flight, so one tap cannot start a second.
  bool get isBusy => _inFlight.isNotEmpty;

  @override
  String? localizedPriceFor(String storeProductId) =>
      _products[storeProductId]?.price;

  /// The failure to show, cleared as it is read.
  ///
  /// Read-once like [SobraStore.takePendingXpNotice], so a rebuild for an
  /// unrelated reason cannot show the same error a second time.
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
    }
    notifyListeners();
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
  Future<void> buy(CatalogEntry entry) async {
    final productId = entry.storeProductId;
    if (productId == null || _store.ownsCatalogEntry(entry)) return;
    if (_inFlight.contains(productId)) return;
    final product = _products[productId];
    if (product == null) {
      _report(PurchaseFailure.storeUnavailable);
      return;
    }
    _inFlight.add(productId);
    notifyListeners();
    try {
      await _backend.buyNonConsumable(product);
    } on Object {
      _inFlight.remove(productId);
      _report(PurchaseFailure.purchaseRejected);
    }
  }

  /// Replays what this store account already owns.
  ///
  /// Reports when it finds nothing, unlike the restore [start] runs: this one
  /// the user asked for, and a button that answers nothing at all reads as
  /// broken.
  Future<void> restore() async {
    _restoreGrantedSomething = false;
    try {
      await _backend.restorePurchases();
    } on Object {
      _report(PurchaseFailure.storeUnavailable);
      return;
    }
    // Waits for the replay rather than for the request. The first grant ends
    // the wait early, so an account with purchases answers as fast as the
    // store does and only an empty one spends the whole grace period.
    final waiting = _awaitingRestore = Completer<void>();
    await Future.any([waiting.future, Future<void>.delayed(restoreGrace)]);
    _awaitingRestore = null;
    if (!_restoreGrantedSomething) _report(PurchaseFailure.nothingToRestore);
  }

  Future<void> _handlePurchases(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          // Play can hold a purchase for hours — cash payment at a shop, or a
          // parent still to approve it. The entry stays locked and the card
          // keeps saying so rather than claiming a delivery that has not
          // happened.
          _inFlight.add(purchase.productID);
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          _inFlight.remove(purchase.productID);
          await _grant(purchase.productID);
        case PurchaseStatus.error:
          _inFlight.remove(purchase.productID);
          _pendingFailure = PurchaseFailure.purchaseRejected;
        case PurchaseStatus.canceled:
          // The user backed out. That is an answer, not a fault, and saying
          // anything about it would be scolding them for using the cancel
          // button.
          _inFlight.remove(purchase.productID);
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

  /// Writes the entitlement, under the catalog id where one is known.
  ///
  /// Falls back to the raw product id so a purchase from a lineup this build
  /// no longer ships survives in the saved state. [SobraStore.ownsCatalogEntry]
  /// matches on both, so a later build that restores the entry finds it owned.
  Future<void> _grant(String productId) async {
    final entry = CatalogPreviewData.entryForProductId(productId);
    await _store.grantCatalogEntry(entry?.id ?? productId);
    _restoreGrantedSomething = true;
    if (_awaitingRestore?.isCompleted == false) _awaitingRestore!.complete();
  }

  void _report(PurchaseFailure failure) {
    _pendingFailure = failure;
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    _subscription = null;
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
