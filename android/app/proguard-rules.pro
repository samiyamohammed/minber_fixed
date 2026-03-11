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

# --- flutter_local_notifications (CRITICAL FIX FOR AAB) ---
# This prevents the OS from losing track of the notification receivers
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keep class com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver { *; }
-keep class com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver { *; }
-keep class com.dexterous.flutterlocalnotifications.NotificationService { *; }
-keep public class * extends android.content.BroadcastReceiver
-keep public class * extends android.app.Service

# --- Adhan & Timezone (Preserve calculation logic) ---
-keep class com.batoulapps.adhan.** { *; }
-keep class dev.fluttercommunity.plus.timezone.** { *; }
-keep class com.samuelclatworthy.flutter_timezone.** { *; }

# --- Shared Preferences (Keep local storage access) ---
-keep class io.flutter.plugins.sharedpreferences.** { *; }

# --- JNI Entry Points (Prevents background task from being deleted) ---
-keep class io.flutter.embedding.engine.plugins.shim.ShimPluginRegistry { *; }
-keep class io.flutter.plugins.GeneratedPluginRegistrant { *; }
-keepnames class * extends io.flutter.plugin.common.MethodChannel$MethodCallHandler

# --- Resource & Package Protection ---
-keep class com.minbertv.minber.** { *; }

# --- Play Core Fixes ---
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.tasks.** { *; }
-keep class com.google.android.play.core.common.** { *; }

# --- Prevent R8 from removing vital attributes ---
-keepattributes Signature, *Annotation*, EnclosingMethod, InnerClasses