import 'package:flutter/material.dart';
import '../main.dart';
import '../models/component.dart';
import '../services/serial_decoder.dart';

/// Form for adding a component to a specific PC.
///
/// Takes [pcId] via the constructor so it knows which PC this new
/// component belongs to — same pattern as PcDetailScreen receiving
/// a whole VirtualPc earlier.
/// Form for adding OR editing a component belonging to a specific PC.
///
/// If [existingComponent] is null, this is "add" mode — an insert.
/// If it's provided, this is "edit" mode — fields are pre-filled and
/// saving performs an update instead. Reusing one screen for both
/// avoids duplicating this entire form in two places.
class AddComponentScreen extends StatefulWidget {
  final String pcId;
  final Component? existingComponent;

  const AddComponentScreen({
    super.key,
    required this.pcId,
    this.existingComponent,
  });

  @override
  State<AddComponentScreen> createState() => _AddComponentScreenState();
}

class _AddComponentScreenState extends State<AddComponentScreen> {
  late final _nameController = TextEditingController(
      text: widget.existingComponent?.name ?? '');
  final _serialController = TextEditingController();
  final _brandController = TextEditingController();
  late String _category =
      widget.existingComponent?.category ?? componentCategories.first;
  DateTime? _manufacturingDate;
  DateTime? _warrantyDate;
  String? _decodeNote;
  bool _isSaving = false;
  String? _errorMessage;

  bool get _isEditing => widget.existingComponent != null;

  @override
  void initState() {
    super.initState();
    // Pre-fill the rest of the fields when editing.
    final existing = widget.existingComponent;
    if (existing != null) {
      _serialController.text = existing.serialNumber ?? '';
      _manufacturingDate = existing.manufacturingDate;
      _warrantyDate = existing.warrantyExpiration;
    }
  }

  void _tryDetectDate() {
    final result = decodeManufacturingDate(
      brand: _brandController.text.trim(),
      serialNumber: _serialController.text.trim(),
    );

    if (result == null) {
      setState(() {
        _decodeNote = null;
        _errorMessage =
            "Couldn't detect a date from that serial — enter it manually below if you know it.";
      });
      return;
    }

    setState(() {
      _manufacturingDate = result.date;
      _decodeNote = result.note;
      _errorMessage = null;
    });
  }

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

  Future<void> _pickWarrantyDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _warrantyDate = picked);
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
      final data = {
        'pc_id': widget.pcId,
        'name': name,
        'category': _category,
        'serial_number': _serialController.text.trim().isEmpty
            ? null
            : _serialController.text.trim(),
        'manufacturing_date': _manufacturingDate?.toIso8601String(),
        'warranty_expiration': _warrantyDate?.toIso8601String(),
      };

      if (_isEditing) {
        await supabase
            .from('components')
            .update(data)
            .eq('id', widget.existingComponent!.id);
      } else {
        await supabase.from('components').insert(data);
      }

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
    _brandController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(_isEditing ? 'Edit component' : 'Add a component')),
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
              controller: _brandController,
              decoration: const InputDecoration(
                labelText: 'Brand (optional, helps detection)',
                hintText: 'e.g. Kingston, Corsair, Seagate',
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
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _tryDetectDate,
              icon: const Icon(Icons.search, size: 16),
              label: const Text('Try to detect manufacturing date'),
            ),
            if (_decodeNote != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  '⚠ Estimated, not confirmed: $_decodeNote',
                  style: TextStyle(fontSize: 11, color: Colors.orange.shade800),
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
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _pickWarrantyDate,
              icon: const Icon(Icons.shield_outlined, size: 16),
              label: Text(
                _warrantyDate == null
                    ? 'Set warranty expiration (optional)'
                    : 'Warranty until: ${_warrantyDate!.year}-${_warrantyDate!.month.toString().padLeft(2, '0')}-${_warrantyDate!.day.toString().padLeft(2, '0')}',
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'You can also set the date manually above if detection doesn\'t work.',
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
                  : Text(_isEditing ? 'Save changes' : 'Save component'),
            ),
          ],
        ),
      ),
    );
  }
}