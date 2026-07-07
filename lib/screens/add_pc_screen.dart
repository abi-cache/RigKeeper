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