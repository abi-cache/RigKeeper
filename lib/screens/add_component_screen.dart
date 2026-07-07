import 'package:flutter/material.dart';
import '../main.dart';
import '../models/component.dart';

/// Form for adding a component to a specific PC.
///
/// Takes [pcId] via the constructor so it knows which PC this new
/// component belongs to — same pattern as PcDetailScreen receiving
/// a whole VirtualPc earlier.
class AddComponentScreen extends StatefulWidget {
  final String pcId;

  const AddComponentScreen({super.key, required this.pcId});

  @override
  State<AddComponentScreen> createState() => _AddComponentScreenState();
}

class _AddComponentScreenState extends State<AddComponentScreen> {
  final _nameController = TextEditingController();
  final _serialController = TextEditingController();
  String _category = componentCategories.first;
  DateTime? _manufacturingDate;
  bool _isSaving = false;
  String? _errorMessage;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _manufacturingDate = picked);
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _errorMessage = 'Give this component a name.');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await supabase.from('components').insert({
        'pc_id': widget.pcId,
        'name': name,
        'category': _category,
        'serial_number': _serialController.text.trim().isEmpty
            ? null
            : _serialController.text.trim(),
        'manufacturing_date': _manufacturingDate?.toIso8601String(),
      });

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _errorMessage = 'Could not save. Try again.');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _serialController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add a component')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: componentCategories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _category = value);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name / model',
                hintText: 'e.g. Ryzen 7 5800X',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _serialController,
              decoration: const InputDecoration(
                labelText: 'Serial number (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_today, size: 16),
              label: Text(
                _manufacturingDate == null
                    ? 'Set manufacturing date (optional)'
                    : 'Made: ${_manufacturingDate!.year}-${_manufacturingDate!.month.toString().padLeft(2, '0')}-${_manufacturingDate!.day.toString().padLeft(2, '0')}',
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Automatic decoding from serial numbers is a future feature — for now, enter the date manually if you know it.',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Save component'),
            ),
          ],
        ),
      ),
    );
  }
}