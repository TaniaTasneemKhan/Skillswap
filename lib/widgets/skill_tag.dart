import 'package:flutter/material.dart';

/// Purple pill for skills someone teaches, green pill for skills they want.
class SkillTag extends StatelessWidget {
  final String label;
  final bool learn;
  final bool compact;
  const SkillTag(this.label, {super.key, this.learn = false, this.compact = false});

  @override
  Widget build(BuildContext context) => Container(
        padding: compact
            ? const EdgeInsets.symmetric(horizontal: 8, vertical: 3)
            : const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: learn ? const Color(0xFFDDF7E8) : const Color(0xFFF0E6FF),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: compact ? 10 : 13,
            fontWeight: FontWeight.w600,
            color: learn ? const Color(0xFF1E7A4A) : const Color(0xFF7A3FD1),
          ),
        ),
      );
}
