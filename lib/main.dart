import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const PrayerTrackerApp());
}

class PrayerTrackerApp extends StatelessWidget {
  const PrayerTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hisab',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.teal),
      home: const HomeScreen(),
    );
  }
}
