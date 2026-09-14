import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:sobra_app/services/purchase_service.dart';

/// A store that answers from lists the test sets, so the purchase logic can be
/// exercised without Play Billing or StoreKit.
class FakeBackend implements PurchaseBackend {
  final _controller = StreamController<List<PurchaseDetails>>.broadcast();

  bool available = true;
  bool failBuy = false;
  bool failRestore = false;
  List<ProductDetails> catalogue = [];
  List<String> notFound = [];

  /// What a restore replays.
  List<String> ownedProductIds = [];

  final List<String> bought = [];
  final List<String> completed = [];

  /// Runs on every completePurchase, so a test can assert on what the rest of
  /// the app already knows at that moment.
  void Function(PurchaseDetails)? onComplete;

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _controller.stream;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<ProductDetailsResponse> queryProductDetails(Set<String> ids) async =>
      ProductDetailsResponse(
        productDetails: [
          for (final product in catalogue)
            if (ids.contains(product.id)) product,
        ],
        notFoundIDs: notFound,
      );

  @override
  Future<void> buyNonConsumable(ProductDetails product) async {
    if (failBuy) throw StateError('store refused');
    bought.add(product.id);
  }

  @override
  Future<void> restorePurchases() async {
    if (failRestore) throw StateError('store unreachable');
    if (ownedProductIds.isEmpty) return;
    emit([
      for (final id in ownedProductIds) detailsFor(id, PurchaseStatus.restored),
    ]);
  }

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async {
    completed.add(purchase.productID);
    onComplete?.call(purchase);
  }

  void emit(List<PurchaseDetails> purchases) => _controller.add(purchases);

  Future<void> close() => _controller.close();
}

PurchaseDetails detailsFor(
  String productId,
  PurchaseStatus status, {
  bool needsCompleting = true,
}) => PurchaseDetails(
  productID: productId,
  verificationData: PurchaseVerificationData(
    localVerificationData: '',
    serverVerificationData: '',
    source: 'test',
  ),
  transactionDate: null,
  status: status,
)..pendingCompletePurchase = needsCompleting;

ProductDetails productFor(String id, String price) => ProductDetails(
  id: id,
  title: id,
  description: id,
  price: price,
  rawPrice: 79,
  currencyCode: 'MXN',
);
