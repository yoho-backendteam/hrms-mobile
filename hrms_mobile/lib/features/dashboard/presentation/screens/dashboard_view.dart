import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/permissions/permission_provider.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../widgets/dashboard_skeleton.dart';
import 'employee_dashboard_view.dart';
import 'hr_dashboard_view.dart';

class DashboardView extends ConsumerWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    if (authState.status == AuthStatus.loading || authState.status == AuthStatus.initial) {
      return const DashboardSkeleton();
    }

    final isHR = ref.watch(isHRorAdminProvider);

    if (isHR) {
      return const HrDashboardView();
    }

    return const EmployeeDashboardView();
  }
}
