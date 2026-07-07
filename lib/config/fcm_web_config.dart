/// Web push VAPID key from Firebase Console:
/// Project Settings → Cloud Messaging → Web Push certificates → Key pair
class FcmWebConfig {
  static const String vapidKey =
      'REPLACE_WITH_YOUR_FIREBASE_WEB_PUSH_VAPID_KEY';

  static bool get isConfigured =>
      vapidKey.isNotEmpty &&
      !vapidKey.startsWith('REPLACE_WITH_YOUR_FIREBASE');
}
