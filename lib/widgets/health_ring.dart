import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// The app's signature visual element: a small circular gauge that
/// replaces a flat number with an actual at-a-glance indicator.
///
/// Color follows the same thermal scale used everywhere else in the
/// app: teal (healthy) → amber (attention) → coral (critical) — so
/// this ring means the same thing wherever it appears.
class HealthRing extends StatelessWidget {
  final int score; // 0-100
  final double size;

  const HealthRing({super.key, required this.score, this.size = 52});

  Color _colorFor(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (score >= 70) return scheme.primary;
    if (score >= 40) return scheme.tertiary;
    return scheme.error;
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(context);
    final progress = (score.clamp(0, 100)) / 100;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 5,
              backgroundColor:
                  Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.4),
              valueColor: AlwaysStoppedAnimation(color),
              strokeCap: StrokeCap.round,
            ),
          ),
          Text(
            '$score',
            style: AppTheme.dataStyle.copyWith(
              fontSize: size * 0.27,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}