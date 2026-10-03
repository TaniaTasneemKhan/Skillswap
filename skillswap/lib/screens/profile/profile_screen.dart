import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/providers.dart';
import '../../widgets/user_avatar.dart';
import 'profile_setup_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(profileProvider).valueOrNull;
    if (p == null) return const Center(child: CircularProgressIndicator());
    final theme = Theme.of(context);

    Widget chips(String title, List<String> items) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 6),
            Wrap(spacing: 6, runSpacing: 4, children: [for (final s in items) Chip(label: Text(s))]),
            const SizedBox(height: 16),
          ],
        );

    return Scaffold(
      appBar: AppBar(title: const Text('My profile')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(child: UserAvatar(name: p.name, photoUrl: p.photoUrl, radius: 52)),
          const SizedBox(height: 12),
          Center(child: Text(p.name, style: theme.textTheme.headlineSmall)),
          Center(child: Text(p.email, style: theme.textTheme.bodyMedium)),
          if (p.bio.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(p.bio, textAlign: TextAlign.center),
          ],
          const SizedBox(height: 20),
          chips('I can teach', p.skillsOffered),
          chips('I want to learn', p.skillsWanted),
          OutlinedButton.icon(
            icon: const Icon(Icons.edit),
            label: const Text('Edit profile'),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const ProfileSetupScreen(isEditing: true))),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            icon: const Icon(Icons.logout),
            label: const Text('Log out'),
            onPressed: () => ref.read(authServiceProvider).signOut(),
          ),
        ],
      ),
    );
  }
}
