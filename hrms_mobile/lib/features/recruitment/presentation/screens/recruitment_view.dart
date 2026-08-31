import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/status_badge.dart';

class RecruitmentView extends StatelessWidget {
  const RecruitmentView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Recruitment & Interviews'),
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Pipeline Summary
            const Text('Hiring Pipeline', style: AppTextStyles.h3),
            const SizedBox(height: AppSpacing.sm),
            const Row(
              children: [
                Expanded(
                  child: _RecruitmentStatCard(
                    title: 'Active Jobs',
                    value: '6 Openings',
                    color: AppColors.info,
                  ),
                ),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _RecruitmentStatCard(
                    title: 'Candidates',
                    value: '34 Profiles',
                    color: AppColors.purple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // Upcoming Interviews
            const Text('Scheduled Interviews', style: AppTextStyles.h3),
            const SizedBox(height: AppSpacing.sm),

            _buildInterviewItem(
              candidateName: 'Alex Mercer',
              role: 'Senior Flutter Architect',
              stage: 'Technical Round 2',
              time: 'Tomorrow at 10:30 AM',
            ),
            const SizedBox(height: AppSpacing.sm),
            _buildInterviewItem(
              candidateName: 'Sophia Lin',
              role: 'Product Designer (UI/UX)',
              stage: 'Portfolio Review',
              time: 'Aug 31 at 02:00 PM',
            ),
            const SizedBox(height: AppSpacing.sm),
            _buildInterviewItem(
              candidateName: 'Marcus Wright',
              role: 'Lead Backend Engineer (NestJS)',
              stage: 'Executive Management',
              time: 'Sep 02 at 04:30 PM',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInterviewItem({
    required String candidateName,
    required String role,
    required String stage,
    required String time,
  }) {
    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primaryLight,
                child: Text(
                  candidateName[0],
                  style: AppTextStyles.bodyBold.copyWith(color: AppColors.primary),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(candidateName, style: AppTextStyles.bodyBold),
                  const SizedBox(height: 2),
                  Text('$role • $stage', style: AppTextStyles.caption),
                  const SizedBox(height: 2),
                  Text(time, style: AppTextStyles.captionBold.copyWith(color: AppColors.primary, fontSize: 10)),
                ],
              ),
            ],
          ),
          const StatusBadge(label: 'Scheduled', type: StatusBadgeType.warning),
        ],
      ),
    );
  }
}

class _RecruitmentStatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _RecruitmentStatCard({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
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
          Text(title, style: AppTextStyles.caption),
          const SizedBox(height: AppSpacing.xs),
          Text(value, style: AppTextStyles.h2.copyWith(color: color)),
        ],
      ),
    );
  }
}
