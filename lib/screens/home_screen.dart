import 'package:flutter/material.dart';
import '../models/virtual_pc.dart';
import '../widgets/pc_card.dart';
import 'pc_detail_screen.dart';
import 'add_pc_screen.dart';
import '../main.dart';

/// The first screen the user sees: a list of their virtual PCs.
///
/// This is now a StatefulWidget (not Stateless like before) because
/// it needs to hold onto data that changes over time — the fetched
/// list of PCs — and re-render itself when that data arrives or
/// changes. StatelessWidgets can't do that on their own.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<VirtualPc> _pcs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // initState runs once, right when this screen is first created —
    // the natural place to kick off a first data fetch.
    _loadPcs();
  }

  Future<void> _loadPcs() async {
    setState(() => _isLoading = true);

    final userId = supabase.auth.currentUser!.id;
    final rows = await supabase
        .from('pcs')
        .select()
        .eq('user_id', userId)
        .order('created_at');

    setState(() {
      _pcs = rows.map((row) => VirtualPc.fromMap(row)).toList();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.grey.shade50,
        elevation: 0,
        title: const Text('RigKeeper'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Log out',
            onPressed: () async {
              await supabase.auth.signOut();
            },
          ),
        ],
      ),
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
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _pcs.isEmpty
                        ? Center(
                            child: Text(
                              'No PCs yet — add your first one below.',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _pcs.length,
                            itemBuilder: (context, index) {
                              final pc = _pcs[index];
                              return PcCard(
                                pc: pc,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            PcDetailScreen(pc: pc)),
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
                    onPressed: () async {
                      // Wait for AddPcScreen to close, then check if it
                      // told us to refresh (it returns `true` on save).
                      final shouldRefresh = await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const AddPcScreen()),
                      );
                      if (shouldRefresh == true) {
                        _loadPcs();
                      }
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