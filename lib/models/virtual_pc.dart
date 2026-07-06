import 'package:flutter/material.dart';

/// Represents one "virtual PC" the user has built in the app.
///
/// This is just data — a plain Dart class with no UI code inside it.
/// Later, this will come from your database/API instead of being
/// typed in by hand. Keeping it separate from the widgets now means
/// swapping in real data later won't touch any UI code.
class VirtualPc {
  final String name;
  final IconData icon;
  final int componentCount;
  final int healthScore; // 0-100
  final int lastCleanedDaysAgo;
  final int nextCleaningInDays;

  const VirtualPc({
    required this.name,
    required this.icon,
    required this.componentCount,
    required this.healthScore,
    required this.lastCleanedDaysAgo,
    required this.nextCleaningInDays,
  });

  /// Which color/label the "clean in Xd" badge should use.
  /// This is placeholder logic — a simple threshold on days remaining.
  /// Later, this same value will come from your prediction engine
  /// (Milestone: Smart Maintenance Prediction), not a fixed rule.
  CleaningUrgency get urgency {
    if (nextCleaningInDays <= 7) return CleaningUrgency.overdueSoon;
    if (nextCleaningInDays <= 20) return CleaningUrgency.dueSoon;
    return CleaningUrgency.healthy;
  }
}

enum CleaningUrgency { healthy, dueSoon, overdueSoon }

/// Temporary mock data so we can see the Home screen before the
/// database/API exists. Replace this with a real data source once
/// Milestone 2 (Virtual PC Builder + backend) is built.
const List<VirtualPc> mockPcs = [
  VirtualPc(
    name: 'Gaming rig',
    icon: Icons.desktop_windows_outlined,
    componentCount: 6,
    healthScore: 82,
    lastCleanedDaysAgo: 47,
    nextCleaningInDays: 13,
  ),
  VirtualPc(
    name: 'Work laptop',
    icon: Icons.laptop_mac_outlined,
    componentCount: 4,
    healthScore: 91,
    lastCleanedDaysAgo: 20,
    nextCleaningInDays: 41,
  ),
];