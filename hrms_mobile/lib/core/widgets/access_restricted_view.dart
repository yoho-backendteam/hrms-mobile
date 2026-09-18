import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_text_styles.dart';
import 'primary_button.dart';

class AccessRestrictedView extends StatelessWidget {
  final String? requiredPermission;
  final String? moduleName;

  const AccessRestrictedView({
    super.key,
    this.requiredPermission,
    this.moduleName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(moduleName ?? 'Restricted Access'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/dashboard');
            }
          },
        ),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: AppSpacing.screenPadding,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primaryBorder, width: 2),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.lock_person_outlined,
                      size: 48,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'Access Restricted',
                  style: AppTextStyles.h1.copyWith(fontSize: 22),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  moduleName != null
                      ? 'You do not have permission to access $moduleName. Please contact your organization administrator or HR department.'
                      : 'You do not have the required permissions to access this screen. Please contact your administrator if you believe this is an error.',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (requiredPermission != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: Text(
                      'Required: $requiredPermission',
                      style: AppTextStyles.caption.copyWith(
                        fontFamily: 'monospace',
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.xxl),
                SizedBox(
                  width: 220,
                  child: PrimaryButton(
                    text: 'Return to Dashboard',
                    icon: const Icon(Icons.dashboard_outlined, size: 18, color: Colors.white),
                    onPressed: () => context.go('/dashboard'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
