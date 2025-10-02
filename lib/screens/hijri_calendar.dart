import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';
import '../core/app_colors.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class HijriCalendarPage extends StatefulWidget {
  const HijriCalendarPage({super.key});

  @override
  State<HijriCalendarPage> createState() => _HijriCalendarPageState();
}

class _HijriCalendarPageState extends State<HijriCalendarPage> {
  static const int _initialPage = 12000;
  late final PageController _pageController;
  int _currentPage = _initialPage;
  int _selectedIndex = 2;

  String _locationName = "Fetching location...";

  static const _gregorianMonths = <String>[
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  static const _hijriMonths = <String>[
    'Muharram',
    'Safar',
    'Rabiʿ al-awwal',
    'Rabiʿ al-thani',
    'Jumada al-ula',
    'Jumada al-akhirah',
    'Rajab',
    'Shaʿban',
    'Ramadan',
    'Shawwal',
    'Dhu al-Qiʿdah',
    'Dhu al-Hijjah',
  ];

  final Map<String, String> _holidays = {
    "1-9": "Start of Ramadan",
    "27-9": "Laylat al-Qadr",
    "1-10": "Eid al-Fitr",
    "10-12": "Eid al-Adha",
  };

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _initialPage);
    _checkLocationPermissionAndFetchLocation();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  HijriCalendar _shiftedMonth(int shift) {
    final today = HijriCalendar.now();
    int newMonth = today.hMonth + shift;
    int newYear = today.hYear;

    while (newMonth > 12) {
      newMonth -= 12;
      newYear += 1;
    }
    while (newMonth < 1) {
      newMonth += 12;
      newYear -= 1;
    }

    return HijriCalendar()
      ..hYear = newYear
      ..hMonth = newMonth
      ..hDay = 1;
  }

  int _leadingEmptyCells(HijriCalendar h) {
    final firstGregorian = HijriCalendar().hijriToGregorian(
      h.hYear,
      h.hMonth,
      1,
    );
    return firstGregorian.weekday % 7;
  }

