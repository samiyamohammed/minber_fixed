import 'package:flutter_compass_v2/flutter_compass_v2.dart';

/// Native compass via flutter_compass_v2.
class CompassHeadingService {
  static Stream<double>? get headingStream => FlutterCompass.events
      ?.where((event) => event.heading != null)
      .map((event) => event.heading!);

  static Future<void> ensureStarted() async {}

  static void stop() {}
}
