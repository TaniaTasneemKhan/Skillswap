import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class BrandLogo extends StatelessWidget {
  /// light = white-on-gradient version for use over coloured backgrounds.
  final bool light;
  const BrandLogo({super.key, this.light = false});

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(fontSize: 20, fontWeight: FontWeight.w800);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            gradient: light ? null : Brand.gradient,
            color: light ? Colors.white.withOpacity(0.25) : null,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.auto_awesome, color: Colors.white, size: 19),
        ),
        const SizedBox(width: 10),
        light
            ? Text('SkillSwap', style: style.copyWith(color: Colors.white))
            : ShaderMask(
                shaderCallback: (r) => Brand.gradient.createShader(r),
                child: Text('SkillSwap', style: style.copyWith(color: Colors.white)),
              ),
      ],
    );
  }
}
