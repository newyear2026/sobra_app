import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sobra_app/data/catalog_preview_data.dart';
import 'package:sobra_app/models/catalog_entry.dart';
import 'package:sobra_app/services/purchase_service.dart';
import 'package:sobra_app/state/sobra_store.dart';

import 'support/fake_purchase_backend.dart';

void main() {
  late SobraStore store;
  late FakeBackend backend;

  const soldProductId = 'sobra.character.02';
  const soldEntryId = 'character-02';

  CatalogEntry entryById(String id) =>
      CatalogPreviewData.all.firstWhere((entry) => entry.id == id);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    store = await SobraStore.load(now: () => DateTime(2026, 9, 14, 11));
    backend = FakeBackend()
      ..catalogue = [
        productFor(soldProductId, r'MX$ 79'),
        productFor('sobra.character.04', r'MX$ 99'),
      ];
  });

  tearDown(() => backend.close());

  Future<SobraPurchases> started({bool restoreOnStart = true}) async {
    final purchases = SobraPurchases(
      backend: backend,
      store: store,
      restoreOnStart: restoreOnStart,
      // The real grace is seconds long so a slow network still answers. A
      // test that means to find nothing should not sit through it.
      restoreGrace: const Duration(milliseconds: 40),
    );
    addTearDown(purchases.dispose);
    await purchases.start();
    await pumpEventQueue();
    return purchases;
  }

  test(
    'prices come from the store, not from the catalog definitions',
    () async {
      final purchases = await started();

      expect(purchases.readiness, StoreReadiness.ready);
      expect(purchases.localizedPriceFor(soldProductId), r'MX$ 79');
      // Listed in the catalog but absent from this store response.
      expect(purchases.localizedPriceFor('sobra.character.06'), isNull);
    },
  );

  test(
    'an unreachable store leaves the catalog priceless, not broken',
    () async {
      backend.available = false;

      final purchases = await started();

      expect(purchases.readiness, StoreReadiness.unavailable);
      expect(purchases.localizedPriceFor(soldProductId), isNull);
      expect(purchases.takeFailure(), isNull);
    },
  );

  test('a completed purchase is granted and then completed', () async {
    final purchases = await started();
    // The store is only told the product was delivered once it actually has
    // been. Completing first would let a crash in between leave the user
    // paid-up and empty-handed.
    backend.onComplete = expectAsync1((_) {
      expect(store.ownsCatalogEntry(entryById(soldEntryId)), isTrue);
    });

    await purchases.buy(entryById(soldEntryId));
    backend.emit([detailsFor(soldProductId, PurchaseStatus.purchased)]);
    await pumpEventQueue();

    expect(backend.bought, [soldProductId]);
    expect(backend.completed, [soldProductId]);
    expect(store.ownsCatalogEntry(entryById(soldEntryId)), isTrue);
    expect(purchases.takeFailure(), isNull);
  });

  test(
    'the entitlement is stored under the catalog id, not the product id',
    () async {
      final purchases = await started();

      await purchases.buy(entryById(soldEntryId));
      backend.emit([detailsFor(soldProductId, PurchaseStatus.purchased)]);
      await pumpEventQueue();

      expect(store.ownedCatalogIds, {soldEntryId});
    },
  );

  test('a restore at launch grants what the account already owns', () async {
    backend.ownedProductIds = [soldProductId];

    await started();

    expect(store.ownsCatalogEntry(entryById(soldEntryId)), isTrue);
    expect(backend.completed, [soldProductId]);
    // Survives the reinstall this whole feature exists for.
    final reopened = await SobraStore.load(
      now: () => DateTime(2026, 9, 14, 12),
    );
    expect(reopened.ownsCatalogEntry(entryById(soldEntryId)), isTrue);
  });

  test('iOS-shaped start does not restore by itself', () async {
    backend.ownedProductIds = [soldProductId];

    await started(restoreOnStart: false);

    expect(store.ownedCatalogIds, isEmpty);
  });

  test('a product this build no longer ships is kept verbatim', () async {
    backend.ownedProductIds = ['sobra.character.99'];

    await started();

    expect(store.ownedCatalogIds, {'sobra.character.99'});
  });

  test('cancelling says nothing and grants nothing', () async {
    final purchases = await started();

    await purchases.buy(entryById(soldEntryId));
    backend.emit([
      detailsFor(
        soldProductId,
        PurchaseStatus.canceled,
        needsCompleting: false,
      ),
    ]);
    await pumpEventQueue();

    expect(purchases.takeFailure(), isNull);
    expect(store.ownedCatalogIds, isEmpty);
    expect(purchases.isBuying(soldProductId), isFalse);
  });

  test('a rejected purchase reports once and then stops reporting', () async {
    final purchases = await started();

    await purchases.buy(entryById(soldEntryId));
    backend.emit([
      detailsFor(soldProductId, PurchaseStatus.error, needsCompleting: false),
    ]);
    await pumpEventQueue();

    expect(purchases.takeFailure(), PurchaseFailure.purchaseRejected);
    expect(purchases.takeFailure(), isNull);
    expect(store.ownedCatalogIds, isEmpty);
  });

  test('a pending purchase leaves the entry locked', () async {
    final purchases = await started();

    await purchases.buy(entryById(soldEntryId));
    backend.emit([
      detailsFor(soldProductId, PurchaseStatus.pending, needsCompleting: false),
    ]);
    await pumpEventQueue();

    expect(store.ownsCatalogEntry(entryById(soldEntryId)), isFalse);
    expect(purchases.isBuying(soldProductId), isTrue);
  });

  test(
    'a second tap while the store is working opens no second checkout',
    () async {
      final purchases = await started();

      await purchases.buy(entryById(soldEntryId));
      await purchases.buy(entryById(soldEntryId));

      expect(backend.bought, [soldProductId]);
    },
  );

  test('buying something already owned does nothing', () async {
    final purchases = await started();
    await store.grantCatalogEntry(soldEntryId);

    await purchases.buy(entryById(soldEntryId));

    expect(backend.bought, isEmpty);
  });

  test('a manual restore that finds nothing says so', () async {
    final purchases = await started(restoreOnStart: false);

    await purchases.restore();
    await pumpEventQueue();

    expect(purchases.takeFailure(), PurchaseFailure.nothingToRestore);
  });

  test('a manual restore that finds something stays quiet', () async {
    final purchases = await started(restoreOnStart: false);
    backend.ownedProductIds = [soldProductId];

    await purchases.restore();
    await pumpEventQueue();

    expect(purchases.takeFailure(), isNull);
    expect(store.ownsCatalogEntry(entryById(soldEntryId)), isTrue);
  });

  test('a restore against an unreachable store reports it', () async {
    final purchases = await started(restoreOnStart: false);
    backend.failRestore = true;

    await purchases.restore();

    expect(purchases.takeFailure(), PurchaseFailure.storeUnavailable);
  });
}
