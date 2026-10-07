import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:expensetracker/core/updates/flexible_update_coordinator.dart';

const _updateMethods = MethodChannel('de.ffuf.in_app_update/methods');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_updateMethods, null);
  });

  test(
    'automatically completes an update already downloaded at startup',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final calls = <String>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_updateMethods, (call) async {
            calls.add(call.method);
            if (call.method == 'checkForUpdate') {
              return _updateInfo(
                availability:
                    UpdateAvailability.developerTriggeredUpdateInProgress,
                installStatus: InstallStatus.downloaded,
              );
            }
            return null;
          });

      final coordinator = FlexibleUpdateCoordinator();
      await coordinator.initialize();
      await coordinator.dispose();

      expect(calls, ['checkForUpdate', 'completeFlexibleUpdate']);
    },
  );

  test('starts a flexible download when an update is available', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final calls = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_updateMethods, (call) async {
          calls.add(call.method);
          if (call.method == 'checkForUpdate') {
            return _updateInfo(
              availability: UpdateAvailability.updateAvailable,
              installStatus: InstallStatus.pending,
            );
          }
          return null;
        });

    final coordinator = FlexibleUpdateCoordinator();
    await coordinator.initialize();
    await coordinator.dispose();

    expect(calls, ['checkForUpdate', 'startFlexibleUpdate']);
  });

  test(
    'does not let an unavailable Play environment escape the check',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_updateMethods, (call) async {
            throw PlatformException(
              code: 'PLAY_UNAVAILABLE',
              message: 'Google Play is unavailable',
            );
          });

      final coordinator = FlexibleUpdateCoordinator();
      await expectLater(coordinator.initialize(), completes);
      await coordinator.dispose();
    },
  );
}

Map<String, Object?> _updateInfo({
  required UpdateAvailability availability,
  required InstallStatus installStatus,
}) {
  return {
    'updateAvailability': availability.value,
    'immediateAllowed': false,
    'immediateAllowedPreconditions': null,
    'flexibleAllowed': true,
    'flexibleAllowedPreconditions': null,
    'availableVersionCode': 7,
    'installStatus': installStatus.value,
    'packageName': 'com.example.expensetracker',
    'clientVersionStalenessDays': null,
    'updatePriority': 0,
  };
}
