import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sobra_app/main.dart';
import 'package:sobra_app/models/cycle_record.dart';
import 'package:sobra_app/models/expense_entry.dart';
import 'package:sobra_app/models/pay_schedule.dart';
import 'package:sobra_app/models/xp_event.dart';
import 'package:sobra_app/screens/app_shell.dart';
import 'package:sobra_app/screens/budget_screen.dart';
import 'package:sobra_app/screens/collection_screen.dart';
import 'package:sobra_app/screens/daily_mission_screen.dart';
import 'package:sobra_app/screens/home_screen.dart';
import 'package:sobra_app/screens/settlement_screen.dart';
import 'package:sobra_app/state/sobra_store.dart';
import 'package:sobra_app/theme/app_theme.dart';
import 'package:sobra_app/widgets/gamification_ui.dart';
import 'package:sobra_app/widgets/pixel_ui.dart';
import 'package:sobra_app/widgets/sobra_native_ad.dart';

import 'support/localizations.dart';

/// Design proposals only: four more places an ad could go (2026-11-09).
/// Real screens are photographed as they are today; each proposed piece is
/// photographed on its own, and `design/ads/expansion/compose.py` stitches
/// the piece into the screen at the anchor written to `raw/anchors.json`.
/// Nothing here is wired to the app.
const _out = 'design/ads/expansion/raw';
const _width = 412.0;
const _dpr = 2.0;
final _anchors = <String, Object>{};

Future<void> _loadFonts() async {
  final pixelify = FontLoader('PixelifySans')
    ..addFont(rootBundle.load('assets/fonts/PixelifySans.ttf'));
  final materialIcons = FontLoader('MaterialIcons')
    ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
  await Future.wait([pixelify.load(), materialIcons.load()]);
}

