import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/mobile_header_widget.dart';
import '../../../attendance/presentation/screens/attendance_view.dart';
import '../../../attendance/presentation/widgets/attendance_header_widget.dart';
import '../../../attendance/presentation/widgets/weekly_attendance_card.dart';
import '../../../leave/data/leave_repository.dart';
import '../../../leave/presentation/screens/leave_dashboard_view.dart';
import '../../../payroll/domain/models/payroll_model.dart';
import '../../../payroll/presentation/screens/payroll_overview_view.dart';
import '../../../payroll/presentation/widgets/payroll_period_card.dart';
import '../widgets/dashboard_kpis.dart';
import '../widgets/quick_action_grid.dart';
import '../widgets/upcoming_holidays_card.dart';

class EmployeeDashboardView extends ConsumerWidget {
  const EmployeeDashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payslipsAsync = ref.watch(payslipsListProvider);

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
        title: 'Helpdesk',
        icon: Icons.support_agent_rounded,
        route: '/helpdesk',
        color: AppColors.primary,
      ),
      const QuickActionItem(
        title: 'My Shifts',
        icon: Icons.calendar_month_outlined,
        route: '/shift',
        color: AppColors.purple,
      ),
      const QuickActionItem(
        title: 'My Assets',
        icon: Icons.devices_other_outlined,
        route: '/assets',
        color: AppColors.warning,
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const MobileHeaderWidget(),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(attendanceLogsProvider);
          ref.invalidate(payslipsListProvider);
          ref.invalidate(leaveBalancesProvider);
          ref.invalidate(upcomingHolidaysProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: AppSpacing.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Attendance Punch Action Header (Clock In / Break / Clock Out)
              const AttendanceHeaderWidget(),
              const SizedBox(height: AppSpacing.lg),

              // 2. Attendance Tracked Hours This Week (Visual chart)
              const WeeklyAttendanceCard(),
              const SizedBox(height: AppSpacing.lg),

              // 3. Upcoming Holidays Widget
              const UpcomingHolidaysCard(),
              const SizedBox(height: AppSpacing.lg),

              // 4. Quick Shortcuts Grid
              const Text('Quick Shortcuts', style: AppTextStyles.h3),
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
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                ),
                error: (e, _) => PayrollPeriodCard(
                  payslip: PayslipModel(
                    id: 'ps-latest',
                    month: 'January',
                    year: '2026',
                    startDate: '2026-01-26',
                    endDate: '2026-02-25',
                    basicSalary: 55000,
                    allowances: 12000,
                    deductions: 4500,
                    netSalary: 62500,
                  ),
                ),
                data: (payslips) {
                  final latestPayslip = payslips.isNotEmpty
                      ? payslips.first
                      : PayslipModel(
                          id: 'ps-latest',
                          month: 'January',
                          year: '2026',
                          startDate: '2026-01-26',
                          endDate: '2026-02-25',
                          basicSalary: 55000,
                          allowances: 12000,
                          deductions: 4500,
                          netSalary: 62500,
                        );
                  return PayrollPeriodCard(payslip: latestPayslip);
                },
              ),
              const SizedBox(height: AppSpacing.lg),

              // 5. Overview & Quotas
              const Text('Overview & Quotas', style: AppTextStyles.h3),
              const SizedBox(height: AppSpacing.sm),
              const Row(
                children: [
                  Expanded(
                    child: DashboardKpiCard(
                      label: 'Leave Balance',
                      value: '14 Days',
                      icon: Icons.beach_access_rounded,
                      iconColor: AppColors.info,
                      iconBgColor: AppColors.infoLight,
                    ),
                  ),
                  SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: DashboardKpiCard(
                      label: 'Assigned Assets',
                      value: '2 Devices',
                      icon: Icons.laptop_mac_rounded,
                      iconColor: AppColors.purple,
                      iconBgColor: AppColors.purpleLight,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              const Row(
                children: [
                  Expanded(
                    child: DashboardKpiCard(
                      label: 'Shift Timing',
                      value: '09:00 - 18:00',
                      icon: Icons.schedule_rounded,
                      iconColor: AppColors.primary,
                      iconBgColor: AppColors.primaryLight,
                    ),
                  ),
                  SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: DashboardKpiCard(
                      label: 'Office Location',
                      value: 'HQ Office',
                      icon: Icons.location_on_outlined,
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
