// import 'package:flutter/material.dart';
// import 'package:webview_flutter/webview_flutter.dart';
// import 'package:webview_flutter_android/webview_flutter_android.dart';
// import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
// import 'package:flutter/services.dart'
//     show
//         rootBundle,
//         DeviceOrientation,
//         SystemChrome,
//         SystemUiMode,
//         SystemUiOverlay;

// class LiveStreamPage extends StatefulWidget {
//   const LiveStreamPage({super.key});

//   @override
//   State<LiveStreamPage> createState() => _LiveStreamPageState();
// }

// class _LiveStreamPageState extends State<LiveStreamPage> {
//   WebViewController? _webViewController;
//   bool _isLoading = true;
//   bool _hasError = false;
//   bool _isFullScreen = false;

//   final String streamUrl = 'http://msa.merkuz.com:8888/live/stream1/index.m3u8';

//   @override
//   void initState() {
//     super.initState();
//     _initializeWebView();
//   }

//   Future<void> _initializeWebView() async {
//     try {
//       String htmlContent = _createEnhancedHtml();

//       final PlatformWebViewControllerCreationParams params;

//       if (WebViewPlatform.instance is WebKitWebViewPlatform) {
//         params = WebKitWebViewControllerCreationParams(
//           allowsInlineMediaPlayback: true,
//           mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
//         );
//       } else {
//         params = const PlatformWebViewControllerCreationParams();
//       }

//       _webViewController = WebViewController.fromPlatformCreationParams(params)
//         ..setJavaScriptMode(JavaScriptMode.unrestricted)
//         ..setBackgroundColor(Colors.black)
//         ..enableZoom(false)
//         ..setNavigationDelegate(
//           NavigationDelegate(
//             onProgress: (int progress) {
//               if (progress > 80) {
//                 setState(() {
//                   _isLoading = false;
//                 });
//               }
//             },
//             onPageFinished: (String url) {
//               setState(() {
//                 _isLoading = false;
//               });
//             },
//             onWebResourceError: (WebResourceError error) {
//               setState(() {
//                 _hasError = true;
//                 _isLoading = false;
//               });
//             },
//             onNavigationRequest: (NavigationRequest request) {
//               return NavigationDecision.navigate;
//             },
//           ),
//         )

//         // Add JavaScript channel to communicate with Flutter
//         ..addJavaScriptChannel('Flutter', onMessageReceived: (message) {
//           if (message.message == 'enterFullscreen') {
//             _enterFullscreen();
//           } else if (message.message == 'exitFullscreen') {
//             _exitFullscreen();
//           }
//         });

//       if (_webViewController!.platform is AndroidWebViewController) {
//         final AndroidWebViewController androidController =
//             _webViewController!.platform as AndroidWebViewController;
//         androidController.setMediaPlaybackRequiresUserGesture(false);
//       }

//       _webViewController!.loadHtmlString(htmlContent);
//     } catch (e) {
//       setState(() {
//         _hasError = true;
//         _isLoading = false;
//       });
//     }
//   }

//   void _enterFullscreen() {
//     if (!_isFullScreen) {
//       SystemChrome.setPreferredOrientations([
//         DeviceOrientation.landscapeLeft,
//         DeviceOrientation.landscapeRight,
//       ]);
//       SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
//       setState(() {
//         _isFullScreen = true;
//       });

//       // Force WebView to update its layout by running a small JS reflow.
//       WidgetsBinding.instance.addPostFrameCallback((_) async {
//         if (mounted) {
//           try {
//             await _webViewController
//                 ?.runJavaScript('window.dispatchEvent(new Event("resize"));');
//           } catch (_) {}
//           setState(() {});
//         }
//       });
//     }
//   }

//   void _exitFullscreen() {
//     if (_isFullScreen) {
//       SystemChrome.setPreferredOrientations([
//         DeviceOrientation.portraitUp,
//       ]);
//       SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
//           overlays: SystemUiOverlay.values);
//       setState(() {
//         _isFullScreen = false;
//       });

//       WidgetsBinding.instance.addPostFrameCallback((_) async {
//         if (mounted) {
//           try {
//             await _webViewController
//                 ?.runJavaScript('window.dispatchEvent(new Event("resize"));');
//           } catch (_) {}
//           setState(() {});
//         }
//       });
//     }
//   }

//   Future<bool> _onWillPop() async {
//     if (_isFullScreen) {
//       _exitFullscreen();
//       return false;
//     }
//     return true;
//   }

