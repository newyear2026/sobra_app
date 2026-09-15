import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sobra_app/data/catalog_preview_data.dart';
import 'package:sobra_app/models/catalog_entry.dart';
import 'package:sobra_app/services/rewarded_ad_service.dart';
import 'package:sobra_app/state/sobra_store.dart';

import 'support/fake_rewarded_ad.dart';

void main() {
  /// The clock the store reads. Moved by the tests that need another day.
  late DateTime now;
  late FakeRewardedAdPort port;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    now = DateTime(2026, 9, 14, 11);
    port = FakeRewardedAdPort();
  });

  Future<SobraStore> loadStore() => SobraStore.load(now: () => now);

  CatalogEntry entryById(String id) =>
      CatalogPreviewData.all.firstWhere((entry) => entry.id == id);

  RewardedAds adsFor(SobraStore store) =>
      RewardedAds(port: port, store: store);

  /// An item: one view and it is owned.
  final item = entryById('item-03');

  /// An ordinary character: two views, on any days.
  final character = entryById('character-03');

  /// The special tier: three views, and never two on the same day.
  final special = entryById('character-08');

  group('the tiers match the spec', () {
    test('an item costs one view', () {
      expect(item.rewardedAdTarget, 1);
      expect(item.rewardedAdOncePerDay, isFalse);
    });

    test('an ordinary character costs two views', () {
      expect(character.rewardedAdTarget, 2);
      expect(character.rewardedAdOncePerDay, isFalse);
    });

    test('a special character costs three, one a day', () {
      expect(special.rewardedAdTarget, 3);
      expect(special.rewardedAdOncePerDay, isTrue);
    });

    // The cap has to leave room to combine, or a character unlock is the only
    // thing a day can hold.
    test('no entry costs a whole day of the cap at once', () {
      final perDay = SobraStore.rewardedAdsPerDay;
      for (final entry in CatalogPreviewData.all) {
        final target = entry.rewardedAdTarget;
        if (target == null || entry.rewardedAdOncePerDay) continue;
        expect(
          target,
          lessThan(perDay),
          reason: '${entry.id} costs $target of a $perDay daily cap, which '
              'leaves nothing to pair it with',
        );
      }
    });
  });

  group('a completed view counts', () {
    test('and the entry is granted at its target', () async {
      final store = await loadStore();
      final ads = adsFor(store);

      expect(await ads.watch(character), RewardedAdOutcome.counted);
      expect(store.rewardedAdProgressFor(character.id), 1);
      expect(store.ownsCatalogEntry(character), isFalse);

      expect(await ads.watch(character), RewardedAdOutcome.counted);

      expect(store.ownsCatalogEntry(character), isTrue);
      expect(store.rewardedAdProgressFor(character.id), 0);
      expect((await loadStore()).ownsCatalogEntry(character), isTrue);
    });

    test('and the daily count moves with the progress', () async {
      final store = await loadStore();
      final ads = adsFor(store);

      await ads.watch(character);

      expect(store.rewardedAdsWatchedToday, 1);
      expect(store.rewardedAdsLeftToday, 2);
      // One write, not two. A progress that survived a restart without its
      // daily count would hand back a free ad on every launch.
      expect((await loadStore()).rewardedAdsWatchedToday, 1);
    });
  });

  group('a view that did not complete changes nothing', () {
    test('an ad closed early leaves the progress alone', () async {
      final store = await loadStore();
      final ads = adsFor(store);
      port.script = [RewardedAdResult.dismissed];

      expect(await ads.watch(character), RewardedAdOutcome.dismissed);

      expect(store.rewardedAdProgressFor(character.id), 0);
      expect(store.rewardedAdsWatchedToday, 0);
    });

    test('an ad that fails to show leaves the progress alone', () async {
      final store = await loadStore();
      final ads = adsFor(store);
      port.script = [RewardedAdResult.failed];

      expect(await ads.watch(character), RewardedAdOutcome.unavailable);

      expect(store.rewardedAdProgressFor(character.id), 0);
      expect(store.rewardedAdsWatchedToday, 0);
    });

    // No-fill is ordinary, not an error. The button says so and nothing is
    // spent.
    test('a network with nothing to serve spends nothing', () async {
      final store = await loadStore();
      final ads = adsFor(store);
      port.fills = false;

      expect(await ads.watch(character), RewardedAdOutcome.unavailable);

      expect(ads.isReady, isFalse);
      expect(port.shows, 0);
      expect(store.rewardedAdsWatchedToday, 0);
    });
  });

  group('the daily cap', () {
    test('stops the fourth view of the day', () async {
      final store = await loadStore();
      final ads = adsFor(store);

      await ads.watch(entryById('item-03'));
      await ads.watch(entryById('item-05'));
      await ads.watch(entryById('item-08'));

      expect(store.rewardedAdsWatchedToday, 3);
      expect(store.rewardedAdsLeftToday, 0);
      expect(
        ads.availabilityFor(character),
        RewardedAdAvailability.dailyCapReached,
      );
      expect(await ads.watch(character), RewardedAdOutcome.notAllowed);
      // Refused before the network was asked, so a capped day costs no
      // requests.
      expect(port.shows, 3);
    });

    // Nothing runs at midnight. The count carries a day, and a day that is no
    // longer today reads as zero.
    test('resets when the local day turns over', () async {
      final store = await loadStore();
      final ads = adsFor(store);
      await ads.watch(entryById('item-03'));
      await ads.watch(entryById('item-05'));
      await ads.watch(entryById('item-08'));
      expect(store.rewardedAdsLeftToday, 0);

      now = DateTime(2026, 9, 15, 0, 1);

      expect(store.rewardedAdsWatchedToday, 0);
      expect(store.rewardedAdsLeftToday, 3);
      expect(await ads.watch(character), RewardedAdOutcome.counted);
      expect(store.rewardedAdsWatchedToday, 1);
    });

    test('survives a restart within the same day', () async {
      final store = await loadStore();
      await adsFor(store).watch(entryById('item-03'));

      final reopened = await loadStore();

      expect(reopened.rewardedAdsWatchedToday, 1);
      expect(reopened.rewardedAdsLeftToday, 2);
    });
  });

  group('the special tier takes three different days', () {
    // On a device this test is three days of waiting, or a changed system
    // clock. That is the reason the port exists.
    test('one view a day, three days to own it', () async {
      final store = await loadStore();
      final ads = adsFor(store);

      expect(await ads.watch(special), RewardedAdOutcome.counted);
      expect(store.rewardedAdProgressFor(special.id), 1);

      // Same day, cap untouched, and still refused.
      expect(store.rewardedAdsLeftToday, 2);
      expect(
        ads.availabilityFor(special),
        RewardedAdAvailability.alreadyEarnedToday,
      );
      expect(await ads.watch(special), RewardedAdOutcome.notAllowed);
      expect(store.rewardedAdProgressFor(special.id), 1);

      now = DateTime(2026, 9, 15, 9);
      expect(await ads.watch(special), RewardedAdOutcome.counted);
      expect(store.rewardedAdProgressFor(special.id), 2);
      expect(store.ownsCatalogEntry(special), isFalse);

      now = DateTime(2026, 9, 16, 9);
      expect(await ads.watch(special), RewardedAdOutcome.counted);

      expect(store.ownsCatalogEntry(special), isTrue);
      expect((await loadStore()).ownsCatalogEntry(special), isTrue);
    });

    test('the date it last earned is remembered across a restart', () async {
      final store = await loadStore();
      await adsFor(store).watch(special);

      final reopened = await loadStore();

      expect(reopened.rewardedAdLastEarnedDateFor(special.id), '2026-09-14');
      expect(
        reopened.rewardedAdAvailabilityFor(special),
        RewardedAdAvailability.alreadyEarnedToday,
      );
    });

    // Blocking the special entry must not block the rest of the day.
    test('does not consume the day for other entries', () async {
      final store = await loadStore();
      final ads = adsFor(store);

      await ads.watch(special);
      await ads.watch(special);

      expect(await ads.watch(character), RewardedAdOutcome.counted);
      expect(store.rewardedAdProgressFor(character.id), 1);
    });
  });

  group('a view is counted once', () {
    // A double tap on a slow network is enough to start two runs. Two runs
    // would each spend a slot of the cap while the user watched one ad.
    test('a second run while an ad is on screen is refused', () async {
      final store = await loadStore();
      final ads = adsFor(store);
      await ads.prepare();

      final first = ads.watch(character);
      final second = await ads.watch(character);
      await first;

      expect(second, RewardedAdOutcome.notAllowed);
      expect(store.rewardedAdsWatchedToday, 1);
      expect(port.shows, 1);
    });

    test('recording the same confirmation twice counts once', () async {
      final store = await loadStore();

      expect(await store.recordRewardedAdView(item), isTrue);
      expect(await store.recordRewardedAdView(item), isFalse);

      expect(store.rewardedAdsWatchedToday, 1);
      expect(store.ownedCatalogIds, {item.id});
    });

    test('an owned entry never counts again', () async {
      final store = await loadStore();
      final ads = adsFor(store);
      await ads.watch(item);
      expect(store.ownsCatalogEntry(item), isTrue);

      expect(
        ads.availabilityFor(item),
        RewardedAdAvailability.alreadyOwned,
      );
      expect(await ads.watch(item), RewardedAdOutcome.notAllowed);
      expect(store.rewardedAdsWatchedToday, 1);
    });
  });

  test('a non-ad entry cannot be recorded', () async {
    final store = await loadStore();

    expect(
      () => store.recordRewardedAdView(entryById('character-02')),
      throwsArgumentError,
    );
  });
}
