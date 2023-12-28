import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

void main() {
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]).then((_) {
    runApp(const GitHubContributionsApp());
  });
}

class GitHubContributionsApp extends StatelessWidget {
  const GitHubContributionsApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      home: const ContributionsCalendar(),
    );
  }
}

class ContributionsCalendar extends StatefulWidget {
  const ContributionsCalendar({Key? key}) : super(key: key);

  @override
  _ContributionsCalendarState createState() => _ContributionsCalendarState();
}

class _ContributionsCalendarState extends State<ContributionsCalendar> {
  late Map<DateTime, bool> contributions = {};
  final CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _loadContributions();
  }

  Future<void> _loadContributions() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? savedData = prefs.getString('contributions');

    if (savedData != null && savedData.isNotEmpty) {
      final Map<String, dynamic> parsedData = jsonDecode(savedData);
      setState(() {
        contributions = parsedData.map(
          (key, value) => MapEntry(DateTime.parse(key), value as bool),
        );
      });
    } else {
      setState(() {
        contributions = {};
      });
    }
  }

  Future<void> _saveContributions() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String encodedContributions =
        jsonEncode(Map<String, dynamic>.fromEntries(
      contributions.entries.map((e) => MapEntry(e.key.toString(), e.value)),
    ));
    await prefs.setString('contributions', encodedContributions);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Consistency Checker')),
      body: WillPopScope(
        onWillPop: () async {
          final shouldPop = await showDialog<bool>(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: const Text('Do you want to exit the app?'),
                actionsAlignment: MainAxisAlignment.spaceBetween,
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context, true);
                    },
                    child: const Text('Yes'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context, false);
                    },
                    child: const Text('No'),
                  ),
                ],
              );
            },
          );
          return shouldPop!;
        },
        child: Column(
          children: [
            TableCalendar(
              calendarFormat: _calendarFormat,
              focusedDay: _focusedDay,
              firstDay: DateTime(2023),
              lastDay: DateTime(2025),
              startingDayOfWeek: StartingDayOfWeek.sunday,
              daysOfWeekVisible: true,
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
              ),
              calendarStyle: const CalendarStyle(
                selectedDecoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blue,
                ),
                todayDecoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.orange,
                ),
                markersMaxCount: 1,
                // markersPositionBottom: 0,

                markerDecoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.green,
                ),
              ),
              selectedDayPredicate: (day) {
                return isSameDay(_selectedDay, day);
              },
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                });
              },
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
              },
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, day, events) {
                  final bool isDone = contributions[day] ?? false;
                  return Container(
                    decoration: isDone
                        ? BoxDecoration(
                            border: Border.all(
                              color: Colors.green,
                              width: 2, // Adjust border width as needed
                            ),
                            borderRadius: BorderRadius.circular(
                                10), // Adjust border radius as needed
                          )
                        : null,
                    child: const Center(
                      child: Text(
                        '', // Display the date
                        style: TextStyle(
                          fontSize: 16, // Adjust font size as needed
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  if (_selectedDay != null) {
                    contributions[_selectedDay!] =
                        !(contributions[_selectedDay!] ?? false);
                    _saveContributions(); // Save the contributions to SharedPreferences
                  }
                });
              },
              child: const Text('Toggle Day'),
            ),
          ],
        ),
      ),
    );
  }
}

// Future<bool> _onWillPop() async {
//   // Handle the back button press event here
//   // For instance, you can show an alert dialog to confirm exit or handle custom logic
//   return true; // Return true to allow back navigation, false to prevent it
// }
