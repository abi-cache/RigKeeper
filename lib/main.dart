import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://foanvgcmdlnvntmtrrnk.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZvYW52Z2NtZGxudm50bXRycm5rIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODMzNTI0MDksImV4cCI6MjA5ODkyODQwOX0.jhRRWzmmT4qpYnRlJMvYlzAlI3yBPYjW8KzfofGkdq4',
  );

  runApp(const PcMaintenanceApp());
}

final supabase = Supabase.instance.client;

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
      home: const AuthGate(),
    );
  }
}