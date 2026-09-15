import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sobra_app/theme/app_theme.dart';
import 'package:sobra_app/widgets/cat_sprite.dart';
import 'package:sobra_app/widgets/character_room.dart';
import 'package:sobra_app/widgets/gamification_ui.dart';
import 'package:sobra_app/widgets/pixel_ui.dart';

import 'support/localizations.dart';

/// Design proposals only: where the daily mission could live on Inicio.
/// Renders two goldens under `design/missions/`.
Future<void> _loadGoldenFonts() async {
  final pixelify = FontLoader('PixelifySans')
    ..addFont(rootBundle.load('assets/fonts/PixelifySans.ttf'));
  final materialIcons = FontLoader('MaterialIcons')
    ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
  await Future.wait([pixelify.load(), materialIcons.load()]);
}

Widget _harness(Widget child) => MaterialApp(
  localizationsDelegates: sobraLocalizationsDelegates,
  supportedLocales: sobraSupportedLocales,
  theme: buildSobraTheme(),
  home: child,
);

enum _Placement { underLevelStrip, atCharacterRoom }

class _MissionCard extends StatelessWidget {
  const _MissionCard();

  @override
  Widget build(BuildContext context) {
    return PixelCard(
      elevation: PixelElevation.none,
      color: AppColors.paperLight,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.ink, width: 2.5),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Misión de hoy',
                  style: pixelText(size: 10, bold: true, color: AppColors.muted),
                ),
                Text(
                  'Registra un movimiento hoy',
                  style: pixelText(size: 13, bold: true),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.ink, width: 2),
            ),
            child: Text(
              '+10 XP',
              style: pixelText(size: 11, bold: true, color: AppColors.tealInk),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeMock extends StatelessWidget {
  const _HomeMock({required this.placement});

  final _Placement placement;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Sobrita', style: pixelText(size: 19, bold: true)),
                ),
                const Icon(Icons.settings, size: 28, color: AppColors.ink),
              ],
            ),
            const SizedBox(height: 18),
            Text('Hoy te queda', style: textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(
              '\$182.50',
              style: textTheme.displayLarge?.copyWith(color: AppColors.teal),
            ),
            const SizedBox(height: 6),
            Text(
              'Límite de hoy \$200.00 · Quedan \$3,650.00 en el ciclo',
              style: textTheme.bodySmall?.copyWith(color: AppColors.muted),
            ),
            const SizedBox(height: 18),
            const LevelStrip(
              level: 2,
              title: 'Michi ahorrador',
              subtitle: '320 XP totales',
              currentXp: 170,
              targetXp: 300,
              trailingLabel: 'Faltan 130 XP',
            ),
            if (placement == _Placement.underLevelStrip) ...[
              const SizedBox(height: 8),
              const _MissionCard(),
            ],
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Avance del ciclo', style: textTheme.titleSmall),
                Text('Quedan 9 días', style: textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 8),
            const SegmentedProgress(value: .42),
            const SizedBox(height: 18),
            PixelCard(
              elevation: PixelElevation.hero,
              color: AppColors.cashSoft,
              borderColor: AppColors.cashInk,
              child: Row(
                children: [
                  const Icon(
                    Icons.account_balance_wallet,
                    color: AppColors.cashInk,
                    size: 34,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Efectivo estimado',
                          style: pixelText(
                            size: 13,
                            bold: true,
                            color: AppColors.cashInk,
                          ),
                        ),
                        Text(
                          '\$1,240.00 MXN',
                          style: pixelText(
                            size: 23,
                            bold: true,
                            color: AppColors.cashInk,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.cashInk),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Movimientos recientes',
                    style: textTheme.titleMedium,
                  ),
                ),
                Text(
                  'Ver todos',
                  style: pixelText(size: 13, bold: true, color: AppColors.teal),
                ),
              ],
            ),
            const SizedBox(height: 6),
            PixelCard(
              elevation: PixelElevation.none,
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              child: Row(
                children: [
                  const Icon(Icons.lunch_dining, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text('Comida', style: pixelText(size: 13)),
                  ),
                  Text('-\$85.00', style: pixelText(size: 13, bold: true)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (placement == _Placement.atCharacterRoom) ...[
              const _MissionCard(),
              const SizedBox(height: 8),
            ],
            CharacterRoom(
              message: placement == _Placement.atCharacterRoom
                  ? '¿Registramos hoy?'
                  : 'Vas muy bien',
              characterBuilder: (width) =>
                  CatSprite(motion: CatMotion.idle, width: width, animate: false),
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  Future<void> render(WidgetTester tester, _Placement placement) async {
    useSpanishDevice(tester);
    tester.view.physicalSize = const Size(520, 1540);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _loadGoldenFonts();

    await tester.pumpWidget(_harness(_HomeMock(placement: placement)));
    await tester.pump();
    final context = tester.element(find.byType(Scaffold));
    await tester.runAsync(
      () => Future.wait([
        precacheImage(CharacterRoom.backgroundProvider(context), context),
        precacheImage(AssetImage(CatMotion.idle.asset), context),
      ]),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
  }

  testWidgets('mission under the level strip', (tester) async {
    await render(tester, _Placement.underLevelStrip);
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile(
        '../design/missions/sobra-mission-placement-a-levelstrip.png',
      ),
    );
  });

  testWidgets('mission next to the character room', (tester) async {
    await render(tester, _Placement.atCharacterRoom);
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile(
        '../design/missions/sobra-mission-placement-b-room.png',
      ),
    );
  });
}
