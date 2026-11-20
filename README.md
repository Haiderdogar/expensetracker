# Expensee

Expensee is a Flutter expense tracker for Android. It stores data locally and synchronizes signed-in users' data with Cloud Firestore.

## GitHub Actions builds

The `Android CI and Release` workflow runs `flutter analyze --no-fatal-infos` and `flutter test` for pull requests to `main` or `master` and pushes to any branch. This keeps existing info-level lints visible without making them block builds; warnings and errors still fail analysis.

- A branch push also builds split, release-signed APKs. Download them from the workflow run's **Artifacts** section in GitHub Actions. Choose the APK matching the device ABI.
- Pushing a tag in `vMAJOR.MINOR.PATCH` form (for example, `v1.2.3`) builds a signed Android App Bundle (`.aab`), uploads it as a workflow artifact, and attaches it to a GitHub Release. Upload that AAB to Play Console.
- Android build jobs require the Firebase config and upload-key secrets below. If they are missing, those jobs fail with an explicit configuration error; signing credentials are never committed to this repository.

### Required GitHub Actions secrets

Configure these in **Repository Settings → Secrets and variables → Actions**:

| Secret | Value |
| --- | --- |
| `GOOGLE_SERVICES_JSON_BASE64` | Base64-encoded contents of the Firebase Android `google-services.json` for this app. |
| `ANDROID_UPLOAD_KEYSTORE_BASE64` | Base64-encoded bytes of the Android upload keystore (`.jks`). |
| `ANDROID_KEY_ALIAS` | Alias of the upload key in that keystore. |
| `ANDROID_KEY_PASSWORD` | Password for the upload key. |
| `ANDROID_STORE_PASSWORD` | Password for the upload keystore. |

Create a dedicated upload keystore and keep a secure backup. On Windows, from the repository root:

```powershell
keytool -genkeypair -v -keystore android\upload-keystore.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload
[Convert]::ToBase64String([IO.File]::ReadAllBytes("android\upload-keystore.jks"))
```

Copy the Base64 output directly into the `ANDROID_UPLOAD_KEYSTORE_BASE64` secret; do not commit the keystore or paste passwords into workflow logs. Add the selected alias and passwords as the other three secrets. The workflow decodes the key only in its ephemeral runner. Git ignores `android\upload-keystore.jks` and `android\key.properties`.

For local signed release builds, create `android\key.properties` with the same key details:

```properties
storeFile=upload-keystore.jks
keyAlias=upload
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
```

The `storeFile` path is relative to the `android` directory. Release builds require an existing keystore and complete credentials; they do not fall back to debug signing. Local debug builds use the upload key when it is configured and present, otherwise they use Android's normal local debug key.

## Firebase, Google Sign-In, and Firestore setup

The Android application ID is `com.haiderdogar.expensee`. It must match the Android app registered in Firebase, the `package_name` in `google-services.json`, and the Play Console application.

1. In Firebase Console, enable Google under **Authentication → Sign-in method**. Confirm the OAuth consent screen and authorized domains/client configuration are complete in Google Cloud.
2. Add SHA-1 and SHA-256 fingerprints for every signing certificate used to install the app:
   - Local debug key, for local `flutter run` builds. The default Windows debug keystore is `%USERPROFILE%\.android\debug.keystore` (alias `androiddebugkey`, password `android`).
   - Upload key, used by CI APKs and to sign the AAB uploaded to Play. Get its fingerprints with `keytool -list -v -keystore android\upload-keystore.jks -alias upload`.
   - **Play App Signing key**, shown in Play Console under **Setup → App integrity**. The app downloaded from Play is signed with this key, not the upload key; register this certificate too.
3. Add those fingerprints to the matching Android app in Firebase project settings. Verify that the Web OAuth client ID configured for Google Sign-In matches a Web client in the Firebase project's `google-services.json` and `lib/firebase_options.dart`. After changing Firebase Android app settings, download the updated `google-services.json`.
4. Refresh the `GOOGLE_SERVICES_JSON_BASE64` GitHub secret from that downloaded file. The local file `android\app\google-services.json` is intentionally ignored by git. Never commit signing keys or passwords.
5. Deploy Firestore rules to the same Firebase project used by the app: `firebase deploy --project expensetracker-c93d4 --only firestore:rules`. Review `firestore.rules` before deployment and confirm the signed-in user's UID-scoped reads and writes are allowed.

## Google AdMob

