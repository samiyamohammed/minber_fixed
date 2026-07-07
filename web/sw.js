// Minber TV - Service Worker
const CACHE_NAME = 'minber-tv-v1';
const OFFLINE_URLS = [
  '/',
  '/index.html',
  '/manifest.json',
  '/icons/Icon-192.png',
  '/icons/Icon-512.png',
];

// Install - cache core assets
self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => {
      return cache.addAll(OFFLINE_URLS);
    })
  );
  self.skipWaiting();
});

// Activate - clean old caches
self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((cacheNames) => {
      return Promise.all(
        cacheNames
          .filter((name) => name !== CACHE_NAME)
          .map((name) => caches.delete(name))
      );
    })
  );
  self.clients.claim();
});

// Fetch - network first, cache fallback
self.addEventListener('fetch', (event) => {
  // Skip non-GET and cross-origin requests
  if (event.request.method !== 'GET') return;
  if (!event.request.url.startsWith(self.location.origin)) return;

  event.respondWith(
    fetch(event.request)
      .then((response) => {
        // Cache successful responses
        if (response.status === 200) {
          const responseClone = response.clone();
          caches.open(CACHE_NAME).then((cache) => {
            cache.put(event.request, responseClone);
          });
        }
        return response;
      })
      .catch(() => {
        // Network failed - try cache
        return caches.match(event.request).then((cached) => {
          return cached || caches.match('/index.html');
        });
      })
  );
});

// Push notifications
self.addEventListener('push', (event) => {
  const data = event.data?.json() ?? {};
  event.waitUntil(
    self.registration.showNotification(data.title || 'Minber TV', {
      body: data.body || 'You have a new notification',
      icon: '/icons/Icon-192.png',
      badge: '/icons/Icon-192.png',
    })
  );
});

let prayerSchedule = [];
let prayerSettings = {};
let scheduleTimers = [];

function clearScheduleTimers() {
  scheduleTimers.forEach((timerId) => clearTimeout(timerId));
  scheduleTimers = [];
}

function schedulePrayerNotification(item, settings) {
  const settingKey = item.settingKey || item.key;
  if (settings && settings[settingKey] === false) return;

  const delay = new Date(item.iso).getTime() - Date.now();
  const maxDelay = 7 * 24 * 60 * 60 * 1000;
  if (delay <= 0 || delay > maxDelay) return;

  const timerId = setTimeout(() => {
    self.registration.showNotification(item.title, {
      body: item.body,
      icon: '/icons/Icon-192.png',
      badge: '/icons/Icon-192.png',
      tag: 'minber-' + item.key + '-' + item.iso,
      renotify: true,
      data: { url: '/', type: item.type || 'prayer' },
    });
  }, delay);

  scheduleTimers.push(timerId);
}

self.addEventListener('message', (event) => {
  const data = event.data || {};
  if (data.type === 'SCHEDULE_PRAYERS') {
    clearScheduleTimers();
    prayerSchedule = data.schedule || [];
    prayerSettings = data.settings || {};
    prayerSchedule.forEach((item) => schedulePrayerNotification(item, prayerSettings));
    console.log('[Minber] Prayer schedule received in service worker:', prayerSchedule.length);
  } else if (data.type === 'CLEAR_PRAYERS') {
    clearScheduleTimers();
    prayerSchedule = [];
    console.log('[Minber] Prayer schedule cleared in service worker');
  }
});
