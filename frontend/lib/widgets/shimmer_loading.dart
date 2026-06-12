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
      baseColor: isDark ? const Color(0xFF132F4C) : const Color(0xFFE8E4DC),
      highlightColor: isDark ? const Color(0xFF1A3A5C) : const Color(0xFFF5F1E9),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF132F4C) : const Color(0xFFE8E4DC),
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

// Skeleton for fee list items
class ShimmerFeeList extends StatelessWidget {
  final int count;
  const ShimmerFeeList({super.key, this.count = 4});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(children: List.generate(count, (i) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Row(children: [
            ShimmerLoading(width: 8, height: 8, borderRadius: 4),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              ShimmerLoading(height: 14, width: 120 + (i * 20).toDouble()),
              const SizedBox(height: 8),
              ShimmerLoading(height: 10, width: 80),
            ])),
            ShimmerLoading(width: 60, height: 14, borderRadius: 4),
          ]),
        ),
      ))),
    );
  }
}

// Skeleton for payment screen
class ShimmerPayment extends StatelessWidget {
  const ShimmerPayment({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Step indicator
        Row(children: [
          ShimmerLoading(width: 24, height: 24, borderRadius: 12),
          Expanded(child: ShimmerLoading(height: 1)),
          ShimmerLoading(width: 24, height: 24, borderRadius: 12),
          Expanded(child: ShimmerLoading(height: 1)),
          ShimmerLoading(width: 24, height: 24, borderRadius: 12),
        ]),
        const SizedBox(height: 24),
        // Amount card
        ShimmerLoading(height: 140, borderRadius: 12),
        const SizedBox(height: 16),
        // Deadline
        ShimmerLoading(height: 48, borderRadius: 8),
        const SizedBox(height: 20),
        // Method label
        ShimmerLoading(height: 12, width: 100, borderRadius: 4),
        const SizedBox(height: 10),
        // Method toggle
        ShimmerLoading(height: 52, borderRadius: 10),
        const SizedBox(height: 28),
        // Button
        ShimmerLoading(height: 54, borderRadius: 12),
      ]),
    );
  }
}

// Skeleton for dashboard
class ShimmerDashboard extends StatelessWidget {
  const ShimmerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          ShimmerLoading(width: 100, height: 12, borderRadius: 4),
          Row(children: [
            ShimmerLoading(width: 36, height: 36, borderRadius: 18),
            const SizedBox(width: 8),
            ShimmerLoading(width: 36, height: 36, borderRadius: 18),
          ]),
        ]),
        const SizedBox(height: 28),
        // Date
        ShimmerLoading(width: 120, height: 10, borderRadius: 4),
        const SizedBox(height: 12),
        // Greeting
        ShimmerLoading(width: 200, height: 28, borderRadius: 6),
        const SizedBox(height: 6),
        ShimmerLoading(width: 140, height: 28, borderRadius: 6),
        const SizedBox(height: 28),
        // Info card
        ShimmerLoading(height: 72, borderRadius: 14),
        const SizedBox(height: 32),
        // Module
        ShimmerLoading(width: 80, height: 10, borderRadius: 4),
        const SizedBox(height: 12),
        ShimmerLoading(height: 64, borderRadius: 10),
        const SizedBox(height: 32),
        // Balance card
        ShimmerLoading(height: 140, borderRadius: 14),
      ]),
    );
  }
}

// Skeleton for history list
class ShimmerHistory extends StatelessWidget {
  final int count;
  const ShimmerHistory({super.key, this.count = 6});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(children: List.generate(count, (i) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(children: [
          ShimmerLoading(width: 40, height: 40, borderRadius: 10),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ShimmerLoading(height: 13, width: 140 + (i % 3 * 30).toDouble(), borderRadius: 4),
            const SizedBox(height: 6),
            ShimmerLoading(height: 10, width: 90, borderRadius: 4),
          ])),
          ShimmerLoading(width: 70, height: 13, borderRadius: 4),
        ]),
      ))),
    );
  }
}

// Legacy exports for backward compat
class ShimmerList extends StatelessWidget {
  final int count;
  final double itemHeight;
  const ShimmerList({super.key, this.count = 5, this.itemHeight = 70});

  @override
  Widget build(BuildContext context) => ShimmerFeeList(count: count);
}

class ShimmerCards extends StatelessWidget {
  const ShimmerCards({super.key});

  @override
  Widget build(BuildContext context) => const ShimmerDashboard();
}
