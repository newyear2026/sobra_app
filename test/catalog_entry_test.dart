import 'package:flutter_test/flutter_test.dart';
import 'package:sobra_app/data/catalog_preview_data.dart';
import 'package:sobra_app/models/catalog_entry.dart';
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
    // The three the pack delivers, which are sold no other way.
    expect(
      entries.where(
        (entry) => entry.unlockMethod == CatalogUnlockMethod.bundle,
      ),
      hasLength(3),
    );
  });

  test('item catalog keeps its rewards and includes new room decorations', () {
    final entries = CatalogPreviewData.items;

    // The numbered lineup and pack decoration keep their unlock routes.
    expect(entries, hasLength(20));
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
      hasLength(1),
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
      (entry) => entry.id == 'character-07',
    );

    expect(paid.storeProductId, isNotEmpty);
    expect(source.localizedPriceFor(paid.storeProductId!), r'MX$ 79');
  });
}
