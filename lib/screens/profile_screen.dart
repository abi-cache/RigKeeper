import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';

/// Account overview — username (editable), email, member-since date,
/// appearance settings, and logout.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isSaving = false;

  String get _username {
    final user = supabase.auth.currentUser;
    final username = user?.userMetadata?['username'] as String?;
    if (username != null && username.isNotEmpty) return username;
    return user?.email?.split('@').first ?? 'Unknown';
  }

  Future<void> _editUsername() async {
    final controller = TextEditingController(text: _username);

    final newUsername = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit username'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Username',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newUsername == null || newUsername.isEmpty) return;

    setState(() => _isSaving = true);
    try {
      // Supabase re-fetches and updates the current user's metadata
      // in place — this is the same `data` field we set at sign-up,
      // just updated after the fact rather than only at creation.
      await supabase.auth.updateUser(
        UserAttributes(data: {'username': newUsername}),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Couldn't update username. Try again.")),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;
    final createdAt =
        user?.createdAt != null ? DateTime.parse(user!.createdAt) : null;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: scheme.primaryContainer,
              child: Icon(Icons.person, size: 32, color: scheme.onPrimaryContainer),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(_username,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(width: 8),
                _isSaving
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: scheme.primary),
                      )
                    : GestureDetector(
                        onTap: _editUsername,
                        child: Icon(Icons.edit_outlined,
                            size: 18, color: scheme.onSurfaceVariant),
                      ),
              ],
            ),
            const SizedBox(height: 2),
            Text(user?.email ?? '',
                style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant)),
            if (createdAt != null) ...[
              const SizedBox(height: 4),
              Text(
                'Member since ${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')}',
                style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
              ),
            ],
            const SizedBox(height: 32),
            Text('Appearance',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: scheme.onSurfaceVariant)),
            const SizedBox(height: 8),
            ValueListenableBuilder<ThemeMode>(
              valueListenable: themeModeNotifier,
              builder: (context, mode, _) {
                return SegmentedButton<ThemeMode>(
                  segments: const [
                    ButtonSegment(
                        value: ThemeMode.light,
                        icon: Icon(Icons.light_mode, size: 18),
                        label: Text('Light')),
                    ButtonSegment(
                        value: ThemeMode.dark,
                        icon: Icon(Icons.dark_mode, size: 18),
                        label: Text('Dark')),
                    ButtonSegment(
                        value: ThemeMode.system,
                        icon: Icon(Icons.brightness_auto, size: 18),
                        label: Text('Auto')),
                  ],
                  selected: {mode},
                  onSelectionChanged: (newSelection) {
                    themeModeNotifier.value = newSelection.first;
                  },
                );
              },
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await supabase.auth.signOut();
                },
                icon: Icon(Icons.logout, color: scheme.error),
                label: Text('Log out', style: TextStyle(color: scheme.error)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}