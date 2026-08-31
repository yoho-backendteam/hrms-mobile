import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/widgets/loading_skeleton.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../data/helpdesk_repository.dart';
import '../../domain/models/ticket_model.dart';
import '../widgets/create_ticket_modal.dart';
import 'ticket_details_view.dart';

final ticketsListProvider =
    FutureProvider.autoDispose.family<List<TicketModel>, String?>((ref, status) async {
  return ref.watch(helpdeskRepositoryProvider).getTickets(status: status);
});

class HelpdeskListView extends ConsumerStatefulWidget {
  const HelpdeskListView({super.key});

  @override
  ConsumerState<HelpdeskListView> createState() => _HelpdeskListViewState();
}

class _HelpdeskListViewState extends ConsumerState<HelpdeskListView> {
  String _selectedStatusFilter = 'ALL';
  final List<String> _statusFilters = ['ALL', 'OPEN', 'IN_PROGRESS', 'RESOLVED', 'CLOSED'];

  @override
  Widget build(BuildContext context) {
    final ticketsAsync = ref.watch(ticketsListProvider(_selectedStatusFilter));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Helpdesk & Support'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(ticketsListProvider),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_comment_rounded),
        label: const Text('Create Ticket', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () {
          CreateTicketModal.show(
            context,
            onSuccess: () => ref.invalidate(ticketsListProvider),
          );
        },
      ),
      body: Column(
        children: [
          // Status Filter Tabs
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6),
            color: AppColors.surface,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _statusFilters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final f = _statusFilters[index];
                final isSelected = _selectedStatusFilter == f;
                return ChoiceChip(
                  label: Text(f.replaceAll('_', ' '), style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                  selected: isSelected,
                  selectedColor: AppColors.primaryLight,
                  backgroundColor: AppColors.background,
                  labelStyle: TextStyle(color: isSelected ? AppColors.primary : AppColors.textSecondary),
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedStatusFilter = f);
                  },
                );
              },
            ),
          ),
          const Divider(height: 1),

          // Tickets List
          Expanded(
            child: ticketsAsync.when(
              loading: () => const Padding(
                padding: AppSpacing.screenPadding,
                child: ListLoadingSkeleton(count: 4),
              ),
              error: (e, _) => Center(
                child: Padding(
                  padding: AppSpacing.screenPadding,
                  child: Text('Unable to load support tickets: $e', style: AppTextStyles.caption),
                ),
              ),
              data: (tickets) {
                if (tickets.isEmpty) {
                  return const EmptyStateView(
                    icon: Icons.support_agent_rounded,
                    title: 'No Tickets Found',
                    description: 'There are no helpdesk tickets matching this filter.',
                  );
                }

                return ListView.separated(
                  padding: AppSpacing.screenPadding,
                  itemCount: tickets.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final t = tickets[index];
                    return InkWell(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => TicketDetailsView(ticket: t),
                          ),
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  t.ticketNumber,
                                  style: AppTextStyles.captionBold.copyWith(color: AppColors.primary),
                                ),
                                StatusBadge.fromStatus(t.status),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              t.title,
                              style: AppTextStyles.bodyBold,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              t.description,
                              style: AppTextStyles.caption,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: t.priority == 'HIGH' || t.priority == 'URGENT'
                                        ? AppColors.errorLight
                                        : AppColors.surfaceMuted,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '${t.priority} Priority',
                                    style: AppTextStyles.captionBold.copyWith(
                                      color: t.priority == 'HIGH' || t.priority == 'URGENT'
                                          ? AppColors.error
                                          : AppColors.textSecondary,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                                Text(
                                  t.formattedCreatedDate,
                                  style: AppTextStyles.caption.copyWith(fontSize: 10),
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
          ),
        ],
      ),
    );
  }
}
