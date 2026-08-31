import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/slide_action_button.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../domain/models/attendance_model.dart';
import '../controllers/attendance_notifier.dart';
import '../screens/face_verification_view.dart';

class AttendanceHeaderWidget extends ConsumerWidget {
  const AttendanceHeaderWidget({super.key});

  void _triggerFaceAction(BuildContext context, WidgetRef ref, AttendanceModalAction action) {
    FaceVerificationView.show(
      context: context,
      action: action,
      onVerified: (coords, template) async {
        final notifier = ref.read(attendanceNotifierProvider.notifier);
        bool ok = false;

        switch (action) {
          case AttendanceModalAction.clockIn:
            ok = await notifier.clockIn(
              method: 'face',
              faceTemplate: template,
              location: coords,
            );
            break;
          case AttendanceModalAction.breakIn:
            ok = await notifier.breakIn(location: coords);
            break;
          case AttendanceModalAction.breakOut:
            ok = await notifier.breakOut(location: coords);
            break;
          case AttendanceModalAction.clockOut:
            ok = await notifier.clockOut(location: coords);
            break;
        }

        if (context.mounted && ok) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✓ Face verified & ${action.name} successful!'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(attendanceNotifierProvider);
    final att = state.todayAttendance;
    final attState = att?.state ?? AttendanceState.notStarted;

    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.xs + 2),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: const Icon(Icons.access_time_filled, size: 16, color: AppColors.primary),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  const Text('Today\'s Attendance', style: AppTextStyles.h3),
                ],
              ),
              StatusBadge.fromStatus(
                attState == AttendanceState.clockedIn
                    ? 'Working'
                    : attState == AttendanceState.onBreak
                        ? 'On Break'
                        : attState == AttendanceState.clockedOut
                            ? 'Clocked Out'
                            : 'Not Started',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Time Grid
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Clock In', style: AppTextStyles.caption),
                      const SizedBox(height: 2),
                      Text(
                        DateFormatter.formatTime(att?.clockIn),
                        style: AppTextStyles.bodyBold,
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 28, color: AppColors.divider),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Clock Out', style: AppTextStyles.caption),
                        const SizedBox(height: 2),
                        Text(
                          DateFormatter.formatTime(att?.clockOut),
                          style: AppTextStyles.bodyBold,
                        ),
                      ],
                    ),
                  ),
                ),
                Container(width: 1, height: 28, color: AppColors.divider),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Work Hours', style: AppTextStyles.caption),
                        const SizedBox(height: 2),
                        Text(
                          DateFormatter.formatMinutesToHours(att?.totalWorkMinutes),
                          style: AppTextStyles.bodyBold.copyWith(color: AppColors.primary),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Sliding Action Buttons
          if (attState == AttendanceState.notStarted) ...[
            SlideActionButton(
              label: 'Slide to Face Clock-In',
              icon: Icons.camera_alt_rounded,
              baseColor: AppColors.primary,
              onSlideComplete: () => _triggerFaceAction(context, ref, AttendanceModalAction.clockIn),
            ),
          ] else if (attState == AttendanceState.clockedIn) ...[
            Column(
              children: [
                SlideActionButton(
                  label: 'Slide to Clock Out',
                  icon: Icons.power_settings_new_rounded,
                  baseColor: AppColors.error,
                  onSlideComplete: () => _triggerFaceAction(context, ref, AttendanceModalAction.clockOut),
                ),
                const SizedBox(height: AppSpacing.sm),
                PrimaryButton(
                  text: 'Take Break',
                  isOutlined: true,
                  icon: const Icon(Icons.coffee_outlined, size: 16, color: AppColors.textPrimary),
                  onPressed: () => _triggerFaceAction(context, ref, AttendanceModalAction.breakIn),
                ),
              ],
            ),
          ] else if (attState == AttendanceState.onBreak) ...[
            SlideActionButton(
              label: 'Slide to Resume Work',
              icon: Icons.play_arrow_rounded,
              baseColor: AppColors.success,
              onSlideComplete: () => _triggerFaceAction(context, ref, AttendanceModalAction.breakOut),
            ),
          ] else if (attState == AttendanceState.clockedOut) ...[
            SlideActionButton(
              label: 'Slide to Clock In Again',
              icon: Icons.refresh_rounded,
              baseColor: AppColors.primary,
              onSlideComplete: () => _triggerFaceAction(context, ref, AttendanceModalAction.clockIn),
            ),
          ],
        ],
      ),
    );
  }
}
