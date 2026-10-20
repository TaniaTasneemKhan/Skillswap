import 'package:flutter/material.dart';

import '../models/user_profile.dart';

/// Read-only stars (supports half stars).
class StarRow extends StatelessWidget {
  final double rating;
  final double size;
  const StarRow({super.key, required this.rating, this.size = 16});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 1; i <= 5; i++)
            Icon(
              rating >= i
                  ? Icons.star
                  : (rating >= i - 0.5 ? Icons.star_half : Icons.star_border),
              size: size,
              color: Colors.amber,
            ),
        ],
      );
}

/// Tappable 1-5 star input.
class StarPicker extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  final double size;
  const StarPicker({super.key, required this.value, required this.onChanged, this.size = 36});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 1; i <= 5; i++)
            IconButton(
              iconSize: size,
              visualDensity: VisualDensity.compact,
              tooltip: '$i star${i == 1 ? '' : 's'}',
              icon: Icon(i <= value ? Icons.star : Icons.star_border, color: Colors.amber),
              onPressed: () => onChanged(i),
            ),
        ],
      );
}

/// "4.8 (12)" next to a star, or "New member" when nobody has rated yet.
class RatingBadge extends StatelessWidget {
  final UserProfile profile;
  const RatingBadge(this.profile, {super.key});

  @override
  Widget build(BuildContext context) {
    if (profile.ratingCount == 0) {
      return Text('New member', style: Theme.of(context).textTheme.bodySmall);
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.star, size: 16, color: Colors.amber),
        const SizedBox(width: 3),
        Text(
          '${profile.rating.toStringAsFixed(1)} (${profile.ratingCount})',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ],
    );
  }
}
