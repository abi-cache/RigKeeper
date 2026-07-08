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
  final String? imageUrl;
  final int componentCount;
  final int healthScore; // 0-100
  final int lastCleanedDaysAgo;
  final int nextCleaningInDays;
  final double averageComponentAgeYears;

  const VirtualPc({
    this.id,
    required this.name,
    required this.icon,
    this.imageUrl,
    required this.componentCount,
    required this.healthScore,
    required this.lastCleanedDaysAgo,
    required this.nextCleaningInDays,
    this.averageComponentAgeYears = 0,
  });

  /// Builds a VirtualPc from a row returned by Supabase.
  /// Stats fields (componentCount, healthScore, etc) are passed in
  /// separately, since they require querying OTHER tables
  /// (components, maintenance_logs) — this factory just handles the
  /// pcs row itself.
  factory VirtualPc.fromMap(
    Map<String, dynamic> map, {
    int componentCount = 0,
    int healthScore = 100,
    int lastCleanedDaysAgo = 0,
    int nextCleaningInDays = 30,
    double averageComponentAgeYears = 0,
  }) {
    return VirtualPc(
      id: map['id'] as String,
      name: map['name'] as String,
      icon: Icons.desktop_windows_outlined,
      imageUrl: map['image_url'] as String?,
      componentCount: componentCount,
      healthScore: healthScore,
      lastCleanedDaysAgo: lastCleanedDaysAgo,
      nextCleaningInDays: nextCleaningInDays,
      averageComponentAgeYears: averageComponentAgeYears,
    );
  }

  CleaningUrgency get urgency {
    if (nextCleaningInDays <= 7) return CleaningUrgency.overdueSoon;
    if (nextCleaningInDays <= 20) return CleaningUrgency.dueSoon;
    return CleaningUrgency.healthy;
  }
}

enum CleaningUrgency { healthy, dueSoon, overdueSoon }