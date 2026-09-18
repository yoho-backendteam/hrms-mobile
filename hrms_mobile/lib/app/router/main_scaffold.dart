import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_colors.dart';
import '../../core/permissions/permission_provider.dart';
import '../../core/widgets/mobile_drawer.dart';
import '../../core/widgets/more_navigation_sheet.dart';

class _BarItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int? branchIndex;
  final bool isMore;

  const _BarItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.branchIndex,
    this.isMore = false,
  });
}

class MainScaffold extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const MainScaffold({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isHR = ref.watch(isHRorAdminProvider);

    final List<_BarItem> items = isHR
        ? [
            const _BarItem(
              icon: Icons.dashboard_outlined,
              activeIcon: Icons.dashboard_rounded,
              label: 'Home',
              branchIndex: 0,
            ),
            const _BarItem(
              icon: Icons.people_outline_rounded,
              activeIcon: Icons.people_rounded,
              label: 'Employees',
              branchIndex: 4,
            ),
            const _BarItem(
              icon: Icons.access_time_rounded,
              activeIcon: Icons.access_time_filled_rounded,
              label: 'Attendance',
              branchIndex: 1,
            ),
            const _BarItem(
              icon: Icons.event_note_outlined,
              activeIcon: Icons.event_note_rounded,
              label: 'Leave',
              branchIndex: 2,
            ),
            const _BarItem(
              icon: Icons.grid_view_rounded,
              activeIcon: Icons.grid_view_rounded,
              label: 'More',
              isMore: true,
            ),
          ]
        : [
            const _BarItem(
              icon: Icons.dashboard_outlined,
              activeIcon: Icons.dashboard_rounded,
              label: 'Home',
              branchIndex: 0,
            ),
            const _BarItem(
              icon: Icons.access_time_rounded,
              activeIcon: Icons.access_time_filled_rounded,
              label: 'Attendance',
              branchIndex: 1,
            ),
            const _BarItem(
              icon: Icons.event_note_outlined,
              activeIcon: Icons.event_note_rounded,
              label: 'Leave',
              branchIndex: 2,
            ),
            const _BarItem(
              icon: Icons.receipt_long_outlined,
              activeIcon: Icons.receipt_long_rounded,
              label: 'Payroll',
              branchIndex: 3,
            ),
            const _BarItem(
              icon: Icons.grid_view_rounded,
              activeIcon: Icons.grid_view_rounded,
              label: 'More',
              isMore: true,
            ),
          ];

    return Scaffold(
      drawer: const MobileDrawer(),
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(
            top: BorderSide(color: AppColors.border, width: 1),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: items.map((item) {
                final isSelected = item.isMore
                    ? navigationShell.currentIndex == 5
                    : item.branchIndex == navigationShell.currentIndex;

                return Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        if (item.isMore) {
                          MoreNavigationSheet.show(context);
                        } else if (item.branchIndex != null) {
                          navigationShell.goBranch(
                            item.branchIndex!,
                            initialLocation: item.branchIndex == navigationShell.currentIndex,
                          );
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      splashColor: AppColors.primaryLight,
                      highlightColor: Colors.transparent,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              curve: Curves.easeInOut,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.primaryLight : Colors.transparent,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                isSelected ? item.activeIcon : item.icon,
                                size: 21,
                                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                                letterSpacing: -0.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}
