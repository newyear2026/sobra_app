import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sobra_app/l10n/generated/app_localizations.dart';
import 'package:sobra_app/theme/app_theme.dart';
import 'package:sobra_app/widgets/ledger_export_dialog.dart';
import '../../test/support/localizations.dart';

void main() {
  testWidgets('renders the implemented export picker in Korean', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.runAsync(() async {
      for (final (family, file) in [
        ('PixelifySans', 'assets/fonts/PixelifySans.ttf'),
        ('SobraHangul', 'assets/fonts/SobraHangul.ttf'),
        ('MaterialIcons', 'fonts/MaterialIcons-Regular.otf'),
      ]) {
        await (FontLoader(family)..addFont(rootBundle.load(file))).load();
      }
    });
    final boundaryKey = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: boundaryKey,
        child: MaterialApp(
            debugShowCheckedModeBanner: false,
          locale: const Locale('ko'),
          localizationsDelegates: sobraLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: buildSobraTheme(),
          home: const Scaffold(body: LedgerExportDialog()),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
    await tester.runAsync(() async {
      final boundary =
          boundaryKey.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2);
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      await File(
        'output/csv-export-review-20261109/export-picker-ko.png',
      ).writeAsBytes(png!.buffer.asUint8List());
      image.dispose();
    });
  });
}
