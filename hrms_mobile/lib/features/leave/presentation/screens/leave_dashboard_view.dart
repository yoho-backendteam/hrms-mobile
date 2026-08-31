import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/permissions/permission_provider.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/widgets/loading_skeleton.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../data/leave_repository.dart';
import '../../domain/models/leave_model.dart';
import '../widgets/leave_request_detail_modal.dart';
import 'apply_leave_bottom_sheet.dart';

final leaveBalancesProvider =
    FutureProvider.autoDispose<List<LeaveBalanceModel>>((ref) async {
  return ref.watch(leaveRepositoryProvider).getBalances();
});

final leaveMyRequestsProvider =
    FutureProvider.autoDispose<List<LeaveRequestModel>>((ref) async {
  return ref.watch(leaveRepositoryProvider).getMyRequests();
});

final leavePendingApprovalsProvider =
    FutureProvider.autoDispose<List<LeaveRequestModel>>((ref) async {
  return ref.watch(leaveRepositoryProvider).getPendingApprovals();
});

class LeaveDashboardView extends ConsumerWidget {
  const LeaveDashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isHR = ref.watch(isHRorAdminProvider);
    final balancesAsync = ref.watch(leaveBalancesProvider);
    final myRequestsAsync = ref.watch(leaveMyRequestsProvider);
    final approvalsAsync = ref.watch(leavePendingApprovalsProvider);
    final holidaysAsync = ref.watch(holidaysListProvider);

    final tabCount = isHR ? 3 : 2;

