import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/widgets/loading_skeleton.dart';
import '../../data/notification_repository.dart';
import '../../domain/models/notification_model.dart';

final notificationsListProvider =
    FutureProvider.autoDispose<List<NotificationModel>>((ref) async {
  return ref.watch(notificationRepositoryProvider).getNotifications();
});

class NotificationListView extends ConsumerWidget {
  const NotificationListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: 'Mark all as read',
            onPressed: () async {
              await ref.read(notificationRepositoryProvider).markAllAsRead();
              ref.invalidate(notificationsListProvider);
            },
          ),
        ],
      ),
      body: notificationsAsync.when(
        loading: () => const Padding(
          padding: AppSpacing.screenPadding,
          child: ListLoadingSkeleton(count: 4),
        ),
        error: (err, _) => Center(
          child: Text('Error loading notifications: $err', style: AppTextStyles.caption),
        ),
        data: (notifications) {
          if (notifications.isEmpty) {
            return const EmptyStateView(
              icon: Icons.notifications_off_outlined,
              title: 'No Notifications',
              description: 'You\'re all caught up on announcements and updates.',
            );
          }

          return ListView.separated(
            padding: AppSpacing.screenPadding,
            itemCount: notifications.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final item = notifications[index];
              return Container(
                padding: AppSpacing.cardPadding,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                      child: const Icon(Icons.notifications_active_outlined, size: 18, color: AppColors.primary),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.title, style: AppTextStyles.bodyBold),
                          const SizedBox(height: 2),
                          Text(item.message, style: AppTextStyles.body),
                          const SizedBox(height: 4),
                          Text(
                            DateFormatter.formatDate(item.createdAt),
                            style: AppTextStyles.caption.copyWith(fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
