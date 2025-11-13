# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# flutter_local_notifications
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keep class **.ScheduledNotificationReceiver { *; }
-keep class **.ScheduledNotificationBootReceiver { *; }
-keep class * extends com.dexterous.flutterlocalnotifications.** { *; }

# WorkManager
-keep class androidx.work.** { *; }
-keepclasseswithmembers class * {
    @androidx.work.* *;
}

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Google Play Core
-keep class com.google.android.play.core.** { *; }

# Timezone/Geolocation
-keep class * extends java.util.TimeZone
-keep class * extends android.location.**
-keep class tzdata.** { *; }

# Adhan calculation
-keep class com.batoulapps.adhan.** { *; }

# Your app package
-keep class com.example.minber_super_app_new_fixed.** { *; }

# Keep callback methods
-keepclassmembers class * {
    @androidx.work.Worker public *;
}

# Keep parcelable for notifications
-keep class * implements android.os.Parcelable {
  public static final android.os.Parcelable$Creator *;
}

# === ADD THESE NEW RULES ===
# Notification system classes
-keep class * extends android.app.Notification { *; }
-keep class * extends android.app.NotificationChannel { *; }
-keep class * extends android.app.NotificationManager { *; }

# Reflection methods used by notifications
-keepclassmembers class * {
    public void onReceive(android.content.Context, android.content.Intent);
}

# Keep all method names in your notification service
-keepclassmembers class com.example.minber_super_app_new_fixed.services.NotificationService {
    public static *;
}