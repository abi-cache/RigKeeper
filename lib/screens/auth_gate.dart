import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';
import 'auth/login_screen.dart';
import 'home_screen.dart';

/// Decides which screen to show based on whether someone is logged in.
///
/// This uses a StreamBuilder, which is Flutter's way of saying "rebuild
/// this widget every time new data arrives on this stream." Supabase
/// gives us a stream of auth events (signed in, signed out, token
/// refreshed, etc) — every time one happens, this widget re-checks
/// and swaps between LoginScreen and HomeScreen automatically.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: supabase.auth.onAuthStateChange,
      builder: (context, snapshot) {
        // Still checking on first load — show a simple spinner instead
        // of a blank screen.
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final session = supabase.auth.currentSession;

        if (session != null) {
          return const HomeScreen();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}