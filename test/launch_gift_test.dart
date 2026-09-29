import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sobra_app/data/launch_gift_campaign.dart';
import 'package:sobra_app/models/room_design.dart';
import 'package:sobra_app/state/sobra_store.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('both items arrive once and remain owned after reload', () async {
    final store = await SobraStore.load(now: () => DateTime(2026, 10, 1, 10));
    expect(
      store.ownedCatalogIds,
      isNot(contains(RoomDecorAssets.launchSofaId)),
    );

    await store.completeOnboarding();

    expect(store.ownedCatalogIds, containsAll(LaunchGiftCampaign.itemIds));
    expect(store.launchGiftNoticePending, isTrue);
    expect(await store.takeLaunchGiftNotice(), isTrue);
    expect(await store.takeLaunchGiftNotice(), isFalse);

    final reopened = await SobraStore.load(
      now: () => DateTime(2026, 12, 1, 10),
    );
    expect(reopened.ownedCatalogIds, containsAll(LaunchGiftCampaign.itemIds));
    expect(reopened.launchGiftNoticePending, isFalse);
    expect(await reopened.maybeGrantLaunchGift(), isFalse);
  });

  test(
    'starting on the last day still qualifies after later onboarding',
    () async {
      var now = DateTime(2026, 11, 15, 23);
      final store = await SobraStore.load(now: () => now);
      now = DateTime(2026, 11, 16, 9);

      await store.completeOnboarding();

      expect(store.ownedCatalogIds, containsAll(LaunchGiftCampaign.itemIds));
    },
  );

  test('a first start after the deadline receives nothing', () async {
    final store = await SobraStore.load(now: () => DateTime(2026, 11, 16, 9));
    await store.completeOnboarding();

    expect(
      store.ownedCatalogIds,
      isNot(contains(RoomDecorAssets.launchSofaId)),
    );
    expect(store.ownedCatalogIds, isNot(contains(RoomDecorAssets.launchTvId)));
    expect(store.launchGiftNoticePending, isFalse);
  });

  test(
    'an early tester is found in legacy saved state after the deadline',
    () async {
      final oldStore = await SobraStore.load(
        now: () => DateTime(2026, 9, 20, 9),
      );
      await oldStore.completeOnboarding();
      final preferences = await SharedPreferences.getInstance();
      final legacy =
          jsonDecode(preferences.getString('sobra_state_v2')!)
              as Map<String, dynamic>;
      legacy.remove('firstStartedAt');
      legacy.remove('launchGiftNoticePending');
      await preferences.setString('sobra_state_v2', jsonEncode(legacy));

      final reopened = await SobraStore.load(
        now: () => DateTime(2026, 12, 1, 10),
      );

      expect(reopened.firstStartedAt, DateTime(2026, 9, 20));
      expect(reopened.ownedCatalogIds, containsAll(LaunchGiftCampaign.itemIds));
      expect(reopened.launchGiftNoticePending, isTrue);
    },
  );
}
