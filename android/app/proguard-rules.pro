# ── Flutter ────────────────────────────────────────────────────────────────────
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# ── Flutter Secure Storage ─────────────────────────────────────────────────────
# Prevents R8 from stripping Android Keystore reflection classes used internally.
-keep class com.it_nomads.fluttersecurestorage.** { *; }
-keep class androidx.security.crypto.** { *; }

# ── Firebase / Google Play Services ───────────────────────────────────────────
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# ── SQLite / sqflite ──────────────────────────────────────────────────────────
-keep class org.sqlite.** { *; }
-keep class org.sqlite.database.** { *; }

# ── local_auth / Biometric ────────────────────────────────────────────────────
-keep class androidx.biometric.** { *; }

# ── Gson / JSON (used internally by some Firebase SDKs) ───────────────────────
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
-keep class com.google.gson.** { *; }
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# ── General: Keep native method names ─────────────────────────────────────────
-keepclasseswithmembernames class * {
    native <methods>;
}
