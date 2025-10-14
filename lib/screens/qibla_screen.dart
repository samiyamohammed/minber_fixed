// lib/screens/qibla_compass_page.dart (Fully Updated & Corrected)

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_compass_v2/flutter_compass_v2.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:adhan_dart/adhan_dart.dart';

class QiblaCompassPage extends StatefulWidget {
  const QiblaCompassPage({super.key});

  @override
  State<QiblaCompassPage> createState() => _QiblaCompassPageState();
}

class _QiblaCompassPageState extends State<QiblaCompassPage> {
  int _selectedIndex = 2;

  double? _heading;
  double? _qiblaDirection;
  String _locationName = "Searching for location...";

  StreamSubscription? _compassSubscription;
  StreamSubscription? _locationSubscription;

  @override
  void initState() {
    super.initState();
    _startListening();
  }

  @override
  void dispose() {
    _compassSubscription?.cancel();
    _locationSubscription?.cancel();
    super.dispose();
  }

  void _startListening() {
    // Listen to compass events
    _compassSubscription = FlutterCompass.events?.listen((event) {
      if (mounted) setState(() => _heading = event.heading);
    });

    // Listen to location changes
    _locationSubscription = Geolocator.getPositionStream()
        .listen((Position position) => _updateLocationAndQibla(position),
            onError: (error) {
      // If there's an error (like permissions denied), show a relevant message
      if (mounted) setState(() => _locationName = "Location access denied");
    });
  }

  Future<void> _updateLocationAndQibla(Position position) async {
    final qiblaDir =
        Qibla.qibla(Coordinates(position.latitude, position.longitude));
    if (mounted) setState(() => _qiblaDirection = qiblaDir);

    // Update location name
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty && mounted) {
        final place = placemarks.first;
        setState(() => _locationName = "${place.locality}, ${place.country}");
      }
    } catch (e) {/* Handle geocoding error if needed */}
  }

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;
    String routeName = '';
    switch (index) {
      case 0:
        routeName = '/home';
        break;
      case 1:
        routeName = '/media';
        break;
      case 2:
        routeName = '/prayer';
        break;
      case 3:
        routeName = '/chatbot';
        break;
      case 4:
        routeName = '/subapps';
        break;
    }
    if (routeName.isNotEmpty)
      Navigator.pushReplacementNamed(context, routeName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Qibla Compass")),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNavBar(Theme.of(context)),
    );
  }

  // --- WIDGET BUILDER METHODS ---

  Widget _buildBody() {
    // ✅ CORRECTION: Removed the explicit permission check UI.
    // Now it just shows a loading indicator until data is available.
    if (_heading == null || _qiblaDirection == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final theme = Theme.of(context);
    final double heading = _heading!;
    final double qiblaDirection = _qiblaDirection!;

    final double normalizedHeading = heading < 0 ? 360 + heading : heading;
    final double difference = (qiblaDirection - normalizedHeading).abs();
    final double shortestAngle =
        difference > 180 ? 360 - difference : difference;
    final bool isAligned = shortestAngle < 2.5;
    if (isAligned) HapticFeedback.lightImpact();

    // ✅ CORRECTION: Wrapped in a Center widget for perfect alignment.
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("Qibla Direction",
              style: theme.textTheme.titleMedium
                  ?.copyWith(color: theme.hintColor)),
          Text("${qiblaDirection.toStringAsFixed(1)}° N",
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const Spacer(flex: 2),
          SizedBox(
            width: 300,
            height: 300,
            child: Stack(
              alignment: Alignment.center,
              children: [
                AnimatedRotation(
                  turns: -normalizedHeading / 360,
                  duration: const Duration(milliseconds: 400),
                  child: CustomPaint(
                    size: const Size(300, 300),
                    painter: _CompassPainter(
                        qiblaAngle: qiblaDirection, theme: theme),
                  ),
                ),
                CustomPaint(
                  size: const Size(20, 30),
                  painter: _TargetMarkerPainter(
                      color: isAligned
                          ? Colors.green.shade400
                          : theme.colorScheme.primary),
                )
              ],
            ),
          ),
          const Spacer(flex: 2),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isAligned
                  ? Colors.green.withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              isAligned ? "Aligned" : "${shortestAngle.round()}° to Qibla",
              style: theme.textTheme.titleLarge?.copyWith(
                color: isAligned
                    ? Colors.green.shade600
                    : theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(_locationName,
              style:
                  theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor)),
          const Spacer(),
        ],
      ),
    );
  }

  BottomNavigationBar _buildBottomNavBar(ThemeData theme) {
    return BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: theme.colorScheme.primary,
        unselectedItemColor: theme.unselectedWidgetColor,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: "Home"),
          BottomNavigationBarItem(
              icon: Icon(Icons.tv_outlined),
              activeIcon: Icon(Icons.tv),
              label: "Media"),
          BottomNavigationBarItem(
              icon: Icon(Icons.mosque_outlined),
              activeIcon: Icon(Icons.mosque),
              label: "Prayer"),
          BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline),
              activeIcon: Icon(Icons.chat_bubble),
              label: "Chat Bot"),
          BottomNavigationBarItem(
              icon: Icon(Icons.explore_outlined),
              activeIcon: Icon(Icons.apps),
              label: "Sub Apps")
        ]);
  }
}

