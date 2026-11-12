// Debug by default. Explicit release QA is for Android test emulators only.
// Preferences are held in memory; this never overwrites the user's ledger.
import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sobra_app/l10n/generated/app_localizations.dart';
import 'package:sobra_app/models/expense_entry.dart';
import 'package:sobra_app/models/native_ad_slot.dart';
import 'package:sobra_app/models/pay_schedule.dart';
import 'package:sobra_app/screens/app_shell.dart';
import 'package:sobra_app/services/admob_config.dart';
import 'package:sobra_app/services/admob_consent_service.dart';
import 'package:sobra_app/services/admob_exit_native_ad_loader.dart';
import 'package:sobra_app/services/exit_native_ad_service.dart';
import 'package:sobra_app/state/sobra_store.dart';
import 'package:sobra_app/theme/app_theme.dart';

class _TestAdConsent extends AdMobConsentController {
  @override
  bool get canRequestAds => true;
}

/// Debug-only controls for a reproducible, real SDK late-load check. Only the
/// request start is held: the creative and completion still come from AdMob.
class _ExitPreviewProbe {
  final bool holdRequest = const bool.fromEnvironment(
    'SOBRA_EXIT_PREVIEW_HOLD_AD_REQUEST',
  );
  final _release = Completer<void>();
  final events = <Map<String, Object?>>[];
  String phase = 'initializing';
  int impressions = 0;

  void record(String stage, [ExitAdSize? size]) {
    phase = stage;
    final event = <String, Object?>{
      'stage': stage,
      'size': size?.name,
      'adUnitId': AdMobConfig.exitNativeAdUnitId.trim(),
      'time': DateTime.now().toUtc().toIso8601String(),
    };
    events.add(event);
    debugPrint('EXIT_PREVIEW_EVENT ${jsonEncode(event)}');
  }

  Future<void> waitForRequest(ExitAdSize size) async {
    if (holdRequest && !_release.isCompleted) {
      record('request_held', size);
      await _release.future;
    }
  }

  Map<String, Object?> snapshot() {
    final boxes = <String, Object?>{};
    const keys = {
      'exit-dialog-frame',
      'exit-cancel',
      'exit-confirm',
      'exit-native-ad-slot',
    };
    void visit(Element element) {
      final key = element.widget.key;
      if (key is ValueKey<String> && keys.contains(key.value)) {
        final render = element.findRenderObject();
        if (render is RenderBox && render.hasSize) {
          final origin = render.localToGlobal(Offset.zero);
          boxes[key.value] = {
            'x': origin.dx,
            'y': origin.dy,
            'width': render.size.width,
            'height': render.size.height,
          };
        }
      }
      element.visitChildElements(visit);
    }

    final root = WidgetsBinding.instance.rootElement;
    if (root != null) visit(root);
    final view = WidgetsBinding.instance.platformDispatcher.views.first;
    return {
      'time': DateTime.now().toUtc().toIso8601String(),
      'phase': phase,
      'buildMode': kReleaseMode ? 'release' : 'debug',
      'adUnitId': AdMobConfig.exitNativeAdUnitId.trim(),
      'holdRequest': holdRequest,
      'requestReleased': _release.isCompleted,
      'impressions': impressions,
      'density': view.devicePixelRatio,
      'boxes': boxes,
      'events': events,
    };
  }

  void register() {
    developer.registerExtension('ext.sobra.exitSnapshot', (_, _) async {
      WidgetsBinding.instance.scheduleFrame();
      await WidgetsBinding.instance.endOfFrame;
      return developer.ServiceExtensionResponse.result(jsonEncode(snapshot()));
    });
    developer.registerExtension('ext.sobra.releaseExitAdRequest', (_, _) async {
      if (!_release.isCompleted) {
        record('request_released');
        _release.complete();
      }
      return developer.ServiceExtensionResponse.result(jsonEncode(snapshot()));
    });
  }
}

Future<void> main() async {
  const releaseQa = bool.fromEnvironment('SOBRA_EXIT_PREVIEW_ALLOW_RELEASE');
  const expectedUnit = String.fromEnvironment(
    'SOBRA_EXIT_PREVIEW_EXPECTED_UNIT_ID',
  );
  if (!kDebugMode && !(kReleaseMode && releaseQa)) {
    throw StateError('Release preview requires explicit test-emulator QA.');
  }
  if (kReleaseMode &&
      (expectedUnit.isEmpty ||
          expectedUnit != AdMobConfig.exitNativeAdUnitId.trim())) {
    throw StateError('Release preview ad unit differs from the QA target.');
  }
  WidgetsFlutterBinding.ensureInitialized();
  final probe = _ExitPreviewProbe();
  if (kDebugMode) probe.register();
  debugPrint(
    'EXIT_PREVIEW_CONFIG ${jsonEncode({'buildMode': kReleaseMode ? 'release' : 'debug', 'adUnitId': AdMobConfig.exitNativeAdUnitId.trim()})}',
  );
  // ignore: invalid_use_of_visible_for_testing_member
  SharedPreferences.setMockInitialValues({});
  final store = await SobraStore.load(now: () => DateTime(2026, 11, 7, 10));
  await store.configureOnboarding(
    budgetCentavos: 600000,
    cashCentavos: 150000,
    schedule: const PaySchedule.semiMonthly(),
  );
  await store.completeOnboarding();
  await store.takeLaunchGiftNotice();
  await store.addExpense(
    amountCentavos: 13500,
    category: ExpenseCategory.food,
    note: '점심 식사',
    occurredAt: DateTime(2026, 11, 7, 9),
    paymentMethod: PaymentMethod.cash,
  );
  store.takePendingXpNotice();
  await store.setLanguageCode('ko');
  await store.setReducedMotion(true);
  await MobileAds.instance.initialize();
  final ads = ExitNativeAds(
    load: (size, onImpression) async {
      final unitId = AdMobConfig.exitNativeAdUnitId.trim();
      if (unitId.isEmpty) {
        probe.record('not_configured', size);
        return null;
      }
      await probe.waitForRequest(size);
      probe.record('requesting', size);
      debugPrint('EXIT_PREVIEW ${size.name}: requesting $unitId');
      final creative = await loadExitNativeAd(size, () {
        probe.impressions++;
        probe.record('impression', size);
        debugPrint('EXIT_PREVIEW ${size.name}: SDK impression');
        onImpression();
      });
      probe.record(creative != null ? 'ready' : 'no_fill', size);
      debugPrint(
        'EXIT_PREVIEW ${size.name}: ${creative != null ? 'ready' : 'no fill'}',
      );
      return creative;
    },
    onImpression: () => unawaited(store.recordNativeAdImpression(NativeAdSlot.exit)),
  );
  runApp(
    SobraScope(
      store: store,
      child: AdMobConsentScope(
        consent: _TestAdConsent(),
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: buildSobraTheme(),
          locale: const Locale('ko'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: AppShell(exitAds: ads),
        ),
      ),
    ),
  );
}
