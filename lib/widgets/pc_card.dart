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
          border: Border.all(color: Colors.grey.shade300, width: 0.5),
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
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(pc.icon, size: 20, color: Colors.blue.shade700),
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
                                fontSize: 12, color: Colors.grey.shade600)),
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
                Expanded(child: _StatBox(label: 'Health score', value: '${pc.healthScore}')),
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
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}