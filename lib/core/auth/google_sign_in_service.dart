import 'package:google_sign_in/google_sign_in.dart';

import '../../firebase_options.dart';

class GoogleSignInService {
  GoogleSignInService._();

  static Future<void>? _initialization;

  static Future<void> ensureInitialized() async {
    final existing = _initialization;
    if (existing != null) {
      return existing;
    }

    final initialization = _initialize();
    _initialization = initialization;
    try {
      await initialization;
    } catch (_) {
      if (identical(_initialization, initialization)) {
        _initialization = null;
      }
      rethrow;
    }
  }

  static Future<void> _initialize() async {
    final serverClientId = DefaultFirebaseOptions.googleServerClientId.trim();
    if (serverClientId.isEmpty) {
      throw StateError(
        'Google Sign-In is missing the Firebase Web OAuth client ID.',
      );
    }

    await GoogleSignIn.instance.initialize(serverClientId: serverClientId);
  }
}
