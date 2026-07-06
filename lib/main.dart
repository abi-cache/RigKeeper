import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const PcMaintenanceApp());
}

/// Root widget. This is where global theme/config lives — every
/// screen in the app sits underneath this one widget.
class PcMaintenanceApp extends StatelessWidget {
  const PcMaintenanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PC Maintenance Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}