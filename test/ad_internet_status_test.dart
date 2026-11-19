import 'dart:async';

import 'package:expensetracker/core/ads/ad_internet_status.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

void main() {
  test(
    'waits for a fresh reachability probe before exposing online status',
    () async {
      final probe = Completer<bool>();
      final checker = _TrackingChecker(probe: () => probe.future);
      final container = _containerFor(() => checker);
      addTearDown(container.dispose);
      final subscription = container.listen(
        adInternetStatusProvider,
        (_, _) {},
      );
      addTearDown(subscription.close);

      expect(container.read(adInternetStatusProvider).isLoading, isTrue);
      await _flushEvents();
      expect(checker.probeCount, 1);
      expect(container.read(adInternetStatusProvider).isLoading, isTrue);

      probe.complete(true);
      expect(
        await container.read(adInternetStatusProvider.future),
        InternetStatus.connected,
      );
    },
  );

  test(
    'a Wi-Fi change still requires working internet and reconnects later',
    () async {
      final networkChanges = StreamController<Object>.broadcast();
      addTearDown(networkChanges.close);
      var reachable = false;
      final checker = _TrackingChecker(
        probe: () async => reachable,
        triggerStream: networkChanges.stream,
      );
      final container = _containerFor(() => checker);
      addTearDown(container.dispose);
      final statuses = <InternetStatus>[];
      final subscription = container.listen(adInternetStatusProvider, (
        _,
        status,
      ) {
        if (status case AsyncData(:final value)) statuses.add(value);
      });
      addTearDown(subscription.close);

      expect(
        await container.read(adInternetStatusProvider.future),
        InternetStatus.disconnected,
      );
      final initialProbeCount = checker.probeCount;
      networkChanges.add('wifi-connected-without-internet');
      await _flushEvents();
      expect(checker.probeCount, greaterThan(initialProbeCount));
      expect(
        container.read(adInternetStatusProvider).asData?.value,
        InternetStatus.disconnected,
      );

      reachable = true;
      networkChanges.add('internet-restored');
      await _flushEvents();
      expect(
        container.read(adInternetStatusProvider).asData?.value,
        InternetStatus.connected,
      );
      expect(statuses, [InternetStatus.disconnected, InternetStatus.connected]);
    },
  );

  test('failed probes are offline rather than an unhandled error', () async {
    final checker = _TrackingChecker(
      probe: () => Future<bool>.error(StateError('Probe failed')),
    );
    final container = _containerFor(() => checker);
    addTearDown(container.dispose);
    final subscription = container.listen(adInternetStatusProvider, (_, _) {});
    addTearDown(subscription.close);

    expect(
      await container.read(adInternetStatusProvider.future),
      InternetStatus.disconnected,
    );
  });

  test('closing the last subscription disposes the owned checker', () async {
    final networkChanges = StreamController<Object>.broadcast();
    addTearDown(networkChanges.close);
    final checker = _TrackingChecker(
      probe: () async => true,
      triggerStream: networkChanges.stream,
    );
    final container = _containerFor(() => checker);
    addTearDown(container.dispose);
    final subscription = container.listen(adInternetStatusProvider, (_, _) {});
    await container.read(adInternetStatusProvider.future);
    expect(networkChanges.hasListener, isTrue);

    subscription.close();
    await container.pump();
    await checker.disposed.future;

    expect(checker.disposeCount, 1);
    expect(networkChanges.hasListener, isFalse);
    final probeCount = checker.probeCount;
    networkChanges.add('ignored-after-disposal');
    await _flushEvents();
    expect(checker.probeCount, probeCount);
  });

  test('invalidating the monitor creates a fresh checker and status', () async {
    final secondProbe = Completer<bool>();
    final first = _TrackingChecker(probe: () async => true);
    final second = _TrackingChecker(probe: () => secondProbe.future);
    var created = 0;
    final container = _containerFor(() => created++ == 0 ? first : second);
    addTearDown(container.dispose);
    final subscription = container.listen(adInternetStatusProvider, (_, _) {});
    addTearDown(subscription.close);
    await container.read(adInternetStatusProvider.future);

    container.invalidate(adInternetStatusProvider);
    final refreshed = container.read(adInternetStatusProvider);
    expect(refreshed.isLoading, isTrue);
    await _flushEvents();
    expect(created, 2);
    expect(first.disposeCount, 1);

    secondProbe.complete(false);
    await _flushEvents();
    expect(
      container.read(adInternetStatusProvider).asData?.value,
      InternetStatus.disconnected,
    );
  });

  test('an unexpectedly closed status stream becomes offline', () async {
    final statuses = StreamController<InternetStatus>();
    final checker = _ControlledChecker(statuses.stream);
    final container = _containerFor(() => checker);
    addTearDown(container.dispose);
    final subscription = container.listen(adInternetStatusProvider, (_, _) {});
    addTearDown(subscription.close);

    statuses.add(InternetStatus.connected);
    await container.read(adInternetStatusProvider.future);
    await statuses.close();
    await _flushEvents();

    expect(
      container.read(adInternetStatusProvider).asData?.value,
      InternetStatus.disconnected,
    );
  });

  test(
    'source errors surface as unavailable and later status can recover',
    () async {
      final statuses = StreamController<InternetStatus>();
      final checker = _ControlledChecker(statuses.stream);
      final container = _containerFor(() => checker);
      addTearDown(container.dispose);
      final subscription = container.listen(
        adInternetStatusProvider,
        (_, _) {},
      );
      addTearDown(subscription.close);

      statuses.add(InternetStatus.connected);
      await container.read(adInternetStatusProvider.future);
      statuses.addError(StateError('Monitor failed'));
      await _flushEvents();
      expect(container.read(adInternetStatusProvider).hasError, isTrue);

      statuses.add(InternetStatus.connected);
      await _flushEvents();
      expect(
        container.read(adInternetStatusProvider).asData?.value,
        InternetStatus.connected,
      );
      await statuses.close();
    },
  );
}

ProviderContainer _containerFor(InternetConnection Function() factory) =>
    ProviderContainer(
      overrides: [adInternetCheckerFactoryProvider.overrideWithValue(factory)],
    );

Future<void> _flushEvents() async {
  for (var i = 0; i < 5; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

class _TrackingChecker extends InternetConnection {
  _TrackingChecker({
    required Future<bool> Function() probe,
    Stream<Object>? triggerStream,
  }) : super.createInstance(
         useDefaultOptions: false,
         customCheckOptions: [
           InternetCheckOption(uri: Uri.parse('https://test.invalid')),
         ],
         triggerStream: triggerStream,
         customConnectivityCheck: (option) async =>
             InternetCheckResult(option: option, isSuccess: await probe()),
       );

  int probeCount = 0;
  int disposeCount = 0;
  final disposed = Completer<void>();

  @override
  Future<bool> get hasInternetAccess {
    probeCount++;
    return super.hasInternetAccess;
  }

  @override
  Future<void> dispose() async {
    disposeCount++;
    await super.dispose();
    if (!disposed.isCompleted) disposed.complete();
  }
}

class _ControlledChecker extends InternetConnection {
  _ControlledChecker(this._statuses) : super.createInstance();

  final Stream<InternetStatus> _statuses;

  @override
  Stream<InternetStatus> get onStatusChange => _statuses;
}