//   String _createEnhancedHtml() {
//     // IMPORTANT: Use single quotes for the Dart string, but the HTML contains double quotes.
//     return '''
// <!DOCTYPE html>
// <html lang="en">
// <head>
//     <meta charset="UTF-8" />
//     <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
//     <title>Live Stream</title>
//     <script src="https://cdn.jsdelivr.net/npm/hls.js@latest"></script>
//     <style>
//         html, body {
//             height: 100%;
//             width: 100%;
//             margin: 0;
//             padding: 0;
//             background: #000;
//             -webkit-user-select: none;
//             user-select: none;
//             -webkit-touch-callout: none;
//             touch-action: none;
//             overflow: hidden;
//         }

//         /* Video container fills full viewport */
//         #videoContainer {
//             width: 100vw;
//             height: 100vh;
//             display: flex;
//             align-items: center;
//             justify-content: center;
//             background: #000;
//             position: relative;
//         }

//         /* Video element default: fill available height while maintaining aspect-ratio */
//         #video {
//             display: block;
//             max-width: 100%;
//             max-height: 100%;
//             height: 100vh;      /* IMPORTANT: use viewport height so in landscape it fills vertically */
//             width: auto;        /* width auto preserves aspect ratio, creates side black bars if needed */
//             object-fit: contain;/* ensure no cropping/stretching */
//             background: #000;
//         }

//         /* Loading overlay */
//         #loading {
//             position: absolute;
//             z-index: 40;
//             color: white;
//             text-align: center;
//         }
//         .spinner {
//             border: 3px solid rgba(255, 255, 255, 0.18);
//             border-radius: 50%;
//             border-top: 3px solid #fff;
//             width: 36px;
//             height: 36px;
//             animation: spin 1s linear infinite;
//             margin-bottom: 8px;
//         }
//         @keyframes spin {
//             0% { transform: rotate(0deg); }
//             100% { transform: rotate(360deg); }
//         }

//         /* Status badge */
//         #status {
//             position: absolute;
//             top: 16px;
//             left: 16px;
//             z-index: 50;
//             background: rgba(0,0,0,0.6);
//             color: #fff;
//             padding: 8px 12px;
//             border-radius: 18px;
//             font-size: 14px;
//             backdrop-filter: blur(6px);
//         }

//         /* Custom fullscreen button */
//         #customFullscreenBtn {
//             position: absolute;
//             bottom: 20px;
//             right: 20px;
//             z-index: 60;
//             background: rgba(0,0,0,0.6);
//             color: #fff;
//             border: none;
//             padding: 10px 12px;
//             border-radius: 8px;
//             font-size: 14px;
//             cursor: pointer;
//             backdrop-filter: blur(6px);
//         }

//         /* Error box */
//         #error {
//             position: absolute;
//             z-index: 70;
//             color: white;
//             background: rgba(255,0,0,0.08);
//             padding: 18px;
//             border-radius: 10px;
//             border: 1px solid rgba(255,255,255,0.12);
//             text-align: center;
//         }

//         /* Make sure native controls do not jump in fullscreen on iOS */
//         video::-webkit-media-controls {
//             display: none !important;
//         }
//     </style>
// </head>
// <body>
//     <div id="videoContainer">
//         <div id="loading">
//             <div class="spinner"></div>
//             <div>Connecting to stream...</div>
//         </div>

//         <video id="video" controls playsinline autoplay muted></video>

//         <div id="status">🔴 LIVE</div>
//         <button id="customFullscreenBtn" onclick="toggleFullscreen()">⛶ Fullscreen</button>
//     </div>

//     <script>
//         const hlsUrl = "$streamUrl";
//         const video = document.getElementById('video');
//         const loading = document.getElementById('loading');
//         let hls;
//         let retryCount = 0;
//         const maxRetries = 6;
//         let isFullscreen = false;

//         function log() { try { console.log.apply(console, arguments); } catch(e) {} }

//         function setupHls() {
//             loading.style.display = 'block';

//             // Ensure correct muting/volume defaults
//             video.muted = false;
//             video.volume = 1.0;

//             if (hls) {
//                 try { hls.destroy(); } catch(_) {}
//                 hls = null;
//             }

