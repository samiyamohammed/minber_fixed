// Web compass using Device Orientation API (PWA + mobile browser)
(function () {
  let absoluteListener = null;
  let relativeListener = null;
  let lastHeading = null;

  function normalizeHeading(value) {
    if (value == null || isNaN(value)) return null;
    return ((value % 360) + 360) % 360;
  }

  function readHeading(event) {
    // iOS Safari: webkitCompassHeading is true magnetic heading
    if (
      event.webkitCompassHeading != null &&
      !isNaN(event.webkitCompassHeading)
    ) {
      return normalizeHeading(event.webkitCompassHeading);
    }

    // Android / Chrome: absolute alpha is degrees from magnetic north
    if (event.alpha != null && !isNaN(event.alpha)) {
      if (event.absolute) {
        return normalizeHeading(360 - event.alpha);
      }
      return normalizeHeading(360 - event.alpha);
    }

    return null;
  }

  function publishHeading(heading) {
    if (heading == null) return;
    lastHeading = heading;
    window._lastCompassHeading = heading;

    const callback = window._webCompassDartCallback;
    if (typeof callback === 'function') {
      callback(heading);
    }
  }

  function handleAbsoluteOrientation(event) {
    publishHeading(readHeading(event));
  }

  function handleRelativeOrientation(event) {
    // iOS uses deviceorientation (non-absolute) with webkitCompassHeading
    if (event.webkitCompassHeading != null) {
      publishHeading(readHeading(event));
    }
  }

  window.webCompassSupported = function () {
    return typeof DeviceOrientationEvent !== 'undefined';
  };

  window.webCompassNeedsPermission = function () {
    // Always require user tap on web/PWA — needed for iOS and Android standalone
    return typeof DeviceOrientationEvent !== 'undefined';
  };

  window.getLastCompassHeading = function () {
    return lastHeading;
  };

  window.requestWebCompassPermission = async function () {
    try {
      if (typeof DeviceOrientationEvent === 'undefined') {
        return 'unsupported';
      }

      if (typeof DeviceOrientationEvent.requestPermission === 'function') {
        const result = await DeviceOrientationEvent.requestPermission(true);
        return result === 'granted' ? 'granted' : 'denied';
      }

      return 'granted';
    } catch (e) {
      console.warn('[Minber] Compass permission error:', e);
      return 'denied';
    }
  };

  window.startWebCompass = function () {
    window.stopWebCompass();

    absoluteListener = handleAbsoluteOrientation;
    relativeListener = handleRelativeOrientation;

    // Listen to both — Android uses absolute, iOS uses relative + webkitCompassHeading
    window.addEventListener('deviceorientationabsolute', absoluteListener, true);
    window.addEventListener('deviceorientation', relativeListener, true);
  };

  window.stopWebCompass = function () {
    if (absoluteListener) {
      window.removeEventListener(
        'deviceorientationabsolute',
        absoluteListener,
        true
      );
      absoluteListener = null;
    }
    if (relativeListener) {
      window.removeEventListener('deviceorientation', relativeListener, true);
      relativeListener = null;
    }
  };
})();
