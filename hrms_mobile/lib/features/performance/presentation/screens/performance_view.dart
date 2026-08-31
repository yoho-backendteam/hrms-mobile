import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/status_badge.dart';

class PerformanceView extends StatelessWidget {
  const PerformanceView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Performance & OKRs'),
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Overall Rating Card
            Container(
              padding: AppSpacing.cardPadding,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Current Review Period (Q3 2026)', style: AppTextStyles.caption),
                      StatusBadge.fromStatus('EXCEEDING_EXPECTATIONS'),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const Text('4.8 / 5.0', style: AppTextStyles.display),
                  const SizedBox(height: 2),
                  const Text('Outstanding Performance Rating', style: AppTextStyles.bodyBold),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Active OKRs
            const Text('Active Key Objectives (OKRs)', style: AppTextStyles.h3),
            const SizedBox(height: AppSpacing.sm),

            _buildOkrCard(
              title: 'Deliver HRMS Face Recognition Attendance Architecture',
              progress: 0.95,
              status: '95% Complete',
            ),
            const SizedBox(height: AppSpacing.sm),
            _buildOkrCard(
              title: 'Enterprise Multi-Tenant Mobile Flutter Implementation',
              progress: 0.90,
              status: '90% Complete',
            ),
            const SizedBox(height: AppSpacing.sm),
            _buildOkrCard(
              title: 'Achieve 99.9% Attendance Service SLA & Zero Downtime',
              progress: 1.0,
              status: '100% Achieved',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOkrCard({
    required String title,
    required double progress,
    required String status,
  }) {
    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.bodyBold),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: AppColors.surfaceMuted,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(status, style: AppTextStyles.captionBold.copyWith(color: AppColors.primary)),
              const Text('Target: End of Q3', style: AppTextStyles.caption),
            ],
          ),
        ],
      ),
    );
  }
}
