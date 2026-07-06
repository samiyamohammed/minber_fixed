import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_compass_v2/flutter_compass_v2.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import '../core/app_colors.dart';
import '../services/compass_heading_service.dart';

class QiblaCompassPage extends StatefulWidget {
  const QiblaCompassPage({super.key});

  @override
  State<QiblaCompassPage> createState() => _QiblaCompassPageState();
}

class _QiblaCompassPageState extends State<QiblaCompassPage> {
  int _selectedIndex = 2;
  String? _locationName;
  Stream<double>? _headingStream;

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;
    setState(() => _selectedIndex = index);

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/home');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/media');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/prayer');
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/chatbot');
        break;
      case 4:
        Navigator.pushReplacementNamed(context, '/subapps');
        break;
    }
  }

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
    _headingStream = CompassHeadingService.headingStream;
    if (kIsWeb) {
      CompassHeadingService.ensureStarted();
    }
  }

  @override
  void dispose() {
    if (kIsWeb) {
      CompassHeadingService.stop();
    }
    super.dispose();
  }

  Future<void> _checkLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      await Geolocator.requestPermission();
    }

    final pos = await Geolocator.getCurrentPosition();

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        pos.latitude,
        pos.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        setState(() {
          _locationName = "${place.locality}, ${place.country}";
        });
      } else {
        setState(() {
          _locationName =
              "Lat: ${pos.latitude.toStringAsFixed(3)}, Lng: ${pos.longitude.toStringAsFixed(3)}";
        });
      }
    } catch (e) {
      setState(() {
        _locationName =
            "Lat: ${pos.latitude.toStringAsFixed(3)}, Lng: ${pos.longitude.toStringAsFixed(3)}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text("Compass", style: theme.textTheme.titleLarge),
        backgroundColor: theme.appBarTheme.backgroundColor ?? theme.cardColor,
        foregroundColor:
            theme.appBarTheme.foregroundColor ?? theme.colorScheme.onSurface,
        elevation: 1,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(30),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              _locationName ?? "Fetching location...",
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
                color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
              ),
            ),
          ),
        ),
      ),
      body: Listener(
        onPointerDown: (_) => CompassHeadingService.ensureStarted(),
        child: StreamBuilder<double>(
          stream: _headingStream,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              return Center(
                child: Text(
                  "Your device does not support Compass",
                  style: theme.textTheme.bodyMedium,
                ),
              );
            }

            double direction = snapshot.data!;

            return Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: size.width * 0.8,
                    height: size.width * 0.8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          theme.cardColor,
                          theme.dividerColor.withOpacity(0.3),
                        ],
                        center: Alignment.center,
                        radius: 0.9,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: theme.shadowColor.withOpacity(0.2),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: CustomPaint(painter: _CompassPainter(theme: theme)),
                  ),
                  Transform.rotate(
                    angle: (-direction) * (math.pi / 180),
                    child: Container(
                      width: size.width * 0.7,
                      height: size.width * 0.7,
                      alignment: Alignment.topCenter,
                      child: Icon(
                        Icons.navigation,
                        size: size.width * 0.35,
                        color: theme.colorScheme.primary,
                        shadows: [
                          Shadow(
                            blurRadius: 12,
                            color: theme.colorScheme.primary.withOpacity(0.6),
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    width: size.width * 0.1,
                    height: size.width * 0.1,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.primaryBlue,
                          theme.colorScheme.primary.withOpacity(0.8),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withOpacity(0.5),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: AppColors.primaryBlue,
        unselectedItemColor: theme.unselectedWidgetColor,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.tv), label: "Media"),
          BottomNavigationBarItem(icon: Icon(Icons.mosque), label: "Prayer"),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble),
            label: "Chat Bot",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.apps), label: "Sub Apps"),
        ],
      ),
    );
  }
}

class _CompassPainter extends CustomPainter {
  final ThemeData theme;
  _CompassPainter({required this.theme});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final tickPaint = Paint()
      ..color = theme.dividerColor
      ..strokeWidth = 2;

    final boldPaint = Paint()
      ..color = theme.colorScheme.onSurface
      ..strokeWidth = 3;

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (int i = 0; i < 360; i += 15) {
      final angle = i * math.pi / 180;
      final isBold = i % 90 == 0;
      final startRadius = isBold ? radius - 20 : radius - 10;
      final paint = isBold ? boldPaint : tickPaint;

      final p1 = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      final p2 = Offset(
        center.dx + startRadius * math.cos(angle),
        center.dy + startRadius * math.sin(angle),
      );
      canvas.drawLine(p1, p2, paint);

      if (isBold) {
        String label = '';
        if (i == 0) label = 'E';
        if (i == 90) label = 'S';
        if (i == 180) label = 'W';
        if (i == 270) label = 'N';

        textPainter.text = TextSpan(
          text: label,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        );
        textPainter.layout();
        final offset = Offset(
          center.dx + (radius - 35) * math.cos(angle) - textPainter.width / 2,
          center.dy + (radius - 35) * math.sin(angle) - textPainter.height / 2,
        );
        textPainter.paint(canvas, offset);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
