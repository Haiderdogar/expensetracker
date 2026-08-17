import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../core/constants/app_colors.dart';

class ShimmerLoader extends StatelessWidget {
  const ShimmerLoader({
    super.key,
    this.height = 80,
    this.width,
    this.borderRadius = 16,
  });

  final double height;
  final double? width;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? AppColors.deepForest : AppColors.gray200;
    final highlight = isDark ? AppColors.gray600 : AppColors.gray100;

    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: Container(
        height: height,
        width: width ?? double.infinity,
        decoration: BoxDecoration(
          color: base,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

class ShimmerList extends StatelessWidget {
  const ShimmerList({super.key, this.itemCount = 5, this.itemHeight = 72});

  final int itemCount;
  final double itemHeight;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        itemCount,
        (i) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: ShimmerLoader(height: itemHeight, borderRadius: 12),
        ),
      ),
    );
  }
}
