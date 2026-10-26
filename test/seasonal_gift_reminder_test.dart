import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sobra_app/l10n/generated/app_localizations.dart';
import 'package:sobra_app/models/character_costume.dart';
import 'package:sobra_app/models/pay_schedule.dart';
import 'package:sobra_app/services/seasonal_gift_reminder.dart';
import 'package:sobra_app/state/sobra_store.dart';

Future<SobraStore> _store(DateTime now, {bool onboarded = true}) async {
  final store = await SobraStore.load(now: () => now);
  if (!onboarded) return store;
  await store.configureOnboarding(
    budgetCentavos: 600000,
    schedule: const PaySchedule.semiMonthly(),
  );
  await store.completeOnboarding();
  return store;
}

void main() {
  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('es'));
  });
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('an unclaimed gift is reminded once, on the last morning', () async {
    final store = await _store(DateTime(2026, 10, 28, 9));
    final plan = planSeasonalGiftReminder(store: store, l10n: l10n)!;

    expect(plan.at, DateTime(2026, 11, 3, 10));
    expect(plan.at.day, CharacterCostumes.lastClaimDay.day);
    expect(plan.title, 'Hoy es el último día del regalo');
    expect(plan.body, contains('12 disfraces'));
  });

  test('claiming the gift takes the reminder back', () async {
    final store = await _store(DateTime(2026, 10, 28, 9));
    await store.claimSeasonalCostumes();

    expect(planSeasonalGiftReminder(store: store, l10n: l10n), isNull);
  });

  test('nothing is planned once its moment has passed', () async {
    final store = await _store(DateTime(2026, 11, 3, 10));

    expect(planSeasonalGiftReminder(store: store, l10n: l10n), isNull);
  });

  test('nothing is planned before onboarding is finished', () async {
    final store = await _store(DateTime(2026, 10, 28, 9), onboarded: false);

    expect(planSeasonalGiftReminder(store: store, l10n: l10n), isNull);
  });

  test('the icon is the companion on screen, in its costume', () async {
    final store = await _store(DateTime(2026, 10, 28, 9));
    final plan = planSeasonalGiftReminder(store: store, l10n: l10n)!;

    expect(plan.iconAsset, contains('/${store.characterId}/idle-8.webp'));
    expect(plan.iconSource.width, inExclusiveRange(0, 1));
    expect(plan.iconSource.height, inExclusiveRange(0, 1));
  });
}
