import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sobra_app/data/catalog_preview_data.dart';
import 'package:sobra_app/models/catalog_entry.dart';
import 'package:sobra_app/screens/collection_screen.dart';
import 'package:sobra_app/state/sobra_store.dart';
import 'package:sobra_app/theme/app_theme.dart';

import 'support/localizations.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<SobraStore> loadStore() =>
      SobraStore.load(now: () => DateTime(2026, 9, 14, 11));

  CatalogEntry entryById(String id) => [
    ...CatalogPreviewData.characters,
    ...CatalogPreviewData.items,
  ].firstWhere((entry) => entry.id == id);

  /// Text inside the open detail dialog.
  ///
  /// Scoped because the card the dialog was opened from is still mounted
  /// behind it, carrying the very same action label.
  Finder inDialog(String text) =>
      find.descendant(of: find.byType(AlertDialog), matching: find.text(text));

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
          home: const CollectionScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  // The screen used to hold ownership in its own State, so what it offered was
  // the same two ids for everybody regardless of what the user had done.
  testWidgets('a granted character is offered for equipping, not for sale', (
    tester,
  ) async {
    final store = await loadStore();
    await store.grantCatalogEntry('character-02');
    await pump(tester, store);

    await tester.tap(find.text('Personaje 2'));
    await tester.pumpAndSettle();

    expect(inDialog('EQUIPAR'), findsOneWidget);
    expect(inDialog('COMPRAR'), findsNothing);
  });

  testWidgets('an unowned character still offers only its purchase', (
    tester,
  ) async {
    final store = await loadStore();
    await pump(tester, store);

    await tester.tap(find.text('Personaje 2'));
    await tester.pumpAndSettle();

    expect(inDialog('COMPRAR'), findsOneWidget);
    expect(inDialog('EQUIPAR'), findsNothing);
  });

  testWidgets('equipping from the dialog is written through to the store', (
    tester,
  ) async {
    final store = await loadStore();
    await store.grantCatalogEntry('character-02');
    await pump(tester, store);
    expect(store.characterId, 'michi');

    await tester.tap(find.text('Personaje 2'));
    await tester.pumpAndSettle();
    await tester.tap(inDialog('EQUIPAR'));
    await tester.pumpAndSettle();

    expect(store.characterId, 'character-02');
    expect(find.text('Personaje 2 quedó seleccionado.'), findsOneWidget);
    // The reason the write matters: a reinstall aside, this used to be gone as
    // soon as the route rebuilt.
    expect((await loadStore()).characterId, 'character-02');
  });

  testWidgets('a stored ad count is what the card counts from', (tester) async {
    final store = await loadStore();
    await store.recordRewardedAdView(entryById('character-03'));

    await pump(tester, store);

    expect(find.text('ANUNCIO 1/3'), findsOneWidget);
    expect(find.text('ANUNCIO 0/3'), findsNWidgets(2));
  });

  testWidgets('an equipped item is remembered across a reload', (tester) async {
    final store = await loadStore();
    await pump(tester, store);

    await tester.tap(find.text('OBJETOS'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Objeto 1'));
    await tester.pumpAndSettle();
    await tester.tap(inDialog('EQUIPAR'));
    await tester.pumpAndSettle();

    expect(store.equippedIdFor(CatalogKind.item), 'item-01');
    expect((await loadStore()).equippedIdFor(CatalogKind.item), 'item-01');
  });
}
