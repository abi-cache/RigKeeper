import 'package:flutter/material.dart';

/// Represents one "virtual PC" the user has built in the app.
///
/// [id] is null for PCs that only exist locally (not used anymore,
/// kept nullable for safety). Everything else after [name] is still
/// placeholder data — health score, last cleaned, next cleaning —
/// until the Components + Maintenance Log milestones are built.
class VirtualPc {
  final String? id;
  final String name;
  final IconData icon;
  final int componentCount;
  final int healthScore; // 0-100
  final int lastCleanedDaysAgo;
  final int nextCleaningInDays;

  const VirtualPc({
    this.id,
    required this.name,
    required this.icon,
    required this.componentCount,
    required this.healthScore,
    required this.lastCleanedDaysAgo,
    required this.nextCleaningInDays,
  });

  /// Builds a VirtualPc from a row returned by Supabase.
  /// The stats fields are hardcoded placeholders for now — they'll
  /// come from real queries once the Components/Maintenance Log
  /// tables exist.
  factory VirtualPc.fromMap(Map<String, dynamic> map) {
    return VirtualPc(
      id: map['id'] as String,
      name: map['name'] as String,
      icon: Icons.desktop_windows_outlined,
      componentCount: 0,
      healthScore: 100,
      lastCleanedDaysAgo: 0,
      nextCleaningInDays: 30,
    );
  }

  CleaningUrgency get urgency {
    if (nextCleaningInDays <= 7) return CleaningUrgency.overdueSoon;
    if (nextCleaningInDays <= 20) return CleaningUrgency.dueSoon;
    return CleaningUrgency.healthy;
  }
}

enum CleaningUrgency { healthy, dueSoon, overdueSoon }