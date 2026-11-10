import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sobra_app/main.dart';
import 'package:sobra_app/models/currency.dart';
import 'package:sobra_app/models/expense_entry.dart';
import 'package:sobra_app/models/pay_schedule.dart';
import 'package:sobra_app/models/room_design.dart';
import 'package:sobra_app/models/savings_goal.dart';
import 'package:sobra_app/screens/completed_savings_goals_screen.dart';
import 'package:sobra_app/screens/savings_goal_screen.dart';
import 'package:sobra_app/services/goal_product_import.dart';
import 'package:sobra_app/state/sobra_store.dart';
import 'package:sobra_app/theme/app_theme.dart';
import 'package:sobra_app/widgets/cat_sprite.dart';
import 'package:sobra_app/widgets/pixel_ui.dart';
import 'package:sobra_app/widgets/savings_goal_card.dart';

/// Design proposals only, for the three gaps found in the 2026-11-09 review:
/// the target date on the home card, buying the thing with goal money, and
/// the cycle XP that the leftover popup no longer announces.
///
/// The background is the real app (SobraApp over an isolated store). Only the
/// card overlay and the dialogs are mock widgets. Run with:
///   flutter test --dart-define=CAPTURE_GOAL_GAP_UI=true \
///     test/savings_goal_gap_proposal_test.dart
const _capture = bool.fromEnvironment('CAPTURE_GOAL_GAP_UI');
const _captureKey = ValueKey('goal-gap-capture');
const _output = 'output/sobrita-goal-gaps-ko-20261109';

// MXN centavos. A Buen Fin TV: list $8,999, bought on sale for $7,499.
const _target = 899900;
const _starting = 650000;
const _leftover = 120000;
const _salePrice = 749900;
final _targetDate = DateTime(2026, 11, 13);
final _cycleStart = DateTime(2026, 11, 2);
const _goalName = '스마트 TV 55" 4K';

/// Tests cannot fetch the shop photo, so the room's TV art stands in for it.
class _Thumb extends StatelessWidget {
  const _Thumb({this.size = 40});
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    color: AppColors.surface,
    padding: EdgeInsets.all(size * .06),
    child: Image.asset(
      RoomDecorAssets.launchTvBase,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.none,
    ),
  );
}

Future<(SobraStore, int)> _store({
  required bool allocate,
  bool keepNotice = false,
}) async {
  SharedPreferences.setMockInitialValues({});
  var now = DateTime(2026, 11, 2, 10);
  final store = await SobraStore.load(now: () => now);
  await store.setCurrency(Currency.mxn);
  await store.setLanguageCode('ko');
  await store.configureOnboarding(
    budgetCentavos: 300000,
    schedule: const PaySchedule.weekly(weeklyPayDay: DateTime.monday),
    cashCentavos: 300000,
  );
  await store.completeOnboarding();
  await store.grantCatalogEntries({'michi'});
  await store.setReducedMotion(true);
  await store.claimSeasonalCostumes();
  await store.takeLaunchGiftNotice();
  // A goal made from a pasted Mercado Libre link, as the link import saves it.
  await store.saveSavingsGoal(
    kind: SavingsGoalKind.product,
    name: _goalName,
    targetCentavos: _target,
    startingCentavos: _starting,
    targetDate: _targetDate,
    productUrl: 'https://www.mercadolibre.com.mx/smart-tv-55-4k/p/MLM12345678',
    imageUrl: 'https://http2.mlstatic.com/D_NQ_NP_tv-55.webp',
    merchantName: 'Mercado Libre',
  );
  await store.addExpense(
    amountCentavos: 300000 - _leftover,
    category: ExpenseCategory.food,
    note: '',
    occurredAt: now,
    paymentMethod: PaymentMethod.cash,
  );
  now = DateTime(2026, 11, 9, 10);
  await store.settleCycles();
  if (keepNotice) return (store, store.pendingXpNotice?.xp ?? 0);
  final xp = store.takePendingXpNotice()?.xp ?? 0;
  await store.acknowledgeSavingsGoalCyclePrompt(_cycleStart);
  if (allocate) {
    await store.allocateCycleToSavingsGoal(
      cycleStart: _cycleStart,
      goalId: store.activeSavingsGoal!.id,
      amountCentavos: _leftover,
    );
  }
  return (store, xp);
}

