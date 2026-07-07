import 'package:flutter/material.dart';
import '../models/virtual_pc.dart';
import '../models/component.dart';
import '../main.dart';
import 'add_component_screen.dart';
import 'maintenance_log_screen.dart';

/// Shown when the user taps a PC from the Home screen.
///
/// Like HomeScreen, this is now Stateful because it fetches real
/// component data from Supabase instead of showing a static message.
class PcDetailScreen extends StatefulWidget {
  final VirtualPc pc;

  const PcDetailScreen({super.key, required this.pc});

  @override
  State<PcDetailScreen> createState() => _PcDetailScreenState();
}

class _PcDetailScreenState extends State<PcDetailScreen> {
  List<Component> _components = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadComponents();
  }

  Future<void> _loadComponents() async {
    setState(() => _isLoading = true);

    final rows = await supabase
        .from('components')
        .select()
        .eq('pc_id', widget.pc.id as String)
        .order('created_at');

    setState(() {
      _components = rows.map((row) => Component.fromMap(row)).toList();
      _isLoading = false;
    });
  }

  void _deleteComponentWithUndo(Component c, int index) {
    setState(() => _components.removeAt(index));

    bool undone = false;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Deleted "${c.name}"'),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () {
            undone = true;
            setState(() => _components.insert(index, c));
          },
        ),
      ),
    );

    Future.delayed(const Duration(seconds: 6), () async {
      if (!undone) {
        await supabase.from('components').delete().eq('id', c.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(widget.pc.name),
        backgroundColor: Colors.grey.shade50,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Components',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600)),
            const SizedBox(height: 8),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _components.isEmpty
                      ? Center(
                          child: Text(
                            'No components yet.\nAdd your CPU, GPU, RAM, etc. below.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _components.length,
                          itemBuilder: (context, index) {
                            final c = _components[index];
                            return Dismissible(
                              key: Key(c.id),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 16),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade400,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                margin: const EdgeInsets.only(bottom: 8),
                                child: const Icon(Icons.delete,
                                    color: Colors.white, size: 20),
                              ),
                              onDismissed: (direction) {
                                _deleteComponentWithUndo(c, index);
                              },
                              child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: GestureDetector(
                                onTap: () async {
                                  final shouldRefresh = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => AddComponentScreen(
                                        pcId: widget.pc.id as String,
                                        existingComponent: c,
                                      ),
                                    ),
                                  );
                                  if (shouldRefresh == true) {
                                    _loadComponents();
                                  }
                                },
                                child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: Colors.grey.shade300, width: 0.5),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(c.name,
                                          style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500)),
                                      Text(
                                        c.ageInYears != null
                                            ? '${c.category} · ${c.ageInYears} yrs old'
                                            : '${c.category} · age unknown',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600),
                                      ),
                                      if (c.warrantyDaysLeft != null)
                                        Text(
                                          c.warrantyDaysLeft! < 0
                                              ? 'Warranty expired'
                                              : 'Warranty: ${c.warrantyDaysLeft}d left',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: c.warrantyDaysLeft! < 0
                                                ? Colors.red
                                                : Colors.green.shade700,
                                          ),
                                        ),
                                    ],
                                  ),
                                  Icon(Icons.chevron_right,
                                      color: Colors.grey.shade400, size: 20),
                                ],
                              ),
                              ),
                              ),
                              ),
                            );
                          },
                        ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final shouldRefresh = await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            AddComponentScreen(pcId: widget.pc.id as String)),
                  );
                  if (shouldRefresh == true) {
                    _loadComponents();
                  }
                },
                icon: const Icon(Icons.add),
                label: const Text('Add a component'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MaintenanceLogScreen(
                        pcId: widget.pc.id as String,
                        pcName: widget.pc.name,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.history),
                label: const Text('View maintenance history'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}