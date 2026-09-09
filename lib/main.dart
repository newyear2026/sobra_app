import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'l10n/generated/app_localizations.dart';
import 'l10n/labels.dart';
import 'models/language.dart';
import 'models/money_movement.dart';
import 'screens/app_shell.dart';
import 'screens/onboarding_screen.dart';
import 'screens/recovery_screen.dart';
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
  runApp(SobraApp(store: store));
}

class SobraApp extends StatefulWidget {
  const SobraApp({super.key, required this.store});

  final SobraStore store;

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
    return SobraScope(
      store: widget.store,
      child: MaterialApp(
        title: 'Sobra',
        debugShowCheckedModeBanner: false,
        theme: buildSobraTheme(),
        // A null locale hands the choice back to the phone. The list comes
        // from `SobraLanguage` so the picker and the app can never disagree
        // about which languages this build has.
        locale: _languageCode == null ? null : Locale(_languageCode!),
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
    );
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
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _StartupRouter extends StatelessWidget {
  const _StartupRouter();

  @override
  Widget build(BuildContext context) {
    final store = SobraScope.of(context);
    return AnimatedSwitcher(
      duration: reducedMotionOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 280),
      child: store.hasStorageError
          ? const RecoveryScreen(key: ValueKey('recovery'))
          : store.hasCompletedOnboarding
          ? const AppShell(key: ValueKey('app'))
          : const OnboardingScreen(key: ValueKey('onboarding')),
    );
  }
}
