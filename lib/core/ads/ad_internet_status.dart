import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

/// Each monitor owns its checker so resumed banner sessions cannot inherit
/// a stale status from the app-wide InternetConnection singleton.
final adInternetCheckerFactoryProvider = Provider<InternetConnection Function()>(
  (ref) =>
      () => InternetConnection.createInstance(
        // An interface change requests a reachability check; Wi-Fi/mobile presence
        // alone never grants permission to load an ad.
        triggerStream: Connectivity().onConnectivityChanged,
      ),
);

/// Loading and errors are deliberately not interpreted as connected by the UI.
/// Listening starts a fresh probe, followed by network-triggered and periodic
/// checks. Closing the last subscription disposes only this private checker.
final adInternetStatusProvider = StreamProvider.autoDispose<InternetStatus>((
  ref,
) {
  final checker = ref.watch(adInternetCheckerFactoryProvider)();
  ref.onDispose(() => unawaited(_disposeChecker(checker)));
  return _statusesUntilClosed(checker.onStatusChange);
});

Stream<InternetStatus> _statusesUntilClosed(
  Stream<InternetStatus> statuses,
) async* {
  yield* statuses;
  // An unexpectedly ended monitor must not leave a previously loaded ad online.
  yield InternetStatus.disconnected;
}

Future<void> _disposeChecker(InternetConnection checker) async {
  try {
    await checker.dispose();
  } catch (error) {
    debugPrint('Ad internet monitor disposal failed: $error');
  }
}
