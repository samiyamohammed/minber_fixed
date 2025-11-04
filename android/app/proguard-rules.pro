# android/app/proguard-rules.pro

# Flutter specific rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Rules for flutter_local_notifications
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# Rules for WorkManager
-keep class androidx.work.** { *; }

# Rules for Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }