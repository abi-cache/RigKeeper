import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';
import '../models/maintenance_log.dart';

class AddMaintenanceLogScreen extends StatefulWidget {
  final String pcId;

  const AddMaintenanceLogScreen({super.key, required this.pcId});

  @override
  State<AddMaintenanceLogScreen> createState() =>
      _AddMaintenanceLogScreenState();
}

class _AddMaintenanceLogScreenState extends State<AddMaintenanceLogScreen> {
  String _type = maintenanceTypes.first;
  DateTime _date = DateTime.now();
  final _notesController = TextEditingController();
  bool _isSaving = false;
  String? _errorMessage;

  // We keep the picked photo as raw bytes (Uint8List) rather than a
  // File path, because this needs to work on web too (Chrome has no
  // real filesystem path to give us) — bytes work identically on
  // every platform.
  Uint8List? _beforeBytes;
  Uint8List? _afterBytes;

  final _picker = ImagePicker();

  Future<void> _pickImage(bool isBefore) async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200, // keep uploads reasonably sized
      imageQuality: 80,
    );
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    setState(() {
      if (isBefore) {
        _beforeBytes = bytes;
      } else {
        _afterBytes = bytes;
      }
    });
  }

  /// Uploads raw bytes to the maintenance-photos bucket and returns
  /// the public URL Supabase gives back for that file.
  Future<String> _uploadPhoto(Uint8List bytes, String label) async {
    final fileName =
        '${supabase.auth.currentUser!.id}/${DateTime.now().millisecondsSinceEpoch}_$label.jpg';

    await supabase.storage.from('maintenance-photos').uploadBinary(
          fileName,
          bytes,
          fileOptions: FileOptions(contentType: 'image/jpeg'),
        );

    return supabase.storage.from('maintenance-photos').getPublicUrl(fileName);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  Future<void> _save() async {
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      // Upload photos first (if any were picked), THEN insert the row
      // — this way we only ever save a URL that actually exists.
      String? beforeUrl;
      String? afterUrl;

      if (_beforeBytes != null) {
        beforeUrl = await _uploadPhoto(_beforeBytes!, 'before');
      }
      if (_afterBytes != null) {
        afterUrl = await _uploadPhoto(_afterBytes!, 'after');
      }

      await supabase.from('maintenance_logs').insert({
        'pc_id': widget.pcId,
        'log_date': _date.toIso8601String().split('T').first,
        'type': _type,
        'notes': _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        'before_photo_url': beforeUrl,
        'after_photo_url': afterUrl,
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
    _notesController.dispose();
    super.dispose();
  }

  Widget _photoPicker(String label, Uint8List? bytes, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 120,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
          ),
          child: bytes != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.memory(bytes, fit: BoxFit.cover),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_a_photo_outlined,
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                    const SizedBox(height: 4),
                    Text(label,
                        style: TextStyle(
                            fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  ],
                ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Log maintenance')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _type,
              decoration: const InputDecoration(
                labelText: 'Type',
                border: OutlineInputBorder(),
              ),
              items: maintenanceTypes
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _type = value);
              },
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_today, size: 16),
              label: Text(
                '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}',
              ),
            ),
            const SizedBox(height: 16),
            Text('Photos',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
            const SizedBox(height: 8),
            Row(
              children: [
                _photoPicker('Before', _beforeBytes, () => _pickImage(true)),
                const SizedBox(width: 10),
                _photoPicker('After', _afterBytes, () => _pickImage(false)),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'e.g. Replaced dust filters, repasted GPU',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(_errorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Save log'),
            ),
          ],
        ),
      ),
    );
  }
}