import 'package:flutter/material.dart';
import '../main.dart';

/// Simple form to create a new PC row in Supabase.
///
/// On success, pops back to HomeScreen with `true` so it knows to
/// refresh its list — that's what the `Navigator.pop(context, true)`
/// call does further down.
class AddPcScreen extends StatefulWidget {
  const AddPcScreen({super.key});

  @override
  State<AddPcScreen> createState() => _AddPcScreenState();
}

class _AddPcScreenState extends State<AddPcScreen> {
  final _nameController = TextEditingController();
  String _dustLevel = 'medium';
  bool _hasPets = false;
  int _dailyUsageHours = 4;
  bool _isSaving = false;
  String? _errorMessage;

  Future<void> _savePc() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _errorMessage = 'Give your PC a name first.');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final userId = supabase.auth.currentUser!.id;
      await supabase.from('pcs').insert({
        'user_id': userId,
        'name': name,
        'dust_level': _dustLevel,
        'has_pets': _hasPets,
        'daily_usage_hours': _dailyUsageHours,
      });

      if (mounted) {
        Navigator.pop(context, true); // true = "something changed, refresh"
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Could not save. Try again.';
      });
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add a PC')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'PC name',
                hintText: 'e.g. Gaming rig',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            Text('Environment (used for smarter predictions)',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _dustLevel,
              decoration: const InputDecoration(
                labelText: 'Dust level in the room',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'low', child: Text('Low')),
                DropdownMenuItem(value: 'medium', child: Text('Medium')),
                DropdownMenuItem(value: 'high', child: Text('High')),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _dustLevel = value);
              },
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Pets in the home'),
              value: _hasPets,
              onChanged: (value) => setState(() => _hasPets = value),
            ),
            const SizedBox(height: 4),
            Text('Average daily usage: $_dailyUsageHours hrs',
                style: const TextStyle(fontSize: 13)),
            Slider(
              value: _dailyUsageHours.toDouble(),
              min: 0,
              max: 16,
              divisions: 16,
              label: '$_dailyUsageHours hrs',
              onChanged: (value) =>
                  setState(() => _dailyUsageHours = value.round()),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isSaving ? null : _savePc,
              child: _isSaving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}