Future<void> _loadFonts() async {
  final pixel = FontLoader('PixelifySans')
    ..addFont(rootBundle.load('assets/fonts/PixelifySans.ttf'));
  final korean = FontLoader('SobraHangul')
    ..addFont(rootBundle.load('assets/fonts/SobraHangul.ttf'))
    ..addFont(rootBundle.load('assets/fonts/SobraHangul-Bold.ttf'));
  final icons = FontLoader('MaterialIcons')
    ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
  await Future.wait([pixel.load(), korean.load(), icons.load()]);
}

Future<void> _warmArt(WidgetTester tester) async {
  final context = tester.element(find.byType(Navigator).first);
  final providers = <ImageProvider>[
    // The shipped card's shop photo cannot load offline; it is covered.
    ...tester
        .widgetList<Image>(find.byType(Image))
        .map((image) => image.image)
        .where((provider) => provider is! NetworkImage),
    ...tester
        .widgetList<CharacterSprite>(find.byType(CharacterSprite))
        .map((sprite) => AssetImage(sprite.asset)),
  ];
  await tester.runAsync(() async {
    for (final provider in providers) {
      await precacheImage(provider, context);
    }
  });
  await tester.pumpAndSettle();
}

Future<void> _save(WidgetTester tester, String name) async {
  await _warmArt(tester);
  await tester.runAsync(() async {
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(_captureKey),
    );
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await Directory(_output).create(recursive: true);
    await File('$_output/$name').writeAsBytes(
      bytes!.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
    );
    image.dispose();
  });
}

String _money(int centavos) =>
    formatMoney(Currency.mxn, centavos, showCode: false);

/// Marks what the proposal adds, so it reads apart from the shipped UI.
class _NewTag extends StatelessWidget {
  const _NewTag();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
    color: AppColors.cash,
    child: Text(
      'NEW',
      style: pixelText(size: 12, bold: true, color: AppColors.surface),
    ),
  );
}

/// The shipped card plus one deadline line. Same paddings and colors.
class _CardWithDeadline extends StatelessWidget {
  const _CardWithDeadline({required this.progress});
  final int progress;

  @override
  Widget build(BuildContext context) {
    final ratio = (progress / _target).clamp(0.0, 1.0);
    return PixelCard(
      elevation: PixelElevation.none,
      color: AppColors.tealSoft,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      child: Row(
        children: [
          const _Thumb(),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '내 목표 · $_goalName',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: pixelText(size: 14, bold: true),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${_money(progress)} / ${_money(_target)} MXN',
                        style: pixelText(
                          size: 12,
                          bold: true,
                          color: AppColors.inkSoft,
                        ),
                      ),
                    ),
                    Text(
                      '${(ratio * 100).floor()}%',
                      style: pixelText(
                        size: 12,
                        bold: true,
                        color: AppColors.tealInk,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                LinearProgressIndicator(
                  value: ratio,
                  minHeight: 4,
                  color: AppColors.teal,
                  backgroundColor: AppColors.line,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      color: AppColors.tealInk,
                      child: Text(
                        'D-4',
                        style: pixelText(
                          size: 12,
                          bold: true,
                          color: AppColors.surface,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '11월 13일까지 ${_money(_target - progress)} 더',
                        style: pixelText(
                          size: 12,
                          bold: true,
                          color: AppColors.tealInk,
                        ),
                      ),
                    ),
                    const _NewTag(),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, size: 20),
        ],
      ),
    );
  }
}

/// Same frame as the shipped goal dialogs (savings_goal_dialog.dart).
class _Frame extends StatelessWidget {
  const _Frame({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: Colors.transparent,
    alignment: const Alignment(0, -0.4),
    insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320),
      child: PixelCard(
        color: AppColors.surface,
        elevation: PixelElevation.hero,
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(title, style: pixelText(size: 16, bold: true)),
                ),
                IconButton(onPressed: () {}, icon: const Icon(Icons.close)),
              ],
            ),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    ),
  );
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.amount, {this.color = AppColors.ink});
  final String label;
  final String amount;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: Text(label, style: pixelText(size: 14, bold: true))),
      Text(amount, style: pixelText(size: 16, bold: true, color: color)),
    ],
  );
}