void _tall(WidgetTester tester, {double height = 1600}) {
  useSpanishDevice(tester);
  tester.view.physicalSize = Size(_width * _dpr, height * _dpr);
  tester.view.devicePixelRatio = _dpr;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<SobraStore> _store({int expenses = 4}) async {
  SharedPreferences.setMockInitialValues({});
  final now = DateTime(2026, 11, 9, 18);
  final store = await SobraStore.load(now: () => now);
  await store.configureOnboarding(
    budgetCentavos: 600000,
    schedule: const PaySchedule.semiMonthly(),
    cashCentavos: 124000,
  );
  await store.completeOnboarding();
  const categories = ExpenseCategory.values;
  for (var i = 0; i < expenses; i++) {
    await store.addExpense(
      amountCentavos: 4500 + (i * 1800),
      category: categories[i % categories.length],
      note: 'Gasto ${i + 1}',
      occurredAt: DateTime(2026, 11, 9 - (i ~/ 2), 9 + i),
      paymentMethod: i.isEven ? PaymentMethod.cash : PaymentMethod.card,
    );
  }
  store.takePendingXpNotice();
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

double _maxBottom(Finder finder) {
  var bottom = 0.0;
  for (final element in finder.evaluate()) {
    final box = element.renderObject! as RenderBox;
    final rect = box.localToGlobal(Offset.zero) & box.size;
    if (rect.bottom > bottom) bottom = rect.bottom;
  }
  return bottom;
}

Future<void> _precacheAll(WidgetTester tester) async {
  for (var pass = 0; pass < 3; pass++) {
    final context = tester.element(find.byType(Scaffold).first);
    final providers = [
      for (final image in tester.widgetList<Image>(find.byType(Image)))
        image.image,
    ];
    await tester.runAsync(
      () => Future.wait(providers.map((p) => precacheImage(p, context))),
    );
    await tester.pumpAndSettle();
  }
}

/// Google's small native template drawn with Sobra tokens, as in
/// `native_ad_placement_test.dart`.
class _SampleNativeBody extends StatelessWidget {
  const _SampleNativeBody();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.tealSoft,
              border: Border.all(color: AppColors.ink, width: 2),
            ),
            child: const Icon(Icons.savings_outlined, color: AppColors.tealInk),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'ANUNCIO',
                  style: pixelText(
                    size: 10,
                    bold: true,
                    color: AppColors.muted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'App de ahorro para tu quincena',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: pixelText(size: 13, bold: true),
                ),
                Text(
                  'Ejemplo de red',
                  style: pixelText(size: 11, color: AppColors.inkSoft),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: const BoxDecoration(color: AppColors.teal),
            child: Text(
              'INSTALAR',
              style: pixelText(size: 11, bold: true, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _IconTile extends StatelessWidget {
  const _IconTile({required this.child, required this.color});

  final Widget child;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 46,
    height: 46,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: color.withValues(alpha: .13),
      border: Border.all(color: AppColors.ink, width: 2.5),
    ),
    child: child,
  );
}

/// 1 — opt-in rewarded boost under today's missions.
class _MissionBoostCard extends StatelessWidget {
  const _MissionBoostCard();

  @override
  Widget build(BuildContext context) {
    return PixelCard(
      color: AppColors.violetSoft,
      borderColor: AppColors.violet,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _IconTile(
                color: AppColors.violet,
                child: Text(
                  'x2',
                  style: pixelText(
                    size: 18,
                    bold: true,
                    color: AppColors.violet,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Duplica tus XP de hoy',
                      style: pixelText(size: 15, bold: true),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Ya ganaste +25 XP. Mira un anuncio corto y recibe +25 más.',
                      style: pixelText(size: 13, color: AppColors.inkSoft),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          PixelButton(
            label: 'VER ANUNCIO · +25 XP',
            icon: Icons.play_circle_outline,
            color: AppColors.violet,
            onPressed: () {},
          ),
          const SizedBox(height: 6),
          Text(
            'Opcional · una vez al día',
            textAlign: TextAlign.center,
            style: pixelText(size: 12, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

/// 2 — a rotating "item of the week" at the top of Colección.
class _WeeklyItemCard extends StatelessWidget {
  const _WeeklyItemCard({required this.image});

  final ImageProvider image;

  @override
  Widget build(BuildContext context) {
    return PixelCard(
      color: AppColors.cashSoft,
      borderColor: AppColors.cashInk,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.paperLight,
              border: Border.all(color: AppColors.ink, width: 2.5),
            ),
            child: Image(
              image: image,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.none,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PixelTag(
                  label: 'DE LA SEMANA',
                  color: AppColors.surface,
                  ink: AppColors.cashInk,
                ),
                const SizedBox(height: 6),
                Text('Puf terracota', style: pixelText(size: 15, bold: true)),
                const SizedBox(height: 2),
                Text(
                  'Quedan 4 días · 1 anuncio',
                  style: pixelText(size: 13, color: AppColors.inkSoft),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          PixelButton(
            label: 'VER',
            icon: Icons.play_circle_outline,
            expand: false,
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}

Future<void> _element(
  WidgetTester tester,
  String name,
  Widget child, {
  EdgeInsets padding = const EdgeInsets.symmetric(horizontal: 20),
}) async {
  _tall(tester, height: 600);
  final key = GlobalKey();
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: sobraLocalizationsDelegates,
      supportedLocales: sobraSupportedLocales,
      theme: buildSobraTheme(),
      home: Scaffold(
        backgroundColor: AppColors.surface,
        body: SingleChildScrollView(
          child: RepaintBoundary(
            key: key,
            child: Container(
              width: _width,
              color: AppColors.surface,
              padding: padding,
              child: child,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await expectLater(
    find.byKey(key),
    matchesGoldenFile('../$_out/el-$name.png'),
  );
}

void main() {
  setUpAll(_loadFonts);
  tearDownAll(() {
    File(
      '$_out/anchors.json',
    ).writeAsStringSync(const JsonEncoder.withIndent('  ').convert(_anchors));
  });

  testWidgets('1 · Misiones de hoy', (tester) async {
    _tall(tester);
    final store = await _store();
    await tester.pumpWidget(_harness(store, const DailyMissionScreen()));
    await tester.pumpAndSettle();
    await _precacheAll(tester);
    _anchors['missions'] = {
      'insertAt': _maxBottom(find.byType(MissionCard)),
      'gapBefore': 14,
      'nav': 0,
    };
    await expectLater(
      find.byType(Scaffold).first,
      matchesGoldenFile('../$_out/screen-missions.png'),
    );
  });

  testWidgets('1 · boost card', (tester) async {
    await _element(
      tester,
      'missions',
      const Padding(
        padding: EdgeInsets.only(top: 14),
        child: _MissionBoostCard(),
      ),
    );
  });

  testWidgets('2 · Colección', (tester) async {
    _tall(tester, height: 1100);
    final store = await _store();
    await tester.pumpWidget(
      _harness(
        store,
        const CollectionScreen(origin: CollectionOrigin.settings),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('OBJETOS'));
    await tester.pumpAndSettle();
    await _precacheAll(tester);
    final tabs = find.byWidgetPredicate(
      (w) => w.runtimeType.toString() == '_CatalogTabs',
    );
    _anchors['collection'] = {'insertAt': tester.getRect(tabs).top, 'nav': 0};
    await expectLater(
      find.byType(Scaffold).first,
      matchesGoldenFile('../$_out/screen-collection.png'),
    );
  });

  testWidgets('2 · weekly item card', (tester) async {
    final image = MemoryImage(
      File('assets/rooms/shared_items/terracotta_pouf.webp').readAsBytesSync(),
    );
    await tester.runAsync(() async {
      final completer = image.resolve(ImageConfiguration.empty);
      final done = <bool>[];
      completer.addListener(
        ImageStreamListener(
          (_, _) => done.add(true),
          onError: (_, _) {
            done.add(false);
          },
        ),
      );
      while (done.isEmpty) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
    });
    await _element(
      tester,
      'collection',
      Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: _WeeklyItemCard(image: image),
      ),
    );
  });

  testWidgets('3 · Presupuesto tab', (tester) async {
    _tall(tester, height: 2300);
    final store = await _store(expenses: 8);
    await tester.pumpWidget(SobraApp(store: store));
    await tester.pumpAndSettle();
    AppShellScope.of(
      tester.element(find.byType(HomeScreen)),
    ).select(AppTab.budget);
    await tester.pumpAndSettle();
    await _precacheAll(tester);
    final budget = find.byType(BudgetScreen);
    _anchors['budget'] = {
      'insertAt': _maxBottom(
        find.descendant(of: budget, matching: find.byType(PixelCard)),
      ),
      'nav': tester.getRect(find.byType(PixelBottomNavigation)).height,
    };
    await expectLater(
      find.byType(Scaffold).first,
      matchesGoldenFile('../$_out/screen-budget.png'),
    );
  });

  testWidgets('3/4 · native card', (tester) async {
    await _element(
      tester,
      'native',
      const NativeAdFrame(child: _SampleNativeBody()),
    );
  });

  testWidgets('4 · Cierre del ciclo', (tester) async {
    _tall(tester);
    final store = await _store();
    final record = CycleRecord(
      start: DateTime(2026, 10, 16),
      end: DateTime(2026, 10, 31),
      budgetCentavos: 600000,
      spentCentavos: 512000,
      cycleType: PayCycleType.semiMonthly,
    );
    const notice = XpNotice(
      kind: XpNoticeKind.cyclesClosed,
      xp: 130,
      closedCycles: 1,
    );
    await tester.pumpWidget(
      _harness(store, SettlementScreen(notice: notice, record: record)),
    );
    await tester.pumpAndSettle();
    await _precacheAll(tester);
    _anchors['settlement'] = {
      'insertAt': _maxBottom(find.byType(PixelCard)),
      'nav': 0,
    };
    await expectLater(
      find.byType(Scaffold).first,
      matchesGoldenFile('../$_out/screen-settlement.png'),
    );
  });
}
