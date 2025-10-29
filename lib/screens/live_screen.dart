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
  // FIXED HTML: Let video control its own size, no forced CSS
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
            display: flex;
            justify-content: center;
            align-items: center;
        }
        
        video {
            max-width: 100%;
            max-height: 100%;
            width: auto;
            height: auto;
            /* Let the video decide its own size */
        }
        
        /* For landscape videos - let them use full height */
        @media (orientation: landscape) {
            video {
                max-height: 100vh;
                width: auto;
            }
        }
    </style>
</head>
<body>
    <video id="video" autoplay playsinline controls></video>
    
    <script>
        const video = document.getElementById('video');
        const hlsUrl = "$streamUrl";

        if (Hls.isSupported()) {
            const hls = new Hls();
            hls.loadSource(hlsUrl);
            hls.attachMedia(video);

            hls.on(Hls.Events.MANIFEST_PARSED, function(event, data) {
                console.log("Manifest parsed, found " + data.levels.length + " quality levels");
                video.play().catch(e => console.error("Autoplay failed", e));
            });
            
        } else if (video.canPlayType('application/vnd.apple.mpegurl')) {
            video.src = hlsUrl;
            video.addEventListener('loadedmetadata', function() {
                video.play().catch(e => console.error("Autoplay failed", e));
            });
        }
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
