import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Full-width purple -> blue call-to-action button.
class GradientButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final bool loading;
  const GradientButton({super.key, required this.onPressed, required this.child, this.loading = false});

  @override
  Widget build(BuildContext context) => Opacity(
        opacity: onPressed == null ? 0.6 : 1,
        child: Container(
          decoration: BoxDecoration(
            gradient: Brand.gradient,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: onPressed,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Center(
                  child: DefaultTextStyle(
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                    child: loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : child,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}
