import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/banner_header.dart';
import '../../widgets/reviews_list.dart';
import '../../widgets/skill_tag.dart';
import '../../widgets/star_rating.dart';
import '../../widgets/user_avatar.dart';
import '../availability/availability_screen.dart';
import 'profile_setup_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Widget _section(BuildContext context, String title, List<String> items, {required bool learn}) => Align(
        alignment: Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [for (final s in items) SkillTag(s, learn: learn)],
            ),
            const SizedBox(height: 20),
          ],
        ),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(profileProvider).valueOrNull;
    if (p == null) return const Center(child: CircularProgressIndicator());
    final theme = Theme.of(context);

    return SingleChildScrollView(
      child: Column(
        children: [
          BannerHeader(
            avatar: UserAvatar(name: p.name, photoUrl: p.photoUrl, radius: 52),
            child: const Align(
              alignment: Alignment.centerLeft,
              child: Text('My profile',
                  style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
            ),
          ),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                child: Column(
                  children: [
                    Text(p.name, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, color: Brand.ink)),
                    const SizedBox(height: 2),
                    Text(p.email, style: theme.textTheme.bodyMedium),
                    const SizedBox(height: 6),
                    if (p.ratingCount > 0) StarRow(rating: p.rating, size: 20),
                    RatingBadge(p),
                    if (p.bio.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(p.bio, textAlign: TextAlign.center),
                    ],
                    const SizedBox(height: 24),
                    _section(context, 'I can teach', p.skillsOffered, learn: false),
                    _section(context, 'I want to learn', p.skillsWanted, learn: true),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        icon: const Icon(Icons.edit),
                        label: const Text('Edit profile'),
                        onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => const ProfileSetupScreen(isEditing: true))),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.event_available),
                        label: Text('My availability (${p.availability.length} slots)'),
                        onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const AvailabilityScreen())),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ReviewsList(p.uid),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      icon: const Icon(Icons.logout),
                      label: const Text('Log out'),
                      onPressed: () async {
                        try {
                          await ref.read(notificationServiceProvider).removeToken(p.uid);
                        } catch (_) {}
                        await ref.read(authServiceProvider).signOut();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
