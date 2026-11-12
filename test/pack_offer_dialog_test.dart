import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sobra_app/data/catalog_preview_data.dart';
import 'package:sobra_app/services/purchase_service.dart';
import 'package:sobra_app/state/sobra_store.dart';
import 'package:sobra_app/theme/app_theme.dart';
import 'package:sobra_app/widgets/pack_offer_dialog.dart';

import 'support/fake_purchase_backend.dart';
import 'support/localizations.dart';

void main() {
  late SobraStore store;
  late FakeBackend backend;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    store = await SobraStore.load(now: () => DateTime(2026, 9, 30, 11));
    backend = FakeBackend();
  });

  tearDown(() => backend.close());

  Future<void> pump(WidgetTester tester, {SobraPurchases? purchases}) async {
    tester.view.physicalSize = const Size(412, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    useSpanishDevice(tester);
    Widget app = SobraScope(
      store: store,
      child: MaterialApp(
        localizationsDelegates: sobraLocalizationsDelegates,
        supportedLocales: sobraSupportedLocales,
        theme: buildSobraTheme(),
        home: const Scaffold(body: PackOfferDialog()),
      ),
    );
    if (purchases != null) {
      app = PurchaseScope(purchases: purchases, child: app);
    }
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();
  }

  FilledButton buyButton(WidgetTester tester) =>
      tester.widget<FilledButton>(find.byType(FilledButton));

  testWidgets('shows the three friends and what the pack includes', (
    tester,
  ) async {
    await pump(tester);

    expect(find.text('Los amigos de Michi'), findsOneWidget);
    expect(find.text('Tranqui, Lana y Bandi'), findsOneWidget);
    expect(find.text('3 amigos para tu cuarto'), findsOneWidget);
    expect(find.text('Sin anuncios generales'), findsOneWidget);
    expect(find.text('Pago único, para siempre'), findsOneWidget);
    expect(
      find.image(const AssetImage(PackOfferDialog.illustration)),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  // No made-up price: the one on the button is the one Play will charge.
  testWidgets('waits for the store price before it sells', (tester) async {
    await pump(tester);

    expect(find.text('COMPRAR'), findsOneWidget);
    expect(buyButton(tester).onPressed, isNull);
  });

  testWidgets('quotes the store price on the button', (tester) async {
    backend.catalogue = [
      productFor(CatalogPreviewData.packProductId, r'MX$ 89'),
    ];
    final purchases = SobraPurchases(
      backend: backend,
      store: store,
      restoreOnStart: false,
    );
    addTearDown(purchases.dispose);
    await purchases.start();

    await pump(tester, purchases: purchases);

    expect(find.text(r'COMPRAR · MX$ 89'), findsOneWidget);
    expect(buyButton(tester).onPressed, isNotNull);
  });

  testWidgets('says the pack is owned and sells nothing more', (tester) async {
    await store.grantCatalogEntries(
      CatalogPreviewData.productEntitlements[CatalogPreviewData.packProductId]!,
    );

    await pump(tester);

    expect(find.text('Ya lo tienes'), findsOneWidget);
    expect(buyButton(tester).onPressed, isNull);
  });
}
