import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/empty_state_card.dart';
import '../../../../core/widgets/loading_skeleton.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../data/shift_repository.dart';
import '../../domain/models/shift_model.dart';

final assignedShiftsProvider =
    FutureProvider.autoDispose<List<ShiftModel>>((ref) async {
  return ref.watch(shiftRepositoryProvider).getAssignedShifts();
});

final todayShiftProvider =
    FutureProvider.autoDispose<ShiftModel?>((ref) async {
  return ref.watch(shiftRepositoryProvider).getTodayShift();
});

class ShiftRosterView extends ConsumerWidget {
  const ShiftRosterView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shiftsAsync = ref.watch(assignedShiftsProvider);
    final todayShiftAsync = ref.watch(todayShiftProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Shift Schedule & Roster'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(assignedShiftsProvider);
              ref.invalidate(todayShiftProvider);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Current Active Shift Highlight
            todayShiftAsync.when(
              loading: () => const SkeletonCard(height: 120),
              error: (_, __) => const EmptyStateCard(
                icon: Icons.schedule_rounded,
                title: 'No Shift Assigned for Today',
                subtitle: 'Contact your team lead or HR administrator to assign your working schedule.',
              ),
              data: (shift) {
                if (shift == null) {
                  return const EmptyStateCard(
                    icon: Icons.schedule_rounded,
                    title: 'No Shift Assigned for Today',
                    subtitle: 'Standard working hours will apply unless otherwise scheduled.',
                  );
                }

                return Container(
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
                          StatusBadge(
                            label: shift.isDefault ? 'Standard' : 'Scheduled',
                            type: StatusBadgeType.info,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(shift.name, style: AppTextStyles.h1),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          const Icon(Icons.schedule, size: 16, color: AppColors.textSecondary),
                          const SizedBox(width: AppSpacing.xs),
                          Text('${shift.startTime} — ${shift.endTime}', style: AppTextStyles.bodyMedium),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.xl),

            // Weekly Schedule View
            const Text('Weekly Shift Schedule', style: AppTextStyles.h3),
            const SizedBox(height: AppSpacing.sm),

            shiftsAsync.when(
              loading: () => const ListLoadingSkeleton(count: 3),
              error: (e, _) => EmptyStateCard(
                icon: Icons.event_busy_outlined,
                title: 'Unable to Load Shifts',
                subtitle: e.toString().replaceAll('Exception:', '').trim(),
              ),
              data: (shifts) {
                if (shifts.isEmpty) {
                  return const EmptyStateCard(
                    icon: Icons.calendar_month_outlined,
                    title: 'No Assigned Shifts in Roster',
                    subtitle: 'You are currently on standard organization schedule.',
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: shifts.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final item = shifts[index];
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
                              Text(item.name, style: AppTextStyles.bodyBold),
                              const SizedBox(height: 2),
                              Text('${item.startTime} — ${item.endTime}', style: AppTextStyles.caption),
                            ],
                          ),
                          StatusBadge(
                            label: item.isDefault ? 'Default' : 'Active',
                            type: item.isDefault ? StatusBadgeType.neutral : StatusBadgeType.success,
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
