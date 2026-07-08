import 'package:flutter/material.dart';
import '../models/virtual_pc.dart';
import '../theme/app_theme.dart';
import 'health_ring.dart';

/// Displays a single PC as a tappable card.
///
/// This widget doesn't know or care where the data came from — it just
/// takes a [VirtualPc] and draws it. That's what makes it reusable:
/// the same card works whether the PC came from mock data (now) or
/// a real API call (later).
class PcCard extends StatelessWidget {
  final VirtualPc pc;
  final VoidCallback onTap;

  const PcCard({super.key, required this.pc, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => _showScoreExplanation(context, pc),
              child: HealthRing(score: pc.healthScore),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(pc.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w500, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(
                    '${pc.componentCount} components',
                    style: AppTheme.dataStyle.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            _CleaningBadge(pc: pc),
          ],
        ),
      ),
    );
  }

  void _showScoreExplanation(BuildContext context, VirtualPc pc) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('How this score is calculated'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
                'This is a simple, transparent rule-based score — '
                'not a black box. It starts at 100 and subtracts points for:'),
            const SizedBox(height: 12),
            Text('• Cleaning recency: last cleaned ${pc.lastCleanedDaysAgo} days ago'
                '${pc.lastCleanedDaysAgo > 60 ? ' (overdue, points deducted)' : ' (on track)'}'),
            const SizedBox(height: 6),
            Text('• Component age: averaging ${pc.averageComponentAgeYears.toStringAsFixed(1)} '
                'years old${pc.averageComponentAgeYears > 3 ? ' (points deducted for aging parts)' : ' (relatively new)'}'),
            const SizedBox(height: 12),
            Text('Final score: ${pc.healthScore} / 100',
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Got it')),
        ],
      ),
    );
  }
}

/// "Clean in Xd" pill — color follows the same thermal scale as
/// everything else in the app (see AppTheme): primary/teal when
/// healthy, tertiary/amber approaching, error/coral overdue. Never a
/// raw Colors.orange/red — that consistency is what makes the color
/// language legible across the whole app.
class _CleaningBadge extends StatelessWidget {
  final VirtualPc pc;
  const _CleaningBadge({required this.pc});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    late Color fg;
    switch (pc.urgency) {
      case CleaningUrgency.healthy:
        fg = scheme.primary;
        break;
      case CleaningUrgency.dueSoon:
        fg = scheme.tertiary;
        break;
      case CleaningUrgency.overdueSoon:
        fg = scheme.error;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: fg.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '${pc.nextCleaningInDays}d',
        style: AppTheme.dataStyle.copyWith(fontSize: 12, color: fg),
      ),
    );
  }
}