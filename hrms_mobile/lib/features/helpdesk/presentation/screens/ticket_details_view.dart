import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/permissions/permission_provider.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../data/helpdesk_repository.dart';
import '../../domain/models/ticket_model.dart';

final ticketCommentsProvider =
    FutureProvider.autoDispose.family<List<TicketCommentModel>, String>((ref, ticketId) async {
  return ref.watch(helpdeskRepositoryProvider).getTicketComments(ticketId);
});

class TicketDetailsView extends ConsumerStatefulWidget {
  final TicketModel ticket;

  const TicketDetailsView({super.key, required this.ticket});

  @override
  ConsumerState<TicketDetailsView> createState() => _TicketDetailsViewState();
}

class _TicketDetailsViewState extends ConsumerState<TicketDetailsView> {
  final _commentController = TextEditingController();
  bool _isSending = false;
  late String _currentStatus;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.ticket.status;
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _sendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSending = true);
    try {
      final repo = ref.read(helpdeskRepositoryProvider);
      await repo.addComment(ticketId: widget.ticket.id, message: text);
      _commentController.clear();
      ref.invalidate(ticketCommentsProvider(widget.ticket.id));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to post comment: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    try {
      final repo = ref.read(helpdeskRepositoryProvider);
      await repo.updateTicketStatus(widget.ticket.id, newStatus);
      setState(() => _currentStatus = newStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✓ Ticket marked as $newStatus'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update status: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isHR = ref.watch(isHRorAdminProvider);
    final commentsAsync = ref.watch(ticketCommentsProvider(widget.ticket.id));
    final dateFormat = DateFormat('MMM d, yyyy • hh:mm a');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.ticket.ticketNumber),
        actions: [
          if (isHR && _currentStatus != 'RESOLVED' && _currentStatus != 'CLOSED')
            TextButton(
              onPressed: () => _updateStatus('RESOLVED'),
              child: const Text('Resolve', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: AppSpacing.screenPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header Information Card
                  Container(
                    padding: AppSpacing.cardPadding,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(widget.ticket.category, style: AppTextStyles.captionBold.copyWith(color: AppColors.primary)),
                            StatusBadge.fromStatus(_currentStatus),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(widget.ticket.title, style: AppTextStyles.h2),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Created on ${dateFormat.format(widget.ticket.createdAt)}',
                          style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
                        ),
                        const Divider(height: AppSpacing.lg),
                        const Text('Description', style: AppTextStyles.caption),
                        const SizedBox(height: 4),
                        Text(widget.ticket.description, style: AppTextStyles.body),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Conversation & Comments Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Conversation & Updates', style: AppTextStyles.h3),
                      IconButton(
                        icon: const Icon(Icons.refresh, size: 20),
                        onPressed: () => ref.invalidate(ticketCommentsProvider(widget.ticket.id)),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  commentsAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                    error: (e, _) => Text('No comments yet or error loading: $e', style: AppTextStyles.caption),
                    data: (comments) {
                      if (comments.isEmpty) {
                        return Container(
                          padding: AppSpacing.cardPadding,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: const Center(
                            child: Text('No messages posted on this ticket yet.', style: AppTextStyles.caption),
                          ),
                        );
                      }

                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: comments.length,
                        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (context, index) {
                          final c = comments[index];
                          return Container(
                            padding: AppSpacing.cardPadding,
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(c.authorName, style: AppTextStyles.bodyBold),
                                    Text(dateFormat.format(c.createdAt), style: AppTextStyles.caption.copyWith(fontSize: 10)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(c.message, style: AppTextStyles.body),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ),

          // Bottom Reply Input
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.border, width: 1)),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      decoration: InputDecoration(
                        hintText: 'Type a message or update...',
                        hintStyle: AppTextStyles.caption,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    icon: _isSending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.send_rounded, size: 20),
                    onPressed: _isSending ? null : _sendComment,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
