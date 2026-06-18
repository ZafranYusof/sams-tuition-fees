import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

// ─── Moon Design tokens ───
// Dark : gohan #1F1F1F (base)  ·  beerus #292929 (highlight)
// Light: bulma #F6F6F8 (base)  ·  goku  #FFFFFF (highlight)
class _MoonShimmer {
  static Color base(bool isDark) => isDark ? const Color(0xFF1F1F1F) : const Color(0xFFF6F6F8);
  static Color highlight(bool isDark) => isDark ? const Color(0xFF292929) : Colors.white;
}

class ShimmerLoading extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerLoading({super.key, this.width = double.infinity, this.height = 60, this.borderRadius = 12});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: _MoonShimmer.base(isDark),
      highlightColor: _MoonShimmer.highlight(isDark),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: _MoonShimmer.base(isDark),
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
// CONTENT-AWARE SKELETONS
// ──────────────────────────────────────────────────────────

/// Mirrors the fee breakdown card: vertical accent bar + 2 text lines + amount on the right.
class SkeletonFeeCard extends StatelessWidget {
  const SkeletonFeeCard({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final isDark = t.brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: _MoonShimmer.base(isDark),
      highlightColor: _MoonShimmer.highlight(isDark),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: t.cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: t.dividerColor),
        ),
        child: Row(
          children: [
            // Avatar / status circle
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: _MoonShimmer.base(isDark),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 14),
            // Two text lines
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(height: 13, width: 160, decoration: BoxDecoration(color: _MoonShimmer.base(isDark), borderRadius: BorderRadius.circular(4))),
                  const SizedBox(height: 8),
                  Container(height: 10, width: 96, decoration: BoxDecoration(color: _MoonShimmer.base(isDark), borderRadius: BorderRadius.circular(4))),
                ],
              ),
            ),
            const SizedBox(width: 14),
            // Amount
            Container(width: 64, height: 14, decoration: BoxDecoration(color: _MoonShimmer.base(isDark), borderRadius: BorderRadius.circular(4))),
          ],
        ),
      ),
    );
  }
}

/// Mirrors the dashboard stat tile / metric tile: icon circle + label + big number.
class SkeletonStatCard extends StatelessWidget {
  final double height;
  const SkeletonStatCard({super.key, this.height = 96});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final isDark = t.brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: _MoonShimmer.base(isDark),
      highlightColor: _MoonShimmer.highlight(isDark),
      child: Container(
        padding: const EdgeInsets.all(14),
        height: height,
        decoration: BoxDecoration(
          color: t.cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: t.dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Icon circle
            Container(
              width: 24, height: 24,
              decoration: BoxDecoration(
                color: _MoonShimmer.base(isDark),
                shape: BoxShape.circle,
              ),
            ),
            // Big number
            Container(height: 18, width: 86, decoration: BoxDecoration(color: _MoonShimmer.base(isDark), borderRadius: BorderRadius.circular(4))),
            // Label
            Container(height: 10, width: 60, decoration: BoxDecoration(color: _MoonShimmer.base(isDark), borderRadius: BorderRadius.circular(4))),
          ],
        ),
      ),
    );
  }
}

/// Mirrors transaction history row: icon block + 2 text lines + amount + status pill.
class SkeletonListItem extends StatelessWidget {
  const SkeletonListItem({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final isDark = t.brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: _MoonShimmer.base(isDark),
      highlightColor: _MoonShimmer.highlight(isDark),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: t.cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: t.dividerColor),
        ),
        child: Row(
          children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(color: _MoonShimmer.base(isDark), borderRadius: BorderRadius.circular(10)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(height: 13, width: 130, decoration: BoxDecoration(color: _MoonShimmer.base(isDark), borderRadius: BorderRadius.circular(4))),
                  const SizedBox(height: 6),
                  Container(height: 10, width: 90, decoration: BoxDecoration(color: _MoonShimmer.base(isDark), borderRadius: BorderRadius.circular(4))),
                ],
              ),
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Container(height: 14, width: 70, decoration: BoxDecoration(color: _MoonShimmer.base(isDark), borderRadius: BorderRadius.circular(4))),
              const SizedBox(height: 6),
              Container(height: 8, width: 48, decoration: BoxDecoration(color: _MoonShimmer.base(isDark), borderRadius: BorderRadius.circular(4))),
            ]),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
