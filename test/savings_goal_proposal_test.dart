import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sobra_app/models/pay_schedule.dart';
import 'package:sobra_app/state/sobra_store.dart';
import 'package:sobra_app/models/room_design.dart';
import 'package:sobra_app/models/room_time_of_day.dart';
import 'package:sobra_app/theme/app_theme.dart';
import 'package:sobra_app/widgets/cat_sprite.dart';
import 'package:sobra_app/widgets/pixel_ui.dart';
import 'package:sobra_app/widgets/room_scene.dart';

import 'support/localizations.dart';

/// Design proposals only: the savings goal ("Mi meta") in docs/savings-goal.md.
/// Renders goldens under `design/savings-goal/`. Nothing here is wired to the
/// store; every figure is a fixed example.
Future<void> _loadGoldenFonts() async {
  final pixelify = FontLoader('PixelifySans')
    ..addFont(rootBundle.load('assets/fonts/PixelifySans.ttf'));
  final materialIcons = FontLoader('MaterialIcons')
    ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
  await Future.wait([pixelify.load(), materialIcons.load()]);
}

const _jarDir = 'design/savings-goal/jar-stages';
final _jarImages = <int, MemoryImage>{};
MemoryImage _jar(int percent) => _jarImages.putIfAbsent(
  percent,
  () => MemoryImage(File('$_jarDir/jar-$percent.png').readAsBytesSync()),
);

const _placements = <RoomSlot, String>{
  RoomSlot.rug: RoomDecorAssets.defaultRugId,
  RoomSlot.floorRight: RoomDecorAssets.roundSideTableId,
  RoomSlot.sideTableTop: RoomDecorAssets.savingsJarId,
};

Future<SobraStore> _buildStore() async {
  SharedPreferences.setMockInitialValues({});
  final store = await SobraStore.load(now: () => DateTime(2026, 11, 8, 10));
  await store.configureOnboarding(
    budgetCentavos: 600000,
    schedule: const PaySchedule.semiMonthly(),
    cashCentavos: 124000,
  );
  await store.completeOnboarding();
  await store.setReducedMotion(true);
  return store;
}

Widget _harness(SobraStore store, Widget child) => SobraScope(
  store: store,
  child: MaterialApp(
    debugShowCheckedModeBanner: false,
    localizationsDelegates: sobraLocalizationsDelegates,
    supportedLocales: sobraSupportedLocales,
    theme: buildSobraTheme(),
    home: child,
  ),
);

class _JarThumb extends StatelessWidget {
  const _JarThumb({required this.percent, this.width = 46});

  final int percent;
  final double width;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: Image(
      image: _jar(percent),
      fit: BoxFit.contain,
      filterQuality: FilterQuality.none,
    ),
  );
}

/// The proposed Inicio card, under the cycle projection.
class _GoalCard extends StatelessWidget {
  const _GoalCard();

  @override
  Widget build(BuildContext context) {
    return PixelCard(
      color: AppColors.paperLight,
      padding: const EdgeInsets.fromLTRB(10, 10, 8, 10),
      onTap: () {},
      child: Row(
        children: [
          const _JarThumb(percent: 50, width: 48),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Mi meta · Viaje a Oaxaca',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: pixelText(size: 14, bold: true),
                      ),
                    ),
                    Text(
                      '37%',
                      style: pixelText(
                        size: 14,
                        bold: true,
                        color: AppColors.tealInk,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const SegmentedProgress(value: .37),
                const SizedBox(height: 6),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '\$1,850',
                        style: pixelText(size: 13, bold: true),
                      ),
                      TextSpan(
                        text: ' de \$5,000',
                        style: pixelText(size: 13, color: AppColors.inkSoft),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Hasta el 15 mar: \$350 por quincena',
                  style: pixelText(size: 12, color: AppColors.cashInk),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.ink),
        ],
      ),
    );
  }
}

/// What Inicio shows before there is a goal.
class _GoalEmptyCard extends StatelessWidget {
  const _GoalEmptyCard();

  @override
  Widget build(BuildContext context) {
    return PixelCard(
      color: AppColors.paperLight,
      elevation: PixelElevation.none,
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      onTap: () {},
      child: Row(
        children: [
          const _JarThumb(percent: 0, width: 40),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¿Para qué estás ahorrando?',
                  style: pixelText(size: 14, bold: true),
                ),
                const SizedBox(height: 2),
                Text(
                  'Ponle nombre y mira cómo se llena el frasco.',
                  style: pixelText(size: 12, color: AppColors.inkSoft),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'Crear',
            style: pixelText(size: 13, bold: true, color: AppColors.tealInk),
          ),
          const Icon(Icons.chevron_right, color: AppColors.ink),
        ],
      ),
    );
  }
}

class _HomeMock extends StatelessWidget {
  const _HomeMock({required this.hasGoal});

