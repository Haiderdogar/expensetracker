import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import 'app.dart';
import 'core/auth/google_sign_in_service.dart';
import 'core/database/database_helper.dart';
import 'core/security/secure_storage_service.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';

void main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  String? startupError;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization warning: $e');
    startupError = 'Firebase could not be initialized. Check your connection and configuration.';
  }

  try {
    await GoogleSignInService.ensureInitialized();
  } catch (e) {
    debugPrint('Google Sign-In initialization warning: $e');
    startupError ??=
        'Google Sign-In could not be initialized. Please try again.';
  }

  final storage = SecureStorageService();
  await DatabaseHelper.instance.initializeInstallationIdentity(storage);

  final container = ProviderContainer();

  // AppLifecycleListener manages background/resume lock transitions without StatefulWidget
  AppLifecycleListener(
    onStateChange: (state) {
      final auth = container.read(authControllerProvider.notifier);
      if (state == AppLifecycleState.paused) {
        auth.onAppBackgrounded();
      } else if (state == AppLifecycleState.resumed) {
        auth.onAppResumed();
      }
    },
  );

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: ExpenseTrackerApp(startupError: startupError),
    ),
  );
}
