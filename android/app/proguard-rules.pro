# --- Flutter Standard Rules ---
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-keep class io.flutter.embedding.** { *; }

# --- WorkManager (Essential for Background Scheduling) ---
-keep class androidx.work.** { *; }
-keepclasseswithmembers class * {
    @androidx.work.* *;
}
-keep class com.batoulapps.adhan.** { *; }

# --- flutter_local_notifications ---
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keep class **.ScheduledNotificationReceiver { *; }
-keep class **.ScheduledNotificationBootReceiver { *; }
-keep class * extends com.dexterous.flutterlocalnotifications.** { *; }

# --- flutter_background_service (CRITICAL FOR PRODUCTION) ---
-keep class id.flutter.flutter_background_service.** { *; }

# --- Firebase & Google Services ---
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-keep class com.google.android.play.core.** { *; }

# --- JNI Entry Points (Prevents background task from being deleted) ---
-keep class io.flutter.embedding.engine.plugins.shim.ShimPluginRegistry { *; }
-keep class io.flutter.plugins.GeneratedPluginRegistrant { *; }
-keepnames class * extends io.flutter.plugin.common.MethodChannel$MethodCallHandler

# --- Resource & Package Protection ---
# Matches your package name in manifest
-keep class com.minbertv.minber.** { *; }

# --- Keep Notification Classes ---
-keep class * extends android.app.Service
-keep class * extends android.content.BroadcastReceiver
-keep class * extends android.app.Notification

# --- Fix for Timezones and Geolocation ---
-keep class * extends java.util.TimeZone
-keep class * extends android.location.**
-keep class tzdata.** { *; }

# --- Play Core Fixes ---
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.tasks.** { *; }
-keep class com.google.android.play.core.common.** { *; }

# --- Ensure R8 doesn't remove the Adhan calculation logic ---
-keep class adhan_dart.** { *; }