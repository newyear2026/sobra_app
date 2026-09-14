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
      expect(entry.rewardedAdTarget, 3);
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
}
