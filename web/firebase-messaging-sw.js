// Firebase Cloud Messaging service worker for web push notifications.
importScripts('https://www.gstatic.com/firebasejs/10.7.1/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.7.1/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyDvmkMHwwK3ISsIw8g4sQbewZ6YibxOvI0',
  appId: '1:712226370485:web:194b483d4d858c2b291ffc',
  messagingSenderId: '712226370485',
  projectId: 'minber-super-app-notifications',
  authDomain: 'minber-super-app-notifications.firebaseapp.com',
  storageBucket: 'minber-super-app-notifications.firebasestorage.app',
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage(function (payload) {
  const title =
    payload.notification?.title || payload.data?.title || 'Minber TV';
  const body =
    payload.notification?.body || payload.data?.body || 'You have a new notification';

  return self.registration.showNotification(title, {
    body: body,
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
    data: payload.data || {},
  });
});
