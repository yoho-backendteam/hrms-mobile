import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/mobile_header_widget.dart';
import '../../../attendance/presentation/widgets/attendance_header_widget.dart';
import '../../../attendance/presentation/widgets/weekly_attendance_card.dart';
import '../../../leave/data/leave_repository.dart';
import '../widgets/dashboard_kpis.dart';
import '../widgets/quick_action_grid.dart';
import '../widgets/upcoming_holidays_card.dart';

class HrDashboardView extends ConsumerWidget {
  const HrDashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

              // 3. Organization Metrics
              const Text('Organization Headcount & Quotas', style: AppTextStyles.h3),
              const SizedBox(height: AppSpacing.sm),
              const Row(
                children: [
                  Expanded(
                    child: DashboardKpiCard(
                      label: 'Total Workforce',
                      value: '128',
                      icon: Icons.groups_rounded,
                      iconColor: AppColors.info,
                      iconBgColor: AppColors.infoLight,
                      trend: '+4 this month',
                    ),
                  ),
                  SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: DashboardKpiCard(
                      label: 'Present Today',
                      value: '116',
                      icon: Icons.how_to_reg_rounded,
                      iconColor: AppColors.success,
                      iconBgColor: AppColors.successLight,
                      trend: '90.6% attendance',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              const Row(
                children: [
                  Expanded(
                    child: DashboardKpiCard(
                      label: 'On Leave',
                      value: '8 Members',
                      icon: Icons.event_busy_rounded,
                      iconColor: AppColors.warning,
                      iconBgColor: AppColors.warningLight,
                    ),
                  ),
                  SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: DashboardKpiCard(
                      label: 'Open Positions',
                      value: '6 Roles',
                      icon: Icons.person_search_rounded,
                      iconColor: AppColors.purple,
                      iconBgColor: AppColors.purpleLight,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // 4. Tracked Hours Overview
              const WeeklyAttendanceCard(),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}
