// lib/providers/prayer_provider.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:adhan_dart/adhan_dart.dart';

class PrayerProvider with ChangeNotifier {
  bool _isLoading = true;
  String _city = "Loading...";
  String _country = "";
  Map<String, DateTime> _prayerTimesDateTimes = {};
  String _nextPrayer = "Loading...";
  String _nextPrayerCountdown = "--:--:--";
  Timer? _timer;

  // Public getters to access the data
  bool get isLoading => _isLoading;
  String get city => _city;
  String get country => _country;
  Map<String, DateTime> get prayerTimes => _prayerTimesDateTimes;
  String get nextPrayer => _nextPrayer;
  String get nextPrayerCountdown => _nextPrayerCountdown;

  PrayerProvider() {
    initialize();
  }

  // A single public method to initialize everything
  Future<void> initialize() async {
    // This guard prevents re-fetching if data is already available
    if (!_isLoading || _prayerTimesDateTimes.isNotEmpty) return;

    await _getLocationAndCalculateTimes();

    _isLoading = false;
    // Notify the UI that loading is complete and data is ready
    notifyListeners();

    // Start the countdown timer only after data is available
    _timer?.cancel(); // Cancel any existing timer
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_prayerTimesDateTimes.isNotEmpty) _updateCountdown();
    });
  }

  Future<void> _getLocationAndCalculateTimes() async {
    try {
      // --- Location Permissions (Good Practice) ---
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _city = "Permission Denied";
          _country = "";
          notifyListeners();
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      _calculatePrayerTimes(position.latitude, position.longitude);

      List<Placemark> placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        _city = placemarks.first.locality ?? "Unknown City";
        _country = placemarks.first.country ?? "";
      }
    } catch (e) {
      _city = "Location Unavailable";
      _country = "";
    }
    // No need to call notifyListeners() here, it's handled in initialize()
  }

  void _calculatePrayerTimes(double lat, double lng) {
    final prayerTimesData = PrayerTimes(
        coordinates: Coordinates(lat, lng),
        date: DateTime.now(),
        calculationParameters: CalculationMethod.muslimWorldLeague()
          ..madhab = Madhab.shafi);

    _prayerTimesDateTimes = {
      "Fajr": prayerTimesData.fajr!.toLocal(),
      "Sunrise": prayerTimesData.sunrise!.toLocal(),
      "Dhuhr": prayerTimesData.dhuhr!.toLocal(),
      "Asr": prayerTimesData.asr!.toLocal(),
      "Maghrib": prayerTimesData.maghrib!.toLocal(),
      "Isha": prayerTimesData.isha!.toLocal(),
    };
    _updateNextPrayerAndCountdown();
  }

  void _updateNextPrayerAndCountdown() {
    final now = DateTime.now();
    String nextPrayer = "Fajr (Tomorrow)";
    for (var entry in _prayerTimesDateTimes.entries) {
      if (now.isBefore(entry.value)) {
        nextPrayer = entry.key;
        break;
      }
    }
    _nextPrayer = nextPrayer;
    _updateCountdown(); // Initial countdown update
  }

  void _updateCountdown() {
    if (_prayerTimesDateTimes.isEmpty) return;

    final now = DateTime.now();
    DateTime? targetTime;

    if (_nextPrayer.contains('Tomorrow')) {
      targetTime = _prayerTimesDateTimes['Fajr']?.add(const Duration(days: 1));
    } else {
      targetTime = _prayerTimesDateTimes[_nextPrayer];
    }

    if (targetTime == null) return;

    if (now.isAfter(targetTime)) {
      // Time has passed, find the next prayer
      _updateNextPrayerAndCountdown();
      return;
    }

    final duration = targetTime.difference(now);
    _nextPrayerCountdown =
        "${duration.inHours.remainder(24).toString().padLeft(2, '0')}:${duration.inMinutes.remainder(60).toString().padLeft(2, '0')}:${duration.inSeconds.remainder(60).toString().padLeft(2, '0')}";

    // Notify listeners to update the countdown text
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
