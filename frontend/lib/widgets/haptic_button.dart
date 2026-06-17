import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HapticButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final Color? backgroundColor;
  final double height;
  final double borderRadius;

  const HapticButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.backgroundColor,
    this.height = 52,
    this.borderRadius = 14,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: ElevatedButton(
        onPressed: onPressed != null ? () {
          HapticFeedback.lightImpact();
          onPressed!();
        } : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(borderRadius)),
        ),
        child: child,
      ),
    );
  }
}

class HapticIconButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget icon;

  const HapticIconButton({super.key, required this.onPressed, required this.icon});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {
        HapticFeedback.selectionClick();
        onPressed();
      },
      icon: icon,
    );
  }
}