class _Field extends StatelessWidget {
  const _Field(this.label, this.value, {this.icon});
  final String label;
  final String value;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => InputDecorator(
    decoration: InputDecoration(
      labelText: label,
      suffixIcon: icon == null ? null : Icon(icon, size: 20),
    ),
    child: Text(value, style: pixelText(size: 16, bold: true)),
  );
}

/// Gap 2: recording the purchase as goal money, outside the cycle budget.
class _BoughtItDialog extends StatelessWidget {
  const _BoughtItDialog({required this.progress});
  final int progress;

  @override
  Widget build(BuildContext context) => _Frame(
    title: '목표로 샀어요',
    children: [
      Row(
        children: [
          const _Thumb(size: 56),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _goalName,
                  style: pixelText(
                    size: 17,
                    bold: true,
                    color: AppColors.tealInk,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Mercado Libre',
                  style: pixelText(size: 13, color: AppColors.muted),
                ),
              ],
            ),
          ),
          const _NewTag(),
        ],
      ),
      const SizedBox(height: 14),
      _Field('산 금액', _money(_salePrice)),
      const SizedBox(height: 6),
      Row(
        children: [
          const Icon(Icons.refresh, size: 18, color: AppColors.tealInk),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              '링크에서 지금 가격 다시 읽기',
              style: pixelText(size: 13, bold: true, color: AppColors.tealInk),
            ),
          ),
        ],
      ),
      const SizedBox(height: 2),
      Text(
        '목표 저장 때 ${_money(_target)} · 오늘 ${_money(_salePrice)}',
        style: pixelText(size: 13, color: AppColors.muted),
      ),
      const SizedBox(height: 12),
      _Field('결제 수단', '카드', icon: Icons.expand_more),
      const SizedBox(height: 16),
      _Row('목표에 모은 돈', _money(progress)),
      const SizedBox(height: 8),
      _Row('산 금액', '-${_money(_salePrice)}'),
      const Divider(height: 18),
      _Row('남는 돈', _money(progress - _salePrice), color: AppColors.tealInk),
      const SizedBox(height: 14),
      PixelCard(
        elevation: PixelElevation.none,
        color: AppColors.tealSoft,
        borderColor: AppColors.tealInk,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.shield_outlined, color: AppColors.tealInk),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '모아 둔 돈으로 산 거라 오늘 남은 돈과 이번 주기 예산은 그대로예요.',
                style: pixelText(
                  size: 13,
                  color: AppColors.tealInk,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 18),
      PixelButton(label: '기록하고 목표 마무리', maxLines: 2, onPressed: () {}),
      TextButton(onPressed: () {}, child: const Text('남는 돈은 다음 목표로')),
      Text(
        '내역에는 “목표” 표시가 붙은 지출로 남아요.',
        textAlign: TextAlign.center,
        style: pixelText(size: 13, color: AppColors.muted),
      ),
    ],
  );
}

/// Gap 3: the shipped leftover popup, with the cycle XP line restored.
class _CycleCloseWithXp extends StatelessWidget {
  const _CycleCloseWithXp({required this.xp, required this.progress});
  final int xp;
  final int progress;

  @override
  Widget build(BuildContext context) => _Frame(
    title: '이번 주기 마감',
    children: [
      Text(
        '${_money(_leftover)} 남았어요!',
        style: pixelText(size: 22, bold: true, color: AppColors.tealInk),
      ),
      const SizedBox(height: 10),
      PixelCard(
        elevation: PixelElevation.none,
        color: AppColors.cashSoft,
        borderColor: AppColors.cashInk,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.star, color: AppColors.cash),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '초록 주기 · +$xp XP',
                style: pixelText(
                  size: 15,
                  bold: true,
                  color: AppColors.cashInk,
                ),
              ),
            ),
            const _NewTag(),
          ],
        ),
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          const _Thumb(size: 36),
          const SizedBox(width: 8),
          Expanded(
            child: Text("'$_goalName'에 모아볼까요?", style: pixelText(size: 15)),
          ),
        ],
      ),
      const SizedBox(height: 16),
      _Row('현재 모은 금액', _money(progress)),
      const SizedBox(height: 8),
      _Row('반영 후 금액', _money(progress + _leftover), color: AppColors.tealInk),
      const SizedBox(height: 20),
      PixelButton(label: '${_money(_leftover)} 전부 모으기', onPressed: () {}),
      Wrap(
        alignment: WrapAlignment.spaceAround,
        spacing: 16,
        children: [
          TextButton(onPressed: () {}, child: const Text('금액 바꾸기')),
          TextButton(onPressed: () {}, child: const Text('나중에')),
        ],
      ),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.receipt_long, size: 18),
            label: const Text('마감 결과 자세히 보기'),
          ),
          const _NewTag(),
        ],
      ),
    ],
  );
}

