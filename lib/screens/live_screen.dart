import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

class LiveStreamPage extends StatefulWidget {
  const LiveStreamPage({super.key});

  @override
  State<LiveStreamPage> createState() => _LiveStreamPageState();
}

class _LiveStreamPageState extends State<LiveStreamPage> {
  late final WebViewController _controller;
  final String streamUrl = 'http://msa.merkuz.com:8888/live/stream1/index.m3u8';

  @override
  void initState() {
    super.initState();

    // Force the screen into landscape mode
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    // Hide the status bar and navigation buttons for a true full-screen experience
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // Initialize the WebView controller to play the video
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      // ✅ THE ONLY CHANGE IS HERE: We load the new, advanced HTML.
      ..loadHtmlString(_createModernLivePlayerHtml());
  }

  @override
  void dispose() {
    // IMPORTANT - When the page is closed, restore the app's default orientation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    // And show the system UI again
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    super.dispose();
  }

  // This function now returns your teammate's advanced HTML player.
  String _createModernLivePlayerHtml() {
    // Note: Using a multiline string `'''` is perfect for embedding this.
    // The `$streamUrl` will be correctly injected into the JavaScript.
    return '''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no, viewport-fit=cover">
  <title>Modern HLS Player</title>
  <script src="https://cdn.jsdelivr.net/npm/hls.js@latest"></script>
  <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
  <style>
    :root {
      --primary-color: #2196F3;
      --hover-color: #64B5F6;
      --bg-color: rgba(0, 0, 0, 0.7);
      --text-color: #fff;
      --controls-height: 70px;
    }
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body, html { width: 100%; height: 100%; overflow: hidden; font-family: 'Segoe UI', Arial, sans-serif; }
    body { background: #000; color: var(--text-color); display: flex; flex-direction: column; }
    #video-container { position: fixed; top: 0; left: 0; right: 0; bottom: 0; display: flex; justify-content: center; align-items: center; background: #000; }
    video { max-width: 100%; max-height: 100%; background: #000; transition: all 0.3s ease; }
    .aspect-fit { object-fit: contain !important; width: 100% !important; height: 100% !important; transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1); }
    .aspect-fill { object-fit: cover !important; width: 100% !important; height: 100% !important; transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1); }
    .aspect-stretch { object-fit: fill !important; width: 100% !important; height: 100% !important; transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1); }
    .aspect-16-9 { aspect-ratio: 16/9 !important; width: 100% !important; height: auto !important; max-height: 100% !important; object-fit: contain !important; transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1); }
    .aspect-4-3 { aspect-ratio: 4/3 !important; width: 100% !important; height: auto !important; max-height: 100% !important; object-fit: contain !important; transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1); }
    .aspect-1-1 { aspect-ratio: 1/1 !important; width: auto !important; height: 100% !important; max-width: 100% !important; object-fit: contain !important; transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1); }
    .aspect-changing video { transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1); }
    :fullscreen #video-container { background: #000; display: flex !important; align-items: center; justify-content: center; }
    :fullscreen video { width: 100% !important; height: 100% !important; object-fit: contain !important; }
    video::-webkit-media-controls { display: none !important; }
    #controls { position: fixed; bottom: 0; left: 0; right: 0; background: linear-gradient(transparent, var(--bg-color)); padding: 15px 20px; display: flex; flex-direction: column; align-items: center; transition: opacity 0.3s ease; z-index: 100; backdrop-filter: blur(5px); opacity: 0; }
    #video-container:hover #controls, #controls.visible { opacity: 1; }
    .progress-container { width: 100%; height: 4px; background: rgba(255, 255, 255, 0.2); border-radius: 2px; margin-bottom: 10px; cursor: pointer; }
    #progress-bar { height: 100%; width: 0%; background: var(--primary-color); border-radius: 2px; transition: width 0.1s linear; position: relative; }
    .controls-bottom { width: 100%; display: flex; justify-content: space-between; align-items: center; }
    .control-btn { background: none; border: none; color: var(--text-color); font-size: 18px; cursor: pointer; margin: 0 8px; padding: 8px 12px; border-radius: 4px; opacity: 0.9; transition: all 0.2s; }
    .control-btn:hover { background: rgba(255, 255, 255, 0.1); opacity: 1; }
    .control-btn.active { color: var(--primary-color); }
    .time-display { font-size: 14px; font-family: monospace; margin: 0 10px; opacity: 0.9; min-width: 110px; text-align: center; }
    .controls-left, .controls-right { display: flex; align-items: center; }
    .dropdown { position: relative; display: inline-block; }
    .dropdown-content { display: none; position: absolute; bottom: 100%; left: 50%; transform: translateX(-50%); background: var(--bg-color); min-width: 140px; border-radius: 4px; box-shadow: 0 2px 10px rgba(0, 0, 0, 0.3); z-index: 1; margin-bottom: 10px; backdrop-filter: blur(10px); }
    .dropdown-content button { color: var(--text-color); padding: 8px 16px; text-decoration: none; display: block; width: 100%; text-align: left; background: none; border: none; cursor: pointer; font-size: 14px; display: flex; align-items: center; gap: 8px; }
    .dropdown-content button i { width: 16px; text-align: center; }
    .dropdown-content button:hover { background: rgba(255, 255, 255, 0.1); }
    .dropdown:hover .dropdown-content { display: block; }
    .dropdown-divider { height: 1px; background: rgba(255, 255, 255, 0.2); margin: 4px 0; }
    .loading { position: fixed; top: 50%; left: 50%; transform: translate(-50%, -50%); font-size: 24px; color: var(--text-color); z-index: 10; display: flex; flex-direction: column; align-items: center; gap: 10px; }
    .spinner { width: 40px; height: 40px; border: 4px solid rgba(255, 255, 255, 0.1); border-radius: 50%; border-top-color: var(--primary-color); animation: spin 1s ease-in-out infinite; }
    @keyframes spin { to { transform: rotate(360deg); } }
    #video-container { padding-bottom: var(--controls-height); }
    #controls { position: fixed; bottom: 0; left: 0; right: 0; height: var(--controls-height); background: linear-gradient(transparent, rgba(0, 0, 0, 0.8)); padding: 0 10px 10px; display: flex; flex-direction: column; justify-content: flex-end; transition: all 0.3s ease; z-index: 100; opacity: 0; backdrop-filter: blur(5px); }
    .progress-container { margin: 0 0 8px; height: 4px; background: rgba(255, 255, 255, 0.2); border-radius: 2px; cursor: pointer; transition: height 0.2s ease; }
    .progress-container:hover { height: 6px; }
    .controls-bottom { display: flex; justify-content: space-between; align-items: center; width: 100%; padding: 0 5px; }
    @media (max-width: 767px) {
      .dropdown-content { position: fixed; bottom: var(--controls-height); left: 0; right: 0; top: auto; transform: none; width: 100%; border-radius: 0; background: rgba(30, 30, 30, 0.95); padding: 10px 0; max-height: 60vh; overflow-y: auto; }
      .dropdown-content button { padding: 14px 20px; font-size: 16px; }
      .dropdown-content button i { font-size: 18px; }
      :root { --controls-height: 60px; }
      .control-btn { font-size: 20px; margin: 0 8px; padding: 8px 12px; min-width: 40px; min-height: 40px; display: flex; align-items: center; justify-content: center; }
      .time-display { font-size: 14px; min-width: 110px; text-align: center; }
      #controls { padding: 12px 8px; }
      .dropdown-content { min-width: 160px; bottom: 100%; left: 50%; transform: translateX(-50%); }
      @media (orientation: portrait) {
        video { width: 100%; height: auto; max-height: 70vh; }
        #video-container { padding-top: env(safe-area-inset-top); padding-bottom: env(safe-area-inset-bottom); }
        .controls-bottom { flex-wrap: wrap; }
        .controls-left, .controls-right { width: 100%; justify-content: space-between; margin: 5px 0; }
      }
      @media (orientation: landscape) { video { width: 100%; height: 100%; max-height: 100%; } }
    }
    .dropdown-content.show { display: block; }
    .dropdown-content button:hover { background: rgba(255, 255, 255, 0.1); }
    @media (min-width: 768px) {
      :root { --controls-height: 80px; }
      .control-btn { font-size: 18px; margin: 0 8px; padding: 8px 12px; transition: all 0.2s ease; }
      .control-btn:hover { background: rgba(255, 255, 255, 0.15); transform: scale(1.1); }
      .time-display { font-size: 14px; min-width: 120px; font-family: 'Roboto Mono', monospace, monospace; }
      #controls { padding: 10px 20px 20px; }
      .progress-container { margin: 0 0 12px; height: 5px; }
      .progress-container:hover { height: 8px; }
      .dropdown-content { bottom: calc(100% + 10px); min-width: 180px; border-radius: 6px; box-shadow: 0 4px 20px rgba(0, 0, 0, 0.3); }
    }
    @media (min-width: 1200px) {
      :root { --controls-height: 90px; }
      .control-btn { font-size: 20px; margin: 0 10px; }
      .time-display { font-size: 16px; min-width: 140px; }
      #controls { padding: 15px 30px 25px; }
      .progress-container { height: 6px; }
      .progress-container:hover { height: 10px; }
    }
  </style>
</head>
<body>
  <div id="video-container">
    <video id="video" autoplay playsinline></video>
    <div class="loading" id="loading"><div class="spinner"></div><div>Loading stream...</div></div>
    <div id="controls">
      <div class="progress-container" id="progress-container"><div id="progress-bar"></div></div>
      <div class="controls-bottom">
        <div class="controls-left">
          <button class="control-btn" id="play-pause-btn" title="Play/Pause"><i class="fas fa-play"></i></button>
          <span class="time-display" id="time-display">00:00 / 00:00</span>
        </div>
        <div class="controls-right">
          <div class="dropdown">
            <button class="control-btn dropdown-btn" id="aspect-btn" title="Aspect Ratio"><i class="fas fa-crop-alt"></i></button>
            <div class="dropdown-content">
              <button data-aspect="fit"><i class="fas fa-compress"></i> Fit</button>
              <button data-aspect="fill"><i class="fas fa-arrows-alt"></i> Fill</button>
              <button data-aspect="stretch"><i class="fas fa-arrows-alt-h"></i> Stretch</button>
              <div class="dropdown-divider"></div>
              <button data-aspect="16-9"><i class="fas fa-tv"></i> 16:9</button>
              <button data-aspect="4-3"><i class="fas fa-tv"></i> 4:3</button>
              <button data-aspect="1-1"><i class="fas fa-square"></i> 1:1</button>
            </div>
          </div>
          <button class="control-btn" id="mute-btn" title="Mute"><i class="fas fa-volume-up"></i></button>
          <button class="control-btn" id="fullscreen-btn" title="Fullscreen"><i class="fas fa-expand"></i></button>
        </div>
      </div>
    </div>
  </div>
  <script>
    const video = document.getElementById('video');
    const playPauseBtn = document.getElementById('play-pause-btn');
    const muteBtn = document.getElementById('mute-btn');
    const fullscreenBtn = document.getElementById('fullscreen-btn');
    const progressBar = document.getElementById('progress-bar');
    const progressContainer = document.getElementById('progress-container');
    const timeDisplay = document.getElementById('time-display');
    const controls = document.getElementById('controls');
    const loadingElement = document.getElementById('loading');
    const videoContainer = document.getElementById('video-container');
    const hlsUrl = "$streamUrl";
    function initHLS() {
      if (Hls.isSupported()) {
        const hls = new Hls({ debug: false, enableWorker: true, lowLatencyMode: true, backBufferLength: 90 });
        hls.loadSource(hlsUrl);
        hls.attachMedia(video);
        hls.on(Hls.Events.MANIFEST_PARSED, function() {
          console.log('Manifest parsed, starting playback');
          video.play().catch(e => { console.log("Autoplay prevented:", e); showControls(); });
          hideLoading();
        });
        hls.on(Hls.Events.ERROR, function(event, data) {
          console.error('HLS Error:', data);
          if (data.fatal) {
            switch(data.type) {
              case Hls.ErrorTypes.NETWORK_ERROR: hls.startLoad(); break;
              case Hls.ErrorTypes.MEDIA_ERROR: hls.recoverMediaError(); break;
              default: break;
            }
          }
        });
      } else if (video.canPlayType('application/vnd.apple.mpegurl')) {
        video.src = hlsUrl;
        video.addEventListener('loadedmetadata', function() {
          video.play().catch(e => { console.log("Autoplay prevented:", e); showControls(); });
          hideLoading();
        });
      }
    }
    function showLoading() { if (loadingElement) loadingElement.style.display = 'flex'; }
    function hideLoading() { if (loadingElement) loadingElement.style.display = 'none'; }
    function showControls() { controls.classList.add('visible'); resetHideControlsTimeout(); }
    function togglePlayPause() {
      if (video.paused) {
        video.play().then(() => { playPauseBtn.innerHTML = '<i class="fas fa-pause"></i>'; resetHideControlsTimeout(); }).catch(e => { console.error('Playback failed:', e); showControls(); });
      } else { video.pause(); playPauseBtn.innerHTML = '<i class="fas fa-play"></i>'; showControls(); }
    }
    function toggleMute() { video.muted = !video.muted; updateMuteButton(); }
    function updateMuteButton() {
      if (video.muted) { muteBtn.innerHTML = '<i class="fas fa-volume-mute"></i>'; muteBtn.setAttribute('title', 'Unmute'); }
      else { muteBtn.innerHTML = '<i class="fas fa-volume-up"></i>'; muteBtn.setAttribute('title', 'Mute'); }
    }
    function toggleFullscreen() {
      if (!document.fullscreenElement) {
        if (videoContainer.requestFullscreen) { videoContainer.requestFullscreen().catch(err => { console.error('Fullscreen error:', err); }); fullscreenBtn.innerHTML = '<i class="fas fa-compress"></i>'; fullscreenBtn.setAttribute('title', 'Exit fullscreen'); }
      } else { if (document.exitFullscreen) { document.exitFullscreen(); fullscreenBtn.innerHTML = '<i class="fas fa-expand"></i>'; fullscreenBtn.setAttribute('title', 'Fullscreen'); } }
    }
    function updateProgress() {
      if (isNaN(video.duration) || !isFinite(video.duration)) return;
      const progress = (video.currentTime / video.duration) * 100;
      progressBar.style.width = `\${progress}%`;
      timeDisplay.textContent = `\${formatTime(video.currentTime)} / \${formatTime(video.duration)}`;
    }
    function formatTime(seconds) {
      if (isNaN(seconds)) return '00:00';
      const minutes = Math.floor(seconds / 60);
      const secs = Math.floor(seconds % 60);
      return `\${minutes.toString().padStart(2, '0')}:\${secs.toString().padStart(2, '0')}`;
    }
    function seek(e) {
      if (!video.duration) return;
      const rect = progressContainer.getBoundingClientRect();
      const pos = (e.clientX - rect.left) / rect.width;
      video.currentTime = pos * video.duration;
    }
    let hideControlsTimeout;
    function resetHideControlsTimeout() {
      clearTimeout(hideControlsTimeout);
      if (!document.fullscreenElement) return;
      controls.classList.add('visible');
      hideControlsTimeout = setTimeout(() => { if (!video.paused) { controls.classList.remove('visible'); } }, 2000);
    }
    function setupAspectRatioButtons() {
      const aspectBtns = document.querySelectorAll('[data-aspect]');
      const aspectBtn = document.getElementById('aspect-btn');
      const dropdownContent = document.querySelector('.dropdown-content');
      let isAnimating = false;
      document.addEventListener('click', (e) => { if (!e.target.closest('.dropdown') && !e.target.matches('.dropdown-content *')) { dropdownContent.style.display = 'none'; } });
      const toggleDropdown = (show = null) => {
        if (show === null) { show = dropdownContent.style.display !== 'block'; }
        dropdownContent.style.display = show ? 'block' : 'none';
        if (window.innerWidth < 768) { document.body.style.overflow = show ? 'hidden' : ''; }
      };
      aspectBtn.addEventListener('click', (e) => { e.stopPropagation(); toggleDropdown(); });
      if (window.innerWidth >= 768) {
        let isHovering = false; let hideTimeout;
        const showDropdown = () => { clearTimeout(hideTimeout); isHovering = true; dropdownContent.style.display = 'block'; };
        const hideDropdown = () => { isHovering = false; clearTimeout(hideTimeout); hideTimeout = setTimeout(() => { if (!isHovering && !dropdownContent.matches(':hover')) { dropdownContent.style.display = 'none'; } }, 300); };
        aspectBtn.addEventListener('mouseenter', showDropdown); aspectBtn.addEventListener('mouseleave', hideDropdown);
        dropdownContent.addEventListener('mouseenter', showDropdown); dropdownContent.addEventListener('mouseleave', hideDropdown);
      } else { document.addEventListener('click', (e) => { if (!e.target.closest('.dropdown') && !e.target.matches('.dropdown-content *')) { dropdownContent.style.display = 'none'; document.body.style.overflow = ''; } }, true); }
      const applyAspectRatio = (btn) => {
        if (isAnimating) return; isAnimating = true;
        const aspect = btn.dataset.aspect;
        const videoContainer = document.getElementById('video-container');
        videoContainer.classList.add('aspect-changing');
        const scrollX = window.scrollX || document.documentElement.scrollLeft;
        const scrollY = window.scrollY || document.documentElement.scrollTop;
        video.className = ''; void video.offsetHeight;
        setTimeout(() => {
          switch(aspect) {
            case 'fit': video.classList.add('aspect-fit'); break;
            case 'fill': video.classList.add('aspect-fill'); break;
            case 'stretch': video.classList.add('aspect-stretch'); break;
            case '16-9': case '4-3': case '1-1': video.classList.add(`aspect-\${aspect}`); break;
          }
          aspectBtns.forEach(b => b.classList.remove('active'));
          btn.classList.add('active'); showControls(); window.scrollTo(scrollX, scrollY);
          setTimeout(() => {
            videoContainer.classList.remove('aspect-changing'); isAnimating = false; void video.offsetHeight;
            const currentAspect = video.className.split(' ')[0];
            if (currentAspect) { video.className = ''; video.classList.add(currentAspect); if (navigator.userAgent.indexOf('Safari') !== -1) { video.style.aspectRatio = currentAspect.replace('aspect-', ''); } }
          }, 350);
        }, 50);
      };
      aspectBtns.forEach(btn => { if (btn.dataset.aspect === 'fit') { btn.classList.add('active'); } btn.addEventListener('click', () => applyAspectRatio(btn)); });
      document.addEventListener('keydown', (e) => {
        if (e.target.closest('.dropdown-content')) {
          const activeBtn = document.activeElement;
          if (e.key === 'Escape') { activeBtn.blur(); }
          else if (e.key === 'ArrowDown' || e.key === 'ArrowUp') {
            e.preventDefault(); const buttons = Array.from(aspectBtns); const currentIndex = buttons.indexOf(activeBtn); let nextIndex = currentIndex;
            if (e.key === 'ArrowDown') { nextIndex = (currentIndex + 1) % buttons.length; } else if (e.key === 'ArrowUp') { nextIndex = (currentIndex - 1 + buttons.length) % buttons.length; }
            buttons[nextIndex].focus();
          } else if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); applyAspectRatio(activeBtn); }
        }
      });
    }
    function initPlayer() {
      video.classList.add('aspect-fit');
      const defaultAspectBtn = document.querySelector('[data-aspect="fit"]'); if (defaultAspectBtn) { defaultAspectBtn.classList.add('active'); }
      updateMuteButton(); playPauseBtn.innerHTML = video.paused ? '<i class="fas fa-play"></i>' : '<i class="fas fa-pause"></i>';
      showLoading(); initHLS(); setupEventListeners();
    }
    function setupEventListeners() {
      playPauseBtn.addEventListener('click', togglePlayPause); video.addEventListener('click', togglePlayPause);
      muteBtn.addEventListener('click', toggleMute);
      async function requestFullscreenMobile() {
        try {
          if (videoContainer.requestFullscreen) { await videoContainer.requestFullscreen(); }
          else if (videoContainer.webkitRequestFullscreen) { await videoContainer.webkitRequestFullscreen(); }
          else if (videoContainer.webkitEnterFullscreen) { await video.webkitEnterFullscreen(); }
          else if (videoContainer.msRequestFullscreen) { await videoContainer.msRequestFullscreen(); }
          return true;
        } catch (err) { console.error('Fullscreen error:', err); return false; }
      }
      fullscreenBtn.addEventListener('click', async () => {
        const isIOS = /iPad|iPhone|iPod/.test(navigator.userAgent) || (navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1);
        if (isIOS && !document.fullscreenElement) { video.webkitEnterFullscreen(); fullscreenBtn.innerHTML = '<i class="fas fa-compress"></i>'; fullscreenBtn.setAttribute('title', 'Exit fullscreen'); }
        else { await toggleFullscreen(); }
      });
      video.addEventListener('timeupdate', updateProgress);
      let isSeeking = false;
      const startSeek = (e) => { isSeeking = true; seek(e); };
      const moveSeek = (e) => { if (isSeeking) { seek(e); } };
      const endSeek = () => { isSeeking = false; };
      progressContainer.addEventListener('mousedown', startSeek); document.addEventListener('mousemove', moveSeek); document.addEventListener('mouseup', endSeek);
      progressContainer.addEventListener('touchstart', (e) => { e.preventDefault(); startSeek(e.touches[0]); });
      document.addEventListener('touchmove', (e) => { if (isSeeking) { e.preventDefault(); moveSeek(e.touches[0]); } }, { passive: false });
      document.addEventListener('touchend', endSeek);
      progressContainer.addEventListener('click', (e) => { if (!isSeeking) { seek(e); } });
      document.addEventListener('fullscreenchange', () => {
        if (!document.fullscreenElement) { fullscreenBtn.innerHTML = '<i class="fas fa-expand"></i>'; fullscreenBtn.setAttribute('title', 'Fullscreen'); showControls(); }
        else { fullscreenBtn.innerHTML = '<i class="fas fa-compress"></i>'; fullscreenBtn.setAttribute('title', 'Exit fullscreen'); resetHideControlsTimeout(); }
      });
      const showControlsOnInteraction = () => { if (!video.paused) { showControls(); } };
      videoContainer.addEventListener('mousemove', showControlsOnInteraction);
      videoContainer.addEventListener('touchstart', showControlsOnInteraction);
      videoContainer.addEventListener('touchend', showControlsOnInteraction);
      videoContainer.addEventListener('touchmove', (e) => { if (e.target === progressContainer) { e.preventDefault(); } else if (e.target.closest('.control-btn')) {} else { e.preventDefault(); } }, { passive: false });
      const handlePlay = () => { playPauseBtn.innerHTML = '<i class="fas fa-pause"></i>'; resetHideControlsTimeout(); };
      const handlePause = () => { playPauseBtn.innerHTML = '<i class="fas fa-play"></i>'; showControls(); };
      video.addEventListener('play', handlePlay); video.addEventListener('pause', handlePause);
      video.addEventListener('error', (e) => { console.error('Video error:', video.error); showControls(); });
      setupAspectRatioButtons();
      document.addEventListener('keydown', (e) => {
        if (e.code === 'Space') { e.preventDefault(); togglePlayPause(); }
        else if (e.code === 'KeyM') { toggleMute(); }
        else if (e.code === 'KeyF') { toggleFullscreen(); }
        else if (e.code === 'ArrowLeft') { e.preventDefault(); video.currentTime = Math.max(0, video.currentTime - 5); showControls(); }
        else if (e.code === 'ArrowRight') { e.preventDefault(); video.currentTime = Math.min(video.duration, video.currentTime + 5); showControls(); }
      });
    }
    function handleOrientationChange() {
      const isPortrait = window.innerHeight > window.innerWidth;
      document.documentElement.classList.toggle('portrait', isPortrait);
      document.documentElement.classList.toggle('landscape', !isPortrait);
    }
    function initializeApp() {
      handleOrientationChange();
      window.addEventListener('resize', handleOrientationChange); window.addEventListener('orientationchange', handleOrientationChange);
      if (document.readyState === 'loading') { document.addEventListener('DOMContentLoaded', initPlayer); } else { initPlayer(); }
    }
    initializeApp();
  </script>
</body>
</html>
''';
  }

  void _navigateBack() {
    // Before navigating back, ensure video is stopped to prevent background play
    _controller.runJavaScript("video.pause();");
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      // WillPopScope handles the Android system back button
      body: WillPopScope(
        onWillPop: () async {
          // This logic is now handled by _navigateBack
          _navigateBack();
          // We return false to prevent a double pop
          return false;
        },
        child: Stack(
          children: [
            // WebView that fills the entire screen
            SizedBox.expand(
              child: WebViewWidget(controller: _controller),
            ),

            // Back button - positioned for landscape
            Positioned(
              top: 16.0,
              left: 16.0,
              child: SafeArea(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    tooltip: 'Go back',
                    onPressed: _navigateBack,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
