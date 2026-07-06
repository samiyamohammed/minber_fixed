import 'dart:async';

import 'package:flutter/foundation.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;
// ignore: avoid_web_libraries_in_flutter
import 'dart:js_util' as js_util;

/// Reads compass heading from the browser Device Orientation API.
class WebCompassService {
  static StreamController<double>? _controller;
  static Timer? _pollTimer;

  static bool get isSupported {
    try {
      return js.context.callMethod('webCompassSupported', []) == true;
    } catch (_) {
      return false;
    }
  }

  static bool get needsPermission {
    try {
      return js.context.callMethod('webCompassNeedsPermission', []) == true;
    } catch (_) {
      return false;
    }
  }

  static Future<String> requestPermission() async {
    try {
      final result =
          await js.context.callMethod('requestWebCompassPermission', []);
      return result?.toString() ?? 'denied';
    } catch (e) {
      debugPrint('[WebCompassService] Permission error: $e');
      return 'denied';
    }
  }

  static Stream<double>? start() {
    if (!isSupported) return null;

    stop();
    _controller = StreamController<double>.broadcast();

    js_util.setProperty(
      js.context,
      '_webCompassDartCallback',
      js_util.allowInterop((num heading) {
        _controller?.add(heading.toDouble());
      }),
    );

    js.context.callMethod('startWebCompass', []);

    // Backup poll in case the JS callback misses events in PWA standalone mode
    _pollTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      try {
        final heading = js.context.callMethod('getLastCompassHeading', []);
        if (heading is num) {
          _controller?.add(heading.toDouble());
        }
      } catch (_) {}
    });

    return _controller!.stream;
  }

  static void stop() {
    _pollTimer?.cancel();
    _pollTimer = null;
    try {
      js.context.callMethod('stopWebCompass', []);
    } catch (_) {}
    _controller?.close();
    _controller = null;
  }
}
