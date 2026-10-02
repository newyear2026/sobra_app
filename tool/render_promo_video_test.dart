// Deterministic footage of the real app widgets with isolated demo data.
// flutter test tool/render_promo_video_test.dart --dart-define=PROMO_PREVIEW=true
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sobra_app/main.dart';
import 'package:sobra_app/models/expense_entry.dart';
import 'package:sobra_app/models/pay_schedule.dart';
import 'package:sobra_app/models/room_design.dart';
import 'package:sobra_app/models/room_time_of_day.dart';
import 'package:sobra_app/screens/room_decorate_screen.dart';
import 'package:sobra_app/state/sobra_store.dart';
import 'package:sobra_app/theme/app_theme.dart';
import 'package:sobra_app/widgets/cat_sprite.dart';
import 'package:sobra_app/widgets/room_scene.dart';
import '../test/support/localizations.dart';

const out = 'design/marketing/video-v1';
const preview = bool.fromEnvironment('PROMO_PREVIEW');
final captureKey = GlobalKey();
final editNavigator = GlobalKey<NavigatorState>();
final clock = ValueNotifier<double>(0);
Offset? tapPoint;
double tapTime = -10;
final labels = ValueNotifier<int>(0);
const ink = Color(0xff23463e);

Widget appPage(SobraStore store, Widget page) => SobraScope(
  store: store,
  child: MaterialApp(
    navigatorKey: editNavigator,
    debugShowCheckedModeBanner: false,
    locale: const Locale('es', 'MX'),
    localizationsDelegates: sobraLocalizationsDelegates,
    supportedLocales: sobraSupportedLocales,
    theme: buildSobraTheme(),
    home: page,
  ),
);

Widget room(
  SobraStore store, {
  String character = 'michi',
  bool celebrate = false,
}) => SobraScope(
  store: store,
  child: MaterialApp(
    debugShowCheckedModeBanner: false,
    locale: const Locale('es', 'MX'),
    localizationsDelegates: sobraLocalizationsDelegates,
    supportedLocales: sobraSupportedLocales,
    theme: buildSobraTheme(),
    home: Material(
      child: RoomScene(
        variant: RoomSceneVariant.immersive,
        roomId: store.equippedRoomId,
        placements: store.roomDecorationsFor(),
        timeOfDay: RoomTimeOfDay.day,
        message: 'Vas muy bien',
        characterId: character,
        catMotion: celebrate ? CatMotion.celebrate : CatMotion.idle,
        catLoop: true,
      ),
    ),
  ),
);

