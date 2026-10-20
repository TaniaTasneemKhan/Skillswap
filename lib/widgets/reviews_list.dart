import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/review.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import 'star_rating.dart';
import 'user_avatar.dart';

/// Reviews other people wrote about [uid].
class ReviewsList extends ConsumerWidget {
  final String uid;
  const ReviewsList(this.uid, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(reviewsForUserProvider(uid));
    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => const Padding(
        padding: EdgeInsets.all(16),
        child: Text('Could not load reviews.'),
      ),
      data: (list) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            list.isEmpty ? 'Reviews' : 'Reviews (${list.length})',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          if (list.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Brand.border),
              ),
              child: const Text('No reviews yet. Reviews appear after completed sessions.'),
            )
          else
            for (final r in list) _ReviewCard(r),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final Review r;
  const _ReviewCard(this.r);

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Brand.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                UserAvatar(name: r.reviewerName, photoUrl: r.reviewerPhotoUrl, radius: 16),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r.reviewerName, style: const TextStyle(fontWeight: FontWeight.w600)),
                      StarRow(rating: r.rating.toDouble(), size: 14),
                    ],
                  ),
                ),
                Text(timeAgo(r.createdAt), style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            if (r.comment.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(r.comment),
            ],
            if (r.topic.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text('Session: ${r.topic}', style: Theme.of(context).textTheme.bodySmall),
            ],
          ],
        ),
      );
}
