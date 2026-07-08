import 'package:flutter/material.dart';
import '../models/virtual_pc.dart';

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: pc.imageUrl != null
                          ? Image.network(pc.imageUrl!, fit: BoxFit.cover)
                          : Icon(pc.icon,
                              size: 20,
                              color:
                                  Theme.of(context).colorScheme.onPrimaryContainer),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(pc.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w500, fontSize: 15)),
                        Text('${pc.componentCount} components',
                            style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant)),
                      ],
                    ),
                  ],
                ),
                _CleaningBadge(pc: pc),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _showScoreExplanation(context, pc),
                    child: _StatBox(
                        label: 'Health score  ⓘ', value: '${pc.healthScore}'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                    child: _StatBox(
                        label: 'Last cleaned', value: '${pc.lastCleanedDaysAgo}d ago')),
              ],
            ),
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

/// Small "Clean in Xd" pill. Color depends on [VirtualPc.urgency].
class _CleaningBadge extends StatelessWidget {
  final VirtualPc pc;
  const _CleaningBadge({required this.pc});

  @override
  Widget build(BuildContext context) {
    late Color bg;
    late Color fg;
    switch (pc.urgency) {
      case CleaningUrgency.healthy:
        bg = Colors.green.shade50;
        fg = Colors.green.shade800;
        break;
      case CleaningUrgency.dueSoon:
        bg = Colors.orange.shade50;
        fg = Colors.orange.shade800;
        break;
      case CleaningUrgency.overdueSoon:
        bg = Colors.red.shade50;
        fg = Colors.red.shade800;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(
        'Clean in ${pc.nextCleaningInDays}d',
        style: TextStyle(fontSize: 12, color: fg, fontWeight: FontWeight.w500),
      ),
    );
  }
}

/// Small stat tile used inside the card (health score, last cleaned, etc).
class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  const _StatBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 2),
          Text(value,
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface)),
        ],
      ),
    );
  }
}