import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sobra_app/data/catalog_preview_data.dart';
import 'package:sobra_app/screens/collection_screen.dart';
import 'package:sobra_app/screens/settings_screen.dart';
import 'package:sobra_app/services/purchase_service.dart';
import 'package:sobra_app/state/sobra_store.dart';
import 'package:sobra_app/theme/app_theme.dart';
import 'package:sobra_app/widgets/pack_offer_dialog.dart';

import 'support/fake_purchase_backend.dart';
import 'support/localizations.dart';

void main() {
  late SobraStore store;
  late FakeBackend backend;
  late SobraPurchases purchases;

  const productId = 'sobra.character.platypus';

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    store = await SobraStore.load(now: () => DateTime(2026, 9, 14, 11));
    backend = FakeBackend()..catalogue = [productFor(productId, r'MX$ 39')];
    purchases = SobraPurchases(
      backend: backend,
      store: store,
      restoreGrace: const Duration(milliseconds: 40),
      // Long enough to survive the dialog's own animation, which pumpAndSettle
      // advances the clock through, and short enough that the expiry test can
      // step over it without a wait anybody would notice.
      checkoutTimeout: const Duration(seconds: 2),
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

  Future<void> openPico(WidgetTester tester) async {
    await tester.ensureVisible(find.text('Pico'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pico'));
    await tester.pumpAndSettle();
  }

  testWidgets('the card shows the price the store quoted', (tester) async {
    await purchases.start();

    await pump(tester, const CollectionScreen());

    // The preview source prices Bunny the same. Only the one the fake store
    // actually listed may carry a price now.
    expect(find.text(r'MX$ 39'), findsOneWidget);
  });

  testWidgets('buying from the dialog reaches the store and then unlocks', (
    tester,
  ) async {
    await purchases.start();
    await pump(tester, const CollectionScreen());

    await openPico(tester);
    await tester.tap(inDialog('COMPRAR'));
    await tester.pumpAndSettle();

    expect(backend.bought, [productId]);

    backend.emit([detailsFor(productId, PurchaseStatus.purchased)]);
    await tester.pumpAndSettle();

    // The catalog answers for itself once the store confirms — no reload, no
    // second trip through the screen.
    await openPico(tester);
    expect(inDialog('OBTENIDO'), findsOneWidget);
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
    await openPico(tester);
    expect(inDialog('EQUIPAR'), findsNothing);
  });

  // In the real sequence the tap only opens the sheet; the rejection lands on
  // the purchase stream afterwards, with no call left waiting to read it.
  testWidgets('a rejection arriving after the tap still reaches the user', (
    tester,
  ) async {
    await purchases.start();
    await pump(tester, const CollectionScreen());

    await openPico(tester);
    await tester.tap(inDialog('COMPRAR'));
    await tester.pumpAndSettle();
    expect(
      find.text('No se pudo completar la compra. No se te cobró nada.'),
      findsNothing,
    );

    backend.emit([
      detailsFor(productId, PurchaseStatus.error, needsCompleting: false),
    ]);
    await tester.pumpAndSettle();

    expect(
      find.text('No se pudo completar la compra. No se te cobró nada.'),
      findsOneWidget,
    );
  });

  testWidgets('a checkout nothing answers frees the card again', (
    tester,
  ) async {
    await purchases.start();
    await pump(tester, const CollectionScreen());

    await openPico(tester);
    await tester.tap(inDialog('COMPRAR'));
    await tester.pumpAndSettle();
    expect(find.text('COMPRANDO…'), findsOneWidget);

    // The store never answers — a sheet swiped away, or a process killed
    // behind it. Without a deadline the card would say this until restart.
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    expect(find.text('COMPRANDO…'), findsNothing);
    expect(find.text('COMPRAR'), findsWidgets);
  });

  testWidgets('backing out of Play checkout immediately allows another try', (
    tester,
  ) async {
    await purchases.start();
    await pump(tester, const CollectionScreen());

    await openPico(tester);
    await tester.tap(inDialog('COMPRAR'));
    await tester.pumpAndSettle();
    expect(find.text('COMPRANDO…'), findsOneWidget);

    // This is the cancellation shape emitted by the Android plugin when the
    // user presses back: there is no purchase from which to get a product id.
    backend.emit([
      detailsFor('', PurchaseStatus.canceled, needsCompleting: false),
    ]);
    await tester.pumpAndSettle();

    expect(find.text('COMPRANDO…'), findsNothing);
    expect(find.byType(SnackBar), findsNothing);
    expect(store.ownedCatalogIds, isEmpty);

    await openPico(tester);
    await tester.tap(inDialog('COMPRAR'));
    await tester.pumpAndSettle();
    expect(backend.bought, [productId, productId]);

    backend.emit([detailsFor(productId, PurchaseStatus.purchased)]);
    await tester.pumpAndSettle();
    expect(purchases.isBusy, isFalse);
    expect(store.ownedCatalogIds, {'platypus'});
  });

  testWidgets('an unreachable store leaves the catalog usable', (tester) async {
    backend.available = false;
    await purchases.start();

    await pump(tester, const CollectionScreen());

    expect(find.text('Tranqui'), findsOneWidget);
    expect(find.text(r'MX$ 39'), findsNothing);
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

    expect(store.ownedCatalogIds, {'platypus'});
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

  testWidgets('Ajustes shows the pack before selling it', (tester) async {
    backend.catalogue = [
      ...backend.catalogue,
      productFor(CatalogPreviewData.packProductId, r'MX$ 149'),
    ];
    await purchases.start();
    await pump(tester, const SettingsScreen(), inScaffold: true);

    expect(find.text('Quitar anuncios generales'), findsNothing);
    expect(find.text('Los amigos de Michi'), findsOneWidget);
    expect(find.text(r'MX$ 149'), findsOneWidget);

    // The row opens the pack, not the checkout: nothing is charged for a
    // look at what it holds.
    await tester.tap(find.text('Los amigos de Michi'));
    await tester.pumpAndSettle();
    expect(backend.bought, isEmpty);
    expect(find.byType(PackOfferDialog), findsOneWidget);
    expect(find.text('Tranqui, Lana y Bandi'), findsOneWidget);
    expect(find.text('Sin anuncios generales'), findsOneWidget);

    await tester.tap(find.text(r'COMPRAR · MX$ 149'));
    await tester.pumpAndSettle();
    expect(backend.bought, [CatalogPreviewData.packProductId]);

    backend.emit([
      detailsFor(CatalogPreviewData.packProductId, PurchaseStatus.purchased),
    ]);
    await tester.pumpAndSettle();

    expect(store.ownsNoAds, isTrue);
    expect(store.ownsPack, isTrue);
    expect(find.text('Ya lo tienes'), findsOneWidget);
  });

  testWidgets('closing the pack buys nothing', (tester) async {
    backend.catalogue = [
      ...backend.catalogue,
      productFor(CatalogPreviewData.packProductId, r'MX$ 89'),
    ];
    await purchases.start();
    await pump(tester, const SettingsScreen(), inScaffold: true);

    await tester.tap(find.text('Los amigos de Michi'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(find.byType(PackOfferDialog), findsNothing);
    expect(backend.bought, isEmpty);
  });

  // A friend's card leads to the pack as well as to its own price.
  testWidgets('a pack friend opens the pack and buys it', (tester) async {
    backend.catalogue = [
      ...backend.catalogue,
      productFor(CatalogPreviewData.packProductId, r'MX$ 89'),
    ];
    await purchases.start();
    await pump(tester, const CollectionScreen());

    await tester.ensureVisible(find.text('Lana'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lana'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('También viene en Los amigos de Michi'));
    await tester.pumpAndSettle();
    expect(find.byType(PackOfferDialog), findsOneWidget);

    await tester.tap(find.text(r'COMPRAR · MX$ 89'));
    await tester.pumpAndSettle();
    expect(backend.bought, [CatalogPreviewData.packProductId]);

    backend.emit([
      detailsFor(CatalogPreviewData.packProductId, PurchaseStatus.purchased),
    ]);
    await tester.pumpAndSettle();

    expect(store.ownsPack, isTrue);
  });

  // Play refunds no overlap, so the dialog says what is already owned before
  // anything is charged.
  testWidgets('the pack names the friends already bought', (tester) async {
    backend.catalogue = [
      ...backend.catalogue,
      productFor(CatalogPreviewData.packProductId, r'MX$ 89'),
    ];
    await store.grantCatalogEntry('alpaca');
    await purchases.start();
    await pump(tester, const SettingsScreen(), inScaffold: true);

    await tester.tap(find.text('Los amigos de Michi'));
    await tester.pumpAndSettle();

    expect(
      find.text('Ya tienes a Lana. El paquete cuesta lo mismo.'),
      findsOneWidget,
    );
  });
}