//             if (Hls.isSupported()) {
//                 hls = new Hls({
//                     enableWorker: true,
//                     lowLatencyMode: true,
//                     backBufferLength: 60
//                 });
//                 hls.attachMedia(video);
//                 hls.on(Hls.Events.MEDIA_ATTACHED, function() {
//                     hls.loadSource(hlsUrl);
//                 });
//                 hls.on(Hls.Events.MANIFEST_PARSED, function() {
//                     loading.style.display = 'none';
//                     video.play().catch(e => log('autoplay error', e));
//                 });
//                 hls.on(Hls.Events.ERROR, function(event, data) {
//                     log('HLS error', data);
//                     if (data.fatal) {
//                         if (data.type === Hls.ErrorTypes.NETWORK_ERROR) {
//                             retryStream();
//                         } else if (data.type === Hls.ErrorTypes.MEDIA_ERROR) {
//                             hls.recoverMediaError();
//                         } else {
//                             showError('Stream error');
//                         }
//                     }
//                 });
//             } else if (video.canPlayType('application/vnd.apple.mpegurl')) {
//                 video.src = hlsUrl;
//                 video.addEventListener('loadeddata', function() {
//                     loading.style.display = 'none';
//                     video.play().catch(e => log('autoplay fail', e));
//                 }, { once: true });
//                 video.addEventListener('error', retryStream);
//             } else {
//                 showError('HLS not supported in this environment');
//             }

//             video.addEventListener('waiting', function() { loading.style.display = 'block'; });
//             video.addEventListener('playing', function() { loading.style.display = 'none'; retryCount = 0; });
//         }

//         function retryStream() {
//             retryCount++;
//             if (retryCount <= maxRetries) {
//                 loading.style.display = 'block';
//                 loading.innerHTML = '<div class="spinner"></div>Reconnecting... (' + retryCount + '/' + maxRetries + ')';
//                 setTimeout(function() {
//                     setupHls();
//                 }, 1800 + (retryCount * 200));
//             } else {
//                 showError('Failed to connect after ' + maxRetries + ' attempts');
//             }
//         }

//         function showError(msg) {
//             loading.style.display = 'none';
//             const e = document.createElement('div');
//             e.id = 'error';
//             e.innerHTML = '❌ ' + msg + '<br><br><button onclick="location.reload()">Retry</button>';
//             document.getElementById('videoContainer').appendChild(e);
//         }

//         function toggleFullscreen() {
//             isFullscreen = !isFullscreen;
//             if (isFullscreen) {
//                 try { Flutter.postMessage('enterFullscreen'); } catch(e) {}
//                 document.getElementById('customFullscreenBtn').textContent = '⛶ Exit Fullscreen';
//             } else {
//                 try { Flutter.postMessage('exitFullscreen'); } catch(e) {}
//                 document.getElementById('customFullscreenBtn').textContent = '⛶ Fullscreen';
//             }
//             // small delay then reflow to ensure WebView updated orientation/size
//             setTimeout(function() { window.dispatchEvent(new Event('resize')); fixVideoSizing(); }, 200);
//         }

//         function fixVideoSizing() {
//             // In fullscreen we want the video to fill vertically (100vh) and keep aspect ratio,
//             // width auto will create black bars on sides when aspect differs (no crop).
//             if (isFullscreen) {
//                 video.style.height = '100vh';
//                 video.style.width = 'auto';
//                 video.style.objectFit = 'contain';
//             } else {
//                 // Normal mode: keep it constrained but visible (still no crop)
//                 video.style.height = '100vh';
//                 video.style.width = 'auto';
//                 video.style.objectFit = 'contain';
//             }
//         }

//         // Re-check when window changes (e.g. device rotated or Flutter toggled orientation)
//         window.addEventListener('resize', function() {
//             fixVideoSizing();
//         });

//         // Prevent zoom (mobile)
//         document.addEventListener('gesturestart', e => e.preventDefault());
//         document.addEventListener('gesturechange', e => e.preventDefault());
//         document.addEventListener('gestureend', e => e.preventDefault());
//         let lastTouch = 0;
//         document.addEventListener('touchend', function(e) {
//             const now = Date.now();
//             if (now - lastTouch <= 300) e.preventDefault();
//             lastTouch = now;
//         }, false);

//         // Initialize player
//         setupHls();
//         fixVideoSizing();

//         // Pause/resume on visibility change
//         document.addEventListener('visibilitychange', function() {
//             if (document.hidden) {
//                 try { video.pause(); } catch(_) {}
//             } else {
//                 video.play().catch(_=>{});
//             }
//         });
//     </script>
// </body>
// </html>
//     ''';
//   }

