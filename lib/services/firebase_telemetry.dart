import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import '../firebase_options.dart';
import 'app_telemetry.dart';

/// Android is the released platform. Web and iOS previews need no Firebase app.
/// Development builds opt in only when validating the Firebase console.
Future<void> initializeFirebaseTelemetry() async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
  const enabled = bool.fromEnvironment(
    'TELEMETRY_ENABLED',
    defaultValue: kReleaseMode,
  );
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on Object catch (error) {
    debugPrint('Firebase unavailable: ${error.runtimeType}');
    return;
  }

  final analytics = FirebaseAnalytics.instance;
  final crashlytics = FirebaseCrashlytics.instance;
  var analyticsReady = false;
  var crashlyticsReady = false;
  try {
    // Analytics measures usage. AdMob retains its existing UMP consent flow.
    await analytics.setConsent(
      adStorageConsentGranted: false,
      adUserDataConsentGranted: false,
      adPersonalizationSignalsConsentGranted: false,
    );
    await analytics.setAnalyticsCollectionEnabled(enabled);
    analyticsReady = enabled;
  } on Object catch (error) {
    debugPrint('Analytics unavailable: ${error.runtimeType}');
  }
  try {
    await crashlytics.setCrashlyticsCollectionEnabled(enabled);
    crashlyticsReady = enabled;
  } on Object catch (error) {
    debugPrint('Crashlytics unavailable: ${error.runtimeType}');
  }

  final telemetry = AppTelemetry(
    sendEvent: analyticsReady
        ? (name, parameters) =>
              analytics.logEvent(name: name, parameters: parameters)
        : null,
    sendError: crashlyticsReady
        ? (type, stack, fatal) => crashlytics.recordError(
            type,
            stack,
            fatal: fatal,
            printDetails: false,
          )
        : null,
  );
  AppTelemetry.instance = telemetry;
  if (!crashlyticsReady) return;

  final previousFlutterHandler = FlutterError.onError;
  FlutterError.onError = (details) {
    previousFlutterHandler?.call(details);
    unawaited(
      telemetry.reportError(
        details.exception,
        details.stack ?? StackTrace.current,
      ),
    );
  };
  final previousPlatformHandler = PlatformDispatcher.instance.onError;
  PlatformDispatcher.instance.onError = (error, stack) {
    unawaited(telemetry.reportError(error, stack, fatal: true));
    return previousPlatformHandler?.call(error, stack) ?? true;
  };
}
