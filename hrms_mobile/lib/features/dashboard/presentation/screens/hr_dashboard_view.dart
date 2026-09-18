import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/mobile_header_widget.dart';
import '../../../attendance/presentation/widgets/attendance_header_widget.dart';
import '../../../attendance/presentation/widgets/weekly_attendance_card.dart';
import '../../../employee/presentation/screens/employee_list_view.dart';
import '../../../leave/data/leave_repository.dart';
import '../../../leave/presentation/screens/leave_dashboard_view.dart';
import '../widgets/dashboard_kpis.dart';
import '../widgets/quick_action_grid.dart';
import '../widgets/upcoming_holidays_card.dart';

class HrDashboardView extends ConsumerWidget {
  const HrDashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employeesAsync = ref.watch(employeeListProvider);
    final pendingLeavesAsync = ref.watch(leavePendingApprovalsProvider);
    final upcomingHolidaysAsync = ref.watch(upcomingHolidaysProvider);

    final totalEmployees = employeesAsync.when(
      data: (list) => list.length.toString(),
      loading: () => '...',
      error: (_, __) => '--',
    );

    final activeEmployees = employeesAsync.when(
      data: (list) => list.where((e) => e.status == 'ACTIVE').length.toString(),
      loading: () => '...',
      error: (_, __) => '--',
    );

    final pendingLeavesCount = pendingLeavesAsync.when(
      data: (list) => '${list.length} Requests',
      loading: () => '...',
      error: (_, __) => '--',
    );

    final holidaysCount = upcomingHolidaysAsync.when(
      data: (list) => '${list.length} Upcoming',
      loading: () => '...',
      error: (_, __) => '--',
    );

    final hrQuickActions = [
      const QuickActionItem(
        title: 'Employees',
        icon: Icons.people_alt_outlined,
        route: '/employees',
        color: AppColors.info,
      ),
      const QuickActionItem(
        title: 'Leave Approvals',
        icon: Icons.approval_outlined,
        route: '/leave',
        color: AppColors.warning,
      ),
      const QuickActionItem(
        title: 'Helpdesk',
        icon: Icons.support_agent_rounded,
        route: '/helpdesk',
        color: AppColors.primary,
      ),
      const QuickActionItem(
        title: 'Payroll Runs',
        icon: Icons.payments_outlined,
        route: '/payroll',
        color: AppColors.success,
      ),
      const QuickActionItem(
        title: 'Recruitment',
        icon: Icons.work_outline_rounded,
        route: '/recruitment',
        color: AppColors.purple,
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const MobileHeaderWidget(),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(employeeListProvider);
          ref.invalidate(leavePendingApprovalsProvider);
          ref.invalidate(upcomingHolidaysProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: AppSpacing.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Personal Attendance Action Card for HR
              const AttendanceHeaderWidget(),
              const SizedBox(height: AppSpacing.lg),

              // 2. Upcoming Holidays Widget
              const UpcomingHolidaysCard(),
              const SizedBox(height: AppSpacing.lg),

              // 3. HR Management Shortcuts
              const Text('Management Shortcuts', style: AppTextStyles.h3),
              const SizedBox(height: AppSpacing.sm),
              QuickActionGrid(items: hrQuickActions),
              const SizedBox(height: AppSpacing.lg),

              // 4. Real Organization Metrics (zero hardcoded counts)
              const Text('Organization Headcount & Quotas', style: AppTextStyles.h3),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: DashboardKpiCard(
                      label: 'Total Workforce',
                      value: totalEmployees,
                      icon: Icons.groups_rounded,
                      iconColor: AppColors.info,
                      iconBgColor: AppColors.infoLight,
                      trend: 'Registered headcount',
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: DashboardKpiCard(
                      label: 'Active Staff',
                      value: activeEmployees,
                      icon: Icons.how_to_reg_rounded,
                      iconColor: AppColors.success,
                      iconBgColor: AppColors.successLight,
                      trend: 'Active records',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: DashboardKpiCard(
                      label: 'Leave Requests',
                      value: pendingLeavesCount,
                      icon: Icons.event_busy_rounded,
                      iconColor: AppColors.warning,
                      iconBgColor: AppColors.warningLight,
                      trend: 'Pending approvals',
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: DashboardKpiCard(
                      label: 'Holiday Cycle',
                      value: holidaysCount,
                      icon: Icons.calendar_month_outlined,
                      iconColor: AppColors.purple,
                      iconBgColor: AppColors.purpleLight,
                      trend: 'Public calendar',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // 5. Tracked Hours Overview
              const WeeklyAttendanceCard(),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}
