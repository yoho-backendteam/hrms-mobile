import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../domain/models/attendance_model.dart';
import '../screens/attendance_view.dart';

class WeeklyAttendanceCard extends ConsumerWidget {
  const WeeklyAttendanceCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(attendanceLogsProvider);

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
      child: logsAsync.when(
        loading: () => _buildLoadingState(),
        error: (err, _) => _buildErrorState(context, ref),
        data: (logs) => _buildDataState(logs),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 140,
              height: 16,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Container(
              width: 60,
              height: 16,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          width: 100,
          height: 28,
          decoration: BoxDecoration(
            color: AppColors.border,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            7,
            (index) => Container(
              width: 32,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Attendance Tracked Hours', style: AppTextStyles.h3),
        const SizedBox(height: AppSpacing.xs),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Unable to load weekly logs', style: AppTextStyles.caption),
            TextButton(
              onPressed: () => ref.invalidate(attendanceLogsProvider),
              child: const Text('Retry', style: TextStyle(color: AppColors.primary)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDataState(List<AttendanceModel> logs) {
    // Determine the start of the current week (Monday)
    final now = DateTime.now();
    final currentWeekday = now.weekday; // 1 = Mon, 7 = Sun
    final monday = now.subtract(Duration(days: currentWeekday - 1));

    final Map<int, double> dayHours = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0, 7: 0};
    int totalWeekMinutes = 0;

    for (final log in logs) {
      final logDate = DateTime.tryParse(log.date);
      if (logDate != null) {
        final diffDays = logDate.difference(DateTime(monday.year, monday.month, monday.day)).inDays;
        if (diffDays >= 0 && diffDays < 7) {
          final weekday = logDate.weekday;
          final mins = log.totalWorkMinutes > 0
              ? log.totalWorkMinutes
              : (log.clockIn != null && log.clockOut != null
                  ? log.clockOut!.difference(log.clockIn!).inMinutes - log.totalBreakMinutes
                  : 0);

          final clampedMins = mins > 0 ? mins : 0;
          dayHours[weekday] = (dayHours[weekday] ?? 0) + (clampedMins / 60.0);
          totalWeekMinutes += clampedMins;
        }
      }
    }

    final totalHours = totalWeekMinutes ~/ 60;
    final totalMins = totalWeekMinutes % 60;
    const standardDailyTargetHours = 8.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.bar_chart_rounded, size: 18, color: AppColors.primary),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'Tracked Hours This Week',
                  style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            Text(
              'Target: 40h',
              style: AppTextStyles.caption.copyWith(color: AppColors.textMuted, fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),

        // Total Formatted Time
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              '${totalHours}h ${totalMins}m',
              style: AppTextStyles.display.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 26,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              '(${DateFormat('MMM d').format(monday)} - ${DateFormat('MMM d').format(monday.add(const Duration(days: 6)))})',
              style: AppTextStyles.caption.copyWith(fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        // Weekly Bar Chart
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _buildDayBar('Mon', dayHours[1] ?? 0, standardDailyTargetHours, now.weekday == 1),
            _buildDayBar('Tue', dayHours[2] ?? 0, standardDailyTargetHours, now.weekday == 2),
            _buildDayBar('Wed', dayHours[3] ?? 0, standardDailyTargetHours, now.weekday == 3),
            _buildDayBar('Thu', dayHours[4] ?? 0, standardDailyTargetHours, now.weekday == 4),
            _buildDayBar('Fri', dayHours[5] ?? 0, standardDailyTargetHours, now.weekday == 5),
            _buildDayBar('Sat', dayHours[6] ?? 0, standardDailyTargetHours, now.weekday == 6, isWeekend: true),
            _buildDayBar('Sun', dayHours[7] ?? 0, standardDailyTargetHours, now.weekday == 7, isWeekend: true),
          ],
        ),
      ],
    );
  }

  Widget _buildDayBar(
    String dayLabel,
    double hours,
    double target,
    bool isToday, {
    bool isWeekend = false,
  }) {
    final fillRatio = (hours / target).clamp(0.0, 1.2);
    const maxHeight = 56.0;
    final barHeight = (fillRatio * maxHeight).clamp(4.0, maxHeight);

    Color barColor;
    if (isWeekend && hours == 0) {
      barColor = AppColors.border;
    } else if (hours >= target) {
      barColor = AppColors.success;
    } else if (hours > 0) {
      barColor = AppColors.primary;
    } else {
      barColor = isToday ? AppColors.primaryLight : AppColors.background;
    }

    return Column(
      children: [
        Text(
          hours > 0 ? '${hours.toStringAsFixed(1)}h' : '-',
          style: AppTextStyles.caption.copyWith(
            fontSize: 9,
            fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
            color: hours > 0 ? AppColors.textPrimary : AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 28,
          height: maxHeight,
          alignment: Alignment.bottomCenter,
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(6),
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 28,
            height: barHeight,
            decoration: BoxDecoration(
              color: barColor,
              borderRadius: BorderRadius.circular(6),
              border: isToday ? Border.all(color: AppColors.primaryDark, width: 1.5) : null,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          dayLabel,
          style: AppTextStyles.caption.copyWith(
            fontSize: 11,
            fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
            color: isToday ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
