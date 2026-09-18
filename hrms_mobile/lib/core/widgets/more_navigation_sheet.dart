import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_text_styles.dart';
import '../permissions/permission_constants.dart';
import '../permissions/permission_provider.dart';

class MoreNavigationSheet extends ConsumerWidget {
  const MoreNavigationSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const MoreNavigationSheet(),
    );
  }

  Widget _toolTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required String route,
    required Color color,
  }) {
    return InkWell(
      onTap: () {
        Navigator.of(context).pop();
        context.push(route);
      },
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Icon(icon, size: 22, color: color),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.bodyBold),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTextStyles.caption.copyWith(fontSize: 11)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canViewShift = ref.watch(hasAnyPermissionProvider([AppPermissions.shiftRead, AppPermissions.shiftRosterRead]));
    final canViewAssets = ref.watch(hasAnyPermissionProvider([AppPermissions.assetRead, AppPermissions.assetRequestRead]));
    final canViewHelpdesk = ref.watch(hasPermissionProvider(AppPermissions.helpdeskRead));
    final canViewRecruitment = ref.watch(hasPermissionProvider(AppPermissions.recruitmentRead));
    final canViewPerformance = ref.watch(hasPermissionProvider(AppPermissions.performanceRead));

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag Indicator Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('All Services & Modules', style: AppTextStyles.h2),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20, color: AppColors.textSecondary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // Quick Grid of Authorized Modules
              _toolTile(
                context: context,
                icon: Icons.person_outline_rounded,
                title: 'My Profile',
                subtitle: 'Personal profile, department, and contact details',
                route: '/profile',
                color: AppColors.info,
              ),
              const SizedBox(height: AppSpacing.sm),

              _toolTile(
                context: context,
                icon: Icons.face_retouching_natural,
                title: 'Face Biometric Profile',
                subtitle: 'Manage facial verification and enrollment status',
                route: '/face-biometrics',
                color: AppColors.primary,
              ),
              const SizedBox(height: AppSpacing.sm),

              if (canViewShift) ...[
                _toolTile(
                  context: context,
                  icon: Icons.schedule_rounded,
                  title: 'Shift Schedule & Roster',
                  subtitle: 'Assigned working hours and weekly calendar',
                  route: '/shift',
                  color: const Color(0xFFF59E0B),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],

              if (canViewHelpdesk) ...[
                _toolTile(
                  context: context,
                  icon: Icons.support_agent_rounded,
                  title: 'Helpdesk & Support',
                  subtitle: 'Submit support requests and view ticket updates',
                  route: '/helpdesk',
                  color: AppColors.primary,
                ),
                const SizedBox(height: AppSpacing.sm),
              ],

              if (canViewAssets) ...[
                _toolTile(
                  context: context,
                  icon: Icons.devices_other_rounded,
                  title: 'Assigned Hardware & Assets',
                  subtitle: 'View company equipment and custody status',
                  route: '/assets',
                  color: AppColors.purple,
                ),
                const SizedBox(height: AppSpacing.sm),
              ],

              _toolTile(
                context: context,
                icon: Icons.task_alt_rounded,
                title: 'Assigned Tasks',
                subtitle: 'Check assigned deliverables and status',
                route: '/tasks',
                color: AppColors.success,
              ),
              const SizedBox(height: AppSpacing.sm),

              if (canViewRecruitment) ...[
                _toolTile(
                  context: context,
                  icon: Icons.person_add_alt_1_rounded,
                  title: 'Recruitment & Job Openings',
                  subtitle: 'View open candidate positions and pipelines',
                  route: '/recruitment',
                  color: AppColors.info,
                ),
                const SizedBox(height: AppSpacing.sm),
              ],

              if (canViewPerformance) ...[
                _toolTile(
                  context: context,
                  icon: Icons.insights_rounded,
                  title: 'Performance Appraisals',
                  subtitle: 'Goals, KPI metrics, and periodic reviews',
                  route: '/performance',
                  color: AppColors.primary,
                ),
                const SizedBox(height: AppSpacing.sm),
              ],

              _toolTile(
                context: context,
                icon: Icons.settings_outlined,
                title: 'App Settings',
                subtitle: 'Security, local biometrics, and preferences',
                route: '/settings',
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
