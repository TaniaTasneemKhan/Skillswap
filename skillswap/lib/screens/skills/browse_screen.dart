import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/skill_listing.dart';
import '../../providers/providers.dart';
import '../../widgets/user_avatar.dart';
import 'add_listing_screen.dart';

class BrowseScreen extends ConsumerWidget {
  const BrowseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listings = ref.watch(filteredListingsProvider);
    final cat = ref.watch(categoryFilterProvider);
    final type = ref.watch(typeFilterProvider);
    final myUid = ref.watch(authStateProvider).valueOrNull?.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('Browse skills')),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('New listing'),
        onPressed: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const AddListingScreen())),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              onChanged: (v) => ref.read(searchQueryProvider.notifier).state = v,
              decoration: const InputDecoration(
                hintText: 'Search skills, topics or people',
                prefixIcon: Icon(Icons.search),
                isDense: true,
              ),
            ),
          ),
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _filterChip('Offering', type == 'offer',
                    (s) => ref.read(typeFilterProvider.notifier).state = s ? 'offer' : null),
                _filterChip('Wanted', type == 'want',
                    (s) => ref.read(typeFilterProvider.notifier).state = s ? 'want' : null),
                const SizedBox(width: 8),
                for (final c in kCategories)
                  _filterChip(c, cat == c,
                      (s) => ref.read(categoryFilterProvider.notifier).state = s ? c : null),
              ],
            ),
          ),
          Expanded(
            child: listings.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Could not load listings.\n$e', textAlign: TextAlign.center)),
              data: (items) => items.isEmpty
                  ? const Center(child: Text('No listings found.\nTry a different filter or add one!', textAlign: TextAlign.center))
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 90),
                      itemCount: items.length,
                      itemBuilder: (_, i) => _ListingCard(items[i], isMine: items[i].ownerId == myUid),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, bool selected, ValueChanged<bool> onSel) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: FilterChip(label: Text(label), selected: selected, onSelected: onSel),
      );
}

class _ListingCard extends ConsumerWidget {
  final SkillListing l;
  final bool isMine;
  const _ListingCard(this.l, {required this.isMine});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                UserAvatar(name: l.ownerName, photoUrl: l.ownerPhotoUrl, radius: 18),
                const SizedBox(width: 10),
                Expanded(child: Text(l.ownerName, style: const TextStyle(fontWeight: FontWeight.w600))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: l.isOffer ? scheme.primaryContainer : scheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(l.isOffer ? 'Offering' : 'Wants to learn', style: const TextStyle(fontSize: 12)),
                ),
                if (isMine)
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Delete listing',
                    onPressed: () async {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Delete listing?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
                          ],
                        ),
                      );
                      if (ok == true) await ref.read(listingServiceProvider).delete(l.id);
                    },
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(l.title, style: Theme.of(context).textTheme.titleMedium),
            if (l.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(l.description, maxLines: 3, overflow: TextOverflow.ellipsis),
            ],
            const SizedBox(height: 8),
            Wrap(spacing: 6, children: [
              Chip(label: Text(l.category), visualDensity: VisualDensity.compact),
              Chip(label: Text(l.level), visualDensity: VisualDensity.compact),
            ]),
          ],
        ),
      ),
    );
  }
}
