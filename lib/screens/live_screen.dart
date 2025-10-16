import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'package:flutter/services.dart'
    show
        rootBundle,
        DeviceOrientation,
        SystemChrome,
        SystemUiMode,
        SystemUiOverlay;

class LiveStreamPage extends StatefulWidget {
  const LiveStreamPage({super.key});

  @override
  State<LiveStreamPage> createState() => _LiveStreamPageState();
}

class _LiveStreamPageState extends State<LiveStreamPage> {
  WebViewController? _webViewController;
  bool _isLoading = true;
  bool _hasError = false;
  bool _isFullScreen = false;

  final String streamUrl = 'http://msa.merkuz.com:8888/live/stream1/index.m3u8';

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  Future<void> _initializeWebView() async {
    try {
      String htmlContent = await _loadHtmlContent();

      final PlatformWebViewControllerCreationParams params;

      if (WebViewPlatform.instance is WebKitWebViewPlatform) {
        params = WebKitWebViewControllerCreationParams(
          allowsInlineMediaPlayback: true,
          mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
        );
      } else {
        params = const PlatformWebViewControllerCreationParams();
      }

      _webViewController = WebViewController.fromPlatformCreationParams(params)
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Colors.black)
        ..enableZoom(false)
        ..setNavigationDelegate(
          NavigationDelegate(
            onProgress: (int progress) {
              if (progress > 80) {
                setState(() {
                  _isLoading = false;
                });
              }
            },
            onPageFinished: (String url) {
              setState(() {
                _isLoading = false;
              });
            },
            onWebResourceError: (WebResourceError error) {
              setState(() {
                _hasError = true;
                _isLoading = false;
              });
            },
            onNavigationRequest: (NavigationRequest request) {
              return NavigationDecision.navigate;
            },
          ),
        )

        // Add JavaScript channel to communicate with Flutter
        ..addJavaScriptChannel('Flutter', onMessageReceived: (message) {
          if (message.message == 'enterFullscreen') {
            _enterFullscreen();
          } else if (message.message == 'exitFullscreen') {
            _exitFullscreen();
          }
        });

      if (_webViewController!.platform is AndroidWebViewController) {
        final AndroidWebViewController androidController =
            _webViewController!.platform as AndroidWebViewController;
        androidController.setMediaPlaybackRequiresUserGesture(false);
      }

      _webViewController!.loadHtmlString(htmlContent);
    } catch (e) {
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  void _enterFullscreen() {
    if (!_isFullScreen) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      setState(() {
        _isFullScreen = true;
      });
    }
  }

