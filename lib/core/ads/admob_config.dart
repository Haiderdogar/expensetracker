import 'package:flutter/foundation.dart';

/// AdMob identifiers are public client configuration, not authentication keys.
abstract final class AdMobConfig {
  static const _forceTestAds = bool.fromEnvironment('ADMOB_USE_TEST_ADS');

  static bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Development and profile builds must never request production ads.
  static String get bannerAdUnitId => !kReleaseMode || _forceTestAds
      ? 'ca-app-pub-3940256099942544/9214589741'
      : 'ca-app-pub-9634940728444652/3221555434';
}
