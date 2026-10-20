import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/skill_listing.dart';
import '../../providers/providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/request_button.dart';
import '../../widgets/user_avatar.dart';
import '../profile/public_profile_screen.dart';
import 'add_listing_screen.dart';

const _popular = [
  'Web Development', 'Photography', 'Graphic Design',
  'Data Analysis', 'Languages', 'Music',
];

class BrowseScreen extends ConsumerStatefulWidget {
  const BrowseScreen({super.key});
  @override
  ConsumerState<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends ConsumerState<BrowseScreen> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _setQuery(String q) {
    _search.text = q;
    _search.selection = TextSelection.collapsed(offset: q.length);
    ref.read(searchQueryProvider.notifier).state = q;
  }

  Widget _hero(BuildContext context) => Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 24, 20, 24),
        decoration: const BoxDecoration(
          gradient: Brand.gradient,
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Swap Skills, Learn & Teach for Free!',
              style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800, height: 1.15),
            ),
            const SizedBox(height: 6),
            const Text('Exchange your expertise with others. No money involved.',
                style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 16),
            TextField(
              controller: _search,
              onChanged: (v) => ref.read(searchQueryProvider.notifier).state = v,
              decoration: InputDecoration(
                hintText: 'Search skills, topics or people',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Text('Popular skills', style: TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                for (final s in _popular)
                  ActionChip(
                    label: Text(s),
                    backgroundColor: Colors.white,
                    side: BorderSide.none,
                    onPressed: () => _setQuery(s),
                  ),
              ],
            ),
          ],
        ),
      );

  Widget _filterChip(String label, bool selected, ValueChanged<bool> onSel) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: FilterChip(label: Text(label), selected: selected, onSelected: onSel),
      );

  @override
  Widget build(BuildContext context) {
    final listings = ref.watch(filteredListingsProvider);
    final cat = ref.watch(categoryFilterProvider);
    final type = ref.watch(typeFilterProvider);
    final myUid = ref.watch(authStateProvider).valueOrNull?.uid;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('New listing'),
        onPressed: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const AddListingScreen())),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 90),
        children: [
          _hero(context),
          SizedBox(
            height: 56,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14),
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
          ...listings.when<List<Widget>>(
            loading: () => const [
              Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator())),
            ],
            error: (e, _) => [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Center(child: Text('Could not load listings.\n$e', textAlign: TextAlign.center)),
              ),
            ],
            data: (items) => items.isEmpty
                ? const [
                    Padding(
                      padding: EdgeInsets.all(40),
                      child: Column(
                        children: [
                          Icon(Icons.search_off, size: 48, color: Colors.grey),
                          SizedBox(height: 8),
                          Text('No listings found.\nTry a different filter or add one!',
                              textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                  ]
                : [for (final l in items) _ListingCard(l, isMine: l.ownerId == myUid)],
          ),
        ],
      ),
    );
  }
}

class _ListingCard extends ConsumerWidget {
  final SkillListing l;
  final bool isMine;
  const _ListingCard(this.l, {required this.isMine});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.fromLTRB(14, 6, 14, 6),
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Brand.border.withOpacity(0.6)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => openProfile(context, l.ownerId),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          UserAvatar(name: l.ownerName, photoUrl: l.ownerPhotoUrl, radius: 18),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(l.ownerName,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
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
            if (!isMine) ...[
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: RequestButton(
                  otherId: l.ownerId,
                  otherName: l.ownerName,
                  otherPhotoUrl: l.ownerPhotoUrl,
                  // They offer it -> I want to learn it; they want it -> I could teach it.
                  initialWanted: l.isOffer ? l.title : '',
                  initialOffered: l.isOffer ? '' : l.title,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
