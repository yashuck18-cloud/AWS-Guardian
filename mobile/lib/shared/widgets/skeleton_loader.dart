import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme/app_colors.dart';

class SkeletonLoader extends StatelessWidget {
  final double? width;
  final double height;
  final double borderRadius;

  const SkeletonLoader({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surfaceElevated,
      highlightColor: AppColors.surfaceElevated2,
      child: Container(
        width: width ?? double.infinity,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      physics: NeverScrollableScrollPhysics(),
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonLoader(height: 60, borderRadius: 12),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: SkeletonLoader(height: 90, borderRadius: 14)),
              SizedBox(width: 12),
              Expanded(child: SkeletonLoader(height: 90, borderRadius: 14)),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: SkeletonLoader(height: 90, borderRadius: 14)),
              SizedBox(width: 12),
              Expanded(child: SkeletonLoader(height: 90, borderRadius: 14)),
            ],
          ),
          SizedBox(height: 20),
          SkeletonLoader(height: 200, borderRadius: 16),
          SizedBox(height: 20),
          SkeletonLoader(height: 180, borderRadius: 16),
        ],
      ),
    );
  }
}

class ListSkeletonLoader extends StatelessWidget {
  final int count;
  const ListSkeletonLoader({super.key, this.count = 5});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: count,
      padding: const EdgeInsets.all(16),
      physics: const NeverScrollableScrollPhysics(),
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => const SkeletonLoader(
        height: 80,
        borderRadius: 14,
      ),
    );
  }
}