  Future<void> _checkLocationPermissionAndFetchLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _locationName = "Location services disabled");
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      setState(() => _locationName = "Location permission denied");
      return;
    }

    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final placemarks = await placemarkFromCoordinates(
        pos.latitude,
        pos.longitude,
      );

      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final locality =
            p.locality ?? p.subAdministrativeArea ?? p.administrativeArea;
        final country = p.country ?? '';
        setState(() {
          _locationName = (locality != null && country.isNotEmpty)
              ? "$locality, $country"
              : "Lat: ${pos.latitude.toStringAsFixed(3)}, Lng: ${pos.longitude.toStringAsFixed(3)}";
        });
      }
    } catch (e) {
      setState(() => _locationName = "Location unavailable");
    }
  }

  String _getGregorianDateForDisplay(HijriCalendar hijriMonth) {
    final now = DateTime.now();
    final monthStart = HijriCalendar().hijriToGregorian(
      hijriMonth.hYear,
      hijriMonth.hMonth,
      1,
    );

    if (hijriMonth.hYear == HijriCalendar.now().hYear &&
        hijriMonth.hMonth == HijriCalendar.now().hMonth) {
      return "${_gregorianMonths[now.month - 1]} ${now.year} AD";
    }
    return "${_gregorianMonths[monthStart.month - 1]} ${monthStart.year} AD";
  }

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
        Navigator.pushReplacementNamed(context, '/Chat Bot');
        break;
      case 4:
        Navigator.pushReplacementNamed(context, '/subapps');
        break;
    }
  }

  void _showDayDetails(BuildContext context, int hYear, int hMonth, int hDay) {
    final g = HijriCalendar().hijriToGregorian(hYear, hMonth, hDay);
    final holiday = _holidays["$hDay-$hMonth"];
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          "Hijri $hDay ${_hijriMonths[hMonth - 1]} $hYear AH",
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Gregorian: ${_gregorianMonths[g.month - 1]} ${g.day}, ${g.year}",
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            if (holiday != null)
              Row(
                children: [
                  Icon(Icons.star, color: theme.colorScheme.secondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      holiday,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              )
            else
              Text(
                "No holiday for this day",
                style: theme.textTheme.bodyMedium,
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.primary,
            ),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final theme = Theme.of(context);
    final today = HijriCalendar.now();
    final currentShift = _currentPage - _initialPage;
    final currentMonth = _shiftedMonth(currentShift);

    // Colors used for holiday and today: prefer theme; fallback to AppColors / color literals only when no theme equivalent
    final holidayColor = theme.colorScheme.secondary;
    final todayTileColor = AppColors
        .primary; // keep primary accent (you may map this to theme if desired)
    final todayTextColor = theme.colorScheme.onPrimary;
    final defaultTileTextColor =
        theme.textTheme.bodyLarge?.color ?? Colors.black;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor ?? theme.cardColor,
        foregroundColor:
            theme.appBarTheme.foregroundColor ??
            // theme.titleLarge?.color ??
            theme.colorScheme.onPrimary,
        elevation: 1,
        title: Column(
          children: [
            Text(
              "Hijri Calendar",
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _locationName,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withOpacity(0.8),
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_none, color: theme.iconTheme.color),
            onPressed: () => Navigator.pushNamed(context, "/notifications"),
          ),
          Padding(
            padding: EdgeInsets.only(right: size.width * 0.03),
            child: InkWell(
              onTap: () => Navigator.pushNamed(context, "/profile"),
              borderRadius: BorderRadius.circular(50),
              child: CircleAvatar(
                radius: size.width * 0.05,
                backgroundImage: const AssetImage("assets/images/profile.jpg"),
                backgroundColor: theme.cardColor,
              ),
            ),
          ),
        ],
      ),

      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: size.height * 0.02),

            // Month Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.chevron_left,
                      color: theme.iconTheme.color,
                    ),
                    onPressed: () => _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          "${_hijriMonths[currentMonth.hMonth - 1]} ${currentMonth.hYear} AH",
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: size.width * 0.05,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _getGregorianDateForDisplay(currentMonth),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.textTheme.bodySmall?.color
                                ?.withOpacity(0.8),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.chevron_right,
                      color: theme.iconTheme.color,
                    ),
                    onPressed: () => _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: size.height * 0.02),

            // Weekday Headers
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  for (final day in [
                    'Sun',
                    'Mon',
                    'Tue',
                    'Wed',
                    'Thu',
                    'Fri',
                    'Sat',
                  ])
                    Expanded(
                      child: Center(
                        child: Text(
                          day,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            SizedBox(height: size.height * 0.01),

            // Calendar Grid
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (page) => setState(() => _currentPage = page),
                itemBuilder: (context, pageIndex) {
                  final shift = pageIndex - _initialPage;
                  final month = _shiftedMonth(shift);

                  final tmp = HijriCalendar()
                    ..hYear = month.hYear
                    ..hMonth = month.hMonth
                    ..hDay = 1;
                  final days = tmp.getDaysInMonth(tmp.hYear, tmp.hMonth);

                  final leading = _leadingEmptyCells(month);
                  final totalCells = leading + days;
                  final trailing = (7 - (totalCells % 7)) % 7;
                  final itemCount = totalCells + trailing;

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 7,
                            childAspectRatio: 1.2,
                            mainAxisSpacing: 6,
                            crossAxisSpacing: 6,
                          ),
                      itemCount: itemCount,
                      itemBuilder: (ctx, idx) {
                        if (idx < leading || idx >= leading + days) {
                          return const SizedBox.shrink();
                        }

                        final hDay = idx - leading + 1;
                        final isToday =
                            (hDay == today.hDay &&
                            month.hMonth == today.hMonth &&
                            month.hYear == today.hYear);
                        final holidayName = _holidays["$hDay-${month.hMonth}"];

                        // Tile colors
                        final tileColor = isToday
                            ? todayTileColor
                            : (holidayName != null
                                  ? holidayColor
                                  : theme.cardColor);
                        final borderColor = theme.dividerColor;
                        final textColor = isToday
                            ? todayTextColor
                            : (holidayName != null
                                  ? theme.colorScheme.onSecondary
                                  : (theme.textTheme.bodyLarge?.color ??
                                        Colors.black));

                        return GestureDetector(
                          onTap: () => _showDayDetails(
                            context,
                            month.hYear,
                            month.hMonth,
                            hDay,
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              color: tileColor,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: borderColor),
                              boxShadow: isToday
                                  ? [
                                      BoxShadow(
                                        color: todayTileColor.withOpacity(0.15),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : [
                                      BoxShadow(
                                        color: theme.shadowColor.withOpacity(
                                          0.02,
                                        ),
                                        blurRadius: 2,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "$hDay",
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      color: textColor,
                                      fontWeight: isToday
                                          ? FontWeight.bold
                                          : FontWeight.w600,
                                    ),
                                  ),
                                  if (holidayName != null)
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                          top: 4,
                                          left: 4,
                                          right: 4,
                                        ),
                                        child: Text(
                                          holidayName,
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: theme
                                                    .colorScheme
                                                    .onSecondary
                                                    .withOpacity(0.95),
                                                fontSize: 10,
                                              ),
                                          textAlign: TextAlign.center,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),

            // Legend
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: todayTileColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Today",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: holidayColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Holiday",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: theme.unselectedWidgetColor,
        type: BottomNavigationBarType.fixed,
        // backgroundColor: theme.bottomAppBarColor,
        selectedFontSize: size.width * 0.03,
        unselectedFontSize: size.width * 0.03,
        iconSize: size.width * 0.06,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home, size: size.width * 0.06),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.tv, size: size.width * 0.06),
            label: "Media",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.mosque, size: size.width * 0.06),
            label: "Prayer",
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble),
            label: "Chat Bot",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore, size: size.width * 0.06),
            label: "Sub Apps",
          ),
        ],
      ),
    );
  }
}
