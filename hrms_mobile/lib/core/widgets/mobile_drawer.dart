import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_text_styles.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../permissions/permission_constants.dart';
import '../permissions/permission_provider.dart';

class MobileDrawer extends ConsumerWidget {
  const MobileDrawer({super.key});

  Widget _drawerItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String route,
    String? badge,
    Color? iconColor,
  }) {
    final currentLoc = GoRouterState.of(context).matchedLocation;
    final isSelected = currentLoc == route || (route != '/dashboard' && currentLoc.startsWith(route));

    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 0),
      leading: Icon(
        icon,
        size: 20,
        color: isSelected ? AppColors.primary : (iconColor ?? AppColors.textSecondary),
      ),
      title: Text(
        title,
        style: AppTextStyles.bodyMedium.copyWith(
          fontSize: 13,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? AppColors.primary : AppColors.textPrimary,
        ),
      ),
      trailing: badge != null
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                badge,
                style: AppTextStyles.caption.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            )
          : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      tileColor: isSelected ? AppColors.primaryLight.withValues(alpha: 0.5) : Colors.transparent,
      onTap: () {
        Navigator.of(context).pop(); // Close drawer
        if (currentLoc != route) {
          context.go(route);
        }
      },
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xs),
      child: Text(
        title.toUpperCase(),
        style: AppTextStyles.caption.copyWith(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppColors.textMuted,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;
    final isHR = ref.watch(isHRorAdminProvider);

    final canViewEmployees = ref.watch(hasPermissionProvider(AppPermissions.employeeRead));
    final canViewRecruitment = ref.watch(hasPermissionProvider(AppPermissions.recruitmentRead));
    final canViewPerformance = ref.watch(hasPermissionProvider(AppPermissions.performanceRead));
    final canViewAssets = ref.watch(hasAnyPermissionProvider([AppPermissions.assetRead, AppPermissions.assetRequestRead]));
    final canViewShift = ref.watch(hasAnyPermissionProvider([AppPermissions.shiftRead, AppPermissions.shiftRosterRead]));
    final canViewPayroll = ref.watch(hasAnyPermissionProvider([AppPermissions.payrollRead, AppPermissions.payslipRead]));
    final canViewHelpdesk = ref.watch(hasPermissionProvider(AppPermissions.helpdeskRead));

    return Drawer(
      backgroundColor: AppColors.surface,
      child: SafeArea(
        child: Column(
          children: [
            // Top User Profile Box
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  bottom: BorderSide(color: AppColors.border, width: 1),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.primaryLight,
                    child: Text(
                      user?.fullName.isNotEmpty == true
                          ? user!.fullName[0].toUpperCase()
                          : 'U',
                      style: AppTextStyles.h3.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.fullName ?? 'Employee',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodyBold.copyWith(fontSize: 14),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user?.email ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption.copyWith(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: isHR ? AppColors.primaryLight : AppColors.surfaceMuted,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isHR ? 'HR ADMIN' : (user?.role ?? 'EMPLOYEE'),
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: isHR ? AppColors.primary : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable Menu Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                children: [
                  // Core Modules
                  _sectionHeader('Core Modules'),
                  _drawerItem(
                    context: context,
                    icon: Icons.dashboard_outlined,
                    title: 'Dashboard',
                    route: '/dashboard',
                  ),
                  _drawerItem(
                    context: context,
                    icon: Icons.access_time_outlined,
                    title: 'Attendance',
                    route: '/attendance',
                  ),
                  if (canViewShift)
                    _drawerItem(
                      context: context,
                      icon: Icons.calendar_month_outlined,
                      title: 'Shift & Rosters',
                      route: '/shift',
                    ),
                  _drawerItem(
                    context: context,
                    icon: Icons.event_note_outlined,
                    title: 'Leave Management',
                    route: '/leave',
                  ),
                  if (canViewPayroll)
                    _drawerItem(
                      context: context,
                      icon: Icons.receipt_long_outlined,
                      title: 'Payroll & Payslips',
                      route: '/payroll',
                    ),

                  const Divider(height: AppSpacing.lg, color: AppColors.border),

                  // Operations & Organization
                  _sectionHeader('Operations'),
                  if (canViewEmployees)
                    _drawerItem(
                      context: context,
                      icon: Icons.people_outline,
                      title: 'Employees Directory',
                      route: '/employees',
                    ),
                  if (canViewRecruitment)
                    _drawerItem(
                      context: context,
                      icon: Icons.person_add_outlined,
                      title: 'Recruitment',
                      route: '/recruitment',
                    ),
                  _drawerItem(
                    context: context,
                    icon: Icons.task_alt_outlined,
                    title: 'My Tasks',
                    route: '/tasks',
                  ),
                  if (canViewAssets)
                    _drawerItem(
                      context: context,
                      icon: Icons.devices_other_outlined,
                      title: 'Asset Inventory',
                      route: '/assets',
                    ),
                  if (canViewPerformance)
                    _drawerItem(
                      context: context,
                      icon: Icons.insights_outlined,
                      title: 'Performance Reviews',
                      route: '/performance',
                    ),
                  if (canViewHelpdesk)
                    _drawerItem(
                      context: context,
                      icon: Icons.support_agent_outlined,
                      title: 'Helpdesk & Tickets',
                      route: '/helpdesk',
                    ),

                  const Divider(height: AppSpacing.lg, color: AppColors.border),

                  // System Preferences
                  _sectionHeader('System'),
                  _drawerItem(
                    context: context,
                    icon: Icons.settings_outlined,
                    title: 'Settings & Security',
                    route: '/settings',
                  ),
                ],
              ),
            ),

            // Bottom Logout Tile
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.border, width: 1)),
              ),
              child: ListTile(
                dense: true,
                leading: const Icon(Icons.logout, size: 20, color: AppColors.error),
                title: Text(
                  'Sign Out',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.error,
                  ),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  ref.read(authControllerProvider.notifier).logout();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
