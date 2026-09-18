import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';

/// Modern Shimmer/Pulse Animated Loading Skeleton Element
class LoadingSkeleton extends StatefulWidget {
  final double? width;
  final double height;
  final double borderRadius;

  const LoadingSkeleton({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = AppSpacing.radiusSm,
  });

  @override
  State<LoadingSkeleton> createState() => _LoadingSkeletonState();
}

class _LoadingSkeletonState extends State<LoadingSkeleton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.4, end: 0.9).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: Color.lerp(
              const Color(0xFFF1F5F9), // Slate 100
              const Color(0xFFE2E8F0), // Slate 200
              _animation.value,
            ),
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
        );
      },
    );
  }
}

/// Circular Shimmer Placeholder for User Avatars & Icons
class SkeletonAvatar extends StatelessWidget {
  final double size;

  const SkeletonAvatar({super.key, this.size = 40.0});

  @override
  Widget build(BuildContext context) {
    return LoadingSkeleton(
      width: size,
      height: size,
      borderRadius: size / 2,
    );
  }
}

/// Structured Card Skeleton for Contextual Screens
class SkeletonCard extends StatelessWidget {
  final double height;
  final Widget? child;

  const SkeletonCard({super.key, this.height = 100.0, this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: child ??
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              LoadingSkeleton(width: 140, height: 16),
              LoadingSkeleton(width: double.infinity, height: 12),
              LoadingSkeleton(width: 200, height: 12),
            ],
          ),
    );
  }
}

/// Multi-row List Skeleton
class ListLoadingSkeleton extends StatelessWidget {
  final int count;

  const ListLoadingSkeleton({super.key, this.count = 4});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: count,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (_, __) => const SkeletonCard(),
    );
  }
}
