import 'dart:async';

import 'package:expensetracker/core/ads/admob_config.dart';
import 'package:expensetracker/core/ads/admob_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
// Use the SDK codecs to verify the actual native channel contracts.
// ignore: implementation_imports
import 'package:google_mobile_ads/src/ad_instance_manager.dart';
// ignore: implementation_imports
import 'package:google_mobile_ads/src/ump/user_messaging_codec.dart';

final _umpChannel = MethodChannel(
  'plugins.flutter.io/google_mobile_ads/ump',
  StandardMethodCodec(UserMessagingCodec()),
);
final _adsChannel = MethodChannel(
  'plugins.flutter.io/google_mobile_ads',
  StandardMethodCodec(AdMessageCodec()),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _AdMobPlatform platform;

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    platform = _AdMobPlatform()..install();
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(_umpChannel, null);
    messenger.setMockMethodCallHandler(_adsChannel, null);
  });

  test('development builds use the official Android test banner', () {
    expect(AdMobConfig.isSupported, isTrue);
    expect(
      AdMobConfig.dashboardBannerAdUnitId,
      'ca-app-pub-3940256099942544/9214589741',
    );
  });

  test('unsupported platforms never invoke the advertising SDKs', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    final service = AdMobService();
    addTearDown(service.dispose);

    await service.initialize();
    await service.showPrivacyOptions();

    expect(service.isSupported, isFalse);
    expect(service.canRequestAds, isFalse);
    expect(service.needsInitializationRetry, isFalse);
    expect(platform.calls, isEmpty);
  });

  test('waits for consent and shares concurrent initialization', () async {
    platform.consentForm = Completer<void>();
    final service = AdMobService();
    addTearDown(service.dispose);

    final first = service.initialize();
    final second = service.initialize();
    await Future<void>.delayed(Duration.zero);

    expect(identical(first, second), isTrue);
    expect(platform.consentUpdates, 1);
    expect(platform.sdkInitializations, 0);
    expect(service.canRequestAds, isFalse);

    platform.consentForm!.complete();
    await Future.wait([first, second]);
    await service.initialize();

    expect(service.canRequestAds, isTrue);
    expect(service.needsInitializationRetry, isFalse);
    expect(platform.sdkInitializations, 1);
    expect(platform.consentUpdates, 1);
    expect(
      platform.calls.indexOf('ConsentInformation#canRequestAds'),
      lessThan(platform.calls.indexOf('MobileAds#initialize')),
    );
  });

  test(
    'does not initialize or request ads when UMP withholds permission',
    () async {
      platform.allowed = false;
      final service = AdMobService();
      addTearDown(service.dispose);

      await service.initialize();
      await service.initialize();

      expect(service.canRequestAds, isFalse);
      expect(service.needsInitializationRetry, isFalse);
      expect(platform.sdkInitializations, 0);
      expect(platform.consentUpdates, 1);
    },
  );

  test('uses valid cached consent after an update network failure', () async {
    platform.consentUpdateError = PlatformException(
      code: '2',
      message: 'Network unavailable',
    );
    final service = AdMobService();
    addTearDown(service.dispose);

    await expectLater(service.initialize(), completes);

    expect(service.canRequestAds, isTrue);
    expect(platform.sdkInitializations, 1);
    expect(
      platform.calls,
      isNot(contains('UserMessagingPlatform#loadAndShowConsentFormIfRequired')),
    );
  });

  testWidgets(
    'retries failed SDK setup after a cooldown without repeating UMP',
    (tester) async {
      platform.sdkError = PlatformException(code: 'SDK_UNAVAILABLE');
      final service = AdMobService();
      try {
        await service.initialize();
        await service.initialize();
        expect(service.canRequestAds, isFalse);
        expect(service.needsInitializationRetry, isTrue);
        expect(platform.sdkInitializations, 1);

        platform.sdkError = null;
        await tester.pump(const Duration(seconds: 30));
        await service.initialize();

        expect(service.canRequestAds, isTrue);
        expect(service.needsInitializationRetry, isFalse);
        expect(platform.sdkInitializations, 2);
        expect(platform.consentUpdates, 1);
      } finally {
        service.dispose();
        // Flutter checks testWidgets debug invariants before normal tearDown.
        debugDefaultTargetPlatformOverride = null;
      }
    },
  );

  test('missing consent plugins never escape as unhandled errors', () async {
    platform.consentUpdateError = MissingPluginException('UMP unavailable');
    platform.consentStatusError = MissingPluginException('UMP unavailable');
    final service = AdMobService();
    addTearDown(service.dispose);

    await expectLater(service.initialize(), completes);
    await service.initialize();

    expect(service.canRequestAds, isFalse);
    expect(service.needsInitializationRetry, isTrue);
    expect(platform.consentUpdates, 1);
    expect(platform.sdkInitializations, 0);
  });

  test(
    'hides ads while options are open and respects revoked consent',
    () async {
      platform.optionsRequired = true;
      platform.privacyForm = Completer<void>();
      final service = AdMobService();
      addTearDown(service.dispose);
      await service.initialize();
      expect(service.privacyOptionsRequired, isTrue);
      expect(service.canRequestAds, isTrue);

      final changes = <bool>[];
      service.addListener(() => changes.add(service.canRequestAds));
      final options = service.showPrivacyOptions();
      await Future<void>.delayed(Duration.zero);

      expect(service.isShowingPrivacyOptions, isTrue);
      expect(service.canRequestAds, isFalse);
      expect(service.needsInitializationRetry, isFalse);
      platform.allowed = false;
      platform.privacyForm!.complete();
      await options;

      expect(service.isShowingPrivacyOptions, isFalse);
      expect(service.canRequestAds, isFalse);
      expect(service.needsInitializationRetry, isFalse);
      expect(changes, everyElement(isFalse));
      expect(platform.sdkInitializations, 1);
    },
  );

  test('restores eligible ads after privacy choices close', () async {
    platform.optionsRequired = true;
    final service = AdMobService();
    addTearDown(service.dispose);
    await service.initialize();

    await service.showPrivacyOptions();

    expect(service.isShowingPrivacyOptions, isFalse);
    expect(service.canRequestAds, isTrue);
    expect(platform.sdkInitializations, 1);
    expect(platform.consentUpdates, 1);
  });

  test(
    'late consent completion does not initialize ads or notify after dispose',
    () async {
      platform.consentForm = Completer<void>();
      final service = AdMobService();
      var notifications = 0;
      service.addListener(() => notifications++);

      final pending = service.initialize();
      await Future<void>.delayed(Duration.zero);
      service.dispose();
      platform.consentForm!.complete();
      await pending;

      expect(platform.sdkInitializations, 0);
      expect(notifications, 0);
      expect(service.canRequestAds, isFalse);
    },
  );
}