class _CompassPainter extends CustomPainter {
  final double qiblaAngle;
  final ThemeData theme;

  _CompassPainter({required this.qiblaAngle, required this.theme});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final textPainter = TextPainter(
        textAlign: TextAlign.center, textDirection: TextDirection.ltr);

    // Dial
    canvas.drawCircle(center, radius, Paint()..color = theme.cardColor);
    canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = theme.dividerColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..isAntiAlias = true);

    // Ticks and Labels
    for (int i = 0; i < 360; i += 2) {
      final isMajor = i % 30 == 0;
      final angle = (i - 90) * (math.pi / 180);
      final tickLength = isMajor ? 15.0 : 8.0;
      final tickStart = center +
          Offset(math.cos(angle) * (radius - tickLength),
              math.sin(angle) * (radius - tickLength));
      final tickEnd =
          center + Offset(math.cos(angle) * radius, math.sin(angle) * radius);
      canvas.drawLine(
          tickStart,
          tickEnd,
          Paint()
            ..color = theme.hintColor.withOpacity(0.5)
            ..strokeWidth = isMajor ? 2 : 1
            ..isAntiAlias = true);

      if (i % 90 == 0) {
        String label = (i == 0)
            ? 'N'
            : (i == 90)
                ? 'E'
                : (i == 180)
                    ? 'S'
                    : 'W';
        textPainter.text = TextSpan(
            text: label,
            style: theme.textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.bold));
        textPainter.layout();
        final labelOffset = center +
            Offset(math.cos(angle) * (radius - 35),
                math.sin(angle) * (radius - 35));
        textPainter.paint(
            canvas,
            labelOffset -
                Offset(textPainter.width / 2, textPainter.height / 2));
      }
    }

    // North Needle
    final northAngleRad = (0 - 90) * (math.pi / 180);
    final northPath = Path()
      ..moveTo(center.dx + 10 * math.cos(northAngleRad + math.pi / 2),
          center.dy + 10 * math.sin(northAngleRad + math.pi / 2))
      ..lineTo(center.dx + (radius * 0.8) * math.cos(northAngleRad),
          center.dy + (radius * 0.8) * math.sin(northAngleRad))
      ..lineTo(center.dx + 10 * math.cos(northAngleRad - math.pi / 2),
          center.dy + 10 * math.sin(northAngleRad - math.pi / 2))
      ..close();
    canvas.drawPath(
        northPath,
        Paint()
          ..color = Colors.red.shade400
          ..isAntiAlias = true);

    // Qibla Indicator
    final qiblaAngleRad = (qiblaAngle - 90) * (math.pi / 180);
    final qiblaPath = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(Rect.fromCircle(center: center, radius: radius * 0.15),
          qiblaAngleRad - 0.2, 0.4, false)
      ..lineTo(center.dx + (radius * 0.5) * math.cos(qiblaAngleRad),
          center.dy + (radius * 0.5) * math.sin(qiblaAngleRad))
      ..close();
    final qiblaStrokePaint = Paint()
      ..color = theme.colorScheme.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..isAntiAlias = true;
    final qiblaFillPaint = Paint()
      ..shader = RadialGradient(colors: [
        theme.colorScheme.primary.withOpacity(0.5),
        Colors.transparent
      ]).createShader(Rect.fromCircle(center: center, radius: radius))
      ..isAntiAlias = true;
    canvas.drawPath(qiblaPath, qiblaStrokePaint);
    canvas.drawPath(qiblaPath, qiblaFillPaint);

    // Center Pin
    canvas.drawCircle(
        center,
        8,
        Paint()
          ..color = theme.scaffoldBackgroundColor
          ..isAntiAlias = true);
    canvas.drawCircle(
        center,
        6,
        Paint()
          ..color = theme.colorScheme.primary
          ..isAntiAlias = true);
  }

  @override
  bool shouldRepaint(_CompassPainter old) =>
      old.qiblaAngle != qiblaAngle || old.theme != theme;
}

class _TargetMarkerPainter extends CustomPainter {
  final Color color;
  _TargetMarkerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(0, size.height)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_TargetMarkerPainter old) => old.color != color;
}
