import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sobra_app/data/catalog_preview_data.dart';
import 'package:sobra_app/models/catalog_entry.dart';
import 'package:sobra_app/models/pay_schedule.dart';
import 'package:sobra_app/services/app_telemetry.dart';
import 'package:sobra_app/services/rewarded_ad_service.dart';
import 'package:sobra_app/state/sobra_store.dart';

import 'support/fake_rewarded_ad.dart';

void main() {
  late DateTime now;
  late List<(String, Map<String, Object>)> sent;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    now = DateTime(2026, 9, 14, 11);
    sent = [];
    AppTelemetry.instance = AppTelemetry(
      sendEvent: (name, parameters) async => sent.add((name, parameters)),
    );
    addTearDown(() => AppTelemetry.instance = AppTelemetry());
  });

  List<(String, Map<String, Object>)> named(String name) =>
      sent.where((event) => event.$1 == name).toList();

  CatalogEntry entryById(String id) =>
      CatalogPreviewData.all.firstWhere((entry) => entry.id == id);

  test('parameters go out as enum names', () async {
    await AppTelemetry.instance.event(TelemetryEvent.rewardedAdResult, {
      'result': RewardedAdOutcome.notAllowed,
      'kind': CatalogKind.room,
    });

    expect(sent.single.$1, 'rewarded_ad_result');
    expect(sent.single.$2, {'result': 'notAllowed', 'kind': 'room'});
  });

  group('rewarded ads', () {
    late FakeRewardedAdPort port;

    setUp(() => port = FakeRewardedAdPort());

    test(
      'a view that owns the entry reports the result and the unlock',
      () async {
        final store = await SobraStore.load(now: () => now);
        final ads = RewardedAds(port: port, store: store);

        await ads.watch(entryById('decor-shelf-books'));
        await Future<void>.delayed(Duration.zero);

        expect(named('rewarded_ad_result').single.$2, {
          'result': 'counted',
          'kind': 'item',
        });
        expect(named('item_unlocked').single.$2, {
          'method': 'rewardedAd',
          'kind': 'item',
        });
      },
    );

    test('a view short of the target unlocks nothing yet', () async {
      final store = await SobraStore.load(now: () => now);
      final ads = RewardedAds(port: port, store: store);

      await ads.watch(entryById('quokka'));
      await Future<void>.delayed(Duration.zero);

      expect(named('rewarded_ad_result'), hasLength(1));
      expect(named('item_unlocked'), isEmpty);
    });

    test('a network with nothing and a closed ad both report', () async {
      final store = await SobraStore.load(now: () => now);
      final ads = RewardedAds(port: port, store: store);
      final character = entryById('quokka');

      port.fills = false;
      await ads.watch(character);
      port
        ..fills = true
        ..script = [RewardedAdResult.dismissed];
      await ads.watch(character);
      await Future<void>.delayed(Duration.zero);

      expect(
        [for (final event in named('rewarded_ad_result')) event.$2['result']],
        ['unavailable', 'dismissed'],
      );
    });

    // A tap Sobra refuses never reached the network. Counting it would make
    // owned cards look like failed ads.
    test('a tap refused by Sobra reports nothing', () async {
      final store = await SobraStore.load(now: () => now);
      final ads = RewardedAds(port: port, store: store);
      final item = entryById('decor-shelf-books');
      await ads.watch(item);
      await Future<void>.delayed(Duration.zero);
      sent.clear();

      expect(await ads.watch(item), RewardedAdOutcome.notAllowed);
      await Future<void>.delayed(Duration.zero);

      expect(sent, isEmpty);
    });
  });

  test('each closed cycle is reported once', () async {
    final store = await SobraStore.load(now: () => now);
    await store.configureOnboarding(
      budgetCentavos: 700000,
      schedule: const PaySchedule.weekly(),
    );
    await store.completeOnboarding();
    expect(named('cycle_settled'), isEmpty);

    now = now.add(const Duration(days: 15));
    await store.refreshForCurrentDate();
    await Future<void>.delayed(Duration.zero);
    final closed = named('cycle_settled').length;
    expect(closed, greaterThanOrEqualTo(2));

    await store.refreshForCurrentDate();
    await Future<void>.delayed(Duration.zero);
    expect(named('cycle_settled'), hasLength(closed));
  });
}
