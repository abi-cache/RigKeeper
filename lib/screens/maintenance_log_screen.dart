import 'package:flutter/material.dart';
import '../main.dart';
import '../models/maintenance_log.dart';
import 'add_maintenance_log_screen.dart';

class MaintenanceLogScreen extends StatefulWidget {
  final String pcId;
  final String pcName;

  const MaintenanceLogScreen(
      {super.key, required this.pcId, required this.pcName});

  @override
  State<MaintenanceLogScreen> createState() => _MaintenanceLogScreenState();
}

class _MaintenanceLogScreenState extends State<MaintenanceLogScreen> {
  List<MaintenanceLog> _logs = [];
  // Maps a log's id to the names of components marked as serviced in
  // that session — populated from a nested query below.
  Map<String, List<String>> _servicedComponentNames = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() => _isLoading = true);

    // Most recent first — order descending by date so the newest
    // maintenance entry appears at the top of the timeline.
    //
    // The nested select below asks Postgres to also embed each log's
    // linked components (through the maintenance_log_components
    // junction table) in the same query, rather than fetching them
    // separately per log — one round trip instead of many.
    final rows = await supabase
        .from('maintenance_logs')
        .select('*, maintenance_log_components(components(id, name))')
        .eq('pc_id', widget.pcId)
        .order('log_date', ascending: false);

    final namesMap = <String, List<String>>{};
    for (final row in rows) {
      final logId = row['id'] as String;
      final links = row['maintenance_log_components'] as List? ?? [];
      final names = links
          .map((link) => (link['components']?['name']) as String?)
          .whereType<String>()
          .toList();
      namesMap[logId] = names;
    }

    setState(() {
      _logs = rows.map((row) => MaintenanceLog.fromMap(row)).toList();
      _servicedComponentNames = namesMap;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.pcName} — history')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _logs.isEmpty
                      ? Center(
                          child: Text(
                            'No maintenance logged yet.',
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _logs.length,
                          itemBuilder: (context, index) {
                            final log = _logs[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: Theme.of(context).colorScheme.outlineVariant, width: 0.5),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(log.type,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w500)),
                                      Text(
                                        '${log.logDate.year}-${log.logDate.month.toString().padLeft(2, '0')}-${log.logDate.day.toString().padLeft(2, '0')}',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Theme.of(context).colorScheme.onSurfaceVariant),
                                      ),
                                    ],
                                  ),
                                  if (log.notes != null &&
                                      log.notes!.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(log.notes!,
                                        style: TextStyle(
                                            fontSize: 13,
                                            color: Theme.of(context).colorScheme.onSurfaceVariant)),
                                  ],
                                  if ((_servicedComponentNames[log.id] ?? [])
                                      .isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      children: _servicedComponentNames[log.id]!
                                          .map((name) => Container(
                                                padding: const EdgeInsets
                                                    .symmetric(
                                                    horizontal: 8, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .secondaryContainer,
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  name,
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onSecondaryContainer,
                                                  ),
                                                ),
                                              ))
                                          .toList(),
                                    ),
                                  ],
                                  if (log.beforePhotoUrl != null ||
                                      log.afterPhotoUrl != null) ...[
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        if (log.beforePhotoUrl != null)
                                          Expanded(
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child: Image.network(
                                                log.beforePhotoUrl!,
                                                height: 90,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                        if (log.beforePhotoUrl != null &&
                                            log.afterPhotoUrl != null)
                                          const SizedBox(width: 8),
                                        if (log.afterPhotoUrl != null)
                                          Expanded(
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child: Image.network(
                                                log.afterPhotoUrl!,
                                                height: 90,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final shouldRefresh = await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            AddMaintenanceLogScreen(pcId: widget.pcId)),
                  );
                  if (shouldRefresh == true) {
                    _loadLogs();
                  }
                },
                icon: const Icon(Icons.add),
                label: const Text('Log maintenance'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}