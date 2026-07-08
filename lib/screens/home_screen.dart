import 'package:flutter/material.dart';
import '../models/virtual_pc.dart';
import '../widgets/pc_card.dart';
import 'pc_detail_screen.dart';
import 'add_pc_screen.dart';
import 'profile_screen.dart';
import '../main.dart';
import '../services/maintenance_prediction.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<VirtualPc> _pcs = [];
  bool _isLoading = true;
  int _overdueCount = 0;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadPcs();
  }

  /// Fetches every PC for the current user, then for each one,
  /// separately fetches its components and maintenance logs to
  /// compute real stats.
  ///
  /// Note: this makes several small queries per PC rather than one
  /// big combined query — perfectly fine at capstone scale (a
  /// handful of PCs), but a production version with many users would
  /// want a single SQL view/join to do this more efficiently. Flagged
  /// here as a known trade-off, not an oversight.
  Future<void> _loadPcs() async {
    setState(() => _isLoading = true);

    final userId = supabase.auth.currentUser!.id;
    final pcRows = await supabase
        .from('pcs')
        .select()
        .eq('user_id', userId)
        .order('created_at');

    final List<VirtualPc> loadedPcs = [];

    for (final pcRow in pcRows) {
      final pcId = pcRow['id'] as String;

      final componentRows =
          await supabase.from('components').select().eq('pc_id', pcId);

      final logRows = await supabase
          .from('maintenance_logs')
          .select()
          .eq('pc_id', pcId)
          .order('log_date', ascending: false)
          .limit(1);

      // Days since last cleaning — if never cleaned, fall back to
      // days since the PC was added.
      int daysSinceLastCleaned;
      if (logRows.isNotEmpty) {
        final lastDate = DateTime.parse(logRows.first['log_date'] as String);
        daysSinceLastCleaned = DateTime.now().difference(lastDate).inDays;
      } else {
        final createdAt = DateTime.parse(pcRow['created_at'] as String);
        daysSinceLastCleaned = DateTime.now().difference(createdAt).inDays;
      }

      // Average component age, in years, ignoring components with no
      // manufacturing date set.
      final agesWithDates = componentRows
          .where((c) => c['manufacturing_date'] != null)
          .map((c) {
        final made = DateTime.parse(c['manufacturing_date'] as String);
        return DateTime.now().difference(made).inDays / 365.0;
      }).toList();

      final averageAge = agesWithDates.isEmpty
          ? 0.0
          : agesWithDates.reduce((a, b) => a + b) / agesWithDates.length;

      final nextCleaningInDays = predictNextCleaning(
        daysSinceLastCleaned: daysSinceLastCleaned,
        dustLevel: pcRow['dust_level'] as String? ?? 'medium',
        hasPets: pcRow['has_pets'] as bool? ?? false,
        dailyUsageHours: pcRow['daily_usage_hours'] as int? ?? 4,
      );
      final healthScore = calculateHealthScore(
        daysSinceLastCleaned: daysSinceLastCleaned,
        averageComponentAgeYears: averageAge,
      );

      loadedPcs.add(VirtualPc.fromMap(
        pcRow,
        componentCount: componentRows.length,
        healthScore: healthScore,
        lastCleanedDaysAgo: daysSinceLastCleaned,
        nextCleaningInDays: nextCleaningInDays,
        averageComponentAgeYears: averageAge,
      ));
    }

    // Most urgent (soonest / most overdue cleaning) shown first.
    loadedPcs.sort(
        (a, b) => a.nextCleaningInDays.compareTo(b.nextCleaningInDays));

    setState(() {
      _pcs = loadedPcs;
      _overdueCount =
          loadedPcs.where((pc) => pc.nextCleaningInDays <= 0).length;
      _isLoading = false;
    });
  }

  /// Removes a PC from the visible list immediately (so the swipe
  /// feels instant), but delays the REAL database delete for a few
  /// seconds. If the user taps "Undo" in that window, we just put it
  /// back in the list and cancel the pending delete. This is the
  /// standard "optimistic delete with undo" pattern used by apps
  /// like Gmail — much friendlier than an upfront confirmation
  /// dialog for something as easy to trigger as a swipe.
  void _deletePcWithUndo(VirtualPc pc, int index) {
    setState(() => _pcs.removeAt(index));

    bool undone = false;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Deleted "${pc.name}"'),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () {
            undone = true;
            setState(() => _pcs.insert(index, pc));
          },
        ),
      ),
    );

    // Wait slightly longer than the snackbar's own duration so the
    // undo button has definitely finished being tappable before we
    // commit to the real delete.
    Future.delayed(const Duration(seconds: 6), () async {
      if (!undone) {
        await supabase.from('pcs').delete().eq('id', pc.id!);
      }
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
            icon: const Icon(Icons.person_outline),
            tooltip: 'Profile',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
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
              const SizedBox(height: 12),
              if (!_isLoading && _overdueCount > 0)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.notifications_active_outlined,
                          size: 18, color: Colors.orange.shade800),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _overdueCount == 1
                              ? '1 PC is due for cleaning'
                              : '$_overdueCount PCs are due for cleaning',
                          style: TextStyle(
                              fontSize: 13, color: Colors.orange.shade900),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 4),
              if (_pcs.isNotEmpty || _searchQuery.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TextField(
                    onChanged: (value) =>
                        setState(() => _searchQuery = value),
                    decoration: InputDecoration(
                      hintText: 'Search your PCs...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      isDense: true,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              Expanded(
                child: Builder(builder: (context) {
                  final filteredPcs = _searchQuery.isEmpty
                      ? _pcs
                      : _pcs
                          .where((pc) => pc.name
                              .toLowerCase()
                              .contains(_searchQuery.toLowerCase()))
                          .toList();

                  if (_isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (_pcs.isEmpty) {
                    return Center(
                      child: Text(
                        'No PCs yet — add your first one below.',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    );
                  }
                  if (filteredPcs.isEmpty) {
                    return Center(
                      child: Text(
                        'No PCs match "$_searchQuery".',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: _loadPcs,
                    child: ListView.builder(
                      itemCount: filteredPcs.length,
                      itemBuilder: (context, index) {
                        final pc = filteredPcs[index];
                        return Dismissible(
                          key: Key(pc.id!),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            decoration: BoxDecoration(
                              color: Colors.red.shade400,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            margin: const EdgeInsets.only(bottom: 12),
                            child:
                                const Icon(Icons.delete, color: Colors.white),
                          ),
                          onDismissed: (direction) {
                            _deletePcWithUndo(
                                pc, _pcs.indexWhere((p) => p.id == pc.id));
                          },
                          child: PcCard(
                            pc: pc,
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        PcDetailScreen(pc: pc)),
                              );
                              _loadPcs();
                            },
                          ),
                        );
                      },
                    ),
                  );
                }),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
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