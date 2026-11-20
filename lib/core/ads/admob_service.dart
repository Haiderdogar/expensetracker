import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'admob_config.dart';

final admobServiceProvider = Provider<AdMobService>((ref) {
  final service = AdMobService();
  ref.onDispose(service.dispose);
  return service;
});

/// Coordinates UMP consent and SDK initialization for the current app session.
class AdMobService extends ChangeNotifier {
  Future<void>? _initialization;
  Future<void>? _privacyOptions;
  Timer? _retryCooldown;
  bool _disposed = false;
  bool _consentFlowCompleted = false;
  bool _sessionPrepared = false;
  bool _sdkInitialized = false;
  bool _canRequestAds = false;
  bool _privacyOptionsRequired = false;
  bool _isShowingPrivacyOptions = false;

  bool get isSupported => AdMobConfig.isSupported;
  bool get canRequestAds => _canRequestAds && !_disposed;
  bool get privacyOptionsRequired => _privacyOptionsRequired && !_disposed;
  bool get isShowingPrivacyOptions => _isShowingPrivacyOptions && !_disposed;

  /// A completed consent decision needs no background polling. Failed setup
  /// can be retried by the banner after the service's cooldown has elapsed.
  bool get needsInitializationRetry =>
      !_disposed &&
      isSupported &&
      !_sessionPrepared &&
      !_isShowingPrivacyOptions;

  /// Call after the first frame so UMP can present any required native form.
  /// Repeated banner mounts share the same consent and initialization work.
  Future<void> initialize() {
    if (_disposed || !isSupported) return Future<void>.value();
    if (_isShowingPrivacyOptions) {
      return _privacyOptions ?? Future<void>.value();
    }
    if (_initialization case final pending?) return pending;
    if (_sessionPrepared || (_retryCooldown?.isActive ?? false)) {
      return Future<void>.value();
    }

    return _initialization = _initialize().whenComplete(() {
      _initialization = null;
    });
  }

  Future<void> _initialize() async {
    try {
      if (!_consentFlowCompleted) {
        final updated = await _requestConsentUpdate();
        if (_disposed) return;
        if (updated) {
          FormError? formError;
          await ConsentForm.loadAndShowConsentFormIfRequired((error) {
            formError = error;
            if (error != null) _reportFormError('Consent form', error);
          });
          if (_disposed) return;
          _consentFlowCompleted = formError == null;
        }
      }

      // UMP may still permit ads using consent from a previous app session
      // when the current consent update or form could not be loaded.
      final allowed = await _refreshConsentAndSdk();
      if (_disposed) return;
      _sessionPrepared = _consentFlowCompleted && (!allowed || _sdkInitialized);
      if (!_sessionPrepared) _deferRetry();
    } catch (error, stackTrace) {
      _canRequestAds = false;
      _reportError('AdMob setup', error, stackTrace);
      _deferRetry();
    } finally {
      _notifyIfActive();
    }
  }

  Future<bool> _requestConsentUpdate() {
    final result = Completer<bool>();
    void complete(bool succeeded) {
      if (!result.isCompleted) result.complete(succeeded);
    }

    // The SDK exposes this operation as async void and catches only native
    // PlatformException errors. Keep missing-plugin errors in this zone too.
    runZonedGuarded(
      () {
        ConsentInformation.instance.requestConsentInfoUpdate(
          ConsentRequestParameters(),
          () => complete(true),
          (error) {
            _reportFormError('Consent update', error);
            complete(false);
          },
        );
      },
      (error, stackTrace) {
        _reportError('Consent update', error, stackTrace);
        complete(false);
      },
    );
    return result.future;
  }

  Future<bool> _refreshConsentAndSdk() async {
    final allowed = await ConsentInformation.instance.canRequestAds();
    final privacyStatus = await ConsentInformation.instance
        .getPrivacyOptionsRequirementStatus();
    if (_disposed) return false;
    _privacyOptionsRequired =
        privacyStatus == PrivacyOptionsRequirementStatus.required;

    if (!allowed) {
      _canRequestAds = false;
      return false;
    }
    if (!_sdkInitialized) {
      _sdkInitialized = await _initializeSdk();
    }
    if (_disposed) return false;
    _canRequestAds = _sdkInitialized && !_isShowingPrivacyOptions;
    return allowed;
  }

  Future<bool> _initializeSdk() {
    final result = Completer<bool>();
    void complete(bool succeeded) {
      if (!result.isCompleted) result.complete(succeeded);
    }

    // Accessing MobileAds.instance also performs an internal, unawaited
    // platform call. Guard that call as well as initialize() itself.
    runZonedGuarded(
      () async {
        try {
          await MobileAds.instance.initialize();
          complete(true);
        } catch (error, stackTrace) {
          _reportError('Mobile Ads initialization', error, stackTrace);
          complete(false);
        }
      },
      (error, stackTrace) {
        _reportError('Mobile Ads initialization', error, stackTrace);
        complete(false);
      },
    );
    return result.future;
  }

  /// Hides current ads before a user revisits their advertising choices.
  Future<void> showPrivacyOptions() {
    if (_disposed || !isSupported || !_privacyOptionsRequired) {
      return Future<void>.value();
    }
    if (_privacyOptions case final pending?) return pending;
    if (_isShowingPrivacyOptions) return Future<void>.value();

    return _privacyOptions = _showPrivacyOptions().whenComplete(() {
      _privacyOptions = null;
    });
  }

  Future<void> _showPrivacyOptions() async {
    _isShowingPrivacyOptions = true;
    _canRequestAds = false;
    _notifyIfActive();
    try {
      await _initialization;
      if (_disposed) return;
      await ConsentForm.showPrivacyOptionsForm((error) {
        if (error != null) _reportFormError('Ad privacy options', error);
      });
      if (_disposed) return;
      _isShowingPrivacyOptions = false;
      final allowed = await _refreshConsentAndSdk();
      if (_disposed) return;
      _sessionPrepared = _consentFlowCompleted && (!allowed || _sdkInitialized);
      if (!_sessionPrepared) _deferRetry();
    } catch (error, stackTrace) {
      _canRequestAds = false;
      _sessionPrepared = false;
      _reportError('Ad privacy options', error, stackTrace);
      _deferRetry();
    } finally {
      _isShowingPrivacyOptions = false;
      _notifyIfActive();
    }
  }

  void _deferRetry() {
    if (_disposed) return;
    _retryCooldown?.cancel();
    // Permit a later screen visit to retry, without repeatedly requesting
    // consent or initialization during rebuilds and rapid tab changes.
    _retryCooldown = Timer(const Duration(seconds: 30), () {
      _retryCooldown = null;
    });
  }

  void _notifyIfActive() {
    if (!_disposed) notifyListeners();
  }

  void _reportFormError(String operation, FormError error) {
    debugPrint('$operation failed (${error.errorCode}): ${error.message}');
  }

  void _reportError(String operation, Object error, StackTrace stackTrace) {
    debugPrint('$operation failed: $error\n$stackTrace');
  }

  @override
  void dispose() {
    _disposed = true;
    _retryCooldown?.cancel();
    super.dispose();
  }
}
