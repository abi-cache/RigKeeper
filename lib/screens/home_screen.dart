import 'package:flutter/material.dart';
import '../models/virtual_pc.dart';
import '../widgets/pc_card.dart';
import 'pc_detail_screen.dart';

/// The first screen the user sees: a list of their virtual PCs.
///
/// Right now it reads from [mockPcs]. When the backend milestone is
/// done, this becomes a StatefulWidget (or uses a state-management
/// package) that fetches the real list instead — the PcCard widget
/// underneath won't need to change at all.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Text('Good evening',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
              const SizedBox(height: 2),
              const Text('Your PCs',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: mockPcs.length,
                  itemBuilder: (context, index) {
                    final pc = mockPcs[index];
                    return PcCard(
                      pc: pc,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => PcDetailScreen(pc: pc)),
                        );
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // Placeholder — will open the "Add a PC" flow.
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add a PC'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}