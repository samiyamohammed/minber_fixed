// MINBER_PRAYER_SW_V2 - Appended to flutter_service_worker.js after build
(function () {
  const DB_NAME = 'minber-prayer-db';
  const DB_STORE = 'schedule';
  const SHOWN_STORE = 'shown';
  const DB_VERSION = 2;
  let scheduledTimers = [];
  let checkInterval = null;

  function clearTimers() {
    scheduledTimers.forEach(clearTimeout);
    scheduledTimers = [];
    if (checkInterval) {
      clearInterval(checkInterval);
      checkInterval = null;
    }
  }

  function openDb() {
    return new Promise(function (resolve, reject) {
      const request = indexedDB.open(DB_NAME, DB_VERSION);
      request.onupgradeneeded = function () {
        const db = request.result;
        if (!db.objectStoreNames.contains(DB_STORE)) {
          db.createObjectStore(DB_STORE);
        }
        if (!db.objectStoreNames.contains(SHOWN_STORE)) {
          db.createObjectStore(SHOWN_STORE);
        }
      };
      request.onsuccess = function () {
        resolve(request.result);
      };
      request.onerror = function () {
        reject(request.error);
      };
    });
  }

  async function saveSchedule(data) {
    const db = await openDb();
    return new Promise(function (resolve, reject) {
      const tx = db.transaction(DB_STORE, 'readwrite');
      tx.objectStore(DB_STORE).put(data, 'current');
      tx.oncomplete = function () {
        resolve();
      };
      tx.onerror = function () {
        reject(tx.error);
      };
    });
  }

  async function loadSchedule() {
    const db = await openDb();
    return new Promise(function (resolve, reject) {
      const tx = db.transaction(DB_STORE, 'readonly');
      const request = tx.objectStore(DB_STORE).get('current');
      request.onsuccess = function () {
        resolve(request.result || null);
      };
      request.onerror = function () {
        reject(request.error);
      };
    });
  }

  async function markShown(tag) {
    const db = await openDb();
    return new Promise(function (resolve) {
      const tx = db.transaction(SHOWN_STORE, 'readwrite');
      tx.objectStore(SHOWN_STORE).put(Date.now(), tag);
      tx.oncomplete = function () {
        resolve();
      };
    });
  }

  async function wasShown(tag) {
    const db = await openDb();
    return new Promise(function (resolve) {
      const tx = db.transaction(SHOWN_STORE, 'readonly');
      const request = tx.objectStore(SHOWN_STORE).get(tag);
      request.onsuccess = function () {
        resolve(request.result != null);
      };
      request.onerror = function () {
        resolve(false);
      };
    });
  }

  async function clearSchedule() {
    clearTimers();
    const db = await openDb();
    return new Promise(function (resolve, reject) {
      const tx = db.transaction([DB_STORE, SHOWN_STORE], 'readwrite');
      tx.objectStore(DB_STORE).delete('current');
      tx.objectStore(SHOWN_STORE).clear();
      tx.oncomplete = function () {
        resolve();
      };
      tx.onerror = function () {
        reject(tx.error);
      };
    });
  }

  async function showPrayerNotification(item) {
    const tag = 'minber-' + item.key + '-' + item.iso;
    if (await wasShown(tag)) return;

    await self.registration.showNotification(item.title, {
      body: item.body,
      icon: '/icons/Icon-192.png',
      badge: '/icons/Icon-192.png',
      tag: tag,
      renotify: true,
      data: { url: '/', type: item.type || 'prayer' },
    });
    await markShown(tag);
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

      const timerId = setTimeout(function () {
        showPrayerNotification(item);
      }, delay);

      scheduledTimers.push(timerId);
    }

    // Backup: check every 30s in case setTimeout was lost when SW restarted
    checkInterval = setInterval(function () {
      checkDuePrayers();
    }, 30000);
  }

  async function checkDuePrayers() {
    const data = await loadSchedule();
    if (!data || !data.schedule) return;

    const settings = data.settings || {};
    const now = Date.now();

    for (const item of data.schedule) {
      const settingKey = item.settingKey || item.key;
      if (settings[settingKey] === false) continue;

      const target = new Date(item.iso).getTime();
      const diff = Math.abs(now - target);
      if (diff <= 60000) {
        await showPrayerNotification(item);
      }
    }
  }

  async function saveAndSchedule(schedule, settings) {
    await saveSchedule({ schedule: schedule, settings: settings, savedAt: Date.now() });
    scheduleNotifications(schedule, settings);
  }

  async function restoreAndSchedule() {
    const data = await loadSchedule();
    if (data && data.schedule) {
      scheduleNotifications(data.schedule, data.settings || {});
    }
  }

  self.addEventListener('message', function (event) {
    const data = event.data;
    if (!data || !data.type) return;

    if (data.type === 'SCHEDULE_PRAYERS') {
      saveAndSchedule(data.schedule, data.settings || {});
    }

    if (data.type === 'CLEAR_PRAYERS') {
      clearSchedule();
    }
  });

  self.addEventListener('activate', function (event) {
    event.waitUntil(restoreAndSchedule());
  });

  self.addEventListener('notificationclick', function (event) {
    event.notification.close();
    event.waitUntil(
      clients.matchAll({ type: 'window', includeUncontrolled: true }).then(function (list) {
        for (const client of list) {
          if ('focus' in client) return client.focus();
        }
        if (clients.openWindow) return clients.openWindow('/');
      })
    );
  });
})();
