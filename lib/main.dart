import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/auth_gate.dart';

Future<void> main() async {
  // Flutter needs this when doing async work (like connecting to
  // Supabase) before runApp() is called.
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://foanvgcmdlnvntmtrrnk.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZvYW52Z2NtZGxudm50bXRycm5rIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODMzNTI0MDksImV4cCI6MjA5ODkyODQwOX0.jhRRWzmmT4qpYnRlJMvYlzAlI3yBPYjW8KzfofGkdq4',
  );

  runApp(const PcMaintenanceApp());
}

/// Convenience accessor used throughout the app instead of typing
/// Supabase.instance.client everywhere.
final supabase = Supabase.instance.client;

/// Holds the current theme mode (light/dark/system) so any screen
/// can change it and have the whole app react immediately.
///
/// This is a lightweight alternative to a full state management
/// package (like Provider or Riverpod) — reasonable for a single
/// piece of app-wide state like this. If the app grows more shared
/// state beyond just theme, that's the point where adopting a real
/// state management package becomes worth the added complexity.
final ValueNotifier<ThemeMode> themeModeNotifier =
    ValueNotifier(ThemeMode.system);

/// Root widget. This is where global theme/config lives — every
/// screen in the app sits underneath this one widget.
class PcMaintenanceApp extends StatelessWidget {
  const PcMaintenanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'PC Maintenance Tracker',
          debugShowCheckedModeBanner: false,
          themeMode: mode,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
          ),
          // AuthGate decides whether to show Login or Home, instead of
          // going straight to HomeScreen like before.
          home: const AuthGate(),
        );
      },
    );
  }
}