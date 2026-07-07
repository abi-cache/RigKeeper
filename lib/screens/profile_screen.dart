import 'package:flutter/material.dart';
import '../main.dart';

/// Simple account overview — email, member-since date, and a
/// dedicated place for logout (in addition to the quick icon on
/// Home). Kept intentionally minimal for now; a natural next step
/// would be adding a display name / avatar, but that needs its own
/// small `profiles` table since Supabase's built-in user table only
/// stores auth fields like email, not custom profile data.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;
    final createdAt =
        user?.createdAt != null ? DateTime.parse(user!.createdAt) : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: Colors.blue.shade50,
              child: Icon(Icons.person, size: 32, color: Colors.blue.shade700),
            ),
            const SizedBox(height: 16),
            Text(user?.email ?? 'Unknown',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            if (createdAt != null) ...[
              const SizedBox(height: 4),
              Text(
                'Member since ${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')}',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            ],
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await supabase.auth.signOut();
                },
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text('Log out',
                    style: TextStyle(color: Colors.red)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}