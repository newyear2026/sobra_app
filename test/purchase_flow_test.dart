import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sobra_app/screens/collection_screen.dart';
import 'package:sobra_app/screens/settings_screen.dart';
import 'package:sobra_app/services/purchase_service.dart';
import 'package:sobra_app/state/sobra_store.dart';
import 'package:sobra_app/theme/app_theme.dart';

import 'support/fake_purchase_backend.dart';
import 'support/localizations.dart';

void main() {
  late SobraStore store;
  late FakeBackend backend;
  late SobraPurchases purchases;

  const productId = 'sobra.character.02';

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    store = await SobraStore.load(now: () => DateTime(2026, 9, 14, 11));
    backend = FakeBackend()..catalogue = [productFor(productId, r'MX$ 79')];
    purchases = SobraPurchases(
      backend: backend,
      store: store,
      restoreGrace: const Duration(milliseconds: 40),
    );
    addTearDown(purchases.dispose);
    addTearDown(backend.close);
  });

  /// [inScaffold] for screens that do not bring one. Ajustes is a tab inside
  /// AppShell's Scaffold in the running app, and a SnackBar with no Scaffold
  /// anywhere above it is never laid out — so without this the restore rows
  /// would fail for a reason that has nothing to do with purchases.
  Future<void> pump(
    WidgetTester tester,
    Widget home, {
    bool inScaffold = false,
  }) async {
    tester.view.physicalSize = const Size(520, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    useSpanishDevice(tester);
    await tester.pumpWidget(
      PurchaseScope(
        purchases: purchases,
        child: SobraScope(
          store: store,
          child: MaterialApp(
            localizationsDelegates: sobraLocalizationsDelegates,
            supportedLocales: sobraSupportedLocales,
            theme: buildSobraTheme(),
            home: inScaffold
                ? Scaffold(backgroundColor: AppColors.surface, body: home)
                : home,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder inDialog(String text) =>
      find.descendant(of: find.byType(AlertDialog), matching: find.text(text));

  testWidgets('the card shows the price the store quoted', (tester) async {
    await purchases.start();

    await pump(tester, const CollectionScreen());

    expect(find.text(r'MX$ 79'), findsOneWidget);
    // The preview source priced six entries. Only the one the fake store
    // actually listed may carry a price now.
    expect(find.text(r'MX$ 99'), findsNothing);
  });

  testWidgets('buying from the dialog reaches the store and then unlocks', (
    tester,
  ) async {
    await purchases.start();
    await pump(tester, const CollectionScreen());

    await tester.tap(find.text('Personaje 2'));
    await tester.pumpAndSettle();
    await tester.tap(inDialog('COMPRAR'));
    await tester.pumpAndSettle();

    expect(backend.bought, [productId]);

    backend.emit([detailsFor(productId, PurchaseStatus.purchased)]);
    await tester.pumpAndSettle();

    // The catalog answers for itself once the store confirms — no reload, no
    // second trip through the screen.
    await tester.tap(find.text('Personaje 2'));
    await tester.pumpAndSettle();
    expect(inDialog('EQUIPAR'), findsOneWidget);
    expect(inDialog('COMPRAR'), findsNothing);
  });

  testWidgets('a purchase Play is still holding keeps saying so', (
    tester,
  ) async {
    await purchases.start();
    await pump(tester, const CollectionScreen());

    backend.emit([
      detailsFor(productId, PurchaseStatus.pending, needsCompleting: false),
    ]);
    await tester.pumpAndSettle();

    expect(find.text('COMPRANDO…'), findsOneWidget);
    // Still locked: the money has not moved yet.
    await tester.tap(find.text('Personaje 2'));
    await tester.pumpAndSettle();
    expect(inDialog('EQUIPAR'), findsNothing);
  });

  testWidgets('a rejected purchase tells the user they were not charged', (
    tester,
  ) async {
    await purchases.start();
    await pump(tester, const CollectionScreen());

    backend.emit([
      detailsFor(productId, PurchaseStatus.error, needsCompleting: false),
    ]);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Personaje 2'));
    await tester.pumpAndSettle();
    await tester.tap(inDialog('COMPRAR'));
    await tester.pumpAndSettle();

    expect(
      find.text('No se pudo completar la compra. No se te cobró nada.'),
      findsOneWidget,
    );
  });

  testWidgets('an unreachable store leaves the catalog usable', (tester) async {
    backend.available = false;
    await purchases.start();

    await pump(tester, const CollectionScreen());

    expect(find.text('Personaje 2'), findsOneWidget);
    expect(find.text(r'MX$ 79'), findsNothing);
    expect(find.text('COMPRAR'), findsWidgets);
  });

  testWidgets('Ajustes restores what the account owns', (tester) async {
    await purchases.start();
    await pump(tester, const SettingsScreen(), inScaffold: true);
    backend.ownedProductIds = [productId];

    await tester.tap(find.text('Restaurar compras'));
    // A restore schedules no frame while it waits, so pumpAndSettle on its
    // own returns before the store has answered. The clock has to be moved
    // past the grace period by hand.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    expect(store.ownedCatalogIds, {'character-02'});
    expect(find.text('Listo. Tus compras volvieron.'), findsOneWidget);
  });

  testWidgets('Ajustes says so when there is nothing to restore', (
    tester,
  ) async {
    await purchases.start();
    await pump(tester, const SettingsScreen(), inScaffold: true);

    await tester.tap(find.text('Restaurar compras'));
    // A restore schedules no frame while it waits, so pumpAndSettle on its
    // own returns before the store has answered. The clock has to be moved
    // past the grace period by hand.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    expect(find.text('No encontramos compras en esta cuenta.'), findsOneWidget);
  });
}