//   void _reloadStream() {
//     setState(() {
//       _isLoading = true;
//       _hasError = false;
//     });
//     _webViewController?.reload();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return WillPopScope(
//       onWillPop: _onWillPop,
//       child: Scaffold(
//         backgroundColor: Colors.black,
//         appBar: _isFullScreen
//             ? null
//             : AppBar(
//                 backgroundColor: Colors.black,
//                 elevation: 0,
//                 leading: IconButton(
//                   icon: const Icon(Icons.arrow_back, color: Colors.white),
//                   onPressed: () => Navigator.of(context).pop(),
//                 ),
//                 title: const Text(
//                   'Live Stream',
//                   style: TextStyle(color: Colors.white, fontSize: 18),
//                 ),
//                 actions: [
//                   IconButton(
//                     icon: const Icon(Icons.refresh, color: Colors.white),
//                     onPressed: _reloadStream,
//                     tooltip: 'Reload Stream',
//                   ),
//                 ],
//               ),
//         body: _buildWebView(),
//       ),
//     );
//   }

//   Widget _buildWebView() {
//     return Container(
//       width: double.infinity,
//       height: double.infinity,
//       color: Colors.black,
//       child: Stack(
//         children: [
//           if (_webViewController != null)
//             WebViewWidget(
//               controller: _webViewController!,
//             ),
//           if (_isLoading)
//             Container(
//               width: double.infinity,
//               height: double.infinity,
//               color: Colors.black,
//               child: const Center(
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     CircularProgressIndicator(color: Colors.white),
//                     SizedBox(height: 20),
//                     Text(
//                       'Loading Stream...',
//                       style: TextStyle(color: Colors.white, fontSize: 16),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           if (_hasError)
//             Container(
//               width: double.infinity,
//               height: double.infinity,
//               color: Colors.black,
//               child: Center(
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     const Icon(Icons.error_outline,
//                         color: Colors.white, size: 64),
//                     const SizedBox(height: 16),
//                     const Text(
//                       'Stream Connection Error',
//                       style: TextStyle(color: Colors.white, fontSize: 18),
//                     ),
//                     const SizedBox(height: 20),
//                     ElevatedButton.icon(
//                       onPressed: _reloadStream,
//                       icon: const Icon(Icons.refresh),
//                       label: const Text('Retry Connection'),
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.blue,
//                         foregroundColor: Colors.white,
//                         padding: const EdgeInsets.symmetric(
//                             horizontal: 24, vertical: 12),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//         ],
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
//     SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
//         overlays: SystemUiOverlay.values);
//     super.dispose();
//   }
// }
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
      ..loadHtmlString(_createLivePlayerHtml());
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

  // FIXED HTML: Proper landscape orientation
  String _createLivePlayerHtml() {
    return '''
<!DOCTYPE html>
<html>
<head>
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <script src="https://cdn.jsdelivr.net/npm/hls.js@latest"></script>
    <style>
        body, html {
            margin: 0;
            padding: 0;
            width: 100%;
            height: 100%;
            background-color: #000;
            overflow: hidden;
            position: fixed;
        }
        
        video {
            position: absolute;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            object-fit: contain;
            transform: scale(1.5) rotate(0deg); /* Scale up to fill landscape */
        }
    </style>
</head>
<body>
    <video id="video" autoplay playsinline controls></video>
    
    <script>
        const video = document.getElementById('video');
        const hlsUrl = "$streamUrl";

        // Function to adjust video for landscape
        function adjustForLandscape() {
            const isLandscape = window.innerWidth > window.innerHeight;
            if (isLandscape) {
                video.style.transform = 'scale(1.0) rotate(0deg)';
            }
        }

        if (Hls.isSupported()) {
            const hls = new Hls();
            hls.loadSource(hlsUrl);
            hls.attachMedia(video);

            hls.on(Hls.Events.MANIFEST_PARSED, function(event, data) {
                console.log("Manifest parsed, found " + data.levels.length + " quality levels");

                let bestLevel = -1;
                let maxHeight = 0;
                data.levels.forEach((level, index) => {
                    if (level.height > maxHeight) {
                        maxHeight = level.height;
                        bestLevel = index;
                    }
                });

                if (bestLevel !== -1) {
                    hls.startLevel = bestLevel;
                }
                
                adjustForLandscape();
                video.play().catch(e => console.error("Autoplay failed", e));
            });
            
        } else if (video.canPlayType('application/vnd.apple.mpegurl')) {
            video.src = hlsUrl;
            video.addEventListener('loadedmetadata', function() {
                adjustForLandscape();
                video.play().catch(e => console.error("Autoplay failed", e));
            });
        }
        
        window.addEventListener('resize', adjustForLandscape);
    </script>
</body>
</html>
''';
  }

  void _navigateBack() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: WillPopScope(
        onWillPop: () async {
          _navigateBack();
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