  void _exitFullscreen() {
    if (_isFullScreen) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
          overlays: SystemUiOverlay.values);
      setState(() {
        _isFullScreen = false;
      });
    }
  }

  Future<bool> _onWillPop() async {
    if (_isFullScreen) {
      _exitFullscreen();
      return false;
    }
    return true;
  }

  Future<String> _loadHtmlContent() async {
    return _createEnhancedHtml();
  }

  String _createEnhancedHtml() {
    return '''
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <title>Live Stream</title>
    <script src="https://cdn.jsdelivr.net/npm/hls.js@latest"></script>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        body {
            margin: 0;
            background: #000000;
            overflow: hidden;
            width: 100vw;
            height: 100vh;
            display: flex;
            justify-content: center;
            align-items: center;
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
        }
        #videoContainer {
            width: 100%;
            height: 100%;
            position: relative;
            background: #000;
        }
        #video {
            width: 100%;
            height: 100%;
            object-fit: contain;
            background: #000;
        }
        #loading {
            position: absolute;
            top: 50%;
            left: 50%;
            transform: translate(-50%, -50%);
            color: white;
            font-size: 16px;
            text-align: center;
            z-index: 10;
        }
        .spinner {
            border: 3px solid rgba(255, 255, 255, 0.3);
            border-radius: 50%;
            border-top: 3px solid #ffffff;
            width: 40px;
            height: 40px;
            animation: spin 1s linear infinite;
            margin: 0 auto 15px;
        }
        @keyframes spin {
            0% { transform: rotate(0deg); }
            100% { transform: rotate(360deg); }
        }
        #error {
            position: absolute;
            top: 50%;
            left: 50%;
            transform: translate(-50%, -50%);
            color: white;
            text-align: center;
            background: rgba(255, 0, 0, 0.1);
            padding: 20px;
            border-radius: 10px;
            border: 1px solid rgba(255, 255, 255, 0.2);
        }
        #status {
            position: absolute;
            top: 20px;
            left: 20px;
            background: rgba(0, 0, 0, 0.7);
            color: white;
            padding: 8px 16px;
            border-radius: 20px;
            font-size: 14px;
            z-index: 5;
            backdrop-filter: blur(10px);
        }
        
        /* Custom fullscreen button */
        #customFullscreenBtn {
            position: absolute;
            bottom: 20px;
            right: 20px;
            background: rgba(0, 0, 0, 0.7);
            border: none;
            border-radius: 8px;
            padding: 10px 15px;
            color: white;
            font-size: 14px;
            cursor: pointer;
            backdrop-filter: blur(10px);
            z-index: 20;
        }
    </style>
</head>
<body>
    <div id="videoContainer">
        <div id="loading">
            <div class="spinner"></div>
            Connecting to stream...
        </div>
        <!-- KEEP CONTROLS ATTRIBUTE for 3-dots menu and sound -->
        <video id="video" controls autoplay playsinline></video>
        <div id="status">🔴 LIVE</div>
        <button id="customFullscreenBtn" onclick="toggleFullscreen()">⛶ Fullscreen</button>
    </div>

    <script>
        const video = document.getElementById("video");
        const videoContainer = document.getElementById("videoContainer");
        const loading = document.getElementById("loading");
        const status = document.getElementById("status");
        const fullscreenBtn = document.getElementById("customFullscreenBtn");
        const hlsUrl = "$streamUrl";

        let hls;
        let retryCount = 0;
        const maxRetries = 5;
        let isFullscreen = false;

        function initializePlayer() {
            loading.style.display = 'block';
            
            // Enable sound by default (remove muted attribute)
            video.muted = false;
            video.volume = 1.0;
            
            if (Hls.isSupported()) {
                if (hls) {
                    hls.destroy();
                }
                
                hls = new Hls({
                    enableWorker: true,
                    lowLatencyMode: true,
                    backBufferLength: 90
                });
                
                hls.loadSource(hlsUrl);
                hls.attachMedia(video);
                
                hls.on(Hls.Events.MANIFEST_PARSED, function() {
                    console.log('HLS manifest parsed');
                    loading.style.display = 'none';
                    video.play().catch(e => {
                        console.log('Auto-play failed:', e);
                    });
                });
                
                hls.on(Hls.Events.ERROR, function(event, data) {
                    console.log('HLS error:', data);
                    if (data.fatal) {
                        switch(data.type) {
                            case Hls.ErrorTypes.NETWORK_ERROR:
                                console.log('Network error, retrying...');
                                retryStream();
                                break;
                            case Hls.ErrorTypes.MEDIA_ERROR:
                                console.log('Media error, recovering...');
                                hls.recoverMediaError();
                                break;
                            default:
                                console.log('Fatal error, cannot recover');
                                showError('Stream error');
                                break;
                        }
                    }
                });
                
            } else if (video.canPlayType("application/vnd.apple.mpegurl")) {
                video.src = hlsUrl;
                video.addEventListener('loadeddata', function() {
                    loading.style.display = 'none';
                    video.play().catch(e => {
                        console.log('Auto-play failed:', e);
                    });
                });
                
                video.addEventListener('error', function() {
                    retryStream();
                });
            } else {
                showError('HLS not supported');
            }

            video.addEventListener('waiting', function() {
                loading.style.display = 'block';
            });
            
            video.addEventListener('playing', function() {
                loading.style.display = 'none';
                retryCount = 0;
            });
        }

        function toggleFullscreen() {
            if (!isFullscreen) {
                // Enter fullscreen - notify Flutter
                Flutter.postMessage('enterFullscreen');
                isFullscreen = true;
                fullscreenBtn.textContent = '⛶ Exit Fullscreen';
            } else {
                // Exit fullscreen - notify Flutter
                Flutter.postMessage('exitFullscreen');
                isFullscreen = false;
                fullscreenBtn.textContent = '⛶ Fullscreen';
            }
        }

        // Handle device back button in fullscreen
        document.addEventListener('keydown', function(e) {
            if (e.key === 'Escape' && isFullscreen) {
                toggleFullscreen();
            }
        });

        function retryStream() {
            if (retryCount < maxRetries) {
                retryCount++;
                console.log('Retrying stream... attempt ' + retryCount);
                loading.style.display = 'block';
                loading.innerHTML = '<div class="spinner"></div>Reconnecting... (' + retryCount + '/' + maxRetries + ')';
                
                setTimeout(function() {
                    initializePlayer();
                }, 2000);
            } else {
                showError('Failed to connect after ' + maxRetries + ' attempts');
            }
        }

        function showError(message) {
            loading.style.display = 'none';
            const errorElement = document.createElement('div');
            errorElement.id = 'error';
            errorElement.innerHTML = '❌ ' + message + '<br><button onclick="location.reload()">Retry</button>';
            videoContainer.appendChild(errorElement);
        }

        initializePlayer();

        document.addEventListener('visibilitychange', function() {
            if (document.hidden) {
                video.pause();
            } else {
                video.play().catch(e => console.log('Resume play failed:', e));
            }
        });

        document.addEventListener('contextmenu', function(e) {
            e.preventDefault();
            return false;
        });
    </script>
</body>
</html>
''';
  }

  void _reloadStream() {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    _webViewController?.reload();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: _isFullScreen
            ? null
            : AppBar(
                backgroundColor: Colors.black,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                title: const Text(
                  'Live Stream',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    onPressed: _reloadStream,
                    tooltip: 'Reload Stream',
                  ),
                ],
              ),
        body: Stack(
          children: [
            if (_webViewController != null)
              WebViewWidget(controller: _webViewController!),
            if (_isLoading)
              Container(
                color: Colors.black,
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(height: 20),
                      Text(
                        'Loading Stream...',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            if (_hasError)
              Container(
                color: Colors.black,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline,
                          color: Colors.white, size: 64),
                      const SizedBox(height: 16),
                      const Text(
                        'Stream Connection Error',
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: _reloadStream,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry Connection'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Reset orientation when leaving the page
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: SystemUiOverlay.values);
    super.dispose();
  }
}
