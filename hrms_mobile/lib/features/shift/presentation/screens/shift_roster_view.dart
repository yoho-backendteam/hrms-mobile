import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/loading_skeleton.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../data/shift_repository.dart';
import '../../domain/models/shift_model.dart';

final assignedShiftsProvider =
    FutureProvider.autoDispose<List<ShiftModel>>((ref) async {
  return ref.watch(shiftRepositoryProvider).getAssignedShifts();
});

class ShiftRosterView extends ConsumerWidget {
  const ShiftRosterView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shiftsAsync = ref.watch(assignedShiftsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Shift Schedule & Roster'),
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Current Active Shift Highlight
            Container(
              padding: AppSpacing.cardPadding,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Assigned Working Shift',
                        style: AppTextStyles.captionBold.copyWith(color: AppColors.primary),
                      ),
                      const StatusBadge(label: 'Standard', type: StatusBadgeType.info),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const Text('General Day Shift', style: AppTextStyles.h1),
                  const SizedBox(height: AppSpacing.xs),
                  const Row(
                    children: [
                      Icon(Icons.schedule, size: 16, color: AppColors.textSecondary),
                      SizedBox(width: AppSpacing.xs),
                      Text('09:00 AM — 06:00 PM (9 Hours)', style: AppTextStyles.bodyMedium),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text('Grace Period: 15 minutes • Break Duration: 60 minutes',
                      style: AppTextStyles.caption.copyWith(fontSize: 10)),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Weekly Schedule View
            const Text('Weekly Shift Schedule', style: AppTextStyles.h3),
            const SizedBox(height: AppSpacing.sm),

            shiftsAsync.when(
              loading: () => const ListLoadingSkeleton(count: 3),
              error: (e, _) => Text('Error loading shifts: $e', style: AppTextStyles.caption),
              data: (shifts) {
                final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: days.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final day = days[index];
                    final isWeekend = day == 'Saturday' || day == 'Sunday';

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
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(day, style: AppTextStyles.bodyBold),
                              const SizedBox(height: 2),
                              Text(
                                isWeekend ? 'Weekly Off' : '09:00 AM — 06:00 PM',
                                style: AppTextStyles.caption.copyWith(
                                  color: isWeekend ? AppColors.warning : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          StatusBadge(
                            label: isWeekend ? 'Off' : 'Working',
                            type: isWeekend ? StatusBadgeType.warning : StatusBadgeType.success,
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
