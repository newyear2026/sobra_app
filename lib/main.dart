import 'dart:async';

import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kDebugMode, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'l10n/generated/app_localizations.dart';
import 'l10n/labels.dart';
import 'models/language.dart';
import 'models/money_movement.dart';
import 'screens/app_shell.dart';
import 'screens/login_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/recovery_screen.dart';
import 'services/purchase_service.dart';
import 'services/rewarded_ad_service.dart';
import 'services/receipt_store.dart';
import 'services/sobra_quick_entry.dart';
import 'services/sobra_widget_sync.dart';
import 'state/sobra_store.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Nothing in the app uses an AppBar, so Flutter never sets an overlay style
  // of its own and the status bar can end up with light icons over Sobra's
  // near-white paper.
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.surface,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  final store = await SobraStore.load();
  await SobraWidgetSync.initialize(store);
  await SobraQuickEntry.initialize();
  final receipts = ReceiptStore.forPlatform();
  await _prepareReceipts(receipts, store);
  final purchasePlatform =
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);
  final purchases = purchasePlatform
      ? SobraPurchases(
          backend: PluginPurchaseBackend(),
          store: store,
          // Android replays past purchases with a silent query, so a reinstall
          // can hand everything back before the user has looked at anything.
          // iOS cannot: a StoreKit restore may raise an App Store sign-in
          // prompt, so the Ajustes row asks instead.
          restoreOnStart: defaultTargetPlatform == TargetPlatform.android,
        )
      : null;
  // Not awaited. Reaching the store takes a network round trip, and the whole
  // app — a ledger that works offline — must not wait behind it to draw.
  if (purchases != null) unawaited(purchases.start());
  // No ad unit and no SDK yet, so the port that ships is the one that never
  // fills. Every ad button says "no ads right now" truthfully, and connecting
  // a network later replaces this one object.
  final ads = RewardedAds(
    port: const UnavailableRewardedAdPort(),
    store: store,
  );
  runApp(
    SobraApp(
      store: store,
      receipts: receipts,
      purchases: purchases,
      ads: ads,
    ),
  );
}

/// Resolves the receipts directory and clears what nothing points at.
///
/// Launch is the one moment where an orphan is provably an orphan: no delete
/// is waiting to be undone, and no half-filled register screen is holding a
/// photo it has not saved yet. Warming the directory here is also what lets
/// thumbnails resolve their file during `build`, which cannot await.
///
/// Both steps are best-effort. A phone that will not hand over its documents
/// directory is a reason to show the ledger without photos, never a reason to
/// refuse to start.
Future<void> _prepareReceipts(ReceiptStore receipts, SobraStore store) async {
  if (receipts is! FileReceiptStore) return;
  try {
    await receipts.warmUp();
    await receipts.sweepOrphans(store.referencedReceipts);
  } on Object catch (error) {
    debugPrint('Receipts unavailable: $error');
  }
}

class SobraApp extends StatefulWidget {
  const SobraApp({
    super.key,
    required this.store,
    this.receipts = const UnsupportedReceiptStore(),
    this.purchases,
    this.ads,
  });

  final SobraStore store;

  /// Null where there is no store to talk to — every widget test that pumps
  /// the app, and any build with billing unavailable. The catalog then shows
  /// its entries without prices and Ajustes drops its restore row, which is
  /// the same screen a phone with no Play services would get.
  final SobraPurchases? purchases;

  /// Null where nothing shows ads — every widget test that pumps the app. The
  /// collection then locks its ad entries, which is the same screen a phone
  /// with no fill gets.
  final RewardedAds? ads;

  /// Defaults to the store that can hold nothing, which is what a harness
  /// pumping the app without a documents directory should get: every screen
  /// renders, and the ones that offer a camera simply do not.
  final ReceiptStore receipts;

  @override
  State<SobraApp> createState() => _SobraAppState();
}

class _SobraAppState extends State<SobraApp> with WidgetsBindingObserver {
  Timer? _midnightTimer;

