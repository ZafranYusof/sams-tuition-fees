import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerLoading extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerLoading({super.key, this.width = double.infinity, this.height = 60, this.borderRadius = 12});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? const Color(0xFF132F4C) : const Color(0xFFE0E0E0),
      highlightColor: isDark ? const Color(0xFF1A3A5C) : const Color(0xFFF5F5F5),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF132F4C) : const Color(0xFFE0E0E0),
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

class ShimmerList extends StatelessWidget {
  final int count;
  final double itemHeight;

  const ShimmerList({super.key, this.count = 5, this.itemHeight = 70});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: List.generate(count, (i) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              ShimmerLoading(width: 48, height: 48, borderRadius: 24),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerLoading(height: 14, width: 150),
                  const SizedBox(height: 8),
                  ShimmerLoading(height: 10, width: 100),
                ],
              )),
            ],
          ),
        )),
      ),
    );
  }
}

class ShimmerCards extends StatelessWidget {
  const ShimmerCards({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(children: [
            Expanded(child: ShimmerLoading(height: 100)),
            const SizedBox(width: 12),
            Expanded(child: ShimmerLoading(height: 100)),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: ShimmerLoading(height: 100)),
            const SizedBox(width: 12),
            Expanded(child: ShimmerLoading(height: 100)),
          ]),
          const SizedBox(height: 16),
          ShimmerLoading(height: 120),
          const SizedBox(height: 12),
          ShimmerLoading(height: 180),
        ],
      ),
    );
  }
}