  final bool hasGoal;

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
                  child: Text(
                    'Sobrita',
                    style: pixelText(size: 19, bold: true),
                  ),
                ),
                const Icon(Icons.settings, size: 28, color: AppColors.ink),
              ],
            ),
            const SizedBox(height: 18),
            Text('Hoy te queda', style: textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(
              '\$412.50 MXN',
              style: textTheme.displayLarge?.copyWith(color: AppColors.teal),
            ),
            const SizedBox(height: 6),
            Text(
              'Límite de hoy \$450 · Quedan \$3,650 en el ciclo',
              style: textTheme.bodySmall?.copyWith(color: AppColors.muted),
            ),
            const SizedBox(height: 14),
            PixelCard(
              elevation: PixelElevation.none,
              color: AppColors.cashSoft,
              borderColor: AppColors.cashInk,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              child: Row(
                children: [
                  const Icon(Icons.savings_outlined, color: AppColors.cashInk),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'A este ritmo, al cierre del 15 nov',
                          style: pixelText(size: 12, color: AppColors.cashInk),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'te sobran \$980',
                          style: pixelText(
                            size: 16,
                            bold: true,
                            color: AppColors.tealInk,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.cashInk),
                ],
              ),
            ),
            const SizedBox(height: 10),
            if (hasGoal) const _GoalCard() else const _GoalEmptyCard(),
            const SizedBox(height: 14),
            PixelCard(
              padding: EdgeInsets.zero,
              elevation: PixelElevation.none,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.home, color: AppColors.ink, size: 24),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Mi casa',
                            style: pixelText(size: 16, bold: true),
                          ),
                        ),
                        Text(
                          'Decorar',
                          style: pixelText(
                            size: 13,
                            bold: true,
                            color: AppColors.tealInk,
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: AppColors.ink),
                      ],
                    ),
                  ),
                  const Divider(
                    height: 2.5,
                    thickness: 2.5,
                    color: AppColors.ink,
                  ),
                  AspectRatio(
                    aspectRatio: 1,
                    child: DecoratedBox(
                      position: DecorationPosition.foreground,
                      decoration: const BoxDecoration(
                        border: Border(
                          left: BorderSide(color: AppColors.ink, width: 2.5),
                          right: BorderSide(color: AppColors.ink, width: 2.5),
                          bottom: BorderSide(color: AppColors.ink, width: 2.5),
                        ),
                      ),
                      child: RoomScene(
                        variant: RoomSceneVariant.preview,
                        animateItems: false,
                        placements: _placements,
                        message: hasGoal ? 'Ya llevas 37%' : 'Vas muy bien',
                        catMotion: CatMotion.idle,
                        catLoop: false,
                        timeOfDay: RoomTimeOfDay.day,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AmountLine extends StatelessWidget {
  const _AmountLine(this.label, this.value, {this.emphasize = false});

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          label,
          style: pixelText(size: 13, color: AppColors.inkSoft),
        ),
      ),
      Text(
        value,
        style: pixelText(
          size: emphasize ? 17 : 14,
          bold: true,
          color: emphasize ? AppColors.tealInk : AppColors.ink,
        ),
      ),
    ],
  );
}

