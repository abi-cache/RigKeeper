import 'package:flutter/material.dart';

/// The "Circuit & Thermal" design system — grounded in the app's
/// actual subject (PC hardware: circuit boards, cooling, heat)
/// rather than a generic Material blue default.
///
/// Color meaning is consistent everywhere in the app:
/// - Teal  = healthy / on track
/// - Amber = needs attention soon
/// - Coral = overdue / critical
/// Any screen showing a status (cleaning due, warranty, component
/// lifespan) should pull from these three, via [ColorScheme.primary],
/// [ColorScheme.tertiary], and [ColorScheme.error] respectively —
/// never a raw Colors.orange/red/green, so the meaning stays uniform
/// across the whole app.
class AppTheme {
  AppTheme._();

  static const _circuitTeal = Color(0xFF0F7173);
  static const _signalCyan = Color(0xFF4FD1C5);
  static const _thermalAmber = Color(0xFFE8A33D);
  static const _overheatCoral = Color(0xFFE8555B);
  static const _graphite = Color(0xFF1B1F22);
  static const _frost = Color(0xFFF4F7F7);

  /// Monospace style for "readout" data: health scores, day counts,
  /// dates, serial numbers. Deliberately distinct from the sans-serif
  /// UI text — no new font package needed, this uses the platform's
  /// built-in monospace fallback.
  static const TextStyle dataStyle = TextStyle(
    fontFamily: 'monospace',
    fontWeight: FontWeight.w600,
  );

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: _circuitTeal,
      brightness: Brightness.light,
      primary: _circuitTeal,
      secondary: _signalCyan,
      tertiary: _thermalAmber,
      error: _overheatCoral,
      surface: _frost,
    );
    return ThemeData(colorScheme: scheme, useMaterial3: true);
  }

  static ThemeData get dark {
    final scheme = ColorScheme.fromSeed(
      seedColor: _circuitTeal,
      brightness: Brightness.dark,
      // Signal Cyan pops better than the deeper Circuit Teal against
      // a dark background, so it takes the primary role here while
      // Circuit Teal moves to secondary — same palette, roles swapped
      // for contrast, not a different color story.
      primary: _signalCyan,
      secondary: _circuitTeal,
      tertiary: _thermalAmber,
      error: _overheatCoral,
      surface: _graphite,
    );
    return ThemeData(colorScheme: scheme, useMaterial3: true);
  }
}