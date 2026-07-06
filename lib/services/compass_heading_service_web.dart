import 'dart:async';

import 'web_compass_service.dart';

/// Web/PWA compass via Device Orientation API.
class CompassHeadingService {
  static StreamController<double>? _controller;
  static Stream<double>? _broadcastStream;
  static bool _started = false;

  static Stream<double>? get headingStream {
    _controller ??= StreamController<double>.broadcast();
    _broadcastStream ??= _controller!.stream;
    return _broadcastStream;
  }

  static Future<void> ensureStarted() async {
    if (_started) return;
    _started = true;

    await WebCompassService.requestPermission();

    final stream = WebCompassService.start();
    if (stream == null) return;

    stream.listen((heading) {
      if (_controller != null && !_controller!.isClosed) {
        _controller!.add(heading);
      }
    });
  }

  static void stop() {
    _started = false;
    WebCompassService.stop();
    _controller?.close();
    _controller = null;
    _broadcastStream = null;
  }
}
