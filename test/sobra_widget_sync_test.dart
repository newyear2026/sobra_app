import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sobra_app/l10n/generated/app_localizations.dart';
import 'package:sobra_app/l10n/labels.dart';
import 'package:sobra_app/models/currency.dart';
import 'package:sobra_app/models/money_movement.dart';
import 'package:sobra_app/models/expense_entry.dart';
import 'package:sobra_app/models/income_entry.dart';
import 'package:sobra_app/models/pay_schedule.dart';
import 'package:sobra_app/services/sobra_widget_sync.dart';
import 'package:sobra_app/state/sobra_store.dart';

/// The widget payload is labelled with the same words the app shows, so these
/// tests resolve Spanish the way the app root does rather than inventing text.
String _label(MoneyMovement movement) =>
    movementTitle(lookupAppLocalizations(const Locale('es')), movement);

void main() {
  test(
    'widget snapshot contains current budget and two newest movements',
    () async {
      SharedPreferences.setMockInitialValues({});
      final now = DateTime(2026, 9, 5, 12);
      final store = await SobraStore.load(now: () => now);
      await store.configureOnboarding(
        budgetCentavos: 600000,
        schedule: PaySchedule.irregular(
          planningHorizonDays: 15,
          irregularCycleStart: DateTime(2026, 9, 1),
        ),
      );
      await store.completeOnboarding();
      await store.addExpense(
        amountCentavos: 1800,
        category: ExpenseCategory.transport,
        note: 'Metro',
        occurredAt: now.subtract(const Duration(minutes: 2)),
        paymentMethod: PaymentMethod.card,
      );
      await store.addIncome(
        amountCentavos: 25000,
        kind: IncomeKind.extra,
        note: 'Reembolso',
        occurredAt: now.subtract(const Duration(minutes: 1)),
        destination: PaymentMethod.card,
        allocation: IncomeAllocation.savings,
      );

      final snapshot = SobraWidgetSnapshot.fromStore(store, _label);
      final payload = snapshot.toPlatformMap();

      expect(payload['hasData'], isTrue);
      expect(payload['daysRemaining'], 11);
      expect(payload['totalBudgetCentavos'], 600000);
      expect(payload['totalSpentCentavos'], 1800);
      expect(payload['progressSegments'], 1);
      expect(payload['movementCount'], 2);
      expect(payload['movement1Title'], 'Reembolso');
      expect(payload['movement1Kind'], 'income');
      expect(payload['movement2Title'], 'Metro');
      expect(payload['movement2Kind'], 'transport');
      expect(payload['characterId'], 'michi');
      expect(payload['currencyCode'], 'MXN');
    },
  );

  test('the payload carries exactly the keys Android reads', () async {
    // MainActivity.saveWidgetData reads these by name and falls back to 0 or ""
    // for anything missing, so a rename on this side does not fail — the widget
    // just quietly shows zeroes. Pin the contract instead.
    SharedPreferences.setMockInitialValues({});
    final now = DateTime(2026, 9, 5, 12);
    final store = await SobraStore.load(now: () => now);
    await store.configureOnboarding(
      budgetCentavos: 600000,
      schedule: const PaySchedule.semiMonthly(),
    );
    await store.completeOnboarding();
    await store.addExpense(
      amountCentavos: 1800,
      category: ExpenseCategory.transport,
      note: 'Metro',
      occurredAt: now,
      paymentMethod: PaymentMethod.card,
    );

    expect(
      SobraWidgetSnapshot.fromStore(store, _label).toPlatformMap().keys.toSet(),
      {
        'hasData',
        'hasBudget',
        'todayRemainingCentavos',
        'todayRemainingText',
        'noAmountText',
        'currencyCode',
        'overCycleBudget',
        'daysRemaining',
        'totalBudgetCentavos',
        'totalSpentCentavos',
        'progressSegments',
        'reducedMotion',
        'characterId',
        'movementCount',
        'movement1Title',
        'movement1AmountCentavos',
        'movement1Kind',
        'todayLeftText',
        'todayLeftShortText',
        'cycleBalanceText',
        'cycleBalanceShortText',
        'cycleProgressText',
        'openAppText',
        'registerExpenseText',
        'daysRemainingText',
      },
    );
  });

  // Android resources follow the phone, not Ajustes, so the widget stayed
  // Spanish beside an English app. The app now writes the words itself.
  test('the widget words are the ones the app is set to', () async {
    SharedPreferences.setMockInitialValues({});
    final now = DateTime(2026, 9, 5, 12);
    final store = await SobraStore.load(now: () => now);
    await store.configureOnboarding(
      budgetCentavos: 600000,
      schedule: PaySchedule.irregular(
        planningHorizonDays: 15,
        irregularCycleStart: DateTime(2026, 9, 1),
      ),
    );
    await store.completeOnboarding();

    for (final (locale, today, short, days, register) in const [
      ('en', 'You have left today', 'Left today', '11 days', 'Add expense'),
      ('es', 'Hoy te queda', 'Hoy te queda', '11 días', 'Registrar gasto'),
      ('ko', '오늘 남은 돈', '오늘 남은 돈', '11일', '지출 기록'),
    ]) {
      final l10n = lookupAppLocalizations(Locale(locale));
      final payload = SobraWidgetSnapshot.fromStore(
        store,
        _label,
        copy: SobraWidgetCopy(
          todayLeft: l10n.homeTodayLeft,
          todayLeftShort: l10n.widgetTodayLeft,
          cycleBalance: l10n.homeCycleBalance,
          cycleBalanceShort: l10n.widgetCycleBalance,
          cycleProgress: l10n.homeCycleProgress,
          openApp: l10n.widgetOpenApp,
          registerExpense: l10n.widgetRegisterExpense,
          days: l10n.daysCount,
        ),
      ).toPlatformMap();
      expect(payload['todayLeftText'], today, reason: locale);
      expect(payload['todayLeftShortText'], short, reason: locale);
      expect(payload['daysRemainingText'], days, reason: locale);
      expect(payload['registerExpenseText'], register, reason: locale);
    }
  });

  test("without the app's words the widget keeps its own", () async {
    SharedPreferences.setMockInitialValues({});
    final store = await SobraStore.load(now: () => DateTime(2026, 9, 5, 12));
    final payload = SobraWidgetSnapshot.fromStore(
      store,
      _label,
    ).toPlatformMap();

    // Empty, not missing: Android reads "" as "use the resource string".
    for (final key in ['todayLeftText', 'openAppText', 'daysRemainingText']) {
      expect(payload[key], '', reason: key);
    }
  });

  test('a fresh install reports no data rather than zeroes', () async {
    SharedPreferences.setMockInitialValues({});
    final store = await SobraStore.load(now: () => DateTime(2026, 9, 5, 12));
    final payload = SobraWidgetSnapshot.fromStore(
      store,
      _label,
    ).toPlatformMap();

    expect(payload['hasData'], isFalse);
    expect(payload['movementCount'], 0);
  });

  test('widget snapshot follows the saved character choice', () async {
    SharedPreferences.setMockInitialValues({});
    final store = await SobraStore.load(now: () => DateTime(2026, 9, 5, 12));
    await store.chooseCharacter('poodle');
    expect(
      SobraWidgetSnapshot.fromStore(
        store,
        _label,
      ).toPlatformMap()['characterId'],
      'poodle',
    );
  });

  test('an overspent cycle reports a full bar and a negative day', () async {
    SharedPreferences.setMockInitialValues({});
    final now = DateTime(2026, 9, 5, 12);
    final store = await SobraStore.load(now: () => now);
    await store.configureOnboarding(
      budgetCentavos: 600000,
      schedule: const PaySchedule.semiMonthly(),
    );
    await store.completeOnboarding();
    await store.addExpense(
      amountCentavos: 700000,
      category: ExpenseCategory.other,
      note: 'Refrigerador',
      occurredAt: now,
      paymentMethod: PaymentMethod.card,
    );

    final payload = SobraWidgetSnapshot.fromStore(
      store,
      _label,
    ).toPlatformMap();
    // 7,000 against a 6,000 budget: the widget reports the cycle's own
    // −1,000, not the day's slice minus a cycle-sized expense, and flips the
    // label with it.
    expect(payload['todayRemainingCentavos'], -100000);
    expect(payload['todayRemainingText'], '−\$1,000');
    expect(payload['overCycleBudget'], isTrue);
    // The bar saturates: 116% and 100% both send 10. The negative amount is
    // the only thing left that says the cycle went over.
    expect(payload['progressSegments'], 10);
  });

  test('snapshot never sends more than two movements', () async {
    SharedPreferences.setMockInitialValues({});
    final now = DateTime(2026, 9, 5, 12);
    final store = await SobraStore.load(now: () => now);
    await store.configureOnboarding(
      budgetCentavos: 600000,
      schedule: const PaySchedule.semiMonthly(),
    );
    for (var index = 0; index < 3; index++) {
      await store.addExpense(
        amountCentavos: 1000 + index,
        category: ExpenseCategory.other,
        note: 'Movimiento $index',
        occurredAt: now.subtract(Duration(minutes: index)),
        paymentMethod: PaymentMethod.card,
      );
    }

    final payload = SobraWidgetSnapshot.fromStore(
      store,
      _label,
    ).toPlatformMap();
    expect(payload['movementCount'], 2);
    expect(payload, isNot(contains('movement3Title')));
  });

  // The widget used to format the figure itself, as dollars in the Mexican
  // style, whatever the app was set to. It now shows what the app wrote.
  test('the widget figure is written in the chosen currency', () async {
    SharedPreferences.setMockInitialValues({});
    final store = await SobraStore.load(now: () => DateTime(2026, 9, 5, 12));
    await store.configureOnboarding(
      budgetCentavos: 60000000,
      schedule: const PaySchedule.semiMonthly(),
    );
    await store.completeOnboarding();

    for (final (currency, text, empty) in const [
      (Currency.clp, r'$60.000', r'$—'),
      (Currency.krw, '₩60,000', '₩—'),
      (Currency.eur, '€60.000', '€—'),
    ]) {
      await store.setCurrency(currency);
      final payload = SobraWidgetSnapshot.fromStore(
        store,
        _label,
      ).toPlatformMap();
      expect(payload['todayRemainingText'], text, reason: currency.code);
      expect(payload['noAmountText'], empty, reason: currency.code);
      expect(payload['currencyCode'], currency.code);
    }
  });
}
