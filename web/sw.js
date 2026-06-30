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
