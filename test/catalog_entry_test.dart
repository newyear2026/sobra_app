import 'package:flutter_test/flutter_test.dart';
import 'package:sobra_app/data/catalog_preview_data.dart';
import 'package:sobra_app/models/catalog_entry.dart';
import 'package:sobra_app/models/xp_event.dart';

void main() {
  test('preview character catalog keeps the undecided 1 + 6 + 3 shape', () {
    final entries = CatalogPreviewData.characters;

    expect(entries, hasLength(10));
    expect(
      entries.where(
        (entry) => entry.unlockMethod == CatalogUnlockMethod.included,
      ),
      hasLength(1),
    );
    expect(
      entries.where(
        (entry) => entry.unlockMethod == CatalogUnlockMethod.purchase,
      ),
      hasLength(6),
    );
    expect(
      entries.where(
        (entry) => entry.unlockMethod == CatalogUnlockMethod.rewardedAd,
      ),
      hasLength(3),
    );
  });

  test('preview item catalog has seven level slots and three ad slots', () {
    final entries = CatalogPreviewData.items;

    expect(entries, hasLength(10));
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
      (entry) => entry.unlockMethod == CatalogUnlockMethod.purchase,
    );

    expect(paid.storeProductId, isNotEmpty);
    expect(source.localizedPriceFor(paid.storeProductId!), r'MX$ 79');
  });
}
