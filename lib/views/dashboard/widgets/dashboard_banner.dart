import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

import '../../../core/ads/ad_internet_status.dart';
import '../../../core/ads/admob_config.dart';
import '../../../core/ads/admob_service.dart';

/// Reserves space only for a loaded ad. The shell's Scaffold positions its FAB
/// above this widget and the navigation bar using their combined actual height.
class DashboardBanner extends ConsumerStatefulWidget {
  const DashboardBanner({super.key});

  @override
  ConsumerState<DashboardBanner> createState() => _DashboardBannerState();
}

class _DashboardBannerState extends ConsumerState<DashboardBanner>
    with WidgetsBindingObserver {
  late final AdMobService _service;
  ProviderSubscription<AsyncValue<InternetStatus>>? _internetSubscription;
  bool _hasInternet = false;
  int _internetGeneration = 0;
  BannerAd? _banner;
  bool _loaded = false;
  bool _loading = false;
  int _generation = 0;
  int _retryAttempt = 0;
  Timer? _retryTimer;
  (int, Orientation)? _dimensions;
  (int, Orientation)? _queuedDimensions;

  bool get _isForeground {
    final state = WidgetsBinding.instance.lifecycleState;
    return state == null || state == AppLifecycleState.resumed;
  }

  @override
  void initState() {
    super.initState();
    _service = ref.read(admobServiceProvider);
    _service.addListener(_onConsentChanged);
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startInternetMonitoring();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _service.removeListener(_onConsentChanged);
    _stopInternetMonitoring();
    _clearAd();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startInternetMonitoring();
      unawaited(_load());
    } else {
      _retryTimer?.cancel();
      _retryTimer = null;
      // Keep monitoring through brief inactive states such as native consent
      // dialogs. A real background transition requires a fresh check on resume.
      if (state == AppLifecycleState.paused ||
          state == AppLifecycleState.hidden ||
          state == AppLifecycleState.detached) {
        _stopInternetMonitoring();
        setState(_clearAd);
      }
    }
  }

  void _startInternetMonitoring() {
    if (!mounted ||
        !_service.isSupported ||
        !_isForeground ||
        _internetSubscription != null) {
      return;
    }

    // A fresh private checker prevents cached connectivity from a previous
    // Dashboard visit or app session from allowing an offline ad request.
    ref.invalidate(adInternetStatusProvider);
    final generation = ++_internetGeneration;
    _internetSubscription = ref.listenManual(adInternetStatusProvider, (
      _,
      next,
    ) {
      if (!mounted || generation != _internetGeneration) return;
      final hasInternet =
          !next.isLoading &&
          !next.hasError &&
          next.asData?.value == InternetStatus.connected;
      if (hasInternet == _hasInternet) return;

      setState(() {
        _hasInternet = hasInternet;
        _clearAd();
        _retryAttempt = 0;
      });
      if (hasInternet) unawaited(_load());
    }, fireImmediately: true);
  }

  void _stopInternetMonitoring() {
    _internetGeneration++;
    _internetSubscription?.close();
    _internetSubscription = null;
    _hasInternet = false;
  }

  void _onConsentChanged() {
    if (!mounted) return;
    if (!_service.canRequestAds || _service.isShowingPrivacyOptions) {
      setState(_clearAd);
      _scheduleRetry();
    } else {
      unawaited(_load());
    }
  }

  void _clearAd() {
    _generation++;
    _retryTimer?.cancel();
    _retryTimer = null;
    final previous = _banner;
    _banner = null;
    _loaded = false;
    _loading = false;
    if (previous != null) unawaited(_disposeAd(previous));
  }

  Future<void> _disposeAd(Ad ad) async {
    try {
      await ad.dispose();
    } catch (error) {
      debugPrint('Dashboard banner disposal failed: $error');
    }
  }

  bool _isCurrent(int generation) => mounted && generation == _generation;

  void _queueDimensions(int width, Orientation orientation) {
    final dimensions = (width, orientation);
    if (_dimensions == dimensions || _queuedDimensions == dimensions) return;
    _queuedDimensions = dimensions;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _queuedDimensions != dimensions) return;
      _queuedDimensions = null;
      setState(() {
        _clearAd();
        _dimensions = dimensions;
        _retryAttempt = 0;
      });
      unawaited(_load());
    });
  }

  Future<void> _load() async {
    final dimensions = _dimensions;
    if (!mounted ||
        !_service.isSupported ||
        !_hasInternet ||
        !_isForeground ||
        _service.isShowingPrivacyOptions ||
        _loading ||
        _banner != null ||
        _retryTimer != null ||
        dimensions == null ||
        dimensions.$1 <= 0) {
      return;
    }

    final generation = _generation;
    _loading = true;
    try {
      await _service.initialize();
      if (!_isCurrent(generation) ||
          !_hasInternet ||
          _service.isShowingPrivacyOptions ||
          !_isForeground) {
        return;
      }
      if (!_service.canRequestAds) {
        // initialize() may be in its cooldown after an earlier network failure
        // and return without notifying listeners. Do not lose the reconnect.
        if (_service.needsInitializationRetry) _scheduleRetry();
        return;
      }

      final size =
          await AdSize.getLargeAnchoredAdaptiveBannerAdSizeWithOrientation(
            dimensions.$2,
            dimensions.$1,
          );
      if (!_isCurrent(generation) ||
          !_hasInternet ||
          !_service.canRequestAds ||
          !_isForeground) {
        return;
      }
      if (size == null || size.width <= 0 || size.height <= 0) {
        _scheduleRetry();
        return;
      }

      final banner = BannerAd(
        adUnitId: AdMobConfig.dashboardBannerAdUnitId,
        size: size,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            if (!_isCurrent(generation) ||
                !_hasInternet ||
                !_service.canRequestAds ||
                !identical(_banner, ad)) {
              return;
            }
            setState(() {
              _loaded = true;
              _retryAttempt = 0;
            });
          },
          onAdFailedToLoad: (ad, error) {
            if (!_isCurrent(generation) || !identical(_banner, ad)) return;
            debugPrint('Dashboard banner could not load: $error');
            setState(_clearAd);
            _scheduleRetry();
          },
          // onAdClosed closes a click-through overlay, not the banner itself.
          // Keep its space reserved until the actual ad is removed.
        ),
      );
      _banner = banner;
      await banner.load();
    } catch (error) {
      if (!_isCurrent(generation)) return;
      debugPrint('Dashboard banner request failed: $error');
      setState(_clearAd);
      _scheduleRetry();
    } finally {
      if (_isCurrent(generation)) _loading = false;
    }
  }

  void _scheduleRetry() {
    if (!mounted ||
        !_hasInternet ||
        !_isForeground ||
        _service.isShowingPrivacyOptions ||
        (!_service.canRequestAds && !_service.needsInitializationRetry)) {
      return;
    }
    _retryTimer?.cancel();
    // Retry transient network/no-fill failures without a tight request loop.
    final seconds = 30 * (1 << _retryAttempt);
    if (_retryAttempt < 2) _retryAttempt++;
    _retryTimer = Timer(Duration(seconds: seconds), () {
      _retryTimer = null;
      unawaited(_load());
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_service.isSupported) return const SizedBox.shrink();

    return SafeArea(
      top: false,
      bottom: false,
      minimum: const EdgeInsets.symmetric(horizontal: 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth.floor();
          final orientation = MediaQuery.orientationOf(context);
          _queueDimensions(width, orientation);
          final banner = _banner;
          if (!_hasInternet ||
              !_loaded ||
              banner == null ||
              !_service.canRequestAds ||
              _dimensions != (width, orientation)) {
            return const SizedBox.shrink();
          }

          return ColoredBox(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Center(
                heightFactor: 1,
                child: SizedBox(
                  key: const ValueKey('dashboard-banner'),
                  width: banner.size.width.toDouble(),
                  height: banner.size.height.toDouble(),
                  child: AdWidget(key: ObjectKey(banner), ad: banner),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