class PromoFrame extends StatelessWidget {
  const PromoFrame({
    super.key,
    required this.content,
    this.hero = false,
    this.end = false,
  });
  final Widget content;
  final bool hero;
  final bool end;
  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.ltr,
    child: DefaultTextStyle(
      style: const TextStyle(fontFamily: 'PromoSans', color: ink),
      child: RepaintBoundary(
        key: captureKey,
        child: ColoredBox(
          color: const Color(0xfffaf5e9),
          child: ValueListenableBuilder<int>(
            valueListenable: labels,
            builder: (context, scene, _) {
              final title = [
                'Una compañía\npara tu quincena.',
                'Registra tus gastos.',
                'Hazlo tuyo.',
                'Elige a tu compañero.',
                'Sobrita',
              ][scene];
              final sub = [
                'Un michi. Un presupuesto. Tu espacio.',
                'Un poquito de orden, cada día.',
                'Decora un espacio que se sienta como tú.',
                'Pequeños amigos para tu día a día.',
                'Tu dinero, con un poco de ternura.',
              ][scene];
              return Stack(
                children: [
                  Positioned(
                    right: -62,
                    top: -75,
                    child: Container(
                      width: 220,
                      height: 220,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xffe4eddd),
                      ),
                    ),
                  ),
                  Positioned(
                    left: -65,
                    bottom: -92,
                    child: Container(
                      width: 240,
                      height: 240,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xffefe2ce),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 24,
                    right: 24,
                    top: 22,
                    child: Row(
                      children: [
                        const Icon(Icons.spa_rounded, color: ink, size: 15),
                        const SizedBox(width: 6),
                        Text(
                          'Sobrita',
                          style: pixelText(size: 18, bold: true, color: ink),
                        ),
                        const Spacer(),
                        Text(
                          end ? 'HECHO PARA TU DÍA A DÍA' : 'TU PEQUEÑO RITUAL',
                          style: const TextStyle(
                            fontSize: 8,
                            letterSpacing: 1.3,
                            color: Color(0xff597065),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 24,
                    right: 20,
                    top: end ? 64 : 61,
                    child: Text(
                      title,
                      style: TextStyle(
                        fontFamily: end ? 'PixelifySans' : 'PromoBold',
                        fontSize: end
                            ? 50
                            : hero
                            ? 31
                            : 26,
                        fontVariations: AppType.bold,
                        height: 1.03,
                        letterSpacing: -.7,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 24,
                    right: 24,
                    top: end
                        ? 122
                        : hero
                        ? 135
                        : 96,
                    child: Text(
                      sub,
                      style: const TextStyle(
                        fontSize: 11,
                        height: 1.3,
                        color: Color(0xff597065),
                      ),
                    ),
                  ),
                  Positioned(
                    left: hero || end ? 20 : 72,
                    right: hero || end ? 20 : 72,
                    top: end
                        ? 164
                        : hero
                        ? 168
                        : 123,
                    bottom: end ? 98 : 54,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(17),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x16344a39),
                            blurRadius: 18,
                            offset: Offset(0, 7),
                          ),
                        ],
                        border: Border.all(
                          color: const Color(0xffd6dfcb),
                          width: 1.2,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: LayoutBuilder(
                          builder: (context, c) => FittedBox(
                            fit: BoxFit.fill,
                            child: SizedBox(
                              width: hero || end ? 360 : 390,
                              height:
                                  (hero || end ? 360 : 390) *
                                  c.maxHeight /
                                  c.maxWidth,
                              child: MediaQuery(
                                data: MediaQueryData(
                                  size: Size(
                                    hero || end ? 360 : 390,
                                    (hero || end ? 360 : 390) *
                                        c.maxHeight /
                                        c.maxWidth,
                                  ),
                                ),
                                child: content,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: ValueListenableBuilder<double>(
                        valueListenable: clock,
                        builder: (_, t, _) {
                          final age = t - tapTime;
                          if (tapPoint == null || age < 0 || age > .45)
                            return const SizedBox.shrink();
                          final r = 9 + 13 * age / .45;
                          return Stack(
                            children: [
                              Positioned(
                                left: tapPoint!.dx - r,
                                top: tapPoint!.dy - r,
                                child: Container(
                                  width: r * 2,
                                  height: r * 2,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color.fromRGBO(
                                      255,
                                      213,
                                      136,
                                      .25 * (1 - age / .45),
                                    ),
                                    border: Border.all(
                                      color: Color.fromRGBO(
                                        198,
                                        111,
                                        59,
                                        .8 * (1 - age / .45),
                                      ),
                                      width: 1.8,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                  if (end)
                    Positioned(
                      left: 25,
                      right: 25,
                      bottom: 55,
                      child: Text(
                        'Registra. Decora. Acompáñate.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'PromoBold',
                          fontSize: 16,
                        ),
                      ),
                    ),
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 27,
                    child: Text(
                      scene == 3 || end
                          ? 'Algunos personajes son de pago.'
                          : scene == 1
                          ? 'Ejemplo con datos de demostración.'
                          : 'Un presupuesto a tu ritmo.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xff597065),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 24,
                    right: 24,
                    bottom: 12,
                    child: ValueListenableBuilder<double>(
                      valueListenable: clock,
                      builder: (_, t, _) => Row(
                        children: List.generate(
                          5,
                          (i) => Expanded(
                            child: Container(
                              height: 2,
                              margin: EdgeInsets.only(right: i == 4 ? 0 : 5),
                              color: i <= scene
                                  ? const Color(0xff648672)
                                  : const Color(0xffdedfcf),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets(
    'render Sobrita Spanish promotional video',
    (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      useSpanishDevice(tester);
      final pixel = FontLoader('PixelifySans')
        ..addFont(rootBundle.load('assets/fonts/PixelifySans.ttf'));
      final icons = FontLoader('MaterialIcons')
        ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      final sans = FontLoader('PromoSans')
        ..addFont(
          Future.value(
            ByteData.sublistView(
              File(
                '/System/Library/Fonts/Supplemental/Arial.ttf',
              ).readAsBytesSync(),
            ),
          ),
        );
      final bold = FontLoader('PromoBold')
        ..addFont(
          Future.value(
            ByteData.sublistView(
              File(
                '/System/Library/Fonts/Supplemental/Arial Rounded Bold.ttf',
              ).readAsBytesSync(),
            ),
          ),
        );
      await Future.wait([pixel.load(), icons.load(), sans.load(), bold.load()]);
      print('Fonts loaded');
      PaintingBinding.instance.imageCache.maximumSizeBytes = 768 * 1024 * 1024;
      SharedPreferences.setMockInitialValues({});
      final now = DateTime(2026, 10, 8, 10);
      final store = await SobraStore.load(now: () => now);
      await store.configureOnboarding(
        budgetCentavos: 600000,
        schedule: const PaySchedule.semiMonthly(),
        cashCentavos: 150000,
      );
      await store.completeOnboarding();
      await store.takeLaunchGiftNotice();
      await store.saveRoomDecorations({
        ...Map<RoomSlot, String>.of(store.roomDecorationsFor())
          ..remove(RoomSlot.tabletop),
        RoomSlot.floorCabinet: RoomDecorAssets.slimBookcaseId,
        RoomSlot.cabinetTopRight: RoomDecorAssets.defaultTablePlantId,
        RoomSlot.wallLeft: RoomDecorAssets.wallClockId,
      });
      await store.grantCatalogEntries({
        'michi',
        'poodle',
        'capybara',
        'alpaca',
        'raccoon',
      });
      await store.addExpense(
        amountCentavos: 145000,
        category: ExpenseCategory.food,
        note: 'Supermercado',
        occurredAt: now.subtract(const Duration(days: 2)),
        paymentMethod: PaymentMethod.card,
      );
      await store.addExpense(
        amountCentavos: 18000,
        category: ExpenseCategory.transport,
        note: 'Transporte',
        occurredAt: now.subtract(const Duration(days: 1)),
        paymentMethod: PaymentMethod.cash,
      );
      store.takePendingXpNotice();
      var warmed = false;
      final frames = Directory('$out/${preview ? 'preview' : 'frames'}')
        ..createSync(recursive: true);
      int frame = 0;

      Future<void> warm() async {
        await tester.pump();
        if (!warmed)
          await tester.runAsync(() async {
            final manifest = await AssetManifest.loadFromAssetBundle(
              rootBundle,
            );
            final context = tester.element(find.byType(PromoFrame));
            for (final path in manifest.listAssets().where(
              (p) =>
                  (p.startsWith('assets/rooms/') ||
                      (RegExp(
                            r'assets/characters/(michi|poodle|capybara|alpaca|raccoon)/',
                          ).hasMatch(p) &&
                          (p.contains('idle-') ||
                              p.contains('success-') ||
                              p.contains('activity-') ||
                              p.contains('positive-')))) &&
                  (p.endsWith('.png') || p.endsWith('.webp')),
            )) {
              await precacheImage(AssetImage(path), context);
            }
            warmed = true;
          });
        await tester.pump(const Duration(milliseconds: 100));
      }

      Future<void> shot() async {
        final boundary =
            captureKey.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        await tester.runAsync(() async {
          final img = await boundary.toImage(pixelRatio: preview ? 2 : 3);
          final data = await img.toByteData(format: ui.ImageByteFormat.png);
          await File(
            '${frames.path}/${frame.toString().padLeft(5, '0')}.png',
          ).writeAsBytes(data!.buffer.asUint8List());
          img.dispose();
        });
        expect(tester.takeException(), isNull);
      }

      Future<void> record(double seconds) async {
        final n = (seconds * 30).round();
        for (var i = 0; i < n; i++) {
          clock.value = frame / 30;
          await tester.pump(const Duration(microseconds: 33333));
          if (!preview || i == 0 || i == n - 1) await shot();
          frame++;
        }
      }

      Future<void> mount(
        Widget content, {
        bool hero = false,
        bool end = false,
      }) async {
        await tester.pumpWidget(
          PromoFrame(content: content, hero: hero, end: end),
        );
        await warm();
      }

      Future<void> touch(Finder finder) async {
        expect(finder, findsOneWidget);
        tapPoint = tester.getCenter(finder);
        tapTime = frame / 30;
        await tester.tap(finder);
        await tester.pump();
      }

      labels.value = 0;
      await mount(room(store, celebrate: true), hero: true);
      await record(3.5);
      print('Scene 1 rendered: $frame');

      labels.value = 1;
      await mount(SobraApp(store: store));
      await record(.7);
      await touch(find.byIcon(Icons.add));
      await record(.4);
      await tester.enterText(find.byType(TextFormField).first, '8');
      await record(.2);
      await tester.enterText(find.byType(TextFormField).first, '85');
      await record(.6);
      await tester.enterText(find.byType(TextFormField).at(1), 'Café y pan');
      FocusManager.instance.primaryFocus?.unfocus();
      await record(.4);
      await tester.ensureVisible(find.text('Guardar'));
      await record(.4);
      await touch(find.text('Guardar'));
      await record(2.3);
      print('Scene 2 rendered: $frame');

      labels.value = 2;
      await mount(appPage(store, const RoomDecorateScreen()));
      await record(.7);
      await touch(find.text('Sillón de ratán'));
      await record(.4);
      await touch(find.bySemanticsLabel('Piso, lugar 1'));
      await record(.8);
      await touch(find.text('Lámpara de pie'));
      await record(.4);
      await touch(find.bySemanticsLabel('Piso, lugar 2'));
      await record(.7);
      await tester.ensureVisible(find.text('Casa'));
      await touch(find.text('Casa'));
      await record(.3);
      await touch(find.text('Casa jardín'));
      await tester.pump();
      await record(1.2);
      print('Scene 3 rendered: $frame');

      labels.value = 3;
      await tester.ensureVisible(find.text('Personajes'));
      await touch(find.text('Personajes'));
      await record(.8);
      await touch(find.text('Miru'));
      await record(.9);
      await tester.ensureVisible(find.text('Tranqui'));
      await touch(find.text('Tranqui'));
      await record(1.1);
      await tester.ensureVisible(find.text('Lana'));
      await touch(find.text('Lana'));
      await record(1.2);
      print('Scene 4 rendered: $frame');

      final decor = tester.widget<RoomScene>(find.byType(RoomScene));
      await store.saveRoomSelection(
        roomId: decor.roomId,
        placementsByRoom: {
          decor.roomId: {
            ...decor.placements,
            RoomSlot.floorRight: RoomDecorAssets.floorLampId,
            RoomSlot.floorCabinet: RoomDecorAssets.slimBookcaseId,
            RoomSlot.cabinetTopRight: RoomDecorAssets.defaultTablePlantId,
            RoomSlot.wallLeft: RoomDecorAssets.wallClockId,
          },
        },
      );
      labels.value = 4;
      await mount(room(store, celebrate: true), end: true);
      await record(3);
      print('Done: $frame frames');
      expect(frame, 600);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      store.dispose();
    },
    timeout: const Timeout(Duration(minutes: 15)),
  );
}
