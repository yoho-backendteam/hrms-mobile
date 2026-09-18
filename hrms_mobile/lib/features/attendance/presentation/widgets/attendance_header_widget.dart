import 'dart:async';
import 'dart:math' as math;
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

class AttendanceHeaderWidget extends ConsumerStatefulWidget {
  const AttendanceHeaderWidget({super.key});

  @override
  ConsumerState<AttendanceHeaderWidget> createState() => _AttendanceHeaderWidgetState();
}

class _AttendanceHeaderWidgetState extends ConsumerState<AttendanceHeaderWidget> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // Live ticking timer for Jibble-style real-time working counter
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _triggerFaceAction(BuildContext context, AttendanceModalAction action) {
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

  Duration _calculateWorkingDuration(AttendanceModel? att, AttendanceState attState) {
    if (att == null || att.clockIn == null) return Duration.zero;

    final now = DateTime.now();
    final clockIn = att.clockIn!;

    int completedBreakSeconds = 0;
    DateTime? activeBreakIn;

    for (final b in att.breaks) {
      if (b.breakIn != null && b.breakOut != null) {
        completedBreakSeconds += b.breakOut!.difference(b.breakIn!).inSeconds;
      } else if (b.breakIn != null && b.breakOut == null) {
        activeBreakIn = b.breakIn;
      }
    }

    if (attState == AttendanceState.clockedOut && att.clockOut != null) {
      final totalSec = att.clockOut!.difference(clockIn).inSeconds - completedBreakSeconds;
      return Duration(seconds: math.max(0, totalSec));
    }

    if (attState == AttendanceState.onBreak && activeBreakIn != null) {
      // Frozen at the start of current break
      final totalSec = activeBreakIn.difference(clockIn).inSeconds - completedBreakSeconds;
      return Duration(seconds: math.max(0, totalSec));
    }

    final totalSec = now.difference(clockIn).inSeconds - completedBreakSeconds;
    return Duration(seconds: math.max(0, totalSec));
  }

  Duration _calculateTotalBreakDuration(AttendanceModel? att) {
    if (att == null) return Duration.zero;
    int totalSec = 0;
    final now = DateTime.now();

    for (final b in att.breaks) {
      if (b.breakIn != null && b.breakOut != null) {
        totalSec += b.breakOut!.difference(b.breakIn!).inSeconds;
      } else if (b.breakIn != null && b.breakOut == null) {
        totalSec += now.difference(b.breakIn!).inSeconds;
      }
    }
    return Duration(seconds: totalSec);
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours.toString().padLeft(2, '0');
    final minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(attendanceNotifierProvider);
    final att = state.todayAttendance;
    final attState = att?.state ?? AttendanceState.notStarted;

    final workDuration = _calculateWorkingDuration(att, attState);
    final breakDuration = _calculateTotalBreakDuration(att);

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
          // Header Row with Title & Status Badge
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

          // Jibble-Style Live Digital Working Timer Card
          Container(
            padding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 16.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: attState == AttendanceState.clockedIn
                    ? [const Color(0xFFF0FDF4), const Color(0xFFDCFCE7)]
                    : attState == AttendanceState.onBreak
                        ? [const Color(0xFFFFFBEB), const Color(0xFFFEF3C7)]
                        : [AppColors.background, AppColors.surfaceMuted],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(
                color: attState == AttendanceState.clockedIn
                    ? AppColors.successBorder
                    : attState == AttendanceState.onBreak
                        ? AppColors.warningBorder
                        : AppColors.borderLight,
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: attState == AttendanceState.clockedIn
                            ? AppColors.success
                            : attState == AttendanceState.onBreak
                                ? AppColors.warning
                                : AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      attState == AttendanceState.clockedIn
                          ? 'TRACKED WORK TIME'
                          : attState == AttendanceState.onBreak
                              ? 'WORK TIME (PAUSED ON BREAK)'
                              : attState == AttendanceState.clockedOut
                                  ? 'TOTAL WORK TIME TODAY'
                                  : 'READY TO START SHIFT',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                        color: attState == AttendanceState.clockedIn
                            ? AppColors.success
                            : attState == AttendanceState.onBreak
                                ? const Color(0xFFB45309)
                                : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  _formatDuration(workDuration),
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2.0,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color: attState == AttendanceState.clockedIn
                        ? const Color(0xFF166534)
                        : attState == AttendanceState.onBreak
                            ? const Color(0xFF92400E)
                            : AppColors.textPrimary,
                  ),
                ),
                if (attState == AttendanceState.onBreak) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.warningBorder),
                    ),
                    child: Text(
                      'Break in progress: ${_formatDuration(breakDuration)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFB45309),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Time Grid Cards
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
                        const Text('Break Total', style: AppTextStyles.caption),
                        const SizedBox(height: 2),
                        Text(
                          breakDuration.inMinutes > 0
                              ? '${breakDuration.inMinutes}m'
                              : '--',
                          style: AppTextStyles.bodyBold.copyWith(
                            color: attState == AttendanceState.onBreak ? AppColors.warning : AppColors.textPrimary,
                          ),
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
              onSlideComplete: () => _triggerFaceAction(context, AttendanceModalAction.clockIn),
            ),
          ] else if (attState == AttendanceState.clockedIn) ...[
            Column(
              children: [
                SlideActionButton(
                  label: 'Slide to Clock Out',
                  icon: Icons.power_settings_new_rounded,
                  baseColor: AppColors.error,
                  onSlideComplete: () => _triggerFaceAction(context, AttendanceModalAction.clockOut),
                ),
                const SizedBox(height: AppSpacing.sm),
                PrimaryButton(
                  text: 'Take Break',
                  isOutlined: true,
                  icon: const Icon(Icons.coffee_outlined, size: 16, color: AppColors.textPrimary),
                  onPressed: () => _triggerFaceAction(context, AttendanceModalAction.breakIn),
                ),
              ],
            ),
          ] else if (attState == AttendanceState.onBreak) ...[
            // STRICT RULE: When on break, Clock Out is NOT shown. Only Resume Work is possible.
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.warningLight,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    border: Border.all(color: AppColors.warningBorder),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: AppColors.warning),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'You are on break. Resume work before clocking out.',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF92400E),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SlideActionButton(
                  label: 'Slide to Resume Work',
                  icon: Icons.play_arrow_rounded,
                  baseColor: AppColors.success,
                  onSlideComplete: () => _triggerFaceAction(context, AttendanceModalAction.breakOut),
                ),
              ],
            ),
          ] else if (attState == AttendanceState.clockedOut) ...[
            SlideActionButton(
              label: 'Slide to Clock In Again',
              icon: Icons.refresh_rounded,
              baseColor: AppColors.primary,
              onSlideComplete: () => _triggerFaceAction(context, AttendanceModalAction.clockIn),
            ),
          ],
        ],
      ),
    );
  }
}
