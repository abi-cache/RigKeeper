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
    final rows = await supabase
        .from('maintenance_logs')
        .select()
        .eq('pc_id', widget.pcId)
        .order('log_date', ascending: false);

    setState(() {
      _logs = rows.map((row) => MaintenanceLog.fromMap(row)).toList();
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