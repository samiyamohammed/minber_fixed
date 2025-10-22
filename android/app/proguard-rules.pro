# Keep Flutter Local Notifications
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keep class io.flutter.plugins.flutterlocalnotifications.** { *; }

# Keep Timezone classes
-keep class net.time4j.** { *; }
-keep class org.joda.time.** { *; }

# Keep Geolocator & Permission Handler
-keep class com.baseflow.geolocator.** { *; }
-keep class com.baseflow.permissionhandler.** { *; }

# Keep notification channels
-keep class * extends android.app.Service
-keep class * extends android.content.BroadcastReceiver