// lib/screens/hijri_calendar.dart (Fully Corrected & With Note Feature)

import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart'; // NEW: Import shared_preferences

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

  // NEW: State variable to hold the notes
  final Map<String, String> _notes = {};

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
    'December'
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
    'Dhu al-Hijjah'
  ];
  final Map<String, String> _holidays = {
    "1-9": "Start of Ramadan",
    "27-9": "Laylat al-Qadr",
    "1-10": "Eid al-Fitr",
    "10-12": "Eid al-Adha"
  };

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _initialPage);
    _checkLocationPermissionAndFetchLocation();
    _loadNotes(); // NEW: Load notes when the widget initializes
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // NEW: Function to generate a unique key for a given date
  String _getNoteKey(int hYear, int hMonth, int hDay) {
    return "note_${hYear}_${hMonth}_$hDay";
  }

  // NEW: Function to load notes from SharedPreferences
  Future<void> _loadNotes() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      final keys = prefs.getKeys();
      for (String key in keys) {
        if (key.startsWith('note_')) {
          _notes[key] = prefs.getString(key) ?? '';
        }
      }
    });
  }

  // NEW: Function to save or delete a note
  Future<void> _saveNote(int hYear, int hMonth, int hDay, String text) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getNoteKey(hYear, hMonth, hDay);

    if (text.isEmpty) {
      // If the note is empty, remove it
      await prefs.remove(key);
      setState(() {
        _notes.remove(key);
      });
    } else {
      // Otherwise, save the note
      await prefs.setString(key, text);
      setState(() {
        _notes[key] = text;
      });
    }
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
    return HijriCalendar().hijriToGregorian(h.hYear, h.hMonth, 1).weekday % 7;
  }

  Future<void> _checkLocationPermissionAndFetchLocation() async {
    try {
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
      final pos = await Geolocator.getCurrentPosition();
      final placemarks =
          await placemarkFromCoordinates(pos.latitude, pos.longitude);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        setState(() => _locationName =
            "${p.locality ?? p.administrativeArea}, ${p.country}");
      }
    } catch (e) {
      setState(() => _locationName = "Location unavailable");
    }
  }

  String _getGregorianDateForDisplay(HijriCalendar hijriMonth) {
    final monthStart = HijriCalendar()
        .hijriToGregorian(hijriMonth.hYear, hijriMonth.hMonth, 1);
    final daysInMonth =
        hijriMonth.getDaysInMonth(hijriMonth.hYear, hijriMonth.hMonth);
    final monthEnd = HijriCalendar()
        .hijriToGregorian(hijriMonth.hYear, hijriMonth.hMonth, daysInMonth);

    if (monthStart.year == monthEnd.year) {
      return "${_gregorianMonths[monthStart.month - 1]} ${monthStart.year} AD";
    }
    return "${_gregorianMonths[monthStart.month - 1]} ${monthStart.year} - ${_gregorianMonths[monthEnd.month - 1]} ${monthEnd.year} AD";
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
        break;
      case 3:
        routeName = '/chatbot';
        break;
      case 4:
        routeName = '/subapps';
        break;
    }
    if (routeName.isNotEmpty) {
      Navigator.pushReplacementNamed(context, routeName);
    }
  }

// MODIFIED: This entire function is updated to include note editing.
  void _showDayDetails(BuildContext context, int hYear, int hMonth, int hDay) {
    final g = HijriCalendar().hijriToGregorian(hYear, hMonth, hDay);
    final holiday = _holidays["$hDay-$hMonth"];
    final theme = Theme.of(context);

    // NEW: Controller for the note text field
    final noteKey = _getNoteKey(hYear, hMonth, hDay);
    final existingNote = _notes[noteKey] ?? '';
    final noteController = TextEditingController(text: existingNote);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        // THIS IS THE CORRECTED LINE:
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Date Details", style: theme.textTheme.titleLarge),
        content: SingleChildScrollView(
          // Added for better scrolling on small screens
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Hijri: $hDay ${_hijriMonths[hMonth - 1]} $hYear AH",
                  style: theme.textTheme.bodyLarge),
              const SizedBox(height: 8),
              Text(
                  "Gregorian: ${_gregorianMonths[g.month - 1]} ${g.day}, ${g.year}",
                  style: theme.textTheme.bodyLarge),
              if (holiday != null) ...[
                const Divider(height: 24),
                Row(
                  children: [
                    Icon(Icons.star_rounded,
                        color: theme.colorScheme.secondary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        holiday,
                        style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.secondary),
                      ),
                    ),
                  ],
                ),
              ],
              // NEW: Section for adding/editing a note
              const Divider(height: 24),
              Text("Note:", style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(
                  hintText: "Add a note for this day...",
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          // NEW: Save button to save the note
          ElevatedButton(
            onPressed: () {
              _saveNote(hYear, hMonth, hDay, noteController.text.trim());
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final today = HijriCalendar.now();
    final currentShift = _currentPage - _initialPage;
    final currentMonth = _shiftedMonth(currentShift);

    return Scaffold(
      appBar: AppBar(
        elevation: 1,
        title: Text("Hijri Calendar",
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded),
                    onPressed: () => _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          transitionBuilder: (child, animation) =>
                              FadeTransition(opacity: animation, child: child),
                          child: Text(
                            key: ValueKey<String>(
                                "${currentMonth.hMonth}-${currentMonth.hYear}"),
                            "${_hijriMonths[currentMonth.hMonth - 1]} ${currentMonth.hYear} AH",
                            style: textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _getGregorianDateForDisplay(currentMonth),
                          style: textTheme.bodyMedium
                              ?.copyWith(color: theme.hintColor),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded),
                    onPressed: () => _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  for (final day in ['S', 'M', 'T', 'W', 'T', 'F', 'S'])
                    Expanded(
                      child: Center(
                        child: Text(day,
                            style: textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.hintColor)),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (page) => setState(() => _currentPage = page),
                itemBuilder: (context, pageIndex) {
                  final month = _shiftedMonth(pageIndex - _initialPage);
                  final daysInMonth =
                      month.getDaysInMonth(month.hYear, month.hMonth);
                  final leadingEmptyDays = _leadingEmptyCells(month);

                  return GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(12),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                    ),
                    itemCount: daysInMonth + leadingEmptyDays,
                    itemBuilder: (ctx, idx) {
                      if (idx < leadingEmptyDays)
                        return const SizedBox.shrink();
                      final hDay = idx - leadingEmptyDays + 1;
                      final isToday = (hDay == today.hDay &&
                          month.hMonth == today.hMonth &&
                          month.hYear == today.hYear);
                      final isHoliday =
                          _holidays.containsKey("$hDay-${month.hMonth}");

                      // NEW: Check if the day has a note
                      final noteKey =
                          _getNoteKey(month.hYear, month.hMonth, hDay);
                      final hasNote = _notes.containsKey(noteKey) &&
                          _notes[noteKey]!.isNotEmpty;

                      // MODIFIED: Pass hasNote to the tile
                      return _CalendarDayTile(
                        day: hDay,
                        isToday: isToday,
                        isHoliday: isHoliday,
                        hasNote: hasNote, // Pass the new property
                        onTap: () => _showDayDetails(
                            context, month.hYear, month.hMonth, hDay),
                      );
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLegendItem(colorScheme.primary, "Today"),
                  const SizedBox(width: 16),
                  _buildLegendItem(colorScheme.secondary, "Holiday"),
                  const SizedBox(width: 16),
                  // NEW: Legend item for notes
                  _buildLegendItem(theme.hintColor, "Note"),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: colorScheme.primary,
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
              label: "Sub Apps"),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

// MODIFIED: The tile widget is updated to accept and display the note indicator.
class _CalendarDayTile extends StatelessWidget {
  final int day;
  final bool isToday;
  final bool isHoliday;
  final bool hasNote; // NEW: Property to indicate if a note exists
  final VoidCallback onTap;

  const _CalendarDayTile({
    required this.day,
    required this.isToday,
    required this.isHoliday,
    required this.hasNote, // NEW
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: isToday
            ? BoxDecoration(color: colorScheme.primary, shape: BoxShape.circle)
            : null,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "$day",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isToday
                      ? colorScheme.onPrimary
                      : colorScheme.onBackground,
                ),
              ),
              // MODIFIED: Display a dot for holidays or notes
              if (isHoliday || hasNote) ...[
                const SizedBox(height: 2),
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    // Logic to decide the dot color
                    color: isHoliday
                        ? (isToday
                            ? colorScheme.onPrimary
                            : colorScheme.secondary)
                        : theme.hintColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
