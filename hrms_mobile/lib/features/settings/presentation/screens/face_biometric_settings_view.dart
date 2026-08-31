import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../attendance/data/attendance_repository.dart';
import '../../../attendance/presentation/controllers/attendance_notifier.dart';
import '../../../attendance/presentation/screens/face_enrollment_view.dart';

class FaceBiometricSettingsView extends ConsumerWidget {
  const FaceBiometricSettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attendanceState = ref.watch(attendanceNotifierProvider);
    final face = attendanceState.faceStatus;
    final isEnrolled = face?.isEnrolled ?? false;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Face Biometric Enrollment'),
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Card
            Container(
              padding: AppSpacing.cardPadding,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: isEnrolled ? AppColors.successLight : AppColors.warningLight,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isEnrolled ? AppColors.successBorder : AppColors.warningBorder,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      isEnrolled ? Icons.face_retouching_natural : Icons.face_unlock_rounded,
                      size: 36,
                      color: isEnrolled ? AppColors.success : AppColors.warning,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    isEnrolled ? 'Face Recognition Active' : 'Face Not Enrolled',
                    style: AppTextStyles.h2,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isEnrolled
                        ? 'Your face profile is enrolled for multi-factor attendance verification.'
                        : 'Enroll your facial template to enable one-touch attendance clock-ins.',
                    style: AppTextStyles.body,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  StatusBadge.fromStatus(isEnrolled ? 'ACTIVE' : 'NOT_REGISTERED'),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Profile Metadata Details
            if (isEnrolled) ...[
              const Text('Biometric Profile Details', style: AppTextStyles.h3),
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
                    _buildRow('Enrollment Date', DateFormatter.formatDate(face?.enrolledAt)),
                    const Divider(),
                    _buildRow('Last Verified Time', DateFormatter.formatTime(face?.lastVerifiedAt)),
                    const Divider(),
                    _buildRow('Matching Pipeline', face?.modelName ?? 'MediaPipe Face Mesh'),
                    const Divider(),
                    _buildRow('Cosense Similarity', 'Threshold >= 0.70'),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Re-enroll & Revoke Actions
              PrimaryButton(
                text: 'Re-enroll / Update Face',
                icon: const Icon(Icons.camera_alt_outlined, size: 18, color: Colors.white),
                onPressed: () => FaceEnrollmentView.show(context),
              ),
              const SizedBox(height: AppSpacing.sm),
              PrimaryButton(
                text: 'Revoke Face Biometrics',
                isOutlined: true,
                backgroundColor: AppColors.error,
                textColor: AppColors.error,
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Revoke Biometric Profile?'),
                      content: const Text(
                        'This will delete your facial recognition vector. You will need to enroll again for biometric attendance.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(true),
                          child: const Text('Revoke', style: TextStyle(color: AppColors.error)),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true) {
                    await ref.read(attendanceRepositoryProvider).revokeFace();
                    ref.read(attendanceNotifierProvider.notifier).fetchStatus();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✓ Biometric profile revoked.'),
                          backgroundColor: AppColors.warning,
                        ),
                      );
                    }
                  }
                },
              ),
            ] else ...[
              PrimaryButton(
                text: 'Enroll Face Recognition',
                icon: const Icon(Icons.camera_alt_outlined, size: 18, color: Colors.white),
                onPressed: () => FaceEnrollmentView.show(context),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
          Text(value, style: AppTextStyles.bodyBold),
        ],
      ),
    );
  }
}
