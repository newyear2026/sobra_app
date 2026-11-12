import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sobra_app/l10n/generated/app_localizations.dart';
import 'package:sobra_app/services/ledger_export.dart';
import 'package:sobra_app/theme/app_theme.dart';
import 'package:sobra_app/widgets/ledger_export_dialog.dart';

import 'support/localizations.dart';

void main() {
  testWidgets(
    'both choices fit a small screen with large text in every language',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final locale in AppLocalizations.supportedLocales) {
        await tester.pumpWidget(
          MaterialApp(
            locale: locale,
            localizationsDelegates: sobraLocalizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: buildSobraTheme(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(1.5)),
              child: child!,
            ),
            home: const Scaffold(body: LedgerExportDialog()),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull, reason: locale.toString());
        expect(find.byKey(const Key('ledger-export-csv')), findsOneWidget);
        await tester.ensureVisible(find.byKey(const Key('ledger-export-xlsx')));
        await tester.pump();
        expect(tester.takeException(), isNull, reason: locale.toString());
      }
    },
  );

  testWidgets('a rapid double choice closes only the picker', (tester) async {
    final results = <LedgerExportFormat?>[];
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: sobraLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        theme: buildSobraTheme(),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                results.add(
                  await showDialog<LedgerExportFormat>(
                    context: context,
                    builder: (_) => const LedgerExportDialog(),
                  ),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pump();
    final choose = find.byKey(const Key('ledger-export-xlsx'));
    final onPressed = tester.widget<OutlinedButton>(choose).onPressed!;
    onPressed();
    onPressed();
    await tester.pump(const Duration(milliseconds: 300));
    expect(results, [LedgerExportFormat.xlsx]);
    expect(find.text('Open'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
