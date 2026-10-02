import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sobra_app/data/catalog_preview_data.dart';
import 'package:sobra_app/models/catalog_entry.dart';
import 'package:sobra_app/models/expense_entry.dart';
import 'package:sobra_app/models/pay_schedule.dart';
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
      final purchased = entryById('capybara');
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
      () => store.recordRewardedAdView(entryById('capybara')),
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

  group('the starters', () {
    Future<SobraStore> onboarded({String pick = 'michi'}) async {
      final store = await loadStore();
      await store.chooseCharacter(pick);
      await store.configureOnboarding(
        budgetCentavos: 600000,
        schedule: const PaySchedule.semiMonthly(),
      );
      await store.completeOnboarding();
      return store;
    }

    Future<void> recordToday(SobraStore store, {DateTime? dated}) =>
        store.addExpense(
          amountCentavos: 5000,
          category: ExpenseCategory.food,
          note: '',
          occurredAt: dated ?? now,
          paymentMethod: PaymentMethod.cash,
        );

    test('neither is owned until onboarding hands one over', () async {
      final store = await loadStore();

      expect(store.ownsCatalogEntry(entryById('michi')), isFalse);
      expect(store.ownsCatalogEntry(entryById('poodle')), isFalse);
      expect(store.waitingStarter, isNull);
    });

    test('onboarding hands over only the one picked', () async {
      final store = await onboarded(pick: 'poodle');

      expect(store.characterId, 'poodle');
      expect(store.ownsCatalogEntry(entryById('poodle')), isTrue);
      expect(store.ownsCatalogEntry(entryById('michi')), isFalse);
      expect(store.waitingStarter?.id, 'michi');
      expect(() => store.chooseCharacter('michi'), throwsArgumentError);
    });

    test('three recorded days bring the other one over', () async {
      final store = await onboarded();
      final miru = entryById('poodle');

      await recordToday(store);
      // A second record the same day is still one day.
      await recordToday(store);
      now = DateTime(2026, 9, 16, 11);
      await recordToday(store);
      expect(store.recordedDayCount, 2);
      expect(store.ownsCatalogEntry(miru), isFalse);

      now = DateTime(2026, 9, 17, 11);
      await recordToday(store);

      expect(store.ownsCatalogEntry(miru), isTrue);
      expect(store.waitingStarter, isNull);
      expect(store.starterArrivalId, 'poodle');
      // Coming over does not swap out the companion of three days.
      expect(store.characterId, 'michi');
      final reopened = await loadStore();
      expect(reopened.ownsCatalogEntry(miru), isTrue);
      expect(reopened.starterArrivalId, 'poodle');

      expect(await reopened.takeStarterArrival(), 'poodle');
      expect(reopened.starterArrivalId, isNull);
    });

    test('a backdated record does not count as a day', () async {
      final store = await onboarded();

      await recordToday(store, dated: DateTime(2026, 9, 13, 20));

      expect(store.recordedDayCount, 0);
    });

    test('two rewarded ads bring the other one over as well', () async {
      final store = await onboarded();
      final miru = entryById('poodle');

      await store.recordRewardedAdView(miru);
      expect(store.waitingStarter?.id, 'poodle');
      await store.recordRewardedAdView(miru);

      expect(store.ownsCatalogEntry(miru), isTrue);
      expect(store.waitingStarter, isNull);
      // The collection that played the ads announces the unlock itself.
      expect(store.starterArrivalId, isNull);
    });

    test('an install that finished onboarding before keeps both', () async {
      final store = await onboarded(pick: 'poodle');
      await store.grantCatalogEntry('capybara');
      final preferences = await SharedPreferences.getInstance();
      final saved =
          jsonDecode(preferences.getString('sobra_state_v2')!)
              as Map<String, dynamic>;
      saved
        ..remove('starterCharacterId')
        ..remove('recordedDays')
        ..['ownedCatalogIds'] = ['capybara'];
      await preferences.setString('sobra_state_v2', jsonEncode(saved));

      final reopened = await loadStore();

      expect(reopened.ownsCatalogEntry(entryById('michi')), isTrue);
      expect(reopened.ownsCatalogEntry(entryById('poodle')), isTrue);
      expect(reopened.starterCharacterId, 'poodle');
      expect(reopened.waitingStarter, isNull);
    });

    test('a refunded character falls back to the picked starter', () async {
      final store = await onboarded(pick: 'poodle');
      await store.grantCatalogEntry('capybara');
      await store.equipCharacter(entryById('capybara'));

      await store.revokeCatalogEntries({'capybara'});

      expect(store.characterId, 'poodle');
    });
  });

  test('Schnauzer takes two rewarded views in one sitting', () async {
    final store = await loadStore();
    final schnauzer = entryById('schnauzer');

    expect(store.ownsCatalogEntry(schnauzer), isFalse);
    expect(() => store.chooseCharacter('schnauzer'), throwsArgumentError);
    expect(() => store.equipCharacter(schnauzer), throwsArgumentError);

    expect(await store.recordRewardedAdView(schnauzer), isTrue);
    expect(store.ownsCatalogEntry(schnauzer), isFalse);
    // Same day, straight after: no waiting until tomorrow.
    expect(await store.recordRewardedAdView(schnauzer), isTrue);
    expect(store.ownsCatalogEntry(schnauzer), isTrue);

    await store.equipCharacter(schnauzer);
    expect((await loadStore()).characterId, 'schnauzer');
  });

  test(
    'Guinea Pig takes two rewarded views and can then be equipped',
    () async {
      final store = await loadStore();
      final guineaPig = entryById('guinea-pig');

      expect(store.ownsCatalogEntry(guineaPig), isFalse);
      expect(() => store.chooseCharacter('guinea-pig'), throwsArgumentError);
      expect(await store.recordRewardedAdView(guineaPig), isTrue);
      expect(store.rewardedAdProgressFor(guineaPig.id), 1);
      expect(store.ownsCatalogEntry(guineaPig), isFalse);

      expect(await store.recordRewardedAdView(guineaPig), isTrue);
      expect(store.ownsCatalogEntry(guineaPig), isTrue);
      expect(store.rewardedAdProgressFor(guineaPig.id), 0);

      await store.equipCharacter(guineaPig);
      final reopened = await loadStore();
      expect(reopened.characterId, 'guinea-pig');
      expect(reopened.ownsCatalogEntry(guineaPig), isTrue);
    },
  );

  test('Quokka takes two rewarded views and can then be equipped', () async {
    final store = await loadStore();
    final quokka = entryById('quokka');

    expect(store.ownsCatalogEntry(quokka), isFalse);
    expect(() => store.chooseCharacter('quokka'), throwsArgumentError);
    expect(await store.recordRewardedAdView(quokka), isTrue);
    expect(store.rewardedAdProgressFor(quokka.id), 1);
    expect(store.ownsCatalogEntry(quokka), isFalse);

    final reopenedAfterFirstAd = await loadStore();
    expect(reopenedAfterFirstAd.rewardedAdProgressFor(quokka.id), 1);
    expect(await reopenedAfterFirstAd.recordRewardedAdView(quokka), isTrue);
    expect(reopenedAfterFirstAd.ownsCatalogEntry(quokka), isTrue);
    expect(reopenedAfterFirstAd.rewardedAdProgressFor(quokka.id), 0);

    await reopenedAfterFirstAd.equipCharacter(quokka);
    final reopened = await loadStore();
    expect(reopened.characterId, 'quokka');
    expect(reopened.ownsCatalogEntry(quokka), isTrue);
  });

  test('Tranqui requires a purchase before it can be equipped', () async {
    final store = await loadStore();
    final capybara = entryById('capybara');

    expect(capybara.unlockMethod, CatalogUnlockMethod.purchase);
    expect(store.ownsCatalogEntry(capybara), isFalse);
    expect(() => store.chooseCharacter('capybara'), throwsArgumentError);

    await store.grantCatalogEntry(capybara.id);
    await store.equipCharacter(capybara);
    final reopened = await loadStore();
    expect(reopened.characterId, 'capybara');
    expect(reopened.ownsCatalogEntry(capybara), isTrue);
  });

  test('Platypus can be equipped only after purchase ownership', () async {
    final store = await loadStore();
    final platypus = entryById('platypus');

    expect(platypus.unlockMethod, CatalogUnlockMethod.purchase);
    expect(store.ownsCatalogEntry(platypus), isFalse);
    expect(() => store.chooseCharacter('platypus'), throwsArgumentError);

    await store.grantCatalogEntry(platypus.id);
    await store.equipCharacter(platypus);
    final reopened = await loadStore();
    expect(reopened.characterId, 'platypus');
    expect(reopened.ownsCatalogEntry(platypus), isTrue);
  });

  test('Bandi can be equipped only after purchase ownership', () async {
    final store = await loadStore();
    final raccoon = entryById('raccoon');

    expect(raccoon.unlockMethod, CatalogUnlockMethod.purchase);
    expect(store.ownsCatalogEntry(raccoon), isFalse);
    expect(() => store.chooseCharacter('raccoon'), throwsArgumentError);

    await store.grantCatalogEntry(raccoon.id);
    await store.equipCharacter(raccoon);
    final reopened = await loadStore();
    expect(reopened.characterId, 'raccoon');
    expect(reopened.ownsCatalogEntry(raccoon), isTrue);
  });

  test('an old free Schnauzer choice reverts until it is earned', () async {
    await loadStore();
    final preferences = await SharedPreferences.getInstance();
    final saved =
        jsonDecode(preferences.getString('sobra_state_v2')!)
            as Map<String, dynamic>;
    saved['characterId'] = 'schnauzer';
    await preferences.setString('sobra_state_v2', jsonEncode(saved));

    final reopened = await loadStore();
    expect(reopened.characterId, 'michi');
    expect(reopened.ownsCatalogEntry(entryById('schnauzer')), isFalse);
  });

  test('an equipped character is remembered', () async {
    final store = await loadStore();
    final character = entryById('alpaca');
    await store.grantCatalogEntry(character.id);

    await store.equipCharacter(character);

    final reopened = await loadStore();
    expect(reopened.equippedIdFor(CatalogKind.character), character.id);
    expect(reopened.characterId, character.id);
  });

  test('equipping a character the user does not own is refused', () async {
    final store = await loadStore();

    expect(
      () => store.equipCharacter(entryById('capybara')),
      throwsArgumentError,
    );
    expect(store.equippedIdFor(CatalogKind.character), 'michi');
  });

  // An item is placed, not worn. Sending one through here used to write a
  // room placement chosen by nobody, from a screen with no room on it.
  test('equipping an item is refused', () async {
    final store = await loadStore();

    expect(
      () => store.equipCharacter(entryById('item-01')),
      throwsArgumentError,
    );
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
      await store.grantCatalogEntry('capybara');
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
    // None today: the pack's friends are sold singly too. The rule is kept
    // for the next entry that is sold only inside a pack.

    for (final entry in bundled) {
      final delivered =
          CatalogPreviewData.productEntitlements[entry.storeProductId];
      expect(
        delivered,
        isNotNull,
        reason:
            '${entry.id} is sold in ${entry.storeProductId}, which no '
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
    expect(store.ownsCatalogEntry(entryById('capybara')), isTrue);
    expect(store.ownsCatalogEntry(entryById('alpaca')), isTrue);
    expect(store.ownsCatalogEntry(entryById('raccoon')), isTrue);
    expect(store.ownsNoAds, isTrue);
    expect(store.ownsPack, isTrue);
    expect((await loadStore()).ownedCatalogIds, containsAll(delivered));
  });

  // Somebody who already bought one of the friends separately still gets the
  // rest. The overlap is not refunded; the pack dialog says so before they
  // pay.
  test('a bundle skips what is already owned and delivers the rest', () async {
    final store = await loadStore();
    await store.grantCatalogEntry('alpaca');

    await store.grantCatalogEntries(
      CatalogPreviewData.productEntitlements[CatalogPreviewData.packProductId]!,
    );

    expect(store.ownsCatalogEntry(entryById('capybara')), isTrue);
    expect(store.ownsCatalogEntry(entryById('alpaca')), isTrue);
    expect(store.ownsCatalogEntry(entryById('raccoon')), isTrue);
  });

  test('granting nothing new writes nothing', () async {
    final store = await loadStore();
    await store.grantCatalogEntry('capybara');

    await store.grantCatalogEntries({'capybara', ''});

    expect(store.ownedCatalogIds, {'capybara'});
  });

  // Rewarded progress is dropped for granted ids, the same way a single grant
  // drops it. A bundle that happens to contain an entry somebody was part-way
  // through must not leave a stale count behind.
  test('a bundle clears rewarded progress for what it grants', () async {
    final store = await loadStore();
    final started = entryById('character-03');
    await store.recordRewardedAdView(started);
    expect(store.rewardedAdProgressFor(started.id), 1);

    await store.grantCatalogEntries({started.id, 'capybara'});

    expect(store.ownsCatalogEntry(started), isTrue);
    expect(store.rewardedAdProgressFor(started.id), 0);
  });

  // No entry carries the pack's id, so only the mapping can answer for it.
  // Falling back to a single entry here is how a pack once delivered one
  // item of five while reporting success.
  test('the pack is delivered by its mapping, never by one entry', () {
    expect(
      CatalogPreviewData.entryForProductId(CatalogPreviewData.packProductId),
      isNull,
    );
    expect(
      CatalogPreviewData.entitlementsForProductId(
        CatalogPreviewData.packProductId,
      ),
      {
        ...CatalogPreviewData.packCharacterIds,
        CatalogPreviewData.noAdsEntitlement,
      },
    );
  });

  // Sold both ways on purpose. The overlap is not refunded, which is why the
  // pack dialog names what the buyer already owns before they pay.
  test('the pack friends are also sold one by one', () {
    for (final id in CatalogPreviewData.packCharacterIds) {
      final entry = entryById(id);
      expect(entry.unlockMethod, CatalogUnlockMethod.purchase, reason: id);
      expect(entry.storeProductId, 'sobra.character.$id');
      expect(
        CatalogPreviewData.storeProductIds,
        contains(entry.storeProductId),
      );
    }
  });

  // Ajustes reads ownsPack to mark the row as owned. Buying all three
  // friends singly must not: ad removal is still only in the pack.
  test(
    'the pack counts as owned only with its friends and ad removal',
    () async {
      final store = await loadStore();
      await store.grantCatalogEntries({...CatalogPreviewData.packCharacterIds});

      expect(store.ownsPack, isFalse);

      await store.grantCatalogEntry(CatalogPreviewData.noAdsEntitlement);

      expect(store.ownsPack, isTrue);
    },
  );

  test('ad removal is sold only inside the pack', () {
    expect(
      CatalogPreviewData.storeProductIds,
      isNot(contains('sobra.ads.remove')),
    );
    expect(
      {
        for (final entitlement
            in CatalogPreviewData.productEntitlements.entries)
          if (entitlement.value.contains(CatalogPreviewData.noAdsEntitlement))
            entitlement.key,
      },
      {CatalogPreviewData.packProductId},
    );
  });

  test(
    'recommended rewarded entry prefers progress, then fewer views',
    () async {
      final store = await loadStore();
      final started = entryById('character-03');
      await store.recordRewardedAdView(started);

      expect(store.recommendedRewardedAdEntry?.id, started.id);
    },
  );

  test('recommended rewarded entry is hidden when the day is capped', () async {
    now = DateTime(2026, 9, 14, 11);
    final store = await SobraStore.load(now: () => now, rewardedAdsPerDay: 1);
    await store.recordRewardedAdView(entryById('item-03'));

    expect(store.recommendedRewardedAdEntry, isNull);
  });

  test('recommended rewarded entry is hidden when nothing is left', () async {
    final store = await loadStore();
    for (final entry in CatalogPreviewData.all.where(
      (entry) => entry.unlockMethod == CatalogUnlockMethod.rewardedAd,
    )) {
      await store.grantCatalogEntry(entry.id);
    }

    expect(store.recommendedRewardedAdEntry, isNull);
  });

  test('the debug switch lends paid characters without buying them', () async {
    final single = entryById('platypus');
    final packOnly = entryById('capybara');
    final adEarned = entryById('schnauzer');
    final store = await loadStore();

    await store.setDebugPaidCharactersUnlocked(true);
    await store.chooseCharacter(single.id);

    expect(store.ownsCatalogEntry(single), isTrue);
    expect(store.ownsCatalogEntry(packOnly), isTrue);
    expect(store.ownsCatalogEntry(adEarned), isFalse);
    // Lent, not granted: nothing a revocation or a backup would read.
    expect(store.ownedCatalogIds, isEmpty);
    expect((await loadStore()).characterId, single.id);

    await store.setDebugPaidCharactersUnlocked(false);

    expect(store.ownsCatalogEntry(single), isFalse);
    expect(store.characterId, 'michi');
  });
}
