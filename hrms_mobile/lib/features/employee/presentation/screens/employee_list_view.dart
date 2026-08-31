import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/widgets/loading_skeleton.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../data/employee_repository.dart';
import '../../domain/models/employee_model.dart';

final employeeListSearchQueryProvider = StateProvider.autoDispose<String>((ref) => '');

final employeeListProvider =
    FutureProvider.autoDispose<List<EmployeeModel>>((ref) async {
  final repository = ref.watch(employeeRepositoryProvider);
  final search = ref.watch(employeeListSearchQueryProvider);
  return repository.getEmployees(search: search);
});

class EmployeeListView extends ConsumerWidget {
  const EmployeeListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employeesAsync = ref.watch(employeeListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Employees Directory'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(employeeListProvider),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Box
          Padding(
            padding: AppSpacing.screenPadding,
            child: TextField(
              onChanged: (val) {
                ref.read(employeeListSearchQueryProvider.notifier).state = val;
              },
              decoration: InputDecoration(
                hintText: 'Search by name, email, or designation...',
                prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textMuted),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
            ),
          ),

          // List View
          Expanded(
            child: employeesAsync.when(
              loading: () => const Padding(
                padding: AppSpacing.screenPadding,
                child: ListLoadingSkeleton(count: 6),
              ),
              error: (err, _) => Center(
                child: Text('Error loading employees: $err', style: AppTextStyles.caption),
              ),
              data: (employees) {
                if (employees.isEmpty) {
                  return const EmptyStateView(
                    icon: Icons.person_search_outlined,
                    title: 'No Employees Found',
                    description: 'Try adjusting your search criteria.',
                  );
                }

                return ListView.separated(
                  padding: AppSpacing.screenPadding,
                  itemCount: employees.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final emp = employees[index];
                    return InkWell(
                      onTap: () => context.push('/employee/${emp.id}', extra: emp),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                      child: Container(
                        padding: AppSpacing.cardPadding,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: AppColors.primaryLight,
                              child: Text(
                                emp.firstName.isNotEmpty ? emp.firstName[0].toUpperCase() : 'E',
                                style: AppTextStyles.bodyBold.copyWith(color: AppColors.primary),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(emp.fullName, style: AppTextStyles.bodyBold),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${emp.designation ?? "Employee"} • ${emp.department ?? "General"}',
                                    style: AppTextStyles.caption,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(emp.email, style: AppTextStyles.caption.copyWith(fontSize: 10)),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                StatusBadge.fromStatus(emp.status),
                                const SizedBox(height: 4),
                                Text(emp.employeeCode, style: AppTextStyles.caption.copyWith(fontSize: 9)),
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
