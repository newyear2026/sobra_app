import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sobra_app/theme/app_theme.dart';

/// A specimen of the figures, at the sizes money is actually read at.
///
/// The font in `assets/fonts` is a modified Pixelify Sans: its digits are
/// redrawn by `tool/patch_pixelify_digits.py` because the ones upstream ships
/// are not distinguishable from each other at these sizes -- `5` in
/// particular is an S on the same closed frame as `8`. Dropping the upstream
/// file back in, or losing the patch in a font update, brings that back
/// silently and everywhere, and only a rendered figure shows it. That is what
/// this golden is for.
Future<void> _loadGoldenFonts() async {
  final pixelify = FontLoader('PixelifySans')
    ..addFont(rootBundle.load('assets/fonts/PixelifySans.ttf'));
  await pixelify.load();
}

const _pairs = <String>[
  '0123456789',
  // The pairs that used to collapse into each other.
  '5868096',
  '808  888  800',
  r'-$1,205.50 MXN',
  r'$857.14  $6,908.35',
  '0 / 150 XP   Faltan 120 XP',
  '09:35   18:56   v1.0.0',
];

void main() {
  testWidgets('every figure is its own shape at the sizes money is read at', (
    tester,
  ) async {
    await _loadGoldenFonts();
    tester.view.physicalSize = const Size(560, 1120);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: buildSobraTheme(),
        home: Scaffold(
          backgroundColor: AppColors.paper,
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final size in [12.0, 15.0, 24.0])
                  for (final bold in [false, true]) ...[
                    for (final line in _pairs)
                      Text(
                        line,
                        style: pixelText(size: size, bold: bold),
                      ),
                    const SizedBox(height: 6),
                  ],
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('../design/type/sobra-figures.png'),
    );
  });
}
