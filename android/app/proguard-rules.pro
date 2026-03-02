# Flutter standard rules
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

# Adhan calculation (Fix for adhan_dart)
-keep class com.batoulapps.adhan.** { *; }
-keep class adhan_dart.** { *; }

# Your app package (FIXED TO MATCH YOUR ACTUAL PACKAGE)
-keep class com.minbertv.minber.** { *; }

# Keep callback methods
-keepclassmembers class * {
    @androidx.work.Worker public *;
}

# Keep parcelable for notifications
-keep class * implements android.os.Parcelable {
  public static final android.os.Parcelable$Creator *;
}

# Notification system classes
-keep class * extends android.app.Notification { *; }
-keep class * extends android.app.NotificationChannel { *; }
-keep class * extends android.app.NotificationManager { *; }

# Reflection methods used by notifications
-keepclassmembers class * {
    public void onReceive(android.content.Context, android.content.Intent);
}

# Keep all method names in your notification service (FIXED PACKAGE NAME)
-keepclassmembers class com.minbertv.minber.services.NotificationService {
    public static *;
}

# Fix for Google Play Core Split Libraries
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.tasks.** { *; }
-keep class com.google.android.play.core.common.** { *; }