import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class SkeletonLoading extends StatelessWidget {
  const SkeletonLoading({
    super.key,
    this.child,
    this.itemCount,
    this.height = 80,
  });

  final Widget? child;
  final int? itemCount;
  final double height;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
    final highlightColor = isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9);

    final content = child ??
        Column(
          children: List.generate(
            itemCount ?? 3,
            (index) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              width: double.infinity,
              height: height,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        );

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: content,
    );
  }
}

class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  final double width;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonLoading(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                SkeletonBox(width: 140, height: 24),
                Spacer(),
                SkeletonBox(width: 80, height: 24),
              ],
            ),
            const SizedBox(height: 16),
            const SkeletonBox(width: double.infinity, height: 120, borderRadius: 14),
            const SizedBox(height: 16),
            Row(
              children: const [
                Expanded(child: SkeletonBox(width: double.infinity, height: 90, borderRadius: 14)),
                SizedBox(width: 12),
                Expanded(child: SkeletonBox(width: double.infinity, height: 90, borderRadius: 14)),
              ],
            ),
            const SizedBox(height: 16),
            const SkeletonBox(width: double.infinity, height: 180, borderRadius: 14),
          ],
        ),
      ),
    );
  }
}
