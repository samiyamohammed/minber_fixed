const fs = require('fs');
const path = require('path');

const swPath = path.join(__dirname, '..', 'build', 'web', 'flutter_service_worker.js');
const extensionPath = path.join(__dirname, '..', 'web', 'prayer_sw_extension.js');
const marker = 'MINBER_PRAYER_SW_V2';

if (!fs.existsSync(swPath)) {
  console.error('flutter_service_worker.js not found. Run flutter build web first.');
  process.exit(1);
}

let sw = fs.readFileSync(swPath, 'utf8');

// Remove any previous prayer extension before re-patching
const oldMarkerIndex = sw.indexOf('MINBER_PRAYER_SW');
if (oldMarkerIndex !== -1) {
  sw = sw.substring(0, oldMarkerIndex);
}

if (!sw.includes(marker)) {
  const extension = fs.readFileSync(extensionPath, 'utf8');
  sw = sw + '\n' + extension;
  fs.writeFileSync(swPath, sw);
  console.log('Patched flutter_service_worker.js with prayer notifications.');
} else {
  console.log('Prayer service worker extension already patched.');
}

// Copy helper scripts to build output
const filesToCopy = ['pwa_notifications.js', 'web_compass.js', 'firebase-messaging-sw.js'];
for (const file of filesToCopy) {
  const src = path.join(__dirname, '..', 'web', file);
  const dest = path.join(__dirname, '..', 'build', 'web', file);
  if (fs.existsSync(src)) {
    fs.copyFileSync(src, dest);
    console.log('Copied ' + file + ' to build/web.');
  }
}
