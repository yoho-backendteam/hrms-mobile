import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/widgets/loading_skeleton.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../data/task_repository.dart';
import '../../domain/models/task_model.dart';

final taskListProvider = FutureProvider.autoDispose<List<TaskModel>>((ref) async {
  return ref.watch(taskRepositoryProvider).getTasks();
});

class TaskListView extends ConsumerWidget {
  const TaskListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(taskListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Tasks & Deliverables'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(taskListProvider),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            tasksAsync.when(
              loading: () => const ListLoadingSkeleton(count: 4),
              error: (err, _) => Text('Error: $err', style: AppTextStyles.caption),
              data: (tasks) {
                if (tasks.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: EmptyStateView(
                      icon: Icons.task_alt_rounded,
                      title: 'No Pending Tasks',
                      description: 'All your deliverables are up to date.',
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: tasks.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final item = tasks[index];
                    final isDone = item.status == 'COMPLETED';

                    return Container(
                      padding: AppSpacing.cardPadding,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Checkbox(
                            value: isDone,
                            activeColor: AppColors.success,
                            onChanged: (val) async {
                              final newStatus = val == true ? 'COMPLETED' : 'PENDING';
                              await ref.read(taskRepositoryProvider).updateTaskStatus(item.id, newStatus);
                              ref.invalidate(taskListProvider);
                            },
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  style: AppTextStyles.bodyBold.copyWith(
                                    decoration: isDone ? TextDecoration.lineThrough : null,
                                    color: isDone ? AppColors.textMuted : AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Due: ${DateFormatter.formatDate(item.dueDate)} • Priority: ${item.priority}',
                                  style: AppTextStyles.caption,
                                ),
                              ],
                            ),
                          ),
                          StatusBadge.fromStatus(item.status),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
