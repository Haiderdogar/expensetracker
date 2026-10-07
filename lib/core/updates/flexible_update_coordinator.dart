import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:in_app_update/in_app_update.dart';

class FlexibleUpdateCoordinator with WidgetsBindingObserver {
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  StreamSubscription<InstallStatus>? _installStatusSubscription;
  bool _started = false;
  bool _disposed = false;
  bool _downloadReady = false;
  bool _installPromptShown = false;

  Future<void> initialize() async {
    if (_started ||
        _disposed ||
        defaultTargetPlatform != TargetPlatform.android) {
      return;
    }
    _started = true;
    WidgetsBinding.instance.addObserver(this);

    late final AppUpdateInfo updateInfo;
    try {
      updateInfo = await InAppUpdate.checkForUpdate();
    } on PlatformException catch (error, stackTrace) {
      debugPrint('In-app update check failed: $error\n$stackTrace');
      return;
    } on MissingPluginException catch (error, stackTrace) {
      debugPrint('In-app update is unavailable: $error\n$stackTrace');
      return;
    } catch (error, stackTrace) {
      debugPrint('In-app update check failed: $error\n$stackTrace');
      return;
    }

    if (_disposed) return;

    if (updateInfo.installStatus == InstallStatus.downloaded) {
      await _completeUpdate();
      return;
    }

    if (updateInfo.updateAvailability ==
        UpdateAvailability.developerTriggeredUpdateInProgress) {
      _listenForInstallStatus();
      return;
    }

    if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
      _listenForInstallStatus();
      try {
        final result = await InAppUpdate.startFlexibleUpdate();
        switch (result) {
          case AppUpdateResult.success:
            break;
          case AppUpdateResult.userDeniedUpdate:
            debugPrint('The user declined the flexible in-app update.');
            break;
          case AppUpdateResult.inAppUpdateFailed:
            debugPrint(
              'Google Play could not start the flexible in-app update.',
            );
            break;
        }
      } on PlatformException catch (error, stackTrace) {
        debugPrint(
          'Could not start the flexible in-app update: $error\n$stackTrace',
        );
      } on MissingPluginException catch (error, stackTrace) {
        debugPrint('In-app update is unavailable: $error\n$stackTrace');
      } catch (error, stackTrace) {
        debugPrint(
          'Could not start the flexible in-app update: $error\n$stackTrace',
        );
      }
    }
  }

  void _listenForInstallStatus() {
    if (_disposed || _installStatusSubscription != null) return;

    try {
      _installStatusSubscription = InAppUpdate.installUpdateListener.listen(
        _handleInstallStatus,
        onError: (Object error, [StackTrace? stackTrace]) {
          debugPrint('In-app update status stream failed: $error');
          if (stackTrace != null) debugPrint('$stackTrace');
        },
      );
    } on PlatformException catch (error, stackTrace) {
      debugPrint('Could not monitor the in-app update: $error\n$stackTrace');
    } on MissingPluginException catch (error, stackTrace) {
      debugPrint(
        'In-app update monitoring is unavailable: $error\n$stackTrace',
      );
    } catch (error, stackTrace) {
      debugPrint('Could not monitor the in-app update: $error\n$stackTrace');
    }
  }

  void _handleInstallStatus(InstallStatus status) {
    if (_disposed) return;

    switch (status) {
      case InstallStatus.downloaded:
        _downloadReady = true;
        _showInstallPrompt();
      case InstallStatus.failed:
        debugPrint('Google Play failed to download the in-app update.');
      case InstallStatus.canceled:
        debugPrint('The flexible in-app update was canceled.');
      case InstallStatus.unknown:
      case InstallStatus.pending:
      case InstallStatus.downloading:
      case InstallStatus.installing:
      case InstallStatus.installed:
        break;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _downloadReady) {
      _showInstallPrompt();
    }
  }

  void _showInstallPrompt() {
    if (_disposed ||
        _installPromptShown ||
        WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) {
      return;
    }
    final messenger = scaffoldMessengerKey.currentState;
    if (messenger == null) {
      debugPrint(
        'Cannot show the in-app update prompt without an app messenger.',
      );
      return;
    }

    _installPromptShown = true;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('An update is ready to install.'),
          duration: const Duration(seconds: 10),
          action: SnackBarAction(
            label: 'Install / Restart',
            onPressed: () => unawaited(_completeUpdate()),
          ),
        ),
      );
  }

  Future<void> _completeUpdate() async {
    try {
      await InAppUpdate.completeFlexibleUpdate();
    } on PlatformException catch (error, stackTrace) {
      _reportInstallFailure(error, stackTrace);
    } on MissingPluginException catch (error, stackTrace) {
      _reportInstallFailure(error, stackTrace);
    } catch (error, stackTrace) {
      _reportInstallFailure(error, stackTrace);
    }
  }

  void _reportInstallFailure(Object error, StackTrace stackTrace) {
    debugPrint(
      'Could not install the downloaded in-app update: $error\n$stackTrace',
    );
    scaffoldMessengerKey.currentState
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text(
            'The update could not be installed. Please try again later.',
          ),
        ),
      );
  }

  Future<void> dispose() async {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    await _installStatusSubscription?.cancel();
    _installStatusSubscription = null;
  }
}