  /// Mirrors the stored choice so the app rebuilds when — and only when — the
  /// language changes. [MaterialApp] sits above the scope that would otherwise
  /// notify it, and rebuilding it on every saved expense would be wasteful.
  String? _languageCode;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _languageCode = widget.store.languageCode;
    widget.store.addListener(_onStoreChanged);
    _scheduleMidnightRefresh();
  }

  @override
  void dispose() {
    _midnightTimer?.cancel();
    widget.store.removeListener(_onStoreChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _onStoreChanged() {
    if (widget.store.languageCode == _languageCode) return;
    setState(() => _languageCode = widget.store.languageCode);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(widget.store.refreshForCurrentDate());
      _scheduleMidnightRefresh();
    }
  }

  void _scheduleMidnightRefresh() {
    _midnightTimer?.cancel();
    final now = widget.store.currentMoment;
    final nextDay = DateTime(now.year, now.month, now.day + 1);
    _midnightTimer = Timer(nextDay.difference(now), () {
      unawaited(widget.store.refreshForCurrentDate());
      _scheduleMidnightRefresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final debugLocale = kDebugMode ? Uri.base.queryParameters['locale'] : null;
    final app = ReceiptScope(
      store: widget.receipts,
      child: SobraScope(
        store: widget.store,
        child: MaterialApp(
          title: 'Sobra',
          debugShowCheckedModeBanner: false,
          theme: buildSobraTheme(),
          // A null locale hands the choice back to the phone. The list comes
          // from `SobraLanguage` so the picker and the app can never disagree
          // about which languages this build has.
          locale: debugLocale == null
              ? (_languageCode == null ? null : Locale(_languageCode!))
              : Locale(debugLocale),
          supportedLocales: SobraLanguage.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (context, child) =>
              _WidgetSyncLabels(child: child ?? const SizedBox.shrink()),
          home: const _StartupRouter(),
        ),
      ),
    );
    // Outside the scopes it reads from rather than inside them: the store and
    // the receipts have to resolve for every screen, while the purchases are
    // optional and only two screens ask.
    final purchases = widget.purchases;
    final ads = widget.ads;
    Widget wrapped = app;
    if (ads != null) wrapped = RewardedAdScope(ads: ads, child: wrapped);
    if (purchases != null) {
      wrapped = PurchaseScope(purchases: purchases, child: wrapped);
    }
    return wrapped;
  }
}

/// Keeps the home screen widget speaking the same language as the app.
///
/// The widget payload is built outside the element tree, so it cannot look up
/// localizations itself. This sits just under [MaterialApp], where they first
/// resolve, and hands the sync a labeller — again whenever the locale changes.
class _WidgetSyncLabels extends StatefulWidget {
  const _WidgetSyncLabels({required this.child});

  final Widget child;

  @override
  State<_WidgetSyncLabels> createState() => _WidgetSyncLabelsState();
}

class _WidgetSyncLabelsState extends State<_WidgetSyncLabels> {
  AppLocalizations? _installed;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final l10n = AppLocalizations.of(context);
    if (identical(_installed, l10n)) return;
    _installed = l10n;
    SobraWidgetSync.movementLabeler = (MoneyMovement movement) =>
        movementTitle(l10n, movement);
    SobraQuickEntry.copy = SobraQuickEntryCopy(
      question: l10n.quickEntryQuestion,
      income: l10n.registerIncome,
      expense: l10n.registerExpense,
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _StartupRouter extends StatelessWidget {
  const _StartupRouter();

  @override
  Widget build(BuildContext context) {
    final store = SobraScope.of(context);
    // Order matters. A ledger that will not open is more urgent than anything
    // else here, so recovery comes before the account offer rather than behind
    // it: somebody whose data is unreadable should not be asked about backups
    // first.
    //
    // The offer is read from the store rather than held in this widget. It
    // used to live in State, so "start without an account" lasted until the
    // process died and every cold start asked again — including of people who
    // had been using Sobra for months.
    return AnimatedSwitcher(
      duration: reducedMotionOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 280),
      child: store.hasStorageError
          ? const RecoveryScreen(key: ValueKey('recovery'))
          : !store.hasAnsweredLoginOffer
          ? LoginScreen(
              key: const ValueKey('login'),
              onGoogleContinue: () => unawaited(store.answerLoginOffer()),
              onGuestContinue: () => unawaited(store.answerLoginOffer()),
            )
          : store.hasCompletedOnboarding
          ? const AppShell(key: ValueKey('app'))
          : const OnboardingScreen(key: ValueKey('onboarding')),
    );
  }
}
