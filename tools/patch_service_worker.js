const fs = require('fs');
const path = require('path');

const swPath = path.join(__dirname, '..', 'build', 'web', 'flutter_service_worker.js');
const extensionPath = path.join(__dirname, '..', 'web', 'prayer_sw_extension.js');
const marker = 'MINBER_PRAYER_SW';

if (!fs.existsSync(swPath)) {
  console.error('flutter_service_worker.js not found. Run flutter build web first.');
  process.exit(1);
}

const sw = fs.readFileSync(swPath, 'utf8');
if (sw.includes(marker)) {
  console.log('Prayer service worker extension already patched.');
  process.exit(0);
}

const extension = fs.readFileSync(extensionPath, 'utf8');
fs.writeFileSync(swPath, sw + '\n' + extension);
console.log('Patched flutter_service_worker.js with prayer notifications.');

// Copy pwa_notifications.js to build output
const notificationsSrc = path.join(__dirname, '..', 'web', 'pwa_notifications.js');
const notificationsDest = path.join(__dirname, '..', 'build', 'web', 'pwa_notifications.js');
fs.copyFileSync(notificationsSrc, notificationsDest);
console.log('Copied pwa_notifications.js to build/web.');