    return DefaultTabController(
      length: tabCount,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Leave Management'),
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                ref.invalidate(leaveBalancesProvider);
                ref.invalidate(leaveMyRequestsProvider);
                ref.invalidate(leavePendingApprovalsProvider);
                ref.invalidate(holidaysListProvider);
              },
            ),
          ],
          bottom: TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            labelStyle: AppTextStyles.bodyBold.copyWith(fontSize: 13),
            unselectedLabelStyle: AppTextStyles.body.copyWith(fontSize: 13),
            tabs: [
              const Tab(text: 'My Leaves'),
              const Tab(text: 'Holidays'),
              if (isHR) const Tab(text: 'Approvals'),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Request Leave', style: TextStyle(fontWeight: FontWeight.bold)),
          onPressed: () {
            ApplyLeaveBottomSheet.show(
              context,
              onSuccess: () => ref.invalidate(leaveMyRequestsProvider),
            );
          },
        ),
        body: TabBarView(
          children: [
            // TAB 1: My Leaves
            RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async {
                ref.invalidate(leaveBalancesProvider);
                ref.invalidate(leaveMyRequestsProvider);
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: AppSpacing.screenPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Quota Cards Section (Horizontal Scrollable)
                    const Text('Your Available Quotas', style: AppTextStyles.h3),
                    const SizedBox(height: AppSpacing.sm),
                    balancesAsync.when(
                      loading: () => const ListLoadingSkeleton(count: 2),
                      error: (e, _) => Container(
                        padding: AppSpacing.cardPadding,
                        decoration: BoxDecoration(
                          color: AppColors.errorLight,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        ),
                        child: Text('Unable to load leave quotas: $e', style: AppTextStyles.caption),
                      ),
                      data: (balances) {
                        if (balances.isEmpty) {
                          return Container(
                            padding: AppSpacing.cardPadding,
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: const Text(
                              'No leave quotas allocated yet for this period.',
                              style: AppTextStyles.caption,
                            ),
                          );
                        }

                        return SizedBox(
                          height: 96,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: balances.length,
                            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
                            itemBuilder: (context, index) {
                              final b = balances[index];
                              return Container(
                                width: 135,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                                  border: Border.all(color: AppColors.border),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.02),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      b.leaveType,
                                      style: AppTextStyles.caption.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textSecondary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '${b.remaining.toInt()} Left',
                                      style: AppTextStyles.h2.copyWith(color: AppColors.primary, fontSize: 17),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${b.used.toInt()} of ${b.totalAllocated.toInt()} days',
                                      style: AppTextStyles.caption.copyWith(fontSize: 10, color: AppColors.textMuted),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // My Leave Requests Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('My Leave Requests', style: AppTextStyles.h2),
                        TextButton(
                          onPressed: () => ref.invalidate(leaveMyRequestsProvider),
                          child: const Text('Refresh'),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    // My Requests List
                    myRequestsAsync.when(
                      loading: () => const ListLoadingSkeleton(count: 3),
                      error: (e, _) => Container(
                        padding: AppSpacing.cardPadding,
                        decoration: BoxDecoration(
                          color: AppColors.errorLight,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        ),
                        child: Text('Unable to load leave requests: $e', style: AppTextStyles.caption),
                      ),
                      data: (requests) {
                        if (requests.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 32),
                            child: EmptyStateView(
                              icon: Icons.event_busy_outlined,
                              title: 'No Leave Requests',
                              description: 'You have not submitted any leave requests yet.',
                            ),
                          );
                        }

                        return ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: requests.length,
                          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
                          itemBuilder: (context, index) {
                            final req = requests[index];
                            return _buildLeaveRequestCard(context, req);
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 80), // Extra padding for FAB
                  ],
                ),
              ),
            ),

            // TAB 2: Holidays List
            RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async {
                ref.invalidate(holidaysListProvider);
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: AppSpacing.screenPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Summary Banner Card
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            AppColors.primaryLight,
                            AppColors.surface,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                        border: Border.all(color: AppColors.primaryBorder),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.sm),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                            ),
                            child: const Icon(
                              Icons.calendar_month_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Official Company Holidays',
                                  style: AppTextStyles.h3,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Calendar year public and regional holidays',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Holidays List
                    holidaysAsync.when(
                      loading: () => const ListLoadingSkeleton(count: 4),
                      error: (e, _) => Container(
                        padding: AppSpacing.cardPadding,
                        decoration: BoxDecoration(
                          color: AppColors.errorLight,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        ),
                        child: Text('Unable to load holidays: $e', style: AppTextStyles.caption),
                      ),
                      data: (holidays) {
                        if (holidays.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 32),
                            child: EmptyStateView(
                              icon: Icons.event_available_outlined,
                              title: 'No Holidays Configured',
                              description: 'No official holidays are listed for this calendar period.',
                            ),
                          );
                        }

                        final now = DateTime.now();
                        final today = DateTime(now.year, now.month, now.day);

                        return ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: holidays.length,
                          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                          itemBuilder: (context, index) {
                            final holiday = holidays[index];
                            final isPast = holiday.startDate.isBefore(today);
                            return _buildHolidayFullCard(context, holiday, isPast: isPast);
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),

            // TAB 3: Approvals (HR Only)
            if (isHR)
              RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () async {
                  ref.invalidate(leavePendingApprovalsProvider);
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: AppSpacing.screenPadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Pending Approvals', style: AppTextStyles.h2),
                          TextButton(
                            onPressed: () => ref.invalidate(leavePendingApprovalsProvider),
                            child: const Text('Refresh'),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      approvalsAsync.when(
                        loading: () => const ListLoadingSkeleton(count: 2),
                        error: (e, _) => Text('Error loading approvals: $e', style: AppTextStyles.caption),
                        data: (approvals) {
                          if (approvals.isEmpty) {
                            return Container(
                              padding: AppSpacing.cardPadding,
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.check_circle_outline, color: AppColors.success, size: 20),
                                  SizedBox(width: AppSpacing.sm),
                                  Text('All employee leave requests reviewed!', style: AppTextStyles.body),
                                ],
                              ),
                            );
                          }

                          return ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: approvals.length,
                            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                            itemBuilder: (context, index) {
                              final item = approvals[index];
                              return _buildApprovalCard(context, ref, item);
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHolidayFullCard(BuildContext context, HolidayModel holiday, {required bool isPast}) {
    final monthStr = DateFormat('MMM').format(holiday.startDate).toUpperCase();
    final dayStr = DateFormat('dd').format(holiday.startDate);
    final weekdayStr = DateFormat('EEEE').format(holiday.startDate);
    final fullDateStr = DateFormat('MMMM d, yyyy').format(holiday.startDate);

    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: isPast ? AppColors.border : AppColors.primaryBorder.withValues(alpha: 0.7),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date Badge
          Container(
            width: 48,
            height: 52,
            decoration: BoxDecoration(
              color: isPast ? AppColors.surfaceMuted : AppColors.primaryLight,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(
                color: isPast ? AppColors.border : AppColors.primaryBorder,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  monthStr,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: isPast ? AppColors.textMuted : AppColors.primary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  dayStr,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: isPast ? AppColors.textSecondary : AppColors.primary,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        holiday.name,
                        style: AppTextStyles.bodyBold.copyWith(
                          color: isPast ? AppColors.textSecondary : AppColors.textPrimary,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: isPast ? AppColors.surfaceMuted : AppColors.successLight,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: isPast ? AppColors.border : AppColors.successBorder,
                        ),
                      ),
                      child: Text(
                        isPast ? 'Past' : 'Public Holiday',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isPast ? AppColors.textMuted : AppColors.success,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.event_outlined,
                      size: 13,
                      color: isPast ? AppColors.textMuted : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$weekdayStr, $fullDateStr',
                      style: AppTextStyles.caption.copyWith(
                        color: isPast ? AppColors.textMuted : AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                if (holiday.description != null && holiday.description!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    holiday.description!,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaveRequestCard(BuildContext context, LeaveRequestModel req) {
    final dateFormat = DateFormat('MMM d');
    final dateRange = req.startDate.day == req.endDate.day && req.startDate.month == req.endDate.month
        ? DateFormat('MMM d, yyyy').format(req.startDate)
        : '${dateFormat.format(req.startDate)} - ${DateFormat('MMM d, yyyy').format(req.endDate)}';

    return InkWell(
      onTap: () => LeaveRequestDetailModal.show(context: context, request: req),
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: Container(
        padding: AppSpacing.cardPadding,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    req.leaveType,
                    style: AppTextStyles.bodyBold.copyWith(fontSize: 15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                StatusBadge.fromStatus(req.status),
              ],
            ),
            const SizedBox(height: AppSpacing.xs + 2),
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 13, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(dateRange, style: AppTextStyles.caption),
                const SizedBox(width: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${req.totalDays.toInt()} ${req.totalDays == 1 ? "Day" : "Days"}',
                    style: AppTextStyles.captionBold.copyWith(color: AppColors.primary, fontSize: 10),
                  ),
                ),
              ],
            ),
            if (req.reason.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                req.reason,
                style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildApprovalCard(BuildContext context, WidgetRef ref, LeaveRequestModel item) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  item.employeeName,
                  style: AppTextStyles.bodyBold,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text('${item.totalDays.toInt()}d (${item.leaveType})', style: AppTextStyles.captionBold),
            ],
          ),
          const SizedBox(height: 4),
          Text(item.reason, style: AppTextStyles.caption),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                  ),
                  onPressed: () async {
                    await ref.read(leaveRepositoryProvider).rejectLeave(item.id, 'Declined by HR');
                    ref.invalidate(leavePendingApprovalsProvider);
                  },
                  child: const Text('Reject'),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    await ref.read(leaveRepositoryProvider).approveLeave(item.id);
                    ref.invalidate(leavePendingApprovalsProvider);
                  },
                  child: const Text('Approve'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