/// Serves one local picture for every image request, so the shipped card and
/// editor can show a "shop photo" offline. Only what NetworkImage touches.
class _PhotoOverrides extends HttpOverrides {
  _PhotoOverrides(this.bytes);
  final List<int> bytes;
  @override
  HttpClient createHttpClient(SecurityContext? context) => _Client(bytes);
}

class _Client implements HttpClient {
  _Client(this.bytes);
  final List<int> bytes;
  @override
  bool autoUncompress = false;
  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _Request(bytes);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Request implements HttpClientRequest {
  _Request(this.bytes);
  final List<int> bytes;
  @override
  Future<HttpClientResponse> close() async => _Response(bytes);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Response extends Stream<List<int>> implements HttpClientResponse {
  _Response(this.bytes);
  final List<int> bytes;
  @override
  int get statusCode => HttpStatus.ok;
  @override
  int get contentLength => bytes.length;
  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;
  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int>)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) => Stream.value(bytes).listen(
    onData,
    onError: onError,
    onDone: onDone,
    cancelOnError: cancelOnError,
  );
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  if (!_capture) return;
  // NetworkImage keeps one HttpClient for the whole run, so the fake photo
  // server must be in place before the first image request of any test.
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = _PhotoOverrides(
    File('assets/rooms/shared_items/launch_tv_base.webp').readAsBytesSync(),
  );

