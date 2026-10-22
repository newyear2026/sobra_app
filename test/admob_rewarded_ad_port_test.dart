import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
// The plugin's own tests use this manager to drive the real Dart adapter
// through its platform channel without requesting live ads.
import 'package:google_mobile_ads/src/ad_instance_manager.dart';
import 'package:sobra_app/services/admob_rewarded_ad_port.dart';
import 'package:sobra_app/services/app_telemetry.dart';
import 'package:sobra_app/services/rewarded_ad_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late List<MethodCall> calls;
  late List<Map<String, Object>> events;
  late List<String> eventNames;
  late bool allowed;
  late AdMobRewardedAdPort port;
  Future<Object?> Function(MethodCall)? platform;

  setUp(() {
    calls = [];
    events = [];
    eventNames = [];
    allowed = true;
    platform = null;
    port = AdMobRewardedAdPort(canRequestAds: () => allowed);
    instanceManager = AdInstanceManager('plugins.flutter.io/google_mobile_ads');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(instanceManager.channel, (call) async {
          calls.add(call);
          return platform?.call(call);
        });
    AppTelemetry.instance = AppTelemetry(
      sendEvent: (name, parameters) async {
        eventNames.add(name);
        events.add(parameters);
      },
    );
  });

  tearDown(() {
    AppTelemetry.instance = AppTelemetry();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(instanceManager.channel, null);
  });

  List<MethodCall> sdkCalls(String method) =>
      calls.where((call) => call.method == method).toList();

  List<Map<String, Object>> stage(String stage) =>
      events.where((event) => event['stage'] == stage).toList();

  RewardedAd adAt(int id) => instanceManager.adFor(id) as RewardedAd;

  Future<RewardedAd> loadAd(WidgetTester tester, {int id = 0}) async {
    final loading = port.load();
    await tester.pump();
    final ad = adAt(id);
    ad.rewardedAdLoadCallback.onAdLoaded(ad);
    await loading;
    return ad;
  }

  testWidgets('a completed load cannot clear the next request with its timer', (
    tester,
  ) async {
    final ad = await loadAd(tester);
    final showing = port.show();
    await tester.pump();
    ad.fullScreenContentCallback!.onAdDismissedFullScreenContent!(ad);
    expect(await showing, RewardedAdResult.dismissed);

    await tester.pump(const Duration(seconds: 10));
    final second = port.load();
    await tester.pump();
    await tester.pump(const Duration(seconds: 20));

    expect(port.load(), same(second));
    expect(sdkCalls('loadRewardedAd'), hasLength(2));
    expect(stage('loadFailed'), isEmpty);

    final nextAd = adAt(1);
    nextAd.rewardedAdLoadCallback.onAdLoaded(nextAd);
    await second;
    await tester.pump(const Duration(minutes: 6));
    expect(stage('loadFailed'), isEmpty);
    expect(stage('showFailed'), isEmpty);
  });

  testWidgets('a timed-out request cannot fail a later pending load', (
    tester,
  ) async {
    final first = port.load();
    await tester.pump();
    final oldAd = adAt(0);
    await tester.pump(const Duration(seconds: 30));
    await first;
    final second = port.load();
    await tester.pump();

    oldAd.rewardedAdLoadCallback.onAdFailedToLoad(
      LoadAdError(3, 'com.google.android.gms.ads', 'late no fill', null),
    );

    expect(port.load(), same(second));
    expect(sdkCalls('loadRewardedAd'), hasLength(2));
    expect(stage('loadFailed'), [
      {'stage': 'loadFailed', 'reason': 'timeout'},
    ]);
    final nextAd = adAt(1);
    nextAd.rewardedAdLoadCallback.onAdLoaded(nextAd);
    await second;
  });

  testWidgets('a late loaded ad is disposed without completing the retry', (
    tester,
  ) async {
    final first = port.load();
    await tester.pump();
    final oldAd = adAt(0);
    await tester.pump(const Duration(seconds: 30));
    await first;
    final retry = port.load();
    await tester.pump();

    oldAd.rewardedAdLoadCallback.onAdLoaded(oldAd);
    await tester.pump();
    expect(port.isReady, isFalse);
    expect(port.load(), same(retry));
    expect(sdkCalls('disposeAd').single.arguments['adId'], 0);
    expect(stage('loaded'), isEmpty);

    final nextAd = adAt(1);
    nextAd.rewardedAdLoadCallback.onAdLoaded(nextAd);
    await retry;
    expect(port.isReady, isTrue);
    // Another late callback must not replace the fresh retry's ad either.
    oldAd.rewardedAdLoadCallback.onAdLoaded(oldAd);
    final showing = port.show();
    await tester.pump();
    expect(sdkCalls('showAdWithoutView').single.arguments['adId'], 1);
    nextAd.fullScreenContentCallback!.onAdDismissedFullScreenContent!(nextAd);
    await showing;
  });

  testWidgets('no fill is recorded once and the next load can succeed', (
    tester,
  ) async {
    final loading = port.load();
    await tester.pump();
    adAt(0).rewardedAdLoadCallback.onAdFailedToLoad(
      LoadAdError(3, 'com.google.android.gms.ads', 'SDK detail', null),
    );
    await loading;
    expect(port.isReady, isFalse);
    expect(stage('loadFailed'), [
      {'stage': 'loadFailed', 'reason': 'noFill'},
    ]);

    await loadAd(tester, id: 1);
    await tester.pump(const Duration(seconds: 30));
    expect(port.isReady, isTrue);
    expect(stage('loadFailed'), hasLength(1));
  });

  testWidgets('consent withdrawn during loading disposes the received ad', (
    tester,
  ) async {
    final loading = port.load();
    await tester.pump();
    final ad = adAt(0);
    allowed = false;
    ad.rewardedAdLoadCallback.onAdLoaded(ad);
    await loading;
    await tester.pump(const Duration(seconds: 30));

    expect(port.isReady, isFalse);
    expect(sdkCalls('disposeAd'), hasLength(1));
    expect(stage('loaded'), isEmpty);
    expect(stage('loadFailed'), [
      {'stage': 'loadFailed', 'reason': 'consentUnavailable'},
    ]);
  });

  testWidgets('only SDK callbacks record a shown ad, impression and reward', (
    tester,
  ) async {
    final ad = await loadAd(tester);
    final showing = port.show();
    await tester.pump();
    expect(stage('showRequested'), hasLength(1));
    expect(stage('showed'), isEmpty);
    expect(stage('impression'), isEmpty);
    expect(stage('rewardEarned'), isEmpty);

    final callback = ad.fullScreenContentCallback!;
    callback.onAdShowedFullScreenContent!(ad);
    callback.onAdImpression!(ad);
    callback.onAdImpression!(ad);
    ad.onUserEarnedRewardCallback!(ad, RewardItem(1, 'reward'));
    ad.onUserEarnedRewardCallback!(ad, RewardItem(1, 'reward'));
    callback.onAdDismissedFullScreenContent!(ad);
    callback.onAdDismissedFullScreenContent!(ad);

    expect(await showing, RewardedAdResult.earned);
    await tester.pump(const Duration(minutes: 6));
    expect(events.map((event) => event['stage']), [
      'loadRequested',
      'loaded',
      'showRequested',
      'showed',
      'impression',
      'rewardEarned',
      'dismissed',
    ]);
    expect(sdkCalls('disposeAd'), hasLength(1));
    expect(stage('showFailed'), isEmpty);
    expect(eventNames, everyElement('rewarded_ad_lifecycle'));
  });

  testWidgets('a failed presentation records the SDK reason once', (
    tester,
  ) async {
    final ad = await loadAd(tester);
    final showing = port.show();
    await tester.pump();
    final fail =
        ad.fullScreenContentCallback!.onAdFailedToShowFullScreenContent!;
    final error = AdError(3, 'com.google.android.gms.ads', 'not in foreground');
    fail(ad, error);
    fail(ad, error);

    expect(await showing, RewardedAdResult.failed);
    await tester.pump(const Duration(minutes: 6));
    expect(stage('showFailed'), [
      {'stage': 'showFailed', 'reason': 'appNotForeground'},
    ]);
    expect(stage('impression'), isEmpty);
    expect(sdkCalls('disposeAd'), hasLength(1));
    expect(port.isReady, isFalse);
  });

  testWidgets('a silent show channel times out without tearing down the ad', (
    tester,
  ) async {
    final ad = await loadAd(tester);
    final platformReply = Completer<Object?>();
    platform = (call) async =>
        call.method == 'showAdWithoutView' ? platformReply.future : null;
    RewardedAdResult? outcome;
    unawaited(port.show().then((value) => outcome = value));
    await tester.pump();
    await tester.pump(const Duration(minutes: 5));

    expect(outcome, RewardedAdResult.failed);
    expect(stage('showFailed'), [
      {'stage': 'showFailed', 'reason': 'timeout'},
    ]);
    expect(sdkCalls('disposeAd'), isEmpty);

    platformReply.complete();
    await tester.pump();
    ad.fullScreenContentCallback!.onAdDismissedFullScreenContent!(ad);
    await tester.pump(const Duration(minutes: 5));
    expect(stage('showFailed'), hasLength(1));
    expect(stage('rewardEarned'), isEmpty);
    expect(sdkCalls('disposeAd'), hasLength(1));
  });

  testWidgets('load channel exceptions carry no free text into telemetry', (
    tester,
  ) async {
    platform = (call) async {
      if (call.method == 'loadRewardedAd') {
        throw PlatformException(code: 'private-code', message: 'private text');
      }
      return null;
    };
    final loading = port.load();
    await tester.pump();
    await loading;
    await tester.pump(const Duration(seconds: 30));

    expect(events, [
      {'stage': 'loadRequested'},
      {'stage': 'loadFailed', 'reason': 'platformError'},
    ]);
  });

  testWidgets('show channel exceptions are recorded and dispose the ad', (
    tester,
  ) async {
    await loadAd(tester);
    platform = (call) async {
      if (call.method == 'showAdWithoutView') {
        throw PlatformException(code: 'private-code', message: 'private text');
      }
      return null;
    };
    final showing = port.show();
    await tester.pump();
    expect(await showing, RewardedAdResult.failed);
    await tester.pump(const Duration(minutes: 6));

    expect(stage('showFailed'), [
      {'stage': 'showFailed', 'reason': 'platformError'},
    ]);
    expect(sdkCalls('disposeAd'), hasLength(1));
  });

  testWidgets('missing consent and missing ads have distinct failure reasons', (
    tester,
  ) async {
    allowed = false;
    await port.load();
    expect(await port.show(), RewardedAdResult.failed);
    allowed = true;
    expect(await port.show(), RewardedAdResult.failed);

    expect(calls, isEmpty);
    expect(stage('loadRequested'), isEmpty);
    expect(stage('showFailed'), [
      {'stage': 'showFailed', 'reason': 'consentUnavailable'},
      {'stage': 'showFailed', 'reason': 'notReady'},
    ]);
  });

  testWidgets('another SDK domain is not given a Google error meaning', (
    tester,
  ) async {
    final loading = port.load();
    await tester.pump();
    adAt(0).rewardedAdLoadCallback.onAdFailedToLoad(
      LoadAdError(2, 'another.adapter', 'adapter-specific failure', null),
    );
    await loading;

    expect(stage('loadFailed'), [
      {'stage': 'loadFailed', 'reason': 'otherSdkError'},
    ]);
  });
}
