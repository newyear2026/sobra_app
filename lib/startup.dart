import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'l10n/generated/app_localizations.dart';
import 'models/language.dart';
import 'screens/startup_screen.dart';
import 'services/app_telemetry.dart';
import 'services/startup_launch.dart';
import 'theme/app_theme.dart';

typedef StartupPreferences = ({String? languageCode, bool reducedMotion});
typedef AppInitializer =
    Future<Widget> Function(
      ValueChanged<StartupPreferences> onPreferencesReady,
    );

/// Paints before touching storage or platform services. Completion replaces
/// the splash immediately, even if its coin animation has only just started.
class SobraStartup extends StatefulWidget {
  const SobraStartup({super.key, required this.initialize});

  final AppInitializer initialize;

  @override
  State<SobraStartup> createState() => _SobraStartupState();
}

class _SobraStartupState extends State<SobraStartup> {
  final _launch = StartupLaunch();
  StartupLaunchState? _launchState;
  Widget? _app;
  bool _failed = false;
  bool _running = false;
  StartupPreferences _preferences = (languageCode: null, reducedMotion: false);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(_readLaunch());
        unawaited(_initialize());
      }
    });
  }

  Future<void> _readLaunch() async {
    final state = await _launch.read();
    if (mounted && _app == null) setState(() => _launchState = state);
  }

  void _releaseAfterFrame() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_launch.release());
    });
  }

  Future<void> _initialize() async {
    if (_running) return;
    setState(() {
      _running = true;
      _failed = false;
    });
    try {
      final app = await widget.initialize((preferences) {
        if (mounted) setState(() => _preferences = preferences);
      });
      if (mounted) {
        setState(() => _app = app);
        _releaseAfterFrame();
      }
    } on Object catch (error, stack) {
      unawaited(AppTelemetry.instance.reportError(error, stack));
      if (mounted) {
        setState(() => _failed = true);
        _releaseAfterFrame();
      }
    } finally {
      _running = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_app case final app?) return app;
    final languageCode = SobraLanguage.fromCode(_preferences.languageCode).code;
    return MaterialApp(
      title: 'Sobrita',
      debugShowCheckedModeBanner: false,
      theme: buildSobraTheme(),
      locale: languageCode == null ? null : Locale(languageCode),
      supportedLocales: SobraLanguage.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: StartupScreen(
        reducedMotion: _preferences.reducedMotion,
        failed: _failed,
        onRetry: () => unawaited(_initialize()),
        launchState: _launchState,
      ),
    );
  }
}