  Future<SobraStore> pumpHome(
    WidgetTester tester, {
    required bool allocate,
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _loadFonts();
    final (store, xp) = await _store(allocate: allocate);
    _lastXp = xp;
    await tester.pumpWidget(
      RepaintBoundary(
        key: _captureKey,
        child: SobraApp(store: store),
      ),
    );
    await _warmArt(tester);
    // The shipped card cannot load the shop photo in a test, so the proposed
    // card (same layout, plus the deadline line) sits over it in every shot.
    final rect = tester.getRect(find.byType(SavingsGoalCard).first);
    final overlay = OverlayEntry(
      builder: (_) => Positioned(
        left: rect.left,
        width: rect.width,
        bottom: tester.view.physicalSize.height - rect.bottom,
        child: Material(
          type: MaterialType.transparency,
          child: _CardWithDeadline(progress: store.savingsGoalProgressCentavos),
        ),
      ),
    );
    tester
        .state<NavigatorState>(find.byType(Navigator).first)
        .overlay!
        .insert(overlay);
    addTearDown(overlay.remove);
    await tester.pumpAndSettle();
    await tester.runAsync(
      () => precacheImage(
        const AssetImage(RoomDecorAssets.launchTvBase),
        tester.element(find.byType(SavingsGoalCard).first),
      ),
    );
    await tester.pumpAndSettle();
    return store;
  }

  // Drawn as overlay entries above the card overlay, so the barrier dims the
  // proposed card the same way a real dialog route dims the shipped one.
  Future<void> dialog(WidgetTester tester, Widget child) async {
    final entry = OverlayEntry(
      builder: (_) => Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: Color(0x80202848)),
          child,
        ],
      ),
    );
    tester
        .state<NavigatorState>(find.byType(Navigator).first)
        .overlay!
        .insert(entry);
    addTearDown(entry.remove);
    await tester.pumpAndSettle();
  }

  testWidgets('home card with the target date', (tester) async {
    await pumpHome(tester, allocate: true);
    await _save(tester, '01-home-deadline-ko.png');
  });

  testWidgets('bought it with goal money', (tester) async {
    final store = await pumpHome(tester, allocate: true);
    await dialog(
      tester,
      _BoughtItDialog(progress: store.savingsGoalProgressCentavos),
    );
    await _save(tester, '02-bought-it-ko.png');
  });

  testWidgets('cycle close popup keeps the XP', (tester) async {
    final store = await pumpHome(tester, allocate: false);
    await dialog(
      tester,
      _CycleCloseWithXp(
        xp: _lastXp,
        progress: store.savingsGoalProgressCentavos,
      ),
    );
    await _save(tester, '03-cycle-close-xp-ko.png');
  });
  // The shipped UI as it is today, with the same link goal. No mock widgets.
  Future<SobraStore> pumpReal(
    WidgetTester tester,
    Size size,
    Widget? screen,
  ) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _loadFonts();
    final (store, _) = await _store(allocate: true);
    await tester.pumpWidget(
      RepaintBoundary(
        key: _captureKey,
        child: SobraApp(store: store),
      ),
    );
    await _warmArt(tester);
    if (screen != null) {
      final context = tester.element(find.byType(SavingsGoalCard).first);
      unawaited(
        Navigator.of(
          context,
        ).push(MaterialPageRoute<void>(builder: (_) => screen)),
      );
      await tester.pumpAndSettle();
    }
    // Let the fake shop photo arrive and decode.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pumpAndSettle();
    return store;
  }

  testWidgets('current home card with the link goal', (tester) async {
    await pumpReal(tester, const Size(390, 844), null);
    await _save(tester, 'current-01-home-ko.png');
  });

  testWidgets('current goal editor with the link goal', (tester) async {
    late SobraStore store;
    store = await pumpReal(tester, const Size(390, 1700), null);
    final context = tester.element(find.byType(SavingsGoalCard).first);
    unawaited(
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => SavingsGoalScreen(existing: store.activeSavingsGoal),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pumpAndSettle();
    await _save(tester, 'current-02-goal-editor-ko.png');
  });

  testWidgets('current home card for each kind of goal date', (tester) async {
    final store = await pumpReal(tester, const Size(390, 844), null);
    final goal = store.activeSavingsGoal!;
    for (final (name, date) in [
      ('near', DateTime(2026, 11, 13)),
      ('next-year', DateTime(2027, 11, 13)),
      ('undated', null),
    ]) {
      await store.saveSavingsGoal(
        id: goal.id,
        name: goal.name,
        targetCentavos: goal.targetCentavos,
        startingCentavos: goal.startingCentavos,
        targetDate: date,
        productUrl: goal.productUrl,
        imageUrl: goal.imageUrl,
        merchantName: goal.merchantName,
      );
      await tester.pumpAndSettle();
      final card = find.byType(SavingsGoalCard).first;
      await tester.ensureVisible(card);
      await tester.pumpAndSettle();
      await _save(tester, 'current-card-$name-ko.png');
    }
  });

  testWidgets('current purchase flow with the link goal', (tester) async {
    final store = await pumpReal(tester, const Size(390, 1500), null);
    final home = tester.element(find.byType(SavingsGoalCard).first);
    unawaited(
      Navigator.of(home).push(
        MaterialPageRoute<void>(
          builder: (_) => SavingsGoalScreen(
            existing: store.activeSavingsGoal,
            readPrice: (_, url) async => GoalProductImport(
              sourceUrl: url,
              title: _goalName,
              priceCentavos: _salePrice,
              currencyCode: 'MXN',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pumpAndSettle();
    await _save(tester, 'current-03-editor-with-purchase-ko.png');

    final purchase = find.byKey(const ValueKey('goal-purchase'));
    await tester.ensureVisible(purchase);
    await tester.pumpAndSettle();
    await tester.tap(purchase);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('goal-purchase-read-price')));
    await tester.pumpAndSettle();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pumpAndSettle();
    await _save(tester, 'current-04-purchase-ko.png');

    await tester.tap(find.byKey(const ValueKey('goal-purchase-confirm')));
    await tester.pumpAndSettle();
    final context = tester.element(find.byType(SavingsGoalCard).first);
    unawaited(
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const CompletedSavingsGoalsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await _save(tester, 'current-05-history-ko.png');
  });

  testWidgets('current cycle close popup with XP', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _loadFonts();
    final (store, _) = await _store(allocate: false, keepNotice: true);
    await tester.pumpWidget(
      RepaintBoundary(
        key: _captureKey,
        child: SobraApp(store: store),
      ),
    );
    await _warmArt(tester);
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('goal-allocation-xp')), findsOneWidget);
    await _save(tester, 'current-06-cycle-close-xp-ko.png');
  });
}

int _lastXp = 0;
