import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sobra_app/data/catalog_preview_data.dart';
import 'package:sobra_app/models/catalog_entry.dart';
import 'package:sobra_app/state/sobra_store.dart';

void main() {
  late DateTime now;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    now = DateTime(2026, 9, 14, 11);
  });

  Future<SobraStore> loadStore() => SobraStore.load(now: () => now);

  CatalogEntry entryById(String id) => [
    ...CatalogPreviewData.characters,
    ...CatalogPreviewData.items,
  ].firstWhere((entry) => entry.id == id);

  // The whole point of moving this out of the collection screen's State: what
  // the user acquired used to live in a StatefulWidget and was gone the moment
  // the route rebuilt, let alone on a reinstall.
  test(
    'a purchased entry is still owned after the store is reloaded',
    () async {
      final purchased = entryById('character-02');
      final store = await loadStore();
      expect(store.ownsCatalogEntry(purchased), isFalse);

      await store.grantCatalogEntry(purchased.id);

      expect(store.ownsCatalogEntry(purchased), isTrue);
      expect((await loadStore()).ownsCatalogEntry(purchased), isTrue);
    },
  );

  test(
    'rewarded-ad progress survives a reload and grants at the target',
    () async {
      final entry = entryById('character-03');
      expect(entry.rewardedAdTarget, 2);
      final store = await loadStore();

      await store.recordRewardedAdView(entry);
      expect(store.rewardedAdProgressFor(entry.id), 1);

      final reopened = await loadStore();
      expect(reopened.rewardedAdProgressFor(entry.id), 1);
      expect(reopened.ownsCatalogEntry(entry), isFalse);

      await reopened.recordRewardedAdView(entry);
      await reopened.recordRewardedAdView(entry);

      expect(reopened.ownsCatalogEntry(entry), isTrue);
      // Dropped rather than left at the target: a finished count is something
      // nothing reads, and keeping it would grow the saved state for nothing.
      expect(reopened.rewardedAdProgressFor(entry.id), 0);
      expect((await loadStore()).ownsCatalogEntry(entry), isTrue);
    },
  );

  test('watching another ad after the grant changes nothing', () async {
    final entry = entryById('item-03');
    expect(entry.rewardedAdTarget, 1);
    final store = await loadStore();

    await store.recordRewardedAdView(entry);
    await store.recordRewardedAdView(entry);

    expect(store.ownsCatalogEntry(entry), isTrue);
    expect(store.rewardedAdProgressFor(entry.id), 0);
    expect(store.ownedCatalogIds, {entry.id});
  });

  test('recording a view against a non-ad entry is rejected', () async {
    final store = await loadStore();

    expect(
      () => store.recordRewardedAdView(entryById('character-02')),
      throwsArgumentError,
    );
  });

  // Level rewards are derived from XP on every read. Writing them into the
  // owned set as well would leave two answers that can disagree once a
  // required level moves.
  test(
    'level rewards are owned without being written to the owned set',
    () async {
      final store = await loadStore();
      final lamp = entryById('item-01');
      expect(lamp.requiredLevel, 1);

      expect(store.xpProgress.level, 1);
      expect(store.ownsCatalogEntry(lamp), isTrue);
      expect(store.ownedCatalogIds, isEmpty);

      final reopened = await loadStore();
      expect(reopened.ownsCatalogEntry(lamp), isTrue);
      expect(reopened.ownedCatalogIds, isEmpty);
    },
  );

  test('michi is owned without being granted', () async {
    final store = await loadStore();

    expect(store.ownsCatalogEntry(entryById('michi')), isTrue);
    expect(store.ownedCatalogIds, isEmpty);
  });

  test('an equipped character and item are both remembered', () async {
    final store = await loadStore();
    final item = entryById('item-01');
    final character = entryById('character-04');
    await store.grantCatalogEntry(character.id);

    await store.equipCatalogEntry(item);
    await store.equipCatalogEntry(character);

    final reopened = await loadStore();
    expect(reopened.equippedIdFor(CatalogKind.item), item.id);
    expect(reopened.equippedIdFor(CatalogKind.character), character.id);
    expect(reopened.characterId, character.id);
  });

  test('equipping something the user does not own is refused', () async {
    final store = await loadStore();

    expect(
      () => store.equipCatalogEntry(entryById('character-02')),
      throwsArgumentError,
    );
    expect(store.equippedIdFor(CatalogKind.character), 'michi');
  });

  // A restore hands back product ids, not catalog entries, so an id this build
  // no longer ships still has to stick: dropping it would revoke something the
  // user paid for.
  test('an id outside the shipped catalog is kept', () async {
    final store = await loadStore();

    await store.grantCatalogEntry('sobra.character.99');

    expect((await loadStore()).ownedCatalogIds, {'sobra.character.99'});
  });

  test(
    'state written before the collection was persisted still opens',
    () async {
      final store = await loadStore();
      await store.grantCatalogEntry('character-02');
      final preferences = await SharedPreferences.getInstance();
      final saved =
          jsonDecode(preferences.getString('sobra_state_v2')!)
              as Map<String, dynamic>;
      saved
        ..remove('ownedCatalogIds')
        ..remove('rewardedAdProgress')
        ..remove('equippedItemId');
      await preferences.setString('sobra_state_v2', jsonEncode(saved));

      final reopened = await loadStore();

      expect(reopened.hasStorageError, isFalse);
      expect(reopened.ownedCatalogIds, isEmpty);
      expect(reopened.equippedIdFor(CatalogKind.item), isNull);
      // Still theirs: nothing about the old shape changes what the level grants.
      expect(reopened.ownsCatalogEntry(entryById('item-01')), isTrue);
    },
  );

  // The mapping is the only thing standing between a bundle purchase and a
  // silent partial delivery, and nothing about a missing entry is visible at
  // runtime: the grant path would fall back to a single entry, write it, and
  // report success. This test is what fails instead.
  test('every bundle entry names a product the mapping covers', () {
    final bundled = CatalogPreviewData.all
        .where((entry) => entry.unlockMethod == CatalogUnlockMethod.bundle)
        .toList();
    expect(bundled, isNotEmpty);

    for (final entry in bundled) {
      final delivered =
          CatalogPreviewData.productEntitlements[entry.storeProductId];
      expect(
        delivered,
        isNotNull,
        reason: '${entry.id} is sold in ${entry.storeProductId}, which no '
            'productEntitlements key covers',
      );
      expect(
        delivered,
        contains(entry.id),
        reason: '${entry.storeProductId} does not deliver ${entry.id}',
      );
    }
  });

  // A typo inside a bundle is the same silent failure by another route: the id
  // is written, owns nothing, and the character never appears.
  test('a bundle only delivers ids the catalog knows', () {
    const notCatalogEntries = {CatalogPreviewData.noAdsEntitlement};
    final catalogIds = CatalogPreviewData.all.map((entry) => entry.id).toSet();

    for (final delivered in CatalogPreviewData.productEntitlements.values) {
      for (final id in delivered.difference(notCatalogEntries)) {
        expect(catalogIds, contains(id), reason: '$id is not a catalog entry');
      }
    }
  });

  // A product the store is never asked about comes back without a price, and
  // an entry with no price cannot be bought.
  test('bundle products are priced with the rest', () {
    expect(
      CatalogPreviewData.storeProductIds,
      containsAll(CatalogPreviewData.productEntitlements.keys),
    );
  });

  test('granting a bundle delivers every id in one write', () async {
    final store = await loadStore();
    final delivered = CatalogPreviewData
        .productEntitlements[CatalogPreviewData.packProductId]!;

    await store.grantCatalogEntries(delivered);

    for (final id in delivered) {
      expect(store.ownedCatalogIds, contains(id));
    }
    expect(store.ownsCatalogEntry(entryById('character-02')), isTrue);
    expect(store.ownsCatalogEntry(entryById('character-04')), isTrue);
    expect(store.ownsCatalogEntry(entryById('character-06')), isTrue);
    expect(
      store.ownsCatalogEntry(
        entryById(CatalogPreviewData.packDecorationId),
      ),
      isTrue,
    );
    expect((await loadStore()).ownedCatalogIds, containsAll(delivered));
  });

  // Somebody who already bought one of the characters separately still gets
  // the rest. The overlap is not refunded, and the purchase sheet says so.
  test('a bundle skips what is already owned and delivers the rest', () async {
    final store = await loadStore();
    await store.grantCatalogEntry('character-04');

    await store.grantCatalogEntries(
      CatalogPreviewData
          .productEntitlements[CatalogPreviewData.packProductId]!,
    );

    expect(store.ownsCatalogEntry(entryById('character-02')), isTrue);
    expect(store.ownsCatalogEntry(entryById('character-04')), isTrue);
    expect(store.ownsCatalogEntry(entryById('character-06')), isTrue);
  });

  test('granting nothing new writes nothing', () async {
    final store = await loadStore();
    await store.grantCatalogEntry('character-02');

    await store.grantCatalogEntries({'character-02', ''});

    expect(store.ownedCatalogIds, {'character-02'});
  });

  // Rewarded progress is dropped for granted ids, the same way a single grant
  // drops it. A bundle that happens to contain an entry somebody was part-way
  // through must not leave a stale count behind.
  test('a bundle clears rewarded progress for what it grants', () async {
    final store = await loadStore();
    final started = entryById('character-03');
    await store.recordRewardedAdView(started);
    expect(store.rewardedAdProgressFor(started.id), 1);

    await store.grantCatalogEntries({started.id, 'character-02'});

    expect(store.ownsCatalogEntry(started), isTrue);
    expect(store.rewardedAdProgressFor(started.id), 0);
  });

  // The collision the grant path has to resolve in the right order. Every
  // entry the pack delivers exclusively carries its product id, so the
  // single-entry lookup answers for the pack too — with one of five, and it
  // is a character now rather than the decoration it used to be. Which one it
  // reaches first is an accident of catalog order and is deliberately not
  // pinned here; that it is never the whole delivery is the point.
  test('the pack product id also resolves to a single entry', () {
    final single = CatalogPreviewData.entryForProductId(
      CatalogPreviewData.packProductId,
    );
    final everything = CatalogPreviewData
        .productEntitlements[CatalogPreviewData.packProductId]!;

    expect(single, isNotNull);
    expect(everything, contains(single!.id));
    expect(everything.length, greaterThan(1));
  });

  // What stops the overlap the pack name no longer papers over: a character
  // in the pack cannot also be bought on its own, so nobody pays twice for
  // the same cat and then finds grantCatalogEntries dropping the duplicate.
  test('no entry is sold both inside the pack and on its own', () {
    final inPack =
        CatalogPreviewData.productEntitlements[CatalogPreviewData
            .packProductId]!;

    for (final entry in CatalogPreviewData.all.where(
      (entry) => inPack.contains(entry.id),
    )) {
      expect(entry.unlockMethod, CatalogUnlockMethod.bundle, reason: entry.id);
      expect(entry.storeProductId, CatalogPreviewData.packProductId);
    }
  });

  test('the pack decoration is locked and not sold on its own', () async {
    final store = await loadStore();
    final decoration = entryById(CatalogPreviewData.packDecorationId);

    expect(decoration.unlockMethod, CatalogUnlockMethod.bundle);
    expect(decoration.storeProductId, CatalogPreviewData.packProductId);
    expect(store.ownsCatalogEntry(decoration), isFalse);
  });
}
