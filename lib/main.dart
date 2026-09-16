import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'app.dart';
import 'core/database/database_helper.dart';
import 'core/security/secure_storage_service.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';

void main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization warning: $e');
  }

  try {
    // google_sign_in 7.x must be initialized exactly once. Once the Firebase
    // config is regenerated it reads the Web OAuth client from
    // google-services.json; the define is a supported explicit fallback.
    await GoogleSignIn.instance.initialize(
      serverClientId: DefaultFirebaseOptions.googleServerClientId.isEmpty
          ? null
          : DefaultFirebaseOptions.googleServerClientId,
    );
  } catch (e) {
    debugPrint('Google Sign-In initialization warning: $e');
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
      child: const ExpenseTrackerApp(),
    ),
  );
}
