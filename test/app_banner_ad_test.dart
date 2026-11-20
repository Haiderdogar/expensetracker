import 'dart:async';

import 'package:expensetracker/core/ads/ad_internet_status.dart';
import 'package:expensetracker/core/ads/admob_config.dart';
import 'package:expensetracker/core/ads/admob_service.dart';
import 'package:expensetracker/core/ads/widgets/app_banner_ad.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
// The SDK's native message codec and ad registry are needed to emulate Android.
// ignore: implementation_imports
import 'package:google_mobile_ads/src/ad_instance_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _TestAdMobService service;
  late List<MethodCall> calls;
  Future<int?> Function()? adaptiveHeight;
  var throwOnLoad = false;
  late StreamController<InternetStatus> internetChanges;
  InternetStatus? initialInternetStatus;
  var monitorSubscriptions = 0;

  setUp(() {
    service = _TestAdMobService();
    calls = [];
    adaptiveHeight = null;
    throwOnLoad = false;
    internetChanges = StreamController<InternetStatus>.broadcast();
    initialInternetStatus = InternetStatus.connected;
    monitorSubscriptions = 0;
    instanceManager = AdInstanceManager('plugins.flutter.io/google_mobile_ads');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(instanceManager.channel, (call) async {
          calls.add(call);
          switch (call.method) {
            case 'getAdSize':
              final ad =
                  instanceManager.adFor(call.arguments['adId']) as BannerAd;
              final height = adaptiveHeight == null
                  ? 50
                  : await adaptiveHeight!();
              return height == null
                  ? null
                  : AdSize(width: ad.size.width, height: height);
            case 'loadBannerAd':
              if (throwOnLoad) {
                throw PlatformException(code: 'load-failed');
              }
              return null;
            case 'disposeAd':
              return null;
            default:
              throw StateError('Unexpected native call: ${call.method}');
          }
        });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform_views, (call) async {
          if (call.method == 'resize') {
            return <String, double>{
              'width': call.arguments['width'] as double,
              'height': call.arguments['height'] as double,
            };
          }
          return call.method == 'create' ? 0 : null;
        });
  });

  tearDown(() async {
    await internetChanges.close();
    service.dispose();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(instanceManager.channel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform_views, null);
  });

  List<MethodCall> loadCalls() =>
      calls.where((call) => call.method == 'loadBannerAd').toList();

  BannerAd lastAd() =>
      instanceManager.adFor(loadCalls().last.arguments['adId']) as BannerAd;

  Stream<InternetStatus> internetStatuses() async* {
    monitorSubscriptions++;
    if (initialInternetStatus case final status?) yield status;
    yield* internetChanges.stream;
  }

  void setInternet(InternetStatus status) {
    initialInternetStatus = status;
    internetChanges.add(status);
  }

  Widget buildApp({bool visible = true}) => ProviderScope(
    overrides: [
      admobServiceProvider.overrideWithValue(service),
      adInternetStatusProvider.overrideWith((ref) => internetStatuses()),
    ],
    child: MaterialApp(
      home: Scaffold(
        extendBody: true,
        body: Column(
          children: [
            if (visible) const AppBannerAd(),
            const Expanded(
              child: SizedBox.expand(key: ValueKey('test-content')),
            ),
          ],
        ),
      ),
    ),
  );

  double contentTop(WidgetTester tester) =>
      tester.getTopLeft(find.byKey(const ValueKey('test-content'))).dy;

  Future<void> removeApp(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  }

  testWidgets('loads test ads, collapses on failure, and retries', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    final originalTop = contentTop(tester);
    expect(find.byType(AdWidget), findsNothing);
    expect(loadCalls(), hasLength(1));
    expect(
      loadCalls().single.arguments['adUnitId'],
      AdMobConfig.bannerAdUnitId,
    );
    expect(
      loadCalls().single.arguments['adUnitId'],
      'ca-app-pub-3940256099942544/9214589741',
    );

    final first = lastAd();
    first.listener.onAdLoaded!(first);
    await tester.pumpAndSettle();
    final bannerRect = tester.getRect(
      find.byKey(const ValueKey('admob-banner')),
    );
    expect(bannerRect.height, 50);
    expect(bannerRect.width, 320);
    expect(first.size, AdSize.banner);
    expect(contentTop(tester), originalTop + 54);
    expect(contentTop(tester), greaterThan(bannerRect.bottom));

    first.listener.onAdFailedToLoad!(
      first,
      LoadAdError(3, 'test', 'No fill', null),
    );
    await tester.pumpAndSettle();
    expect(find.byType(AdWidget), findsNothing);
    expect(contentTop(tester), originalTop);
    expect(calls.where((call) => call.method == 'disposeAd'), hasLength(1));
    await tester.pump(const Duration(seconds: 29));
    expect(loadCalls(), hasLength(1));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(loadCalls(), hasLength(2));

    final second = lastAd();
    second.listener.onAdLoaded!(second);
    await tester.pumpAndSettle();
    // A click-through overlay closing does not remove a banner.
    second.listener.onAdClosed?.call(second);
    await tester.pumpAndSettle();
    expect(find.byType(AdWidget), findsOneWidget);
    expect(contentTop(tester), originalTop + 54);

    await tester.pumpWidget(buildApp(visible: false));
    await tester.pumpAndSettle();
    expect(contentTop(tester), originalTop);
    expect(calls.where((call) => call.method == 'disposeAd'), hasLength(2));
    second.listener.onAdLoaded!(second);
    expect(tester.takeException(), isNull);
    await removeApp(tester);
  });

  testWidgets('consent gates requests and revocation removes a visible ad', (
    tester,
  ) async {
    service.allowed = false;
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    expect(loadCalls(), isEmpty);

    service.setAllowed(true);
    await tester.pumpAndSettle();
    expect(loadCalls(), hasLength(1));
    final old = lastAd();
    old.listener.onAdLoaded!(old);
    await tester.pumpAndSettle();
    expect(find.byType(AdWidget), findsOneWidget);

    service.setAllowed(false);
    await tester.pumpAndSettle();
    expect(find.byType(AdWidget), findsNothing);
    old.listener.onAdLoaded!(old);
    await tester.pumpAndSettle();
    expect(find.byType(AdWidget), findsNothing);
    service.setAllowed(true);
    await tester.pumpAndSettle();
    expect(loadCalls(), hasLength(2));
    await removeApp(tester);
  });

  testWidgets('keeps the compact size when the available width changes', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(400, 800);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    final first = lastAd();
    expect(first.size, AdSize.banner);
    first.listener.onAdLoaded!(first);
    await tester.pumpAndSettle();

    tester.view.physicalSize = const Size(800, 400);
    await tester.pumpAndSettle();
    expect(find.byType(AdWidget), findsNothing);
    expect(loadCalls(), hasLength(2));
    final second = lastAd();
    expect(second.size, AdSize.banner);
    first.listener.onAdLoaded!(first);
    await tester.pumpAndSettle();
    expect(find.byType(AdWidget), findsNothing);
    second.listener.onAdLoaded!(second);
    await tester.pumpAndSettle();
    expect(
      tester.getSize(find.byKey(const ValueKey('admob-banner'))).width,
      320,
    );
    expect(tester.takeException(), isNull);
    await removeApp(tester);
  });

  testWidgets(
    'does not request a banner when the available width is too small',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(300, 800);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();
      final originalTop = contentTop(tester);
      expect(service.initializationCalls, 0);
      expect(calls, isEmpty);
      expect(find.byType(AdWidget), findsNothing);

      tester.view.physicalSize = const Size(400, 800);
      await tester.pumpAndSettle();
      expect(loadCalls(), hasLength(1));
      final ad = lastAd();
      ad.listener.onAdLoaded!(ad);
      await tester.pumpAndSettle();
      final banner = tester.getRect(find.byKey(const ValueKey('admob-banner')));
      expect(banner.size, const Size(320, 50));
      expect(contentTop(tester), originalTop + 54);
      expect(tester.takeException(), isNull);
      await removeApp(tester);
    },
  );

  testWidgets('retries transient setup failure without leaving the screen', (
    tester,
  ) async {
    service.allowed = false;
    service.retrySetup = true;
    var attempts = 0;
    service.onInitialize = () {
      attempts++;
      if (attempts > 1) {
        service.allowed = true;
        service.retrySetup = false;
      }
      service.notifyListeners();
    };
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    expect(attempts, 1);
    expect(loadCalls(), isEmpty);

    await tester.pump(const Duration(seconds: 30));
    await tester.pumpAndSettle();
    expect(attempts, 2);
    expect(loadCalls(), hasLength(1));
    await removeApp(tester);
  });

  testWidgets('missing native sizes retry without reserving blank space', (
    tester,
  ) async {
    adaptiveHeight = () async => null;
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    final first = lastAd();
    first.listener.onAdLoaded!(first);
    await tester.pumpAndSettle();
    expect(loadCalls(), hasLength(1));
    expect(find.byType(AdWidget), findsNothing);
    adaptiveHeight = () async => 50;
    await tester.pump(const Duration(seconds: 30));
    await tester.pumpAndSettle();
    expect(loadCalls(), hasLength(2));
    final ad = lastAd();
    ad.listener.onAdLoaded!(ad);
    await tester.pumpAndSettle();
    expect(
      tester.getSize(find.byKey(const ValueKey('admob-banner'))).height,
      50,
    );
    await removeApp(tester);
  });

  testWidgets('native load exceptions are contained and retried', (
    tester,
  ) async {
    throwOnLoad = true;
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    expect(find.byType(AdWidget), findsNothing);
    expect(tester.takeException(), isNull);
    throwOnLoad = false;
    await tester.pump(const Duration(seconds: 30));
    await tester.pumpAndSettle();
    expect(loadCalls(), hasLength(2));
    await removeApp(tester);
  });

  testWidgets('leaving the screen cancels a pending size request safely', (
    tester,
  ) async {
    final pendingSize = Completer<int?>();
    adaptiveHeight = () => pendingSize.future;
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    final ad = lastAd();
    ad.listener.onAdLoaded!(ad);
    await tester.pumpAndSettle();
    await removeApp(tester);
    pendingSize.complete(50);
    await tester.pumpAndSettle();
    expect(loadCalls(), hasLength(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('unknown and offline internet reserve no space or SDK requests', (
    tester,
  ) async {
    initialInternetStatus = null;
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    final originalTop = contentTop(tester);
    expect(service.initializationCalls, 0);
    expect(calls, isEmpty);
    expect(find.byType(AdWidget), findsNothing);

    // This also represents Wi-Fi whose external reachability probes fail.
    setInternet(InternetStatus.disconnected);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(minutes: 3));
    expect(service.initializationCalls, 0);
    expect(calls, isEmpty);
    expect(contentTop(tester), originalTop);

    setInternet(InternetStatus.connected);
    await tester.pumpAndSettle();
    expect(loadCalls(), hasLength(1));
    expect(contentTop(tester), originalTop);
    final ad = lastAd();
    ad.listener.onAdLoaded!(ad);
    await tester.pumpAndSettle();
    expect(contentTop(tester), originalTop + 54);
    await removeApp(tester);
  });

  testWidgets(
    'disconnect removes a loaded banner and reconnect loads a new ad',
    (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();
      final originalTop = contentTop(tester);
      final first = lastAd();
      first.listener.onAdLoaded!(first);
      await tester.pumpAndSettle();
      expect(find.byType(AdWidget), findsOneWidget);

      setInternet(InternetStatus.disconnected);
      await tester.pumpAndSettle();
      expect(find.byType(AdWidget), findsNothing);
      expect(contentTop(tester), originalTop);
      expect(calls.where((call) => call.method == 'disposeAd'), hasLength(1));
      first.listener.onAdLoaded!(first);
      await tester.pump(const Duration(minutes: 3));
      expect(loadCalls(), hasLength(1));
      expect(find.byType(AdWidget), findsNothing);

      setInternet(InternetStatus.connected);
      await tester.pumpAndSettle();
      expect(loadCalls(), hasLength(2));
      expect(contentTop(tester), originalTop);
      final second = lastAd();
      second.listener.onAdLoaded!(second);
      await tester.pumpAndSettle();
      expect(contentTop(tester), originalTop + 54);

      second.listener.onAdFailedToLoad!(
        second,
        LoadAdError(3, 'test', 'No fill', null),
      );
      await tester.pumpAndSettle();
      setInternet(InternetStatus.disconnected);
      await tester.pumpAndSettle();
      await tester.pump(const Duration(minutes: 3));
      expect(
        loadCalls(),
        hasLength(2),
        reason: 'Offline cancels pending retries',
      );
      await removeApp(tester);
    },
  );

  testWidgets('disconnect invalidates an ad that has not finished loading', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    final pendingAd = lastAd();
    setInternet(InternetStatus.disconnected);
    await tester.pumpAndSettle();
    pendingAd.listener.onAdLoaded!(pendingAd);
    pendingAd.listener.onAdFailedToLoad!(
      pendingAd,
      LoadAdError(2, 'test', 'Late network error', null),
    );
    await tester.pumpAndSettle();
    expect(find.byType(AdWidget), findsNothing);
    expect(calls.where((call) => call.method == 'disposeAd'), hasLength(1));
    await tester.pump(const Duration(minutes: 3));
    expect(loadCalls(), hasLength(1));
    expect(tester.takeException(), isNull);
    await removeApp(tester);
  });

  testWidgets('disconnect invalidates a pending adaptive-size lookup', (
    tester,
  ) async {
    final pendingSize = Completer<int?>();
    adaptiveHeight = () => pendingSize.future;
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    final ad = lastAd();
    ad.listener.onAdLoaded!(ad);
    await tester.pumpAndSettle();
    setInternet(InternetStatus.disconnected);
    await tester.pumpAndSettle();
    pendingSize.complete(50);
    await tester.pumpAndSettle();
    expect(loadCalls(), hasLength(1));
    expect(find.byType(AdWidget), findsNothing);

    adaptiveHeight = () async => 50;
    setInternet(InternetStatus.connected);
    await tester.pumpAndSettle();
    expect(loadCalls(), hasLength(2));
    expect(tester.takeException(), isNull);
    await removeApp(tester);
  });

  testWidgets('monitor errors hide ads and a later online status recovers', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    final first = lastAd();
    first.listener.onAdLoaded!(first);
    await tester.pumpAndSettle();

    internetChanges.addError(StateError('Reachability monitoring failed'));
    await tester.pumpAndSettle();
    expect(find.byType(AdWidget), findsNothing);
    expect(tester.takeException(), isNull);
    setInternet(InternetStatus.connected);
    await tester.pumpAndSettle();
    expect(loadCalls(), hasLength(2));
    await removeApp(tester);
  });

  testWidgets('resume starts a fresh check before allowing any new ad', (
    tester,
  ) async {
    addTearDown(() {
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    });
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    final first = lastAd();
    first.listener.onAdLoaded!(first);
    await tester.pumpAndSettle();
    expect(monitorSubscriptions, 1);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pumpAndSettle();
    expect(internetChanges.hasListener, isFalse);
    // Paused apps do not render queued rebuilds. Verify native cleanup now;
    // verify the collapsed widget after frames resume below.
    expect(calls.where((call) => call.method == 'disposeAd'), hasLength(1));
    initialInternetStatus = null;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(monitorSubscriptions, 2);
    expect(find.byType(AdWidget), findsNothing);
    expect(loadCalls(), hasLength(1));

    setInternet(InternetStatus.disconnected);
    await tester.pumpAndSettle();
    expect(loadCalls(), hasLength(1));
    setInternet(InternetStatus.connected);
    await tester.pumpAndSettle();
    expect(loadCalls(), hasLength(2));
    await removeApp(tester);
  });

  testWidgets('reconnect retries SDK cooldown even without a service event', (
    tester,
  ) async {
    service.allowed = false;
    service.retrySetup = true;
    service.onInitialize = () {
      if (service.initializationCalls == 1) {
        service.notifyListeners();
      } else if (service.initializationCalls >= 3) {
        service.allowed = true;
        service.retrySetup = false;
        service.notifyListeners();
      }
      // The second call emulates initialize() returning early during cooldown.
    };
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    expect(service.initializationCalls, 1);
    setInternet(InternetStatus.disconnected);
    await tester.pumpAndSettle();
    setInternet(InternetStatus.connected);
    await tester.pumpAndSettle();
    expect(service.initializationCalls, 2);
    expect(loadCalls(), isEmpty);

    await tester.pump(const Duration(seconds: 30));
    await tester.pumpAndSettle();
    expect(service.initializationCalls, 3);
    expect(loadCalls(), hasLength(1));
    await removeApp(tester);
  });

  testWidgets(
    'leaving during an initial connectivity check cancels monitoring',
    (tester) async {
      initialInternetStatus = null;
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();
      expect(internetChanges.hasListener, isTrue);
      await removeApp(tester);
      expect(internetChanges.hasListener, isFalse);
      setInternet(InternetStatus.connected);
      await tester.pumpAndSettle();
      expect(service.initializationCalls, 0);
      expect(calls, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );
}

class _TestAdMobService extends AdMobService {
  bool allowed = true;
  bool retrySetup = false;
  VoidCallback? onInitialize;
  int initializationCalls = 0;

  @override
  bool get isSupported => true;

  @override
  bool get canRequestAds => allowed;

  @override
  bool get isShowingPrivacyOptions => false;

  @override
  bool get needsInitializationRetry => retrySetup;

  @override
  Future<void> initialize() async {
    initializationCalls++;
    onInitialize?.call();
  }

  void setAllowed(bool value) {
    allowed = value;
    notifyListeners();
  }
}
