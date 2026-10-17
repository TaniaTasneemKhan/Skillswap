import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Gradient banner with an optional avatar that overlaps its bottom edge.
class BannerHeader extends StatelessWidget {
  final Widget child;
  final Widget? avatar;
  final double height;
  final double avatarRadius;
  const BannerHeader({
    super.key,
    required this.child,
    this.avatar,
    this.height = 150,
    this.avatarRadius = 52,
  });

  @override
  Widget build(BuildContext context) {
    final lower = avatar == null ? 0.0 : avatarRadius + 4;
    return SizedBox(
      height: height + lower,
      child: Stack(
        children: [
          Container(
            height: height,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: Brand.gradient,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Align(alignment: Alignment.topCenter, child: child),
              ),
            ),
          ),
          if (avatar != null)
            Positioned(
              top: height - avatarRadius - 4,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 14, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: avatar,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
