import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import 'app.dart';
import 'app/app_bootstrap.dart';
import 'core/auth/google_sign_in_service.dart';
import 'core/database/database_helper.dart';
import 'core/security/secure_storage_service.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';

void main() {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  runApp(
    AppBootstrap(
      initialize: _initializeApp,
      onInitializationFailure: FlutterNativeSplash.remove,
      child: const ProviderScope(child: _AppLifecycle()),
    ),
  );
}

Future<void> _initializeApp() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await GoogleSignInService.ensureInitialized();
  await DatabaseHelper.instance.initializeInstallationIdentity(
    SecureStorageService(),
  );
}

class _AppLifecycle extends ConsumerStatefulWidget {
  const _AppLifecycle();

  @override
  ConsumerState<_AppLifecycle> createState() => _AppLifecycleState();
}

class _AppLifecycleState extends ConsumerState<_AppLifecycle> {
  late final AppLifecycleListener _listener;

  @override
  void initState() {
    super.initState();
    _listener = AppLifecycleListener(
      onPause: () =>
          ref.read(authControllerProvider.notifier).onAppBackgrounded(),
      onResume: _onResumed,
    );
  }

  Future<void> _onResumed() async {
    try {
      await ref.read(authControllerProvider.notifier).onAppResumed();
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'app lifecycle',
          context: ErrorDescription('while restoring the app lock'),
        ),
      );
      if (mounted) ref.invalidate(authControllerProvider);
    }
  }

  @override
  void dispose() {
    _listener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const ExpenseeApp();
}
