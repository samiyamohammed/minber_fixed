// Minber PWA - Prayer notification bridge for Flutter web
(function () {
  let mainThreadTimers = [];

  function clearMainThreadTimers() {
    mainThreadTimers.forEach(clearTimeout);
    mainThreadTimers = [];
  }

  async function getRegistration() {
    if (!('serviceWorker' in navigator)) return null;
    try {
      return await navigator.serviceWorker.ready;
    } catch (e) {
      console.warn('[Minber] Service worker not ready:', e);
      return null;
    }
  }

  function scheduleOnMainThread(schedule, settings) {
    clearMainThreadTimers();
    const now = Date.now();
    const maxDelay = 7 * 24 * 60 * 60 * 1000;

    getRegistration().then((registration) => {
      if (!registration) return;

      for (const item of schedule) {
        const settingKey = item.settingKey || item.key;
        if (settings && settings[settingKey] === false) continue;

        const delay = new Date(item.iso).getTime() - now;
        if (delay <= 0 || delay > maxDelay) continue;

        const timerId = setTimeout(() => {
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

    const registration = await getRegistration();
    if (registration && registration.active) {
      registration.active.postMessage({
        type: 'SCHEDULE_PRAYERS',
        schedule: schedule,
        settings: settings,
      });
    }

    // Fallback while app is open (also helps during local dev before SW patch)
    scheduleOnMainThread(schedule, settings);
    return true;
  };

  window.clearPrayerNotifications = async function () {
    clearMainThreadTimers();
    const registration = await getRegistration();
    registration?.active?.postMessage({ type: 'CLEAR_PRAYERS' });
  };
})();
