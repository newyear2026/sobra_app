import 'package:flutter_test/flutter_test.dart';
import 'package:sobra_app/data/catalog_preview_data.dart';
import 'package:sobra_app/models/catalog_entry.dart';
import 'package:sobra_app/models/room_design.dart';
import 'package:sobra_app/models/xp_event.dart';

void main() {
  test('Michi and Poodle are included; new companions use ads', () {
    final entries = CatalogPreviewData.characters;

    expect(entries, hasLength(13));
    expect(
      entries.where(
        (entry) => entry.unlockMethod == CatalogUnlockMethod.included,
      ),
      hasLength(2),
    );
    expect(
      entries.where(
        (entry) => entry.unlockMethod == CatalogUnlockMethod.purchase,
      ),
      hasLength(3),
    );
    expect(
      entries.where(
        (entry) => entry.unlockMethod == CatalogUnlockMethod.rewardedAd,
      ),
      hasLength(5),
    );
    // The ordinary character tier: two views, back to back if wanted.
    final schnauzer = entries.firstWhere((entry) => entry.id == 'schnauzer');
    expect(schnauzer.unlockMethod, CatalogUnlockMethod.rewardedAd);
    expect(schnauzer.rewardedAdTarget, 2);
    expect(schnauzer.rewardedAdOncePerDay, isFalse);
    expect(schnauzer.storeProductId, isNull);
    final guineaPig = entries.firstWhere((entry) => entry.id == 'guinea-pig');
    expect(guineaPig.unlockMethod, CatalogUnlockMethod.rewardedAd);
    expect(guineaPig.rewardedAdTarget, 2);
    expect(guineaPig.rewardedAdOncePerDay, isFalse);
    expect(guineaPig.storeProductId, isNull);
    expect(guineaPig.assetPath, 'assets/characters/guinea-pig/idle-8.png');
    final platypus = entries.firstWhere((entry) => entry.id == 'platypus');
    expect(platypus.name, 'Pico');
    expect(platypus.unlockMethod, CatalogUnlockMethod.purchase);
    expect(platypus.storeProductId, 'sobra.character.platypus');
    expect(platypus.assetPath, 'assets/characters/platypus/idle-8.png');
    expect(
      CatalogPreviewData.entryForProductId(platypus.storeProductId!),
      same(platypus),
    );
    expect(
      CatalogPreviewData.storeProductIds,
      contains(platypus.storeProductId),
    );
    final rabbit = entries.firstWhere((entry) => entry.id == 'rabbit');
    expect(rabbit.name, 'Bunny');
    expect(rabbit.unlockMethod, CatalogUnlockMethod.purchase);
    expect(rabbit.storeProductId, 'sobra.character.rabbit');
    expect(rabbit.assetPath, 'assets/characters/rabbit/idle-8.png');
    expect(
      CatalogPreviewData.entryForProductId(rabbit.storeProductId!),
      rabbit,
    );
    expect(CatalogPreviewData.storeProductIds, contains(rabbit.storeProductId));
    // Every single character is one flat price.
    for (final paid in [platypus, rabbit]) {
      expect(
        const PreviewCatalogPriceSource().localizedPriceFor(
          paid.storeProductId!,
        ),
        r'MX$ 39',
      );
    }
  });

  test('Los amigos de Michi holds Tranqui, Lana and Bandi and nothing '
      'else sells them', () {
    final entries = CatalogPreviewData.characters;
    final pack = [
      for (final id in CatalogPreviewData.packCharacterIds)
        entries.firstWhere((entry) => entry.id == id),
    ];

    expect(
      [for (final entry in pack) entry.name],
      ['Tranqui', 'Lana', 'Bandi'],
    );
    expect(
      entries.where(
        (entry) => entry.unlockMethod == CatalogUnlockMethod.bundle,
      ),
      pack,
    );
    for (final entry in pack) {
      expect(entry.unlockMethod, CatalogUnlockMethod.bundle);
      expect(entry.storeProductId, CatalogPreviewData.packProductId);
      expect(entry.assetPath, 'assets/characters/${entry.id}/idle-8.png');
    }
    expect(
      CatalogPreviewData.productEntitlements[CatalogPreviewData.packProductId],
      {
        ...CatalogPreviewData.packCharacterIds,
        CatalogPreviewData.noAdsEntitlement,
      },
    );
    // Their old single products were deactivated in Play before launch. The
    // app must neither price them nor treat them as its own.
    for (final retired in [
      'sobra.character.capybara',
      'sobra.character.alpaca',
      'sobra.character.raccoon',
    ]) {
      expect(CatalogPreviewData.storeProductIds, isNot(contains(retired)));
      expect(CatalogPreviewData.entryForProductId(retired), isNull);
      expect(
        const PreviewCatalogPriceSource().localizedPriceFor(retired),
        isNull,
      );
    }
    // Grouped, so the collection shows the pack as one run of cards.
    final ids = [for (final entry in entries) entry.id];
    final first = ids.indexOf('capybara');
    expect(ids.sublist(first, first + 3), CatalogPreviewData.packCharacterIds);
  });

  test('item catalog keeps its rewards and includes new room decorations', () {
    final entries = CatalogPreviewData.items;

    // The numbered lineup keeps its unlock routes. The pack's star was
    // dropped before launch, so no item comes in a bundle.
    expect(entries, hasLength(21));
    expect(
      entries.where((entry) => entry.unlockMethod == CatalogUnlockMethod.gift),
      hasLength(2),
    );
    expect(
      entries.where(
        (entry) => entry.unlockMethod == CatalogUnlockMethod.included,
      ),
      hasLength(9),
    );
    expect(
      entries.where(
        (entry) => entry.unlockMethod == CatalogUnlockMethod.bundle,
      ),
      isEmpty,
    );
    expect(
      entries.where((entry) => entry.unlockMethod == CatalogUnlockMethod.level),
      hasLength(7),
    );
    expect(
      entries.where(
        (entry) => entry.unlockMethod == CatalogUnlockMethod.rewardedAd,
      ),
      hasLength(3),
    );
    expect(
      entries
          .where((entry) => entry.requiredLevel != null)
          .map((entry) => entry.requiredLevel)
          .toSet(),
      {1, 2, 3, 4, 5, 8, 10},
    );
    expect(
      entries.firstWhere((entry) => entry.id == 'item-02').requiredLevel,
      5,
    );
    expect(
      entries.firstWhere((entry) => entry.id == 'item-04').requiredLevel,
      8,
    );
  });

  group('the launch gift', () {
    final gifts = CatalogPreviewData.items
        .where((entry) => entry.unlockMethod == CatalogUnlockMethod.gift)
        .toList();

    test('is a two-item app grant with no Play product', () {
      expect(gifts.map((entry) => entry.id).toSet(), {
        RoomDecorAssets.launchSofaId,
        RoomDecorAssets.launchTvId,
      });
      expect(gifts.every((entry) => entry.storeProductId == null), isTrue);
      expect(
        CatalogPreviewData.storeProductIds,
        isNot(contains('sobra.reward.preregistration')),
      );
    });

    test('is listed only once owned', () {
      for (final gift in gifts) {
        expect(CatalogPreviewData.isListed(gift, isOwned: false), isFalse);
        expect(CatalogPreviewData.isListed(gift, isOwned: true), isTrue);
      }
      final sold = CatalogPreviewData.all.firstWhere(
        (entry) => entry.unlockMethod == CatalogUnlockMethod.purchase,
      );
      expect(CatalogPreviewData.isListed(sold, isOwned: false), isTrue);
    });
  });

  test('level rewards are derived for existing and multi-level users', () {
    final restoredProgress = XpProgress.fromTotal(5450);
    final existingLevelEight = CatalogPreviewData.levelItemsUnlockedAt(
      restoredProgress.level,
    );
    final crossedFromOneToEight = CatalogPreviewData.levelItemsUnlockedBetween(
      previousLevel: 1,
      currentLevel: 8,
    );

    expect(restoredProgress.level, 8);
    expect(existingLevelEight, hasLength(6));
    expect(existingLevelEight.map((entry) => entry.requiredLevel), contains(5));
    expect(existingLevelEight.map((entry) => entry.requiredLevel), contains(8));
    expect(
      existingLevelEight.map((entry) => entry.requiredLevel),
      isNot(contains(10)),
    );
    expect(crossedFromOneToEight, hasLength(5));
  });

  test('localized price is resolved outside the static catalog entry', () {
    const source = PreviewCatalogPriceSource();
    final paid = CatalogPreviewData.characters.firstWhere(
      (entry) => entry.id == 'platypus',
    );

    expect(paid.storeProductId, isNotEmpty);
    expect(source.localizedPriceFor(paid.storeProductId!), r'MX$ 39');
  });
}
