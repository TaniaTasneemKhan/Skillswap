import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/banner_header.dart';
import '../../widgets/request_button.dart';
import '../../widgets/reviews_list.dart';
import '../../widgets/skill_tag.dart';
import '../../widgets/star_rating.dart';
import '../../widgets/user_avatar.dart';

void openProfile(BuildContext context, String uid) => Navigator.of(context)
    .push(MaterialPageRoute(builder: (_) => PublicProfileScreen(uid: uid)));

/// Another member's profile: reputation, skills and reviews.
class PublicProfileScreen extends ConsumerWidget {
  final String uid;
  const PublicProfileScreen({super.key, required this.uid});

  Widget _skills(BuildContext context, String title, List<String> items, {required bool learn}) => Align(
        alignment: Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [for (final s in items) SkillTag(s, learn: learn)]),
            const SizedBox(height: 20),
          ],
        ),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(publicProfileProvider(uid));
    final theme = Theme.of(context);
    return Scaffold(
      body: profile.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load profile.\n$e', textAlign: TextAlign.center)),
        data: (p) {
          if (p == null) {
            return Scaffold(
              appBar: AppBar(),
              body: const Center(child: Text('Profile not found.')),
            );
          }
          return SingleChildScrollView(
            child: Column(
              children: [
                BannerHeader(
                  avatar: UserAvatar(name: p.name, photoUrl: p.photoUrl, radius: 52),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const Text('Profile',
                          style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                      child: Column(
                        children: [
                          Text(p.name,
                              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, color: Brand.ink)),
                          const SizedBox(height: 4),
                          if (p.ratingCount > 0) StarRow(rating: p.rating, size: 20),
                          const SizedBox(height: 2),
                          RatingBadge(p),
                          if (p.bio.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text(p.bio, textAlign: TextAlign.center),
                          ],
                          const SizedBox(height: 20),
                          _skills(context, 'Can teach', p.skillsOffered, learn: false),
                          _skills(context, 'Wants to learn', p.skillsWanted, learn: true),
                          RequestButton(
                            otherId: p.uid,
                            otherName: p.name,
                            otherPhotoUrl: p.photoUrl,
                          ),
                          const SizedBox(height: 24),
                          ReviewsList(p.uid),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