class _AdMobPlatform {
  final calls = <String>[];
  bool allowed = true;
  bool optionsRequired = false;
  int consentUpdates = 0;
  int sdkInitializations = 0;
  Object? consentUpdateError;
  Object? consentStatusError;
  Object? sdkError;
  Completer<void>? consentForm;
  Completer<void>? privacyForm;

  void install() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(_umpChannel, _handleConsentCall);
    messenger.setMockMethodCallHandler(_adsChannel, _handleAdsCall);
  }

  Future<Object?> _handleConsentCall(MethodCall call) async {
    calls.add(call.method);
    switch (call.method) {
      case 'ConsentInformation#requestConsentInfoUpdate':
        consentUpdates++;
        if (consentUpdateError case final error?) throw error;
        return null;
      case 'UserMessagingPlatform#loadAndShowConsentFormIfRequired':
        await consentForm?.future;
        return null;
      case 'ConsentInformation#canRequestAds':
        if (consentStatusError case final error?) throw error;
        return allowed;
      case 'ConsentInformation#getPrivacyOptionsRequirementStatus':
        return optionsRequired ? 1 : 0;
      case 'UserMessagingPlatform#showPrivacyOptionsForm':
        await privacyForm?.future;
        return null;
      default:
        throw StateError('Unexpected consent call: ${call.method}');
    }
  }

  Future<Object?> _handleAdsCall(MethodCall call) async {
    calls.add(call.method);
    switch (call.method) {
      case '_init':
        return null;
      case 'MobileAds#initialize':
        sdkInitializations++;
        if (sdkError case final error?) throw error;
        return InitializationStatus({});
      default:
        throw StateError('Unexpected advertising call: ${call.method}');
    }
  }
}
