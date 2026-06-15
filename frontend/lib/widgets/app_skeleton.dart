import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../config/theme.dart';

/// Reusable skeleton helper for SAMs app — wraps skeletonizer with consistent
/// theming. Use [AppSkeleton.wrap] to skeletonize any widget tree, or
/// [AppSkeleton.box] for a quick rectangular placeholder.
class AppSkeleton {
  AppSkeleton._();

  /// Wraps [child] with a Skeletonizer that activates when [enabled] is true.
  static Widget wrap({
    required bool enabled,
    required Widget child,
    bool ignoreContainers = false,
  }) {
    return Skeletonizer(
      enabled: enabled,
      ignoreContainers: ignoreContainers,
      effect: const ShimmerEffect(
        baseColor: SAMsTheme.surface,
        highlightColor: SAMsTheme.surfaceLight,
        duration: Duration(milliseconds: 1200),
      ),
      child: child,
    );
  }

  /// A simple rectangular skeleton placeholder.
  static Widget box({
    double? width,
    double height = 16,
    BorderRadius? borderRadius,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: SAMsTheme.surface,
        borderRadius: borderRadius ?? BorderRadius.circular(8),
      ),
    );
  }

  /// Circular skeleton placeholder (avatars, icon buttons).
  static Widget circle({double size = 40}) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: SAMsTheme.surface,
        shape: BoxShape.circle,
      ),
    );
  }
}
