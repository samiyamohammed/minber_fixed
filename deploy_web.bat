@echo off
echo Building Minber TV Web App...
call flutter build web --release

echo.
echo Patching service worker for PWA prayer notifications...
node tools/patch_service_worker.js

echo.
echo Build complete! 
echo.
echo To deploy to Firebase Hosting:
echo 1. Install Firebase CLI: npm install -g firebase-tools
echo 2. Login: firebase login
echo 3. Init project: firebase init hosting
echo 4. Deploy: firebase deploy --only hosting
echo.
echo Or test locally:
echo   firebase serve --only hosting
echo.
pause
