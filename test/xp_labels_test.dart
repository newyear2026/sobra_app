import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sobra_app/l10n/generated/app_localizations.dart';
import 'package:sobra_app/l10n/labels.dart';
import 'package:sobra_app/models/cash_reconciliation.dart';
import 'package:sobra_app/models/expense_entry.dart';
import 'package:sobra_app/models/pay_schedule.dart';
import 'package:sobra_app/models/xp_event.dart';
import 'package:sobra_app/state/sobra_store.dart';
import 'package:sobra_app/theme/app_theme.dart';
import 'package:sobra_app/widgets/gamification_ui.dart';

import 'support/localizations.dart';

final l10n = lookupAppLocalizations(const Locale('es'));

XpEvent _event(XpEventKind kind, {int? quantity, PayCycleType? cycleType}) =>
    XpEvent(
      id: 'xp-1',
      kind: kind,
      xp: 25,
      occurredAt: DateTime(2026, 9, 7),
      sourceKey: 'test',
      quantity: quantity,
      cycleType: cycleType,
    );

void main() {
  group('an XP row headline', () {
    // The store used to pick between "día" and "días" itself, which only ever
    // worked because the app was Spanish. The count now reaches the message.
    test('agrees with the number of days it counts', () {
      expect(
        _event(XpEventKind.daysUnderDailyLimit, quantity: 1).title(l10n),
        '1 día bajo tu límite',
      );
      expect(
        _event(XpEventKind.daysUnderDailyLimit, quantity: 4).title(l10n),
        '4 días bajo tu límite',
      );
      expect(
        _event(XpEventKind.daysUnderDailyLimit).title(l10n),
        '0 días bajo tu límite',
      );
    });

    test('names the cycle the way the user set it up', () {
      String titleFor(PayCycleType? type) =>
          _event(XpEventKind.cycleInGreen, cycleType: type).title(l10n);

      expect(
        titleFor(PayCycleType.semiMonthly),
        'Cerraste la quincena en verde',
      );
      expect(titleFor(PayCycleType.monthly), 'Cerraste el mes en verde');
      expect(titleFor(PayCycleType.weekly), 'Cerraste la semana en verde');
      expect(titleFor(PayCycleType.irregular), 'Cerraste el ciclo en verde');
      expect(titleFor(null), 'Cerraste el ciclo en verde');
    });

    test('carries a short reason for every kind', () {
      for (final kind in XpEventKind.values) {
        expect(kind.shortDetail(l10n), isNotEmpty, reason: '$kind');
      }
    });

    test('mission rows read as a completed record, not today\'s board', () {
      expect(
        XpEventKind.dailyMissionRecord.shortDetail(l10n),
        'Misión completada',
      );
      expect(
        XpEventKind.dailyMissionRecord.shortDetail(l10n),
        isNot(l10n.dailyMissionTitle),
      );
    });
  });

  test('every level has a name', () {
    for (var level = 1; level <= XpProgress.levelCount; level++) {
      expect(xpLevelTitle(l10n, level), isNotEmpty, reason: 'level $level');
    }
    expect(xpLevelTitle(l10n, 1), 'Michi curioso');
    expect(xpLevelTitle(l10n, XpProgress.levelCount), 'Michi leyenda');
  });

  group('an XP notice', () {
    test('reads as one cycle or many', () {
      expect(
        xpNoticeTitle(
          l10n,
          const XpNotice(
            kind: XpNoticeKind.cyclesClosed,
            xp: 45,
            closedCycles: 1,
          ),
        ),
        'Ciclo cerrado',
      );
      expect(
        xpNoticeTitle(
          l10n,
          const XpNotice(
            kind: XpNoticeKind.cyclesClosed,
            xp: 90,
            closedCycles: 3,
          ),
        ),
        '3 ciclos cerrados',
      );
    });

    test('names a saved cash count', () {
      const notice = XpNotice(kind: XpNoticeKind.cashCountSaved, xp: 25);
      expect(xpNoticeTitle(l10n, notice), 'Conteo de efectivo guardado');
      expect(
        xpNoticeDetail(l10n, notice),
        'Primer conteo con XP de la semana.',
      );
    });

    testWidgets('shows its wording in the toast', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: sobraLocalizationsDelegates,
          supportedLocales: sobraSupportedLocales,
          theme: buildSobraTheme(),
          home: const Scaffold(
            body: XpToast(
              notice: XpNotice(
                kind: XpNoticeKind.cyclesClosed,
                xp: 90,
                closedCycles: 3,
              ),
            ),
          ),
        ),
      );

      expect(find.text('3 ciclos cerrados'), findsOneWidget);
      expect(find.text('XP acreditados automáticamente.'), findsOneWidget);
      expect(find.text('+90 XP'), findsOneWidget);
    });
  });

  group('the store', () {
    late DateTime now;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      now = DateTime(2026, 9, 1, 9);
    });

    Future<SobraStore> newUser({int? cashCentavos}) async {
      final store = await SobraStore.load(now: () => now);
      await store.configureOnboarding(
        budgetCentavos: 700000,
        schedule: const PaySchedule.weekly(),
        cashCentavos: cashCentavos,
      );
      await store.completeOnboarding();
      return store;
    }

    // The notice is held in a field and read on a later frame, so it must
    // carry the numbers rather than an already-written sentence.
    test('files a settlement notice as a kind and a count', () async {
      final store = await newUser();
      now = DateTime(2026, 9, 20, 9);
      await store.settleCycles();

      final notice = store.takePendingXpNotice();
      expect(notice, isNotNull);
      expect(notice!.kind, XpNoticeKind.cyclesClosed);
      expect(notice.closedCycles, greaterThan(0));
      expect(notice.xp, greaterThan(0));
      expect(xpNoticeTitle(l10n, notice), isNotEmpty);
    });

    test('files a cash count notice as its own kind', () async {
      final store = await newUser(cashCentavos: 200000);
      now = DateTime(2026, 9, 2, 10);
      await store.reconcileCashCount(
        actualCentavos: 200000,
        resolution: CashResolution.correction,
      );

      final notice = store.takePendingXpNotice();
      expect(notice?.kind, XpNoticeKind.cashCountSaved);
      expect(notice?.xp, 25);
    });

    test('restores XP rows well enough to label them', () async {
      final store = await newUser();
      await store.addExpense(
        amountCentavos: 1000,
        category: ExpenseCategory.food,
        note: '',
        occurredAt: now,
        paymentMethod: PaymentMethod.cash,
      );
      now = DateTime(2026, 9, 20, 9);
      await store.settleCycles();

      final restored = await SobraStore.load(now: () => now);
      expect(restored.xpEvents, isNotEmpty);
      for (final event in restored.xpEvents) {
        expect(event.title(l10n), isNotEmpty, reason: '${event.kind}');
        expect(event.kind.shortDetail(l10n), isNotEmpty);
      }
    });
  });
}