class _SettlementMock extends StatelessWidget {
  const _SettlementMock();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
          children: [
            PixelTopBar(title: 'Cierre de este ciclo', onBack: () {}),
            const SizedBox(height: 18),
            PixelCard(
              elevation: PixelElevation.hero,
              color: AppColors.tealSoft,
              borderColor: AppColors.tealInk,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Ciclo cerrado', style: pixelText(size: 18, bold: true)),
                  const SizedBox(height: 6),
                  Text(
                    '1 – 15 nov',
                    style: pixelText(size: 13, color: AppColors.inkSoft),
                  ),
                  const SizedBox(height: 14),
                  const _AmountLine('Gastado', '\$4,760.00'),
                  const SizedBox(height: 8),
                  const _AmountLine('Sobrante', '\$1,240.00', emphasize: true),
                  const SizedBox(height: 8),
                  const _AmountLine('Promedio diario', '\$317.00'),
                  const SizedBox(height: 12),
                  Text(
                    '+40 XP',
                    style: pixelText(
                      size: 16,
                      bold: true,
                      color: AppColors.tealInk,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            // The proposal: the leftover becomes the goal, right here.
            PixelCard(
              elevation: PixelElevation.hero,
              color: AppColors.cashSoft,
              borderColor: AppColors.cashInk,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const _JarThumb(percent: 75, width: 54),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Mi meta · Viaje a Oaxaca',
                              style: pixelText(
                                size: 14,
                                bold: true,
                                color: AppColors.cashInk,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  '37%',
                                  style: pixelText(
                                    size: 15,
                                    color: AppColors.inkSoft,
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 4),
                                  child: Icon(
                                    Icons.arrow_forward,
                                    size: 16,
                                    color: AppColors.tealInk,
                                  ),
                                ),
                                Text(
                                  '62%',
                                  style: pixelText(
                                    size: 18,
                                    bold: true,
                                    color: AppColors.tealInk,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            const SegmentedProgress(value: .62),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  PixelButton(
                    label: 'Mandar \$1,240 a tu meta',
                    icon: Icons.savings_outlined,
                    onPressed: () {},
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: Text(
                      'Elegir otro monto',
                      style: pixelText(
                        size: 13,
                        bold: true,
                        color: AppColors.cashInk,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            PixelCard(
              color: AppColors.paperLight,
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome, color: AppColors.violet),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Text(
                      'Ir por un adorno especial',
                      style: pixelText(size: 15, bold: true),
                    ),
                  ),
                  Text(
                    'Ver colección',
                    style: pixelText(
                      size: 13,
                      bold: true,
                      color: AppColors.muted,
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.ink),
                ],
              ),
            ),
            const SizedBox(height: 20),
            PixelButton(
              label: 'Listo',
              variant: PixelButtonVariant.secondary,
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateSheetMock extends StatelessWidget {
  const _CreateSheetMock();

  Widget _field(String label, String value, {IconData? icon}) => TextField(
    controller: TextEditingController(text: value),
    style: pixelText(size: 16, bold: true),
    decoration: InputDecoration(
      labelText: label,
      floatingLabelBehavior: FloatingLabelBehavior.always,
      suffixIcon: icon == null ? null : Icon(icon, color: AppColors.ink),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Stack(
        children: [
          const _HomeMock(hasGoal: false),
          ColoredBox(
            color: AppColors.ink.withValues(alpha: .55),
            child: const SizedBox.expand(),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  top: BorderSide(color: AppColors.ink, width: 2.5),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const _JarThumb(percent: 0, width: 38),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Ponerme una meta',
                            style: pixelText(size: 20, bold: true),
                          ),
                        ),
                        const Icon(Icons.close, color: AppColors.ink, size: 26),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _field('¿Para qué ahorras?', 'Viaje a Oaxaca'),
                    const SizedBox(height: 16),
                    _field('¿Cuánto necesitas?', '\$5,000'),
                    const SizedBox(height: 16),
                    _field(
                      '¿Para cuándo? (opcional)',
                      '15 mar 2027',
                      icon: Icons.calendar_today,
                    ),
                    const SizedBox(height: 16),
                    _field('Lo que ya tienes guardado', '\$600'),
                    const SizedBox(height: 14),
                    PixelCard(
                      elevation: PixelElevation.none,
                      color: AppColors.tealSoft,
                      borderColor: AppColors.tealInk,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.flag_outlined,
                            color: AppColors.tealInk,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Para llegar, guarda \$490 por quincena. '
                              'Lo que te sobre al cerrar cada ciclo también cuenta.',
                              style: pixelText(
                                size: 12,
                                color: AppColors.tealInk,
                                height: 1.45,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    PixelButton(label: 'Guardar meta', onPressed: () {}),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _JarStagesMock extends StatelessWidget {
  const _JarStagesMock();

  @override
  Widget build(BuildContext context) {
    const stages = [0, 25, 50, 75, 100];
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'El frasco se llena con tu meta',
              style: pixelText(size: 16, bold: true),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Row(
                children: [
                  for (final percent in stages)
                    Expanded(
                      child: Column(
                        children: [
                          Expanded(
                            child: _JarThumb(percent: percent, width: 110),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            percent == 100 ? '¡Lo lograste!' : '$percent%',
                            style: pixelText(
                              size: 13,
                              bold: true,
                              color: percent == 100
                                  ? AppColors.tealInk
                                  : AppColors.inkSoft,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  Future<void> render(
    WidgetTester tester,
    Widget screen, {
    Size size = const Size(426, 919),
  }) async {
    useSpanishDevice(tester);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _loadGoldenFonts();
    final store = await _buildStore();

    await tester.pumpWidget(_harness(store, screen));
    await tester.pump();
    final context = tester.element(find.byType(Scaffold).first);
    await tester.runAsync(
      () => Future.wait([
        for (final percent in const [0, 25, 50, 75, 100])
          precacheImage(_jar(percent), context),
        precacheImage(
          AssetImage(RoomThemes.casaClara.sceneAssetFor(RoomTimeOfDay.day)),
          context,
        ),
        for (final id in _placements.values)
          if (RoomDecorAssets.assetFor(id) case final asset?)
            precacheImage(AssetImage(asset), context),
        precacheImage(AssetImage(CatMotion.idle.asset), context),
      ]),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
  }

  testWidgets('Inicio with a goal', (tester) async {
    await render(tester, const _HomeMock(hasGoal: true));
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('../design/savings-goal/01-inicio-goal.png'),
    );
  });

  testWidgets('Inicio before a goal', (tester) async {
    await render(tester, const _HomeMock(hasGoal: false));
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('../design/savings-goal/02-inicio-empty.png'),
    );
  });

  testWidgets('settlement sends the leftover to the goal', (tester) async {
    await render(tester, const _SettlementMock());
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('../design/savings-goal/03-settlement-pledge.png'),
    );
  });

  testWidgets('creating a goal', (tester) async {
    await render(tester, const _CreateSheetMock());
    await expectLater(
      find.byType(Scaffold).first,
      matchesGoldenFile('../design/savings-goal/04-create-goal.png'),
    );
  });

  testWidgets('jar stages', (tester) async {
    await render(tester, const _JarStagesMock(), size: const Size(640, 260));
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('../design/savings-goal/05-jar-stages.png'),
    );
  });
}
