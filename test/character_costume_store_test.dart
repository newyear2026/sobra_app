import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:sobra_app/models/character_costume.dart';
import 'package:sobra_app/models/pay_schedule.dart';
import 'package:sobra_app/models/store_failure.dart';
import 'package:sobra_app/services/sobra_widget_sync.dart';
import 'package:sobra_app/state/sobra_store.dart';

class _BreakablePreferences extends InMemorySharedPreferencesStore {
  _BreakablePreferences() : super.empty();
  bool writesFail = false;

  @override
  Future<bool> setValue(String valueType, String key, Object value) =>
      writesFail
      ? Future<bool>.value(false)
      : super.setValue(valueType, key, value);
}

Future<SobraStore> _started(NowProvider now) async {
  final store = await SobraStore.load(now: now);
  await store.configureOnboarding(
    budgetCentavos: 600000,
    schedule: const PaySchedule.semiMonthly(),
  );
  await store.completeOnboarding();
  return store;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('only acquisition is limited to the local event dates', () {
    expect(
      CharacterCostumes.canClaimOn(DateTime(2026, 10, 22, 23, 59)),
      isFalse,
    );
    expect(CharacterCostumes.canClaimOn(DateTime(2026, 10, 23)), isTrue);
    expect(CharacterCostumes.canClaimOn(DateTime(2026, 11, 3, 23, 59)), isTrue);
    expect(CharacterCostumes.canClaimOn(DateTime(2026, 11, 4)), isFalse);
    expect(CharacterCostumes.canClaimOn(DateTime(2027, 10, 24)), isFalse);
  });

  test(
    'one serialized free claim gives twelve costumes, no base characters',
    () async {
      final store = await _started(() => DateTime(2026, 10, 24));
      final charactersBefore = store.ownedCatalogIds.toSet();
      final claims = await Future.wait([
        store.claimSeasonalCostumes(),
        store.claimSeasonalCostumes(),
      ]);
      expect(claims, [true, false]);
      expect(store.ownedCostumeIds, hasLength(12));
      expect(store.ownedCatalogIds, charactersBefore);
      expect(store.characterId, 'michi');
      expect(store.costumeSelections, isEmpty);
      expect(store.ownsCharacter('capybara'), isFalse);
      expect(store.canClaimSeasonalCostumes, isFalse);
    },
  );

  test(
    'not started, not yet active and ended events cannot grant a gift',
    () async {
      var now = DateTime(2026, 10, 24);
      final store = await SobraStore.load(now: () => now);
      expect(await store.claimSeasonalCostumes(), isFalse);
      await store.completeOnboarding();
      now = DateTime(2026, 10, 22);
      expect(await store.claimSeasonalCostumes(), isFalse);
      now = DateTime(2026, 11, 4);
      expect(await store.claimSeasonalCostumes(), isFalse);
      expect(store.ownedCostumeIds, isEmpty);
    },
  );

  test(
    'a saved gift for a locked character can be worn after unlocking it',
    () async {
      final store = await _started(() => DateTime(2026, 10, 24));
      await store.claimSeasonalCostumes();
      final costume = CharacterCostumes.forCharacter('capybara').single.id;
      expect(store.ownedCostumeIds, contains(costume));
      await expectLater(
        store.equipCharacterCostume('capybara', costume),
        throwsArgumentError,
      );
      expect(store.equippedCostumeFor('capybara'), isNull);
      await store.grantCatalogEntry('capybara');
      await store.equipCharacterCostume('capybara', costume);
      expect(store.equippedCostumeFor('capybara'), costume);
      expect(store.characterId, 'michi');
    },
  );

  test(
    'a costume cannot be borrowed from another character or an unowned set',
    () async {
      final store = await _started(() => DateTime(2026, 10, 24));
      final dracula = CharacterCostumes.forCharacter('michi').single.id;
      await expectLater(
        store.equipCharacterCostume('michi', dracula),
        throwsArgumentError,
      );
      await store.claimSeasonalCostumes();
      await expectLater(
        store.equipCharacterCostume('michi', 'autumn-2026-poodle'),
        throwsArgumentError,
      );
      await expectLater(
        store.equipCharacterCostume('michi', 'future-costume'),
        throwsArgumentError,
      );
      expect(store.costumeSelections, isEmpty);
    },
  );

  test(
    'received costumes and the per-character choice survive the event and restart',
    () async {
      var now = DateTime(2026, 10, 24);
      final store = await _started(() => now);
      await store.claimSeasonalCostumes();
      await store.equipCharacterCostume('michi', 'autumn-2026-michi');
      await store.grantCatalogEntry('poodle');
      await store.equipCharacterCostume('poodle', 'autumn-2026-poodle');
      await store.chooseCharacter('poodle');
      now = DateTime(2027, 2, 12);
      final reopened = await SobraStore.load(now: () => now);
      expect(reopened.ownedCostumeIds, hasLength(12));
      expect(reopened.characterId, 'poodle');
      expect(reopened.equippedCostumeFor('poodle'), 'autumn-2026-poodle');
      await reopened.chooseCharacter('michi');
      expect(reopened.equippedCostumeFor('michi'), 'autumn-2026-michi');
      await reopened.equipCharacterCostume('michi', null);
      expect(reopened.equippedCostumeFor('michi'), isNull);
      expect(reopened.ownedCostumeIds, hasLength(12));
      expect(reopened.canClaimSeasonalCostumes, isFalse);
      final payload = SobraWidgetSnapshot.fromStore(
        reopened,
        (_) => '',
      ).toPlatformMap();
      expect(payload['characterId'], 'michi');
      expect(payload['costumeId'], '');
    },
  );

  test(
    'backup transfer keeps free outfits without granting paid characters',
    () async {
      final source = await _started(() => DateTime(2026, 10, 24));
      await source.claimSeasonalCostumes();
      await source.grantCatalogEntry('capybara');
      await source.equipCharacterCostume('capybara', 'autumn-2026-capybara');
      final backup = source.exportJson();
      SharedPreferences.setMockInitialValues({});
      final target = await _started(() => DateTime(2026, 12, 1));
      await target.importBackup(backup);
      expect(target.ownedCostumeIds, hasLength(12));
      expect(target.hasClaimedSeasonalCostumes, isTrue);
      expect(target.ownsCharacter('capybara'), isFalse);
      expect(target.equippedCostumeFor('capybara'), isNull);
      await target.grantCatalogEntry('capybara');
      expect(target.equippedCostumeFor('capybara'), 'autumn-2026-capybara');
    },
  );

  test(
    'importing a pre-costume backup does not revoke a received gift',
    () async {
      final store = await _started(() => DateTime(2026, 10, 24));
      final older = jsonDecode(store.exportJson()) as Map<String, dynamic>
        ..['schemaVersion'] = 10
        ..remove('ownedCostumeIds')
        ..remove('claimedCostumeCampaignIds')
        ..remove('costumeSelections');
      await store.claimSeasonalCostumes();
      await store.importBackup(jsonEncode(older));
      expect(store.ownedCostumeIds, hasLength(12));
      expect(store.hasClaimedSeasonalCostumes, isTrue);
    },
  );

  test(
    'purchase revocation hides an outfit without destroying its ownership',
    () async {
      final store = await _started(() => DateTime(2026, 10, 24));
      await store.claimSeasonalCostumes();
      await store.grantCatalogEntry('capybara');
      await store.chooseCharacter('capybara');
      await store.equipCharacterCostume('capybara', 'autumn-2026-capybara');
      await store.revokeCatalogEntries({'capybara'});
      expect(store.characterId, 'michi');
      expect(store.equippedCostumeFor('capybara'), isNull);
      expect(store.ownedCostumeIds, contains('autumn-2026-capybara'));
    },
  );

  test(
    'failed persistence rolls back the gift and allows a real retry',
    () async {
      final originalPlatform = SharedPreferencesStorePlatform.instance;
      final preferences = _BreakablePreferences();
      SharedPreferencesStorePlatform.instance = preferences;
      SharedPreferences.resetStatic();
      addTearDown(() {
        SharedPreferencesStorePlatform.instance = originalPlatform;
        SharedPreferences.resetStatic();
      });
      final store = await _started(() => DateTime(2026, 10, 24));
      final before = store.exportJson();
      var notifications = 0;
      store.addListener(() => notifications++);
      preferences.writesFail = true;
      await expectLater(
        store.claimSeasonalCostumes(),
        throwsA(isA<SobraStoreException>()),
      );
      expect(store.exportJson(), before);
      expect(store.ownedCostumeIds, isEmpty);
      expect(notifications, 0);
      preferences.writesFail = false;
      expect(await store.claimSeasonalCostumes(), isTrue);
      preferences.writesFail = true;
      await expectLater(
        store.equipCharacterCostume('michi', 'autumn-2026-michi'),
        throwsA(isA<SobraStoreException>()),
      );
      expect(store.equippedCostumeFor('michi'), isNull);
      expect(store.ownedCostumeIds, hasLength(12));
      final beforeDone = store.exportJson();
      await expectLater(
        store.saveRoomSelection(
          roomId: store.equippedRoomId,
          placementsByRoom: {store.equippedRoomId: {}},
          selectedCharacterId: 'michi',
          costumeChanges: {'michi': 'autumn-2026-michi'},
        ),
        throwsA(isA<SobraStoreException>()),
      );
      expect(store.exportJson(), beforeDone);
    },
  );

  test(
    'appearance validation leaves every staged room change untouched',
    () async {
      final store = await _started(() => DateTime(2026, 10, 24));
      await store.claimSeasonalCostumes();
      final before = store.exportJson();
      await expectLater(
        store.saveRoomSelection(
          roomId: store.equippedRoomId,
          placementsByRoom: {store.equippedRoomId: {}},
          costumeChanges: {'michi': 'autumn-2026-poodle'},
        ),
        throwsArgumentError,
      );
      expect(store.exportJson(), before);
    },
  );

  test(
    'unknown future costume records round-trip but cannot be displayed',
    () async {
      final store = await _started(() => DateTime(2026, 10, 24));
      final data = jsonDecode(store.exportJson()) as Map<String, dynamic>
        ..['ownedCostumeIds'] = ['future-costume']
        ..['costumeSelections'] = {'michi': 'future-costume'};
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('sobra_state_v2', jsonEncode(data));
      final restored = await SobraStore.load(now: () => DateTime(2026, 10, 24));
      expect(restored.hasStorageError, isFalse);
      expect(restored.ownedCostumeIds, contains('future-costume'));
      expect(restored.equippedCostumeFor('michi'), isNull);
      expect(
        jsonDecode(restored.exportJson())['costumeSelections']['michi'],
        'future-costume',
      );
    },
  );
}
