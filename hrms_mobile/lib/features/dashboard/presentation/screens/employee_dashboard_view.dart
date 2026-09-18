import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/empty_state_card.dart';
import '../../../../core/widgets/loading_skeleton.dart';
import '../../../../core/widgets/mobile_header_widget.dart';
import '../../../asset/presentation/screens/my_assets_view.dart';
import '../../../attendance/presentation/widgets/attendance_header_widget.dart';
import '../../../attendance/presentation/widgets/weekly_attendance_card.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../leave/presentation/screens/leave_dashboard_view.dart';
import '../../../payroll/presentation/screens/payroll_overview_view.dart';
import '../../../payroll/presentation/widgets/payroll_period_card.dart';
import '../../../shift/presentation/screens/shift_roster_view.dart';
import '../widgets/dashboard_kpis.dart';
import '../widgets/quick_action_grid.dart';
import '../widgets/upcoming_holidays_card.dart';

class EmployeeDashboardView extends ConsumerWidget {
  const EmployeeDashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payslipsAsync = ref.watch(payslipsListProvider);
    final leaveBalancesAsync = ref.watch(leaveBalancesProvider);
    final assetsAsync = ref.watch(myAssetsProvider);
    final todayShiftAsync = ref.watch(todayShiftProvider);
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;

    final totalLeaveRemaining = leaveBalancesAsync.when(
      data: (balances) => balances.fold<double>(0.0, (sum, b) => sum + b.remaining).toInt().toString(),
      loading: () => '...',
      error: (_, __) => '--',
    );

    final assignedAssetsCount = assetsAsync.when(
      data: (assets) => '${assets.length} Devices',
      loading: () => '...',
      error: (_, __) => '--',
    );

    final shiftText = todayShiftAsync.when(
      data: (shift) => shift != null ? '${shift.startTime} - ${shift.endTime}' : 'Standard Shift',
      loading: () => '...',
      error: (_, __) => 'General Shift',
    );

    final departmentText = user?.department != null && user!.department!.isNotEmpty
        ? user.department!
        : 'Enterprise HQ';

    final quickActions = [
      const QuickActionItem(
        title: 'Apply Leave',
        icon: Icons.event_available_outlined,
        route: '/leave',
        color: AppColors.info,
      ),
      const QuickActionItem(
        title: 'My Payslips',
        icon: Icons.receipt_long_outlined,
        route: '/payroll',
        color: AppColors.success,
      ),
      const QuickActionItem(
        title: 'Support Desk',
        icon: Icons.support_agent_rounded,
        route: '/helpdesk',
        color: AppColors.primary,
      ),
      const QuickActionItem(
        title: 'My Assets',
        icon: Icons.laptop_chromebook,
        route: '/assets',
        color: AppColors.purple,
      ),
      const QuickActionItem(
        title: 'Shift Roster',
        icon: Icons.schedule_rounded,
        route: '/shifts',
        color: Color(0xFFF59E0B),
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const MobileHeaderWidget(),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(payslipsListProvider);
          ref.invalidate(leaveBalancesProvider);
          ref.invalidate(myAssetsProvider);
          ref.invalidate(todayShiftProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: AppSpacing.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Live Jibble-Style Face Biometric Attendance Action Card
              const AttendanceHeaderWidget(),
              const SizedBox(height: AppSpacing.lg),

              // 2. Upcoming Holidays / Announcements
              const UpcomingHolidaysCard(),
              const SizedBox(height: AppSpacing.lg),

              // 3. Weekly Attendance Trends
              const WeeklyAttendanceCard(),
              const SizedBox(height: AppSpacing.lg),

              // 4. Quick Actions
              const Text('Quick Services', style: AppTextStyles.h3),
              const SizedBox(height: AppSpacing.sm),
              QuickActionGrid(items: quickActions),
              const SizedBox(height: AppSpacing.lg),

              // 5. Recent Payroll Period Card
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Payroll Overview', style: AppTextStyles.h3),
                  Text(
                    'Active Period',
                    style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              payslipsAsync.when(
                loading: () => Container(
                  height: 120,
                  padding: AppSpacing.cardPadding,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          LoadingSkeleton(width: 120, height: 16),
                          LoadingSkeleton(width: 70, height: 20, borderRadius: 10),
                        ],
                      ),
                      LoadingSkeleton(width: 180, height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          LoadingSkeleton(width: 90, height: 14),
                          LoadingSkeleton(width: 80, height: 14),
                        ],
                      ),
                    ],
                  ),
                ),
                error: (e, _) => const EmptyStateCard(
                  icon: Icons.receipt_long_outlined,
                  title: 'No Payslip Records Available',
                  subtitle: 'Published monthly payslips will appear here once processed.',
                ),
                data: (payslips) {
                  if (payslips.isEmpty) {
                    return const EmptyStateCard(
                      icon: Icons.receipt_long_outlined,
                      title: 'No Published Payslips',
                      subtitle: 'Your confidential monthly payslips will appear here once generated.',
                    );
                  }
                  return PayrollPeriodCard(payslip: payslips.first);
                },
              ),
              const SizedBox(height: AppSpacing.lg),

              // 6. Overview & Quotas
              const Text('Overview & Quotas', style: AppTextStyles.h3),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: DashboardKpiCard(
                      label: 'Leave Balance',
                      value: '$totalLeaveRemaining Days',
                      icon: Icons.beach_access_rounded,
                      iconColor: AppColors.info,
                      iconBgColor: AppColors.infoLight,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: DashboardKpiCard(
                      label: 'Assigned Assets',
                      value: assignedAssetsCount,
                      icon: Icons.laptop_mac_rounded,
                      iconColor: AppColors.purple,
                      iconBgColor: AppColors.purpleLight,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: DashboardKpiCard(
                      label: 'Shift Timing',
                      value: shiftText,
                      icon: Icons.schedule_rounded,
                      iconColor: AppColors.primary,
                      iconBgColor: AppColors.primaryLight,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: DashboardKpiCard(
                      label: 'Department',
                      value: departmentText,
                      icon: Icons.business_rounded,
                      iconColor: AppColors.success,
                      iconBgColor: AppColors.successLight,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}
