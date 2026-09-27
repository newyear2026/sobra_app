import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:sobra_app/data/catalog_preview_data.dart';
import 'package:sobra_app/models/catalog_entry.dart';
import 'package:sobra_app/services/purchase_service.dart';
import 'package:sobra_app/state/sobra_store.dart';

import 'support/fake_purchase_backend.dart';

/// A preferences store whose writes can be switched off mid-test.
///
/// The one way to reach a failed save: nothing in the purchase flow can
/// provoke one on its own, so the disk has to be broken from underneath.
class _BreakableStore extends InMemorySharedPreferencesStore {
  _BreakableStore.empty() : super.empty();

  bool writesFail = false;

  @override
  Future<bool> setValue(String valueType, String key, Object value) =>
      writesFail
      ? Future<bool>.value(false)
      : super.setValue(valueType, key, value);
}

void main() {
  late SobraStore store;
  late FakeBackend backend;

  const soldProductId = 'sobra.character.07';
  const soldEntryId = 'character-07';

  CatalogEntry entryById(String id) =>
      CatalogPreviewData.all.firstWhere((entry) => entry.id == id);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    store = await SobraStore.load(now: () => DateTime(2026, 9, 14, 11));
    backend = FakeBackend()
      ..catalogue = [
        productFor(soldProductId, r'MX$ 79'),
        productFor('sobra.character.09', r'MX$ 99'),
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
      expect(purchases.localizedPriceFor('sobra.character.10'), isNull);
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

  group('a purchase Play no longer holds as paid', () {
    test('is taken back at launch and stops being shown', () async {
      await store.grantCatalogEntry(soldEntryId);
      await store.equipCharacter(entryById(soldEntryId));
      backend.paidProductIds = {};

      await started();

      expect(store.ownsCatalogEntry(entryById(soldEntryId)), isFalse);
      expect(store.characterId, 'michi');
      // The revocation is saved, not only held in memory.
      final reopened = await SobraStore.load(
        now: () => DateTime(2026, 9, 14, 12),
      );
      expect(reopened.ownsCatalogEntry(entryById(soldEntryId)), isFalse);
    });

    test('leaves what is still paid for alone', () async {
      await store.grantCatalogEntries({soldEntryId, 'character-09'});
      backend.paidProductIds = {soldProductId};

      await started();

      expect(store.ownedCatalogIds, {soldEntryId});
    });

    test(
      'keeps ad removal while the standalone product is still paid',
      () async {
        const packId = CatalogPreviewData.packProductId;
        const removeId = CatalogPreviewData.removeAdsProductId;
        await store.grantCatalogEntries(
          CatalogPreviewData.productEntitlements[packId]!,
        );
        backend.paidProductIds = {removeId};

        await started();

        expect(store.ownsPack, isFalse);
        expect(store.ownsNoAds, isTrue);
        expect(store.ownsCatalogEntry(entryById('character-02')), isFalse);
      },
    );

    test('is also found under its raw product id', () async {
      await store.grantCatalogEntry(soldProductId);
      backend.paidProductIds = {};

      await started();

      expect(store.ownedCatalogIds, isEmpty);
    });

    test('never touches what was earned with ads', () async {
      final adEntry = entryById('character-03');
      for (var view = 0; view < adEntry.rewardedAdTarget!; view++) {
        await store.recordRewardedAdView(adEntry);
      }
      backend.paidProductIds = {};

      await started();

      expect(store.ownsCatalogEntry(adEntry), isTrue);
    });

    test('is left alone when the store cannot answer', () async {
      await store.grantCatalogEntry(soldEntryId);
      backend.failPaidQuery = true;

      await started();

      expect(store.ownsCatalogEntry(entryById(soldEntryId)), isTrue);
    });

    test('is left alone when the store has no such query', () async {
      await store.grantCatalogEntry(soldEntryId);
      backend.paidProductIds = null;

      await started();

      expect(store.ownsCatalogEntry(entryById(soldEntryId)), isTrue);
    });

    test('is not checked on an iOS-shaped start', () async {
      await store.grantCatalogEntry(soldEntryId);
      backend.paidProductIds = {};

      await started(restoreOnStart: false);

      expect(store.ownsCatalogEntry(entryById(soldEntryId)), isTrue);
    });

    test(
      'does not include a purchase delivered while Play was asked',
      () async {
        final purchases = SobraPurchases(
          backend: backend,
          store: store,
          restoreGrace: const Duration(milliseconds: 40),
        );
        addTearDown(purchases.dispose);
        // Play's answer predates the checkout that finishes during the launch.
        backend
          ..paidProductIds = {}
          ..onRestore = () => backend.emit([
            detailsFor(soldProductId, PurchaseStatus.purchased),
          ]);

        await purchases.start();
        await pumpEventQueue();

        expect(store.ownsCatalogEntry(entryById(soldEntryId)), isTrue);
      },
    );
  });

  test('buying something already owned does nothing', () async {
    final purchases = await started();
    await store.grantCatalogEntry(soldEntryId);

    await purchases.buy(entryById(soldEntryId));

    expect(backend.bought, isEmpty);
  });

  test('a manual restore that finds nothing says so', () async {
    final purchases = await started(restoreOnStart: false);

    expect(await purchases.restore(), PurchaseFailure.nothingToRestore);
    // Answered its caller, not the queue the catalog screen is watching.
    expect(purchases.takeFailure(), isNull);
  });

  test('a manual restore that finds something stays quiet', () async {
    final purchases = await started(restoreOnStart: false);
    backend.ownedProductIds = [soldProductId];

    expect(await purchases.restore(), isNull);
    expect(purchases.takeFailure(), isNull);
    expect(store.ownsCatalogEntry(entryById(soldEntryId)), isTrue);
  });

  test('a restore against an unreachable store reports it', () async {
    final purchases = await started(restoreOnStart: false);
    backend.failRestore = true;

    expect(await purchases.restore(), PurchaseFailure.storeUnavailable);
  });

  // A purchase arriving while a restore waits used to answer for the restore,
  // so an account that owned nothing could report that something came back.
  test('a purchase during a restore does not answer for it', () async {
    final purchases = await started(restoreOnStart: false);
    backend.onRestore = () =>
        backend.emit([detailsFor(soldProductId, PurchaseStatus.purchased)]);

    expect(await purchases.restore(), PurchaseFailure.nothingToRestore);
    await pumpEventQueue();

    expect(store.ownsCatalogEntry(entryById(soldEntryId)), isTrue);
  });

  group('when the disk refuses the write', () {
    late _BreakableStore preferences;

    setUp(() async {
      // setMockInitialValues installs a platform store of its own, so the
      // breakable one has to replace it afterwards or writes never fail.
      SharedPreferences.setMockInitialValues({});
      preferences = _BreakableStore.empty();
      SharedPreferencesStorePlatform.instance = preferences;
      store = await SobraStore.load(now: () => DateTime(2026, 9, 14, 11));
    });

    // The delivery used to be lost in silence: the save threw inside an async
    // stream handler nobody was listening to, the purchase was never
    // completed, and the user who had just paid was told nothing. Play
    // refunds an unacknowledged purchase after three days, so the entry
    // quietly went away again.
    test('the purchase is reported and left for the next launch', () async {
      final purchases = await started(restoreOnStart: false);
      await purchases.buy(entryById(soldEntryId));
      preferences.writesFail = true;

      backend.emit([detailsFor(soldProductId, PurchaseStatus.purchased)]);
      await pumpEventQueue();

      expect(purchases.takeFailure(), PurchaseFailure.deliveryNotSaved);
      // Not completed, so the store still owes it.
      expect(backend.completed, isEmpty);
      expect(purchases.isBuying(soldProductId), isFalse);
    });

    test('the next launch finishes what the failed save started', () async {
      await started(restoreOnStart: false);
      preferences.writesFail = true;
      backend.emit([detailsFor(soldProductId, PurchaseStatus.purchased)]);
      await pumpEventQueue();
      expect(backend.completed, isEmpty);

      // The store replays what it was never told was delivered.
      preferences.writesFail = false;
      backend.emit([detailsFor(soldProductId, PurchaseStatus.restored)]);
      await pumpEventQueue();

      expect(store.ownsCatalogEntry(entryById(soldEntryId)), isTrue);
      expect(backend.completed, [soldProductId]);
    });
  });

  // A sheet dismissed with a swipe, or a process killed behind it, can leave
  // nothing to arrive on the stream at all.
  test('a checkout nothing answers stops claiming the card forever', () async {
    final purchases = SobraPurchases(
      backend: backend,
      store: store,
      restoreOnStart: false,
      checkoutTimeout: const Duration(milliseconds: 30),
    );
    addTearDown(purchases.dispose);
    await purchases.start();

    await purchases.buy(entryById(soldEntryId));
    expect(purchases.isBuying(soldProductId), isTrue);

    await Future<void>.delayed(const Duration(milliseconds: 60));

    expect(purchases.isBuying(soldProductId), isFalse);
    // And the entry can be bought again rather than staying dead.
    await purchases.buy(entryById(soldEntryId));
    expect(backend.bought, [soldProductId, soldProductId]);
  });

  test('a purchase Play is holding is never timed out', () async {
    final purchases = SobraPurchases(
      backend: backend,
      store: store,
      restoreOnStart: false,
      checkoutTimeout: const Duration(milliseconds: 30),
    );
    addTearDown(purchases.dispose);
    await purchases.start();

    await purchases.buy(entryById(soldEntryId));
    backend.emit([
      detailsFor(soldProductId, PurchaseStatus.pending, needsCompleting: false),
    ]);
    await pumpEventQueue();
    await Future<void>.delayed(const Duration(milliseconds: 60));

    // Play can hold one of these for hours. Waiting is the correct answer.
    expect(purchases.isBuying(soldProductId), isTrue);
  });

  // The regression this whole mapping exists for. Before it, the bundle's
  // product id resolved through entryForProductId to the one decoration sold
  // exclusively inside it: the store took the money, the save succeeded, the
  // delivery reported true, and the user received a single room object instead
  // of three characters, a decoration and ad removal.
  test('buying the pack delivers all of it', () async {
    const bundleId = CatalogPreviewData.packProductId;
    backend.catalogue = [...backend.catalogue, productFor(bundleId, r'MX$ 199')];
    await started(restoreOnStart: false);

    backend.emit([detailsFor(bundleId, PurchaseStatus.purchased)]);
    await pumpEventQueue();

    expect(
      store.ownedCatalogIds,
      containsAll(CatalogPreviewData.productEntitlements[bundleId]!),
    );
    expect(store.ownsCatalogEntry(entryById('character-02')), isTrue);
    expect(store.ownsCatalogEntry(entryById('character-04')), isTrue);
    expect(store.ownsCatalogEntry(entryById('character-06')), isTrue);
    expect(
      store.ownsCatalogEntry(
        entryById(CatalogPreviewData.packDecorationId),
      ),
      isTrue,
    );
    expect(
      store.ownedCatalogIds,
      contains(CatalogPreviewData.noAdsEntitlement),
    );
    // The delivery landed, so the store is told to close the transaction.
    expect(backend.completed, [bundleId]);
  });

  test('restoring the pack delivers all of it', () async {
    const bundleId = CatalogPreviewData.packProductId;
    backend
      ..catalogue = [...backend.catalogue, productFor(bundleId, r'MX$ 199')]
      ..ownedProductIds = [bundleId];
    final purchases = await started(restoreOnStart: false);

    final failure = await purchases.restore();
    await pumpEventQueue();

    expect(failure, isNull);
    expect(
      store.ownedCatalogIds,
      containsAll(CatalogPreviewData.productEntitlements[bundleId]!),
    );
  });

  // The decoration carries the bundle's product id so the store can price the
  // bundle. Its card must not turn that into a checkout: one room object would
  // charge for the whole bundle.
  test('a bundle entry cannot be bought from its own card', () async {
    const bundleId = CatalogPreviewData.packProductId;
    backend.catalogue = [...backend.catalogue, productFor(bundleId, r'MX$ 199')];
    final purchases = await started(restoreOnStart: false);

    await purchases.buy(entryById(CatalogPreviewData.packDecorationId));

    expect(backend.bought, isEmpty);
  });

  test('buying remove-ads grants only the entitlement', () async {
    const productId = CatalogPreviewData.removeAdsProductId;
    backend.catalogue = [...backend.catalogue, productFor(productId, r'MX$ 89')];
    final purchases = await started(restoreOnStart: false);

    await purchases.buyProduct(productId);
    backend.emit([detailsFor(productId, PurchaseStatus.purchased)]);
    await pumpEventQueue();

    expect(store.ownsNoAds, isTrue);
    expect(store.ownsPack, isFalse);
    expect(backend.completed, [productId]);
  });

  test('buying remove-ads is a no-op once the pack already granted it',
      () async {
    const packId = CatalogPreviewData.packProductId;
    const removeId = CatalogPreviewData.removeAdsProductId;
    backend.catalogue = [
      ...backend.catalogue,
      productFor(packId, r'MX$ 199'),
      productFor(removeId, r'MX$ 89'),
    ];
    final purchases = await started(restoreOnStart: false);
    await store.grantCatalogEntries(
      CatalogPreviewData.productEntitlements[packId]!,
    );

    await purchases.buyProduct(removeId);

    expect(backend.bought, isEmpty);
    expect(store.ownsNoAds, isTrue);
  });
}
