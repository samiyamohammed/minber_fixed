// Minber PWA - Prayer notification bridge for Flutter web
(function () {
  let mainThreadTimers = [];

  function clearMainThreadTimers() {
    mainThreadTimers.forEach(clearTimeout);
    mainThreadTimers = [];
  }

  async function waitForActiveWorker(attempts) {
    const maxAttempts = attempts || 30;
    if (!('serviceWorker' in navigator)) return null;

    for (let i = 0; i < maxAttempts; i++) {
      try {
        let registration = await navigator.serviceWorker.getRegistration('/sw.js');
        if (!registration) {
          registration = await navigator.serviceWorker.register('/sw.js');
        }
        if (registration?.active) return registration;
      } catch (e) {
        console.warn('[Minber] Waiting for service worker...', e);
      }

      await new Promise(function (resolve) {
        setTimeout(resolve, 500);
      });
    }
    return null;
  }

  function scheduleOnMainThread(schedule, settings) {
    clearMainThreadTimers();
    const now = Date.now();
    const maxDelay = 7 * 24 * 60 * 60 * 1000;

    waitForActiveWorker(10).then(function (registration) {
      if (!registration) return;

      for (const item of schedule) {
        const settingKey = item.settingKey || item.key;
        if (settings && settings[settingKey] === false) continue;

        const delay = new Date(item.iso).getTime() - now;
        if (delay <= 0 || delay > maxDelay) continue;

        const timerId = setTimeout(function () {
          registration.showNotification(item.title, {
            body: item.body,
            icon: '/icons/Icon-192.png',
            badge: '/icons/Icon-192.png',
            tag: 'minber-' + item.key + '-' + item.iso,
            renotify: true,
            data: { url: '/', type: item.type || 'prayer' },
          });
        }, delay);

        mainThreadTimers.push(timerId);
      }
    });
  }

  window.requestPrayerNotificationPermission = async function () {
    if (!('Notification' in window)) return 'unsupported';
    if (Notification.permission === 'granted') return 'granted';
    if (Notification.permission === 'denied') return 'denied';
    return await Notification.requestPermission();
  };

  window.getPrayerNotificationPermission = function () {
    if (!('Notification' in window)) return 'unsupported';
    return Notification.permission;
  };

  window.schedulePrayerNotifications = async function (scheduleJson, settingsJson) {
    if (!('Notification' in window) || Notification.permission !== 'granted') {
      console.warn('[Minber] Notification permission not granted');
      return false;
    }

    let schedule;
    let settings;
    try {
      schedule = JSON.parse(scheduleJson);
      settings = JSON.parse(settingsJson);
    } catch (e) {
      console.error('[Minber] Invalid prayer schedule JSON:', e);
      return false;
    }

    const registration = await waitForActiveWorker(30);
    if (registration && registration.active) {
      registration.active.postMessage({
        type: 'SCHEDULE_PRAYERS',
        schedule: schedule,
        settings: settings,
      });
      console.log('[Minber] Prayer schedule sent to service worker');
    } else {
      console.warn('[Minber] Service worker not active, using main-thread fallback');
    }

    scheduleOnMainThread(schedule, settings);
    return true;
  };

  window.clearPrayerNotifications = async function () {
    clearMainThreadTimers();
    const registration = await waitForActiveWorker(5);
    registration?.active?.postMessage({ type: 'CLEAR_PRAYERS' });
  };
})();
