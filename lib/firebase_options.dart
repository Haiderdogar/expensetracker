import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

/// Android Firebase configuration for this Android-only application.
class DefaultFirebaseOptions {
  /// The Web OAuth client ID used by Android to request a Firebase-compatible
  /// Google ID token. Prefer the generated `google-services.json` entry; this
  /// optional define is useful until that file has been refreshed.
  ///
  /// Example:
  /// `flutter run --dart-define=GOOGLE_SERVER_CLIENT_ID=...apps.googleusercontent.com`
  static const googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue:
        '26459435888-8abike6aklbtmo74sur4ra590aom7kms.apps.googleusercontent.com',
  );

  static const FirebaseOptions currentPlatform = android;

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAT-vnbIy6fD7P4y359qNc8G8fjSY2p3qw',
    appId: '1:26459435888:android:0dadd0dbc5db4d748915b5',
    messagingSenderId: '26459435888',
    projectId: 'expensetracker-c93d4',
    storageBucket: 'expensetracker-c93d4.firebasestorage.app',
  );
}