Android banner ads use Google's official `google_mobile_ads` package (`9.2.0`). The AdMob App ID is `ca-app-pub-9634940728444652~1973933277`, and the production banner unit is `ca-app-pub-9634940728444652/3221555434`. These are public client identifiers, not passwords or authentication secrets, so they are kept in the Android manifest and central Dart configuration. No additional CI secret is required.

Debug and profile builds automatically request Google's test banner unit; release builds use the production unit. This includes the release-signed APKs labelled as test APKs in GitHub Actions. To test a signed release build with Google's demo ads, use `flutter build apk --release --dart-define=ADMOB_USE_TEST_ADS=true` (upload signing must be configured). If testing the production unit instead, first register your device as an AdMob test device. See Google's [test ads guide](https://developers.google.com/admob/flutter/test-ads).

The compact standard banner (320 by 50 logical pixels, with 2 pixels of padding above and below) stays fixed at the top of the Add Transaction body. Only the form below it scrolls. Dashboard and existing-transaction editing do not display ads. Loading and failed ads reserve no space. The ad is hidden when the viewport is too narrow for a standard banner or the keyboard leaves too little vertical room for the form. Width or orientation changes replace the ad; transient load failures retry after 30, 60, then 120 seconds while the app is in the foreground.

Ads also require confirmed internet access. The existing internet checker verifies reachability rather than treating a Wi-Fi/mobile connection as proof of internet access. While the initial check is pending, offline, or monitoring has failed, no banner space is reserved. A detected disconnect disposes the current ad and cancels pending retries. Reconnection automatically requests a new ad through the consent checks. Network-interface changes trigger immediate reachability checks, with periodic checks every 10 seconds to detect an outage even when Wi-Fi stays connected. Monitoring stops in the background and starts with a fresh check on return.

Before requesting ads, the app updates Google's User Messaging Platform consent information and shows any required consent form. It initializes Mobile Ads and requests banners only when `canRequestAds` permits. **Settings > Privacy > Ad privacy choices** appears when Google requires a privacy-options entry point. Opening it removes the existing banner until the consent flow finishes.

In the AdMob console, configure and publish the applicable messages under **Privacy & messaging** for this app, using the published privacy-policy URL. The repository's `app-ads.txt` already matches publisher `pub-9634940728444652`; keep its publicly hosted copy current. Production ad delivery also depends on AdMob app readiness, account approval, and available ad inventory. The repository changes do not publish the updated privacy policy or change console settings. Google's [Flutter setup](https://developers.google.com/admob/flutter/quick-start), [banner](https://developers.google.com/admob/flutter/banner), and [consent](https://developers.google.com/admob/flutter/privacy) guides describe these external requirements.

On an Android device, verify a compact test banner stays fixed above the scrolling Add Transaction form for both expense and income, and verify no banner appears on Dashboard or Edit Transaction. Check that loading, disconnecting, and reconnecting do not reset the draft. Check portrait/landscape, keyboard focus and scrolling to Save, very narrow/short viewports, offline startup, Wi-Fi without internet, turning internet off while an ad is visible or loading, reconnecting without leaving the form, background/resume, and returning from an ad click. Verify offline states leave no empty banner space. Where consent messages apply, verify the first consent form and subsequent privacy-choice changes. Check production readiness separately with a registered test device.

## Local development and verification

```powershell
flutter pub get
flutter analyze --no-fatal-infos
flutter test
flutter run
```

Run `flutter build apk --release` to locally build a signed APK and `flutter build appbundle --release` to build a Play Store AAB. Both release commands require the configured upload key.

## Pre-release acceptance checks

Automated builds verify compilation and tests, but they cannot prove that external Firebase/Google OAuth settings or live Firestore rules are correct. Before rollout:

1. Install an APK downloaded from a GitHub Actions push artifact and confirm Google Sign-In completes without a configuration/client error.
2. Create or edit wallet/expense data while online, then confirm it appears in Firestore under that signed-in user's UID. Verify offline changes synchronize after reconnecting.
3. Upload a tagged AAB to a Play Console internal-testing track, install it through the Play Store testing link, and repeat sign-in and Firestore checks. This specifically verifies the Play App Signing certificate.
4. Reinstall or use a second device with the same Google account; confirm remote data restores and other users' data remains inaccessible.
5. Increment the semantic version tag for each Play release. The workflow derives an increasing Android `versionCode` from `vMAJOR.MINOR.PATCH`.
