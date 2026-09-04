import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../auth/presentation/widgets/organization_selector_sheet.dart';
import '../../../settings/presentation/screens/face_biometric_settings_view.dart';

class UserProfileScreen extends ConsumerWidget {
  const UserProfileScreen({super.key});

  void _showAvatarOptionsModal(BuildContext context, WidgetRef ref, UserModel? user) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg, horizontal: AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const Text('Profile Photo', style: AppTextStyles.h2),
              const SizedBox(height: AppSpacing.lg),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: const Icon(Icons.camera_alt_outlined, color: AppColors.primary),
                ),
                title: const Text('Take Photo', style: AppTextStyles.bodyBold),
                subtitle: const Text('Use camera to take a new profile picture', style: AppTextStyles.caption),
                onTap: () {
                  Navigator.of(ctx).pop();
                  // Simulate photo capture and update
                  ref.read(authControllerProvider.notifier).updateAvatar(
                    'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400',
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✓ Profile picture updated successfully!'),
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              const Divider(),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.infoLight,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: const Icon(Icons.photo_library_outlined, color: AppColors.info),
                ),
                title: const Text('Choose from Gallery', style: AppTextStyles.bodyBold),
                subtitle: const Text('Select a photo from your photo library', style: AppTextStyles.caption),
                onTap: () {
                  Navigator.of(ctx).pop();
                  // Simulate gallery pick and update
                  ref.read(authControllerProvider.notifier).updateAvatar(
                    'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400',
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✓ Profile picture updated from gallery!'),
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              if (user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty) ...[
                const Divider(),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.errorLight,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                  ),
                  title: const Text('Remove Photo', style: AppTextStyles.bodyBold),
                  subtitle: const Text('Reset to default initials avatar', style: AppTextStyles.caption),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    ref.read(authControllerProvider.notifier).removeAvatar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✓ Profile picture removed.'),
                        backgroundColor: AppColors.textPrimary,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showEditProfileModal(BuildContext context, WidgetRef ref, UserModel? user) {
    final firstNameController = TextEditingController(text: user?.firstName ?? '');
    final lastNameController = TextEditingController(text: user?.lastName ?? '');
    final phoneController = TextEditingController(text: user?.phone ?? '');
    final locationController = TextEditingController(text: user?.location ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          top: AppSpacing.lg,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.xl,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Edit Profile', style: AppTextStyles.h2),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              CustomTextField(
                label: 'First Name',
                controller: firstNameController,
                prefixIcon: const Icon(Icons.person_outline, size: 18),
              ),
              const SizedBox(height: AppSpacing.md),
              CustomTextField(
                label: 'Last Name',
                controller: lastNameController,
                prefixIcon: const Icon(Icons.person_outline, size: 18),
              ),
              const SizedBox(height: AppSpacing.md),
              CustomTextField(
                label: 'Phone Number',
                controller: phoneController,
                keyboardType: TextInputType.phone,
                prefixIcon: const Icon(Icons.phone_outlined, size: 18),
              ),
              const SizedBox(height: AppSpacing.md),
              CustomTextField(
                label: 'Work Location / City',
                controller: locationController,
                prefixIcon: const Icon(Icons.location_on_outlined, size: 18),
              ),
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(
                text: 'Save Changes',
                icon: const Icon(Icons.check_rounded, color: Colors.white, size: 18),
                onPressed: () {
                  ref.read(authControllerProvider.notifier).updateProfile(
                    firstName: firstNameController.text.trim(),
                    lastName: lastNameController.text.trim(),
                    phone: phoneController.text.trim(),
                    location: locationController.text.trim(),
                  );
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✓ Profile details saved successfully!'),
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Profile'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Account Settings',
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Profile Header Card
            Container(
              padding: AppSpacing.cardPadding,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Avatar with Photo Upload & Edit Badge
                  Stack(
                    children: [
                      GestureDetector(
                        onTap: () => _showAvatarOptionsModal(context, ref, user),
                        child: CircleAvatar(
                          radius: 44,
                          backgroundColor: AppColors.primaryLight,
                          backgroundImage: user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty
                              ? NetworkImage(user.avatarUrl!)
                              : null,
                          child: (user?.avatarUrl == null || user!.avatarUrl!.isEmpty)
                              ? Text(
                                  user?.fullName.isNotEmpty == true
                                      ? user!.fullName[0].toUpperCase()
                                      : 'U',
                                  style: AppTextStyles.display.copyWith(
                                    color: AppColors.primary,
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () => _showAvatarOptionsModal(context, ref, user),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    user?.fullName ?? 'Employee Profile',
                    style: AppTextStyles.h2,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${user?.designation ?? "Team Member"} • ${user?.department ?? "Operations"}',
                    style: AppTextStyles.caption.copyWith(fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      StatusBadge.fromStatus(user?.status ?? 'ACTIVE'),
                      const SizedBox(width: AppSpacing.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                        ),
                        child: Text(
                          user?.role ?? 'EMPLOYEE',
                          style: AppTextStyles.captionBold.copyWith(
                            color: AppColors.primary,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  // Edit Profile CTA
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primaryBorder),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
                    ),
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text('Edit Profile Information'),
                    onPressed: () => _showEditProfileModal(context, ref, user),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Work Information Section
            const Text('Work Information', style: AppTextStyles.h3),
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: AppSpacing.cardPadding,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _buildDetailRow(Icons.badge_outlined, 'Employee ID', user?.employeeCode ?? 'EMP-001'),
                  const Divider(height: AppSpacing.lg),
                  _buildDetailRow(Icons.business_outlined, 'Company', user?.displayCompanyName ?? user?.displayCompanyName ?? 'Brook Tech'),
                  const Divider(height: AppSpacing.lg),
                  _buildDetailRow(Icons.apartment_outlined, 'Department', user?.department ?? 'Engineering'),
                  const Divider(height: AppSpacing.lg),
                  _buildDetailRow(Icons.work_outline_rounded, 'Designation', user?.designation ?? 'Software Engineer'),
                  const Divider(height: AppSpacing.lg),
                  _buildDetailRow(Icons.pin_drop_outlined, 'Location', user?.location ?? 'Chennai HQ'),
                  const Divider(height: AppSpacing.lg),
                  _buildDetailRow(Icons.calendar_today_outlined, 'Joining Date', user?.joiningDate ?? '2024-01-15'),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Contact Information Section
            const Text('Contact Information', style: AppTextStyles.h3),
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: AppSpacing.cardPadding,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _buildDetailRow(Icons.email_outlined, 'Work Email', user?.email ?? '--'),
                  const Divider(height: AppSpacing.lg),
                  _buildDetailRow(Icons.phone_outlined, 'Phone Number', user?.phone ?? '+91 98765 43210'),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Security & Settings Shortcuts
            const Text('Biometrics & Security', style: AppTextStyles.h3),
            const SizedBox(height: AppSpacing.sm),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.face_retouching_natural, color: AppColors.primary),
                    title: const Text('Face Recognition Biometrics', style: AppTextStyles.bodyBold),
                    subtitle: const Text('Manage facial recognition template for attendance', style: AppTextStyles.caption),
                    trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const FaceBiometricSettingsView(),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.business_outlined, color: AppColors.primary),
                    title: const Text('Switch Organization', style: AppTextStyles.bodyBold),
                    subtitle: const Text('Switch workspace for multi-tenant accounts', style: AppTextStyles.caption),
                    trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
                    onTap: () async {
                      final orgs = await ref
                          .read(authControllerProvider.notifier)
                          .fetchUserOrganizations();
                      if (context.mounted) {
                        if (orgs.isNotEmpty) {
                          OrganizationSelectorSheet.show(
                            context,
                            organizations: orgs,
                            isSwitchMode: true,
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('No additional organizations linked to your account.'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: AppSpacing.sm),
        Text(label, style: AppTextStyles.caption),
        const Spacer(),
        Expanded(
          flex: 2,
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: AppTextStyles.bodyBold,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
