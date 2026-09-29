import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sobra_app/screens/app_shell.dart';
import 'package:sobra_app/state/sobra_store.dart';
import 'package:sobra_app/theme/app_theme.dart';

import 'support/localizations.dart';

void main() {
  testWidgets('the gift arrives once and opens the decorator', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = await SobraStore.load(now: () => DateTime(2026, 10, 1, 10));
    await store.completeOnboarding();
    tester.view.physicalSize = const Size(520, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      SobraScope(
        store: store,
        child: MaterialApp(
          locale: const Locale('es'),
          localizationsDelegates: sobraLocalizationsDelegates,
          supportedLocales: sobraSupportedLocales,
          theme: buildSobraTheme(),
          home: const AppShell(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('¡Llegó tu regalo de lanzamiento!'), findsOneWidget);
    expect(store.launchGiftNoticePending, isTrue);

    await tester.tap(find.text('Ponerlos en mi casa'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(store.launchGiftNoticePending, isFalse);
    expect(
      find.text('Elige un objeto y toca el lugar donde va.'),
      findsOneWidget,
    );
  });
}
