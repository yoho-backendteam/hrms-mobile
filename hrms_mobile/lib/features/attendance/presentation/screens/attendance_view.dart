import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/widgets/loading_skeleton.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../data/attendance_repository.dart';
import '../../domain/models/attendance_model.dart';
import '../controllers/attendance_notifier.dart';
import '../widgets/attendance_date_details_modal.dart';
import '../widgets/attendance_header_widget.dart';
import 'face_enrollment_view.dart';

final attendanceLogsProvider =
    FutureProvider.autoDispose<List<AttendanceModel>>((ref) async {
  final repository = ref.watch(attendanceRepositoryProvider);
  return repository.getMyLogs();
});

class AttendanceView extends ConsumerWidget {
  const AttendanceView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(attendanceLogsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Attendance'),
        actions: [
          IconButton(
            icon: const Icon(Icons.face_retouching_natural, color: AppColors.primary),
            tooltip: 'Face Biometric Enrollment',
            onPressed: () => FaceEnrollmentView.show(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(attendanceNotifierProvider.notifier).fetchStatus();
              ref.invalidate(attendanceLogsProvider);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          await ref.read(attendanceNotifierProvider.notifier).fetchStatus();
          ref.invalidate(attendanceLogsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: AppSpacing.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Main Action Header
              const AttendanceHeaderWidget(),
              const SizedBox(height: AppSpacing.xl),

              // Recent Logs Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Attendance History', style: AppTextStyles.h2),
                  Text(
                    'Tap record for details',
                    style: AppTextStyles.caption.copyWith(color: AppColors.primary),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),

              // Attendance History List
              logsAsync.when(
                loading: () => const ListLoadingSkeleton(count: 3),
                error: (err, _) => Container(
                  padding: AppSpacing.cardPadding,
                  decoration: BoxDecoration(
                    color: AppColors.errorLight,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Text('Failed to load history: $err', style: AppTextStyles.caption),
                ),
                data: (logs) {
                  if (logs.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: EmptyStateView(
                        icon: Icons.history_toggle_off_rounded,
                        title: 'No Logs Yet',
                        description: 'Your attendance records will appear here.',
                      ),
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: logs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final item = logs[index];
                      return InkWell(
                        onTap: () {
                          AttendanceDateDetailsModal.show(
                            context: context,
                            attendance: item,
                          );
                        },
                        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                        child: Container(
                          padding: AppSpacing.cardPadding,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                            border: Border.all(color: AppColors.border),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    DateFormatter.formatDate(item.date),
                                    style: AppTextStyles.bodyBold,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'In: ${DateFormatter.formatTime(item.clockIn)} • Out: ${DateFormatter.formatTime(item.clockOut)}',
                                    style: AppTextStyles.caption,
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        DateFormatter.formatMinutesToHours(item.totalWorkMinutes),
                                        style: AppTextStyles.bodyBold,
                                      ),
                                      const SizedBox(height: 2),
                                      StatusBadge.fromStatus(item.status),
                                    ],
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.chevron_right_rounded,
                                    size: 18,
                                    color: AppColors.textMuted,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }
}