// LIST WRAPPERS — content-aware
// ──────────────────────────────────────────────────────────

/// Skeleton for fee list — uses [SkeletonFeeCard].
class ShimmerFeeList extends StatelessWidget {
  final int count;
  const ShimmerFeeList({super.key, this.count = 4});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        children: List.generate(count, (i) => const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: SkeletonFeeCard(),
        )),
      ),
    );
  }
}

/// Skeleton for history list — uses [SkeletonListItem].
class ShimmerHistory extends StatelessWidget {
  final int count;
  const ShimmerHistory({super.key, this.count = 6});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        children: List.generate(count, (i) => const SkeletonListItem()),
      ),
    );
  }
}

/// Skeleton for payment screen.
class ShimmerPayment extends StatelessWidget {
  const ShimmerPayment({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Step indicator
        Row(children: [
          ShimmerLoading(width: 24, height: 24, borderRadius: 12),
          Expanded(child: ShimmerLoading(height: 1)),
          ShimmerLoading(width: 24, height: 24, borderRadius: 12),
          Expanded(child: ShimmerLoading(height: 1)),
          ShimmerLoading(width: 24, height: 24, borderRadius: 12),
        ]),
        SizedBox(height: 24),
        ShimmerLoading(height: 140, borderRadius: 12),
        SizedBox(height: 16),
        ShimmerLoading(height: 48, borderRadius: 8),
        SizedBox(height: 20),
        ShimmerLoading(height: 12, width: 100, borderRadius: 4),
        SizedBox(height: 10),
        ShimmerLoading(height: 52, borderRadius: 10),
        SizedBox(height: 28),
        ShimmerLoading(height: 54, borderRadius: 12),
      ]),
    );
  }
}

/// Skeleton for the home dashboard — content-aware: header strip, greeting,
/// stat grid, balance card, fee list rows.
class ShimmerDashboard extends StatelessWidget {
  const ShimmerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final isDark = t.brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Shimmer.fromColors(
            baseColor: _MoonShimmer.base(isDark),
            highlightColor: _MoonShimmer.highlight(isDark),
            child: Container(width: 120, height: 12, decoration: BoxDecoration(color: _MoonShimmer.base(isDark), borderRadius: BorderRadius.circular(4))),
          ),
          const Row(children: [
            ShimmerLoading(width: 36, height: 36, borderRadius: 18),
            SizedBox(width: 8),
            ShimmerLoading(width: 36, height: 36, borderRadius: 18),
          ]),
        ]),
        const SizedBox(height: 24),
        // Hero text
        const ShimmerLoading(width: 220, height: 28, borderRadius: 6),
        const SizedBox(height: 8),
        const ShimmerLoading(width: 140, height: 28, borderRadius: 6),
        const SizedBox(height: 24),
        // Balance / info card
        const ShimmerLoading(height: 96, borderRadius: 14),
        const SizedBox(height: 20),
        // 2x2 stat grid
        const Row(children: [
          Expanded(child: SkeletonStatCard()),
          SizedBox(width: 10),
          Expanded(child: SkeletonStatCard()),
        ]),
        const SizedBox(height: 10),
        const Row(children: [
          Expanded(child: SkeletonStatCard()),
          SizedBox(width: 10),
          Expanded(child: SkeletonStatCard()),
        ]),
        const SizedBox(height: 24),
        // Fee section title
        const ShimmerLoading(width: 120, height: 14, borderRadius: 4),
        const SizedBox(height: 12),
        const SkeletonFeeCard(),
        const SizedBox(height: 10),
        const SkeletonFeeCard(),
        const SizedBox(height: 10),
        const SkeletonFeeCard(),
      ]),
    );
  }
}

// ──────────────────────────────────────────────────────────
// LEGACY EXPORTS — back-compat
// ──────────────────────────────────────────────────────────

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
