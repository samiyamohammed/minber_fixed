// MINBER_PRAYER_SW - Appended to flutter_service_worker.js after build
(function () {
  const DB_NAME = 'minber-prayer-db';
  const DB_STORE = 'schedule';
  const DB_VERSION = 1;
  let scheduledTimers = [];

  function clearTimers() {
    scheduledTimers.forEach(clearTimeout);
    scheduledTimers = [];
  }

  function openDb() {
    return new Promise((resolve, reject) => {
      const request = indexedDB.open(DB_NAME, DB_VERSION);
      request.onupgradeneeded = () => {
        const db = request.result;
        if (!db.objectStoreNames.contains(DB_STORE)) {
          db.createObjectStore(DB_STORE);
        }
      };
      request.onsuccess = () => resolve(request.result);
      request.onerror = () => reject(request.error);
    });
  }

  async function saveSchedule(data) {
    const db = await openDb();
    return new Promise((resolve, reject) => {
      const tx = db.transaction(DB_STORE, 'readwrite');
      tx.objectStore(DB_STORE).put(data, 'current');
      tx.oncomplete = () => resolve();
      tx.onerror = () => reject(tx.error);
    });
  }

  async function loadSchedule() {
    const db = await openDb();
    return new Promise((resolve, reject) => {
      const tx = db.transaction(DB_STORE, 'readonly');
      const request = tx.objectStore(DB_STORE).get('current');
      request.onsuccess = () => resolve(request.result || null);
      request.onerror = () => reject(request.error);
    });
  }

  async function clearSchedule() {
    clearTimers();
    const db = await openDb();
    return new Promise((resolve, reject) => {
      const tx = db.transaction(DB_STORE, 'readwrite');
      tx.objectStore(DB_STORE).delete('current');
      tx.oncomplete = () => resolve();
      tx.onerror = () => reject(tx.error);
    });
  }

  function scheduleNotifications(schedule, settings) {
    clearTimers();
    if (!schedule || !Array.isArray(schedule)) return;

    const now = Date.now();
    const maxDelay = 7 * 24 * 60 * 60 * 1000;

    for (const item of schedule) {
      const settingKey = item.settingKey || item.key;
      if (settings && settings[settingKey] === false) continue;

      const target = new Date(item.iso).getTime();
      const delay = target - now;
      if (delay <= 0 || delay > maxDelay) continue;

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

      scheduledTimers.push(timerId);
    }
  }

  async function saveAndSchedule(schedule, settings) {
    await saveSchedule({ schedule, settings, savedAt: Date.now() });
    scheduleNotifications(schedule, settings);
  }

  async function restoreAndSchedule() {
    const data = await loadSchedule();
    if (data && data.schedule) {
      scheduleNotifications(data.schedule, data.settings || {});
    }
  }

  self.addEventListener('message', (event) => {
    const data = event.data;
    if (!data || !data.type) return;

    if (data.type === 'SCHEDULE_PRAYERS') {
      event.waitUntil(saveAndSchedule(data.schedule, data.settings || {}));
    }

    if (data.type === 'CLEAR_PRAYERS') {
      event.waitUntil(clearSchedule());
    }
  });

  self.addEventListener('activate', (event) => {
    event.waitUntil(restoreAndSchedule());
  });

  self.addEventListener('notificationclick', (event) => {
    event.notification.close();
    event.waitUntil(
      clients.matchAll({ type: 'window', includeUncontrolled: true }).then((list) => {
        for (const client of list) {
          if ('focus' in client) return client.focus();
        }
        if (clients.openWindow) return clients.openWindow('/');
      })
    );
  });
})();
