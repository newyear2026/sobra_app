import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sobra_app/data/catalog_preview_data.dart';
import 'package:sobra_app/models/catalog_entry.dart';
import 'package:sobra_app/models/cycle_record.dart';
import 'package:sobra_app/models/pay_schedule.dart';
import 'package:sobra_app/models/xp_event.dart';
import 'package:sobra_app/screens/collection_screen.dart';
import 'package:sobra_app/screens/settlement_screen.dart';
import 'package:sobra_app/state/sobra_store.dart';
import 'package:sobra_app/theme/app_theme.dart';

import 'support/localizations.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  final record = CycleRecord(
    start: DateTime(2026, 9, 1),
    end: DateTime(2026, 9, 7),
    budgetCentavos: 700000,
    spentCentavos: 180000,
    cycleType: PayCycleType.weekly,
  );

  const notice = XpNotice(
    kind: XpNoticeKind.cyclesClosed,
    xp: 130,
    closedCycles: 1,
  );

  Future<SobraStore> loadStore() =>
      SobraStore.load(now: () => DateTime(2026, 9, 14, 11));

  Future<void> pump(WidgetTester tester, SobraStore store) async {
    tester.view.physicalSize = const Size(520, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    useSpanishDevice(tester);
    await tester.pumpWidget(
      SobraScope(
        store: store,
        child: MaterialApp(
          localizationsDelegates: sobraLocalizationsDelegates,
          supportedLocales: sobraSupportedLocales,
          theme: buildSobraTheme(),
          home: SettlementScreen(notice: notice, record: record),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the close shows cycle figures and no ad playback', (
    tester,
  ) async {
    final store = await loadStore();
    await pump(tester, store);

    expect(find.text('Cierre de este ciclo'), findsOneWidget);
    expect(find.text('Ciclo cerrado'), findsOneWidget);
    expect(find.text('+130 XP'), findsOneWidget);
    expect(find.text('Ir por un adorno especial'), findsOneWidget);
    expect(find.byType(CollectionScreen), findsNothing);
  });

  testWidgets('the card opens the collection on the recommended entry', (
    tester,
  ) async {
    final store = await loadStore();
    final started = CatalogPreviewData.all.firstWhere(
      (entry) => entry.id == 'character-03',
    );
    await store.recordRewardedAdView(started);
    await pump(tester, store);

    await tester.tap(find.text('Ir por un adorno especial'));
    await tester.pumpAndSettle();

    expect(find.byType(CollectionScreen), findsOneWidget);
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Personaje 3'),
      ),
      findsOneWidget,
    );
    expect(store.rewardedAdProgressFor('character-03'), 1);
  });

  testWidgets('the card is hidden when nothing can be unlocked', (
    tester,
  ) async {
    final store = await loadStore();
    for (final entry in CatalogPreviewData.all.where(
      (entry) => entry.unlockMethod == CatalogUnlockMethod.rewardedAd,
    )) {
      await store.grantCatalogEntry(entry.id);
    }

    await pump(tester, store);

    expect(find.text('Ir por un adorno especial'), findsNothing);
    expect(find.text('Listo'), findsOneWidget);
  });
}
