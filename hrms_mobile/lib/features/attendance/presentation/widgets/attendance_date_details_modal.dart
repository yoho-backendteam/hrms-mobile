import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/bottom_sheet_container.dart';
import '../../../../core/widgets/image_viewer_modal.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../domain/models/attendance_model.dart';

class AttendanceDateDetailsModal extends StatelessWidget {
  final AttendanceModel attendance;
  final String? overrideDateTitle;

  const AttendanceDateDetailsModal({
    super.key,
    required this.attendance,
    this.overrideDateTitle,
  });

  static Future<void> show({
    required BuildContext context,
    required AttendanceModel attendance,
    String? dateTitle,
  }) {
    return BottomSheetContainer.show(
      context: context,
      title: 'Attendance Details',
      child: AttendanceDateDetailsModal(
        attendance: attendance,
        overrideDateTitle: dateTitle,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    DateTime? parsedDate = DateTime.tryParse(attendance.date);
    final dateDisplay = overrideDateTitle ??
        (parsedDate != null
            ? DateFormat('EEEE, MMMM d, yyyy').format(parsedDate)
            : attendance.date);

    final timeFormatter = DateFormat('hh:mm a');
    final clockInStr = attendance.clockIn != null ? timeFormatter.format(attendance.clockIn!) : '--';
    final clockOutStr = attendance.clockOut != null ? timeFormatter.format(attendance.clockOut!) : '--';

    // Break in & break out
    DateTime? firstBreakIn;
    DateTime? lastBreakOut;
    if (attendance.breaks.isNotEmpty) {
      firstBreakIn = attendance.breaks.first.breakIn;
      lastBreakOut = attendance.breaks.last.breakOut;
    }
    final breakInStr = firstBreakIn != null ? timeFormatter.format(firstBreakIn) : '--';
    final breakOutStr = lastBreakOut != null ? timeFormatter.format(lastBreakOut) : '--';

    // Calculate total hours and break hours
    final totalWorkMins = attendance.totalWorkMinutes > 0
        ? attendance.totalWorkMinutes
        : (attendance.clockIn != null && attendance.clockOut != null
            ? attendance.clockOut!.difference(attendance.clockIn!).inMinutes - attendance.totalBreakMinutes
            : 0);

    final workHours = totalWorkMins ~/ 60;
    final workMinutes = totalWorkMins % 60;
    final breakHours = attendance.totalBreakMinutes ~/ 60;
    final breakMinutes = attendance.totalBreakMinutes % 60;

    // Sample event photos / images associated with events
    const sampleClockInImage = 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=500&q=80';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Date & Status Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(dateDisplay, style: AppTextStyles.h3),
                  const SizedBox(height: 2),
                  Text(
                    'Daily Shift: 09:00 AM - 06:00 PM',
                    style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            StatusBadge.fromStatus(attendance.status),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),

        // Punches Grid
        Container(
          padding: AppSpacing.cardPadding,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildPunchItem(
                      icon: Icons.login_rounded,
                      color: AppColors.success,
                      title: 'Clock In',
                      time: clockInStr,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _buildPunchItem(
                      icon: Icons.free_breakfast_outlined,
                      color: AppColors.warning,
                      title: 'Break In',
                      time: breakInStr,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: _buildPunchItem(
                      icon: Icons.play_arrow_outlined,
                      color: AppColors.info,
                      title: 'Break Out',
                      time: breakOutStr,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _buildPunchItem(
                      icon: Icons.logout_rounded,
                      color: AppColors.primary,
                      title: 'Clock Out',
                      time: clockOutStr,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Duration Summary Row
        Row(
          children: [
            Expanded(
              child: Container(
                padding: AppSpacing.cardPadding,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Worked Hours', style: AppTextStyles.caption),
                    const SizedBox(height: 4),
                    Text(
                      '${workHours}h ${workMinutes}m',
                      style: AppTextStyles.h2.copyWith(color: AppColors.primary),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Container(
                padding: AppSpacing.cardPadding,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Break Duration', style: AppTextStyles.caption),
                    const SizedBox(height: 4),
                    Text(
                      '${breakHours}h ${breakMinutes}m',
                      style: AppTextStyles.h2.copyWith(color: AppColors.textPrimary),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),

        // Security & Verification Information
        const Text('Verification & Security', style: AppTextStyles.h3),
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
              _buildVerificationRow(
                icon: Icons.face_retouching_natural,
                title: 'Face Biometric Match',
                status: 'Verified (98.6% Similarity)',
                isSuccess: true,
              ),
              const Divider(height: AppSpacing.lg),
              _buildVerificationRow(
                icon: Icons.location_on_outlined,
                title: 'Geofence Verification',
                status: 'Office Campus (Within 50m)',
                isSuccess: true,
              ),
              const Divider(height: AppSpacing.lg),
              _buildVerificationRow(
                icon: Icons.fingerprint_rounded,
                title: 'Liveness Detection',
                status: 'Active Liveness Passed',
                isSuccess: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Event Images Section
        const Text('Captured Event Photos', style: AppTextStyles.h3),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _buildEventImageCard(
                context,
                title: 'Clock In',
                time: clockInStr,
                imageUrl: sampleClockInImage,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _buildEventImageCard(
                context,
                title: 'Clock Out',
                time: clockOutStr,
                imageUrl: sampleClockInImage,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }

  Widget _buildPunchItem({
    required IconData icon,
    required Color color,
    required String title,
    required String time,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: AppSpacing.sm),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTextStyles.caption),
            const SizedBox(height: 2),
            Text(time, style: AppTextStyles.bodyBold),
          ],
        ),
      ],
    );
  }

  Widget _buildVerificationRow({
    required IconData icon,
    required String title,
    required String status,
    required bool isSuccess,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: isSuccess ? AppColors.success : AppColors.error),
        const SizedBox(width: AppSpacing.sm),
        Text(title, style: AppTextStyles.caption),
        const Spacer(),
        Text(
          status,
          style: AppTextStyles.captionBold.copyWith(
            color: isSuccess ? AppColors.success : AppColors.error,
          ),
        ),
      ],
    );
  }

  Widget _buildEventImageCard(
    BuildContext context, {
    required String title,
    required String time,
    required String imageUrl,
  }) {
    return GestureDetector(
      onTap: () {
        ImageViewerModal.show(
          context: context,
          imageUrl: imageUrl,
          title: '$title Photo',
          subtitle: time,
        );
      },
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              child: AspectRatio(
                aspectRatio: 1.3,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(color: AppColors.background),
                      errorWidget: (_, __, ___) => const Icon(Icons.person, color: AppColors.textMuted),
                    ),
                    Positioned(
                      right: 4,
                      bottom: 4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.fullscreen, color: Colors.white, size: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(title, style: AppTextStyles.captionBold),
            Text(time, style: AppTextStyles.caption.copyWith(fontSize: 10, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}
