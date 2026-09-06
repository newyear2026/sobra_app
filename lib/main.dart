import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scheduleMidnightRefresh();
  }

  @override
  void dispose() {
    _midnightTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
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
        locale: const Locale('es', 'MX'),
        supportedLocales: const [Locale('es', 'MX')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const _StartupRouter(),
      ),
    );
  }
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
