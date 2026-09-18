import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/empty_state_card.dart';
import '../../../../core/widgets/loading_skeleton.dart';
import '../../../leave/data/leave_repository.dart';
import '../../../leave/domain/models/leave_model.dart';

class UpcomingHolidaysCard extends ConsumerWidget {
  const UpcomingHolidaysCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final upcomingAsync = ref.watch(upcomingHolidaysProvider);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.xs + 2),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(color: AppColors.primaryBorder),
                    ),
                    child: const Icon(
                      Icons.event_note_rounded,
                      size: 18,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Upcoming Holidays',
                        style: AppTextStyles.h3,
                      ),
                      Text(
                        'Next 3 official leaves',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              InkWell(
                onTap: () => context.push('/leave'),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View All',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Content List
          upcomingAsync.when(
            loading: () => Column(
              children: List.generate(
                2,
                (index) => const Padding(
                  padding: EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Row(
                    children: [
                      LoadingSkeleton(width: 44, height: 44, borderRadius: 12),
                      SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            LoadingSkeleton(width: 140, height: 14),
                            SizedBox(height: 6),
                            LoadingSkeleton(width: 80, height: 11),
                          ],
                        ),
                      ),
                      LoadingSkeleton(width: 50, height: 20, borderRadius: 10),
                    ],
                  ),
                ),
              ),
            ),
            error: (_, __) => const EmptyStateCard(
              icon: Icons.calendar_month_outlined,
              title: 'No Upcoming Holidays',
              subtitle: 'No scheduled public holidays for the current period.',
              verticalPadding: 16,
            ),
            data: (holidays) {
              if (holidays.isEmpty) {
                return const EmptyStateCard(
                  icon: Icons.calendar_month_outlined,
                  title: 'No Upcoming Holidays',
                  subtitle: 'No scheduled public holidays for the current period.',
                  verticalPadding: 16,
                );
              }
              return Column(
                children: holidays
                    .map((h) => _buildHolidayItem(context, h))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHolidayItem(BuildContext context, HolidayModel holiday) {
    final monthStr = DateFormat('MMM').format(holiday.startDate).toUpperCase();
    final dayStr = DateFormat('dd').format(holiday.startDate);
    final weekdayStr = DateFormat('EEEE').format(holiday.startDate);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.8)),
      ),
      child: Row(
        children: [
          // Date Badge Container
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: AppColors.primaryBorder),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  monthStr,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                    letterSpacing: 0.5,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  dayStr,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm + 4),

          // Title & Weekday info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  holiday.name,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      weekdayStr,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text('•', style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.successLight,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Public Holiday',
                        style: AppTextStyles.caption.copyWith(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
