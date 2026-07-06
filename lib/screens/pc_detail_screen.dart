import 'package:flutter/material.dart';
import '../models/virtual_pc.dart';

/// Shown when the user taps a PC from the Home screen.
///
/// Takes the [VirtualPc] that was tapped via the constructor — this is
/// how data moves between screens in Flutter: the parent screen (Home)
/// passes the object in when it navigates here, rather than this screen
/// re-fetching or guessing which PC to show.
class PcDetailScreen extends StatelessWidget {
  final VirtualPc pc;

  const PcDetailScreen({super.key, required this.pc});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(pc.name),
        backgroundColor: Colors.grey.shade50,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300, width: 0.5),
              ),
              child: Row(
                children: [
                  Text('Next cleaning predicted in ${pc.nextCleaningInDays} days',
                      style: const TextStyle(fontSize: 14)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text('Components',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600)),
            const SizedBox(height: 8),
            const Expanded(
              child: Center(
                child: Text(
                  'Component list coming in the next milestone\n(Virtual PC Builder + database).',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}