import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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

  // Same bytes-based approach used for maintenance photos — works
  // identically across web, Android, and iOS.
  Uint8List? _photoBytes;
  final _picker = ImagePicker();

  Future<void> _pickPhoto() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      imageQuality: 80,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() => _photoBytes = bytes);
  }

  Future<String> _uploadPhoto(Uint8List bytes) async {
    final fileName =
        '${supabase.auth.currentUser!.id}/${DateTime.now().millisecondsSinceEpoch}.jpg';
    await supabase.storage.from('pc-photos').uploadBinary(fileName, bytes);
    return supabase.storage.from('pc-photos').getPublicUrl(fileName);
  }

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

      String? imageUrl;
      if (_photoBytes != null) {
        imageUrl = await _uploadPhoto(_photoBytes!);
      }

      await supabase.from('pcs').insert({
        'user_id': userId,
        'name': name,
        'dust_level': _dustLevel,
        'has_pets': _hasPets,
        'daily_usage_hours': _dailyUsageHours,
        'image_url': imageUrl,
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GestureDetector(
              onTap: _pickPhoto,
              child: Container(
                height: 140,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant),
                ),
                child: _photoBytes != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(_photoBytes!, fit: BoxFit.cover, width: double.infinity),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo_outlined,
                              color: Theme.of(context).colorScheme.onSurfaceVariant),
                          const SizedBox(height: 6),
                          Text('Add a photo (optional)',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),
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
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
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
              Text(_errorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
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