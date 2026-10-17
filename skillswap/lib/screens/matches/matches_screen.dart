import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/providers.dart';
import '../../utils/matcher.dart';
import '../../widgets/user_avatar.dart';

class MatchesScreen extends ConsumerWidget {
  const MatchesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matches = ref.watch(matchesProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Suggested matches'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(otherUsersProvider),
          ),
        ],
      ),
      body: matches.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load matches.\n$e', textAlign: TextAlign.center)),
        data: (list) => list.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('No matches yet.\nAdd more skills to your profile to find partners.', textAlign: TextAlign.center),
                ),
              )
            : RefreshIndicator(
                onRefresh: () async => ref.refresh(otherUsersProvider.future),
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: list.length,
                  itemBuilder: (_, i) => _MatchCard(list[i]),
                ),
              ),
      ),
    );
  }
}

class _MatchCard extends StatelessWidget {
  final Match m;
  const _MatchCard(this.m);

  @override
  Widget build(BuildContext context) {
    final u = m.user;
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                UserAvatar(name: u.name, photoUrl: u.photoUrl, radius: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(u.name, style: Theme.of(context).textTheme.titleMedium),
                      if (u.bio.isNotEmpty)
                        Text(u.bio, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                if (m.isMutual)
                  Chip(
                    avatar: const Icon(Icons.swap_horiz, size: 16),
                    label: const Text('Mutual'),
                    backgroundColor: scheme.primaryContainer,
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            if (m.theyCanTeachYou.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text('Can teach you', style: Theme.of(context).textTheme.labelLarge),
              Wrap(spacing: 6, children: [for (final s in m.theyCanTeachYou) Chip(label: Text(s), visualDensity: VisualDensity.compact)]),
            ],
            if (m.youCanTeachThem.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text('Wants to learn from you', style: Theme.of(context).textTheme.labelLarge),
              Wrap(spacing: 6, children: [for (final s in m.youCanTeachThem) Chip(label: Text(s), visualDensity: VisualDensity.compact)]),
            ],
          ],
        ),
      ),
    );
  }
}
