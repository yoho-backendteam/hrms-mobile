import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/permissions/permission_provider.dart';
import '../../features/asset/presentation/screens/my_assets_view.dart';
import '../../features/attendance/presentation/screens/attendance_view.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_view.dart';
import '../../features/employee/domain/models/employee_model.dart';
import '../../features/employee/presentation/screens/employee_list_view.dart';
import '../../features/employee/presentation/screens/employee_profile_view.dart';
import '../../features/employee/presentation/screens/user_profile_screen.dart';
import '../../features/helpdesk/presentation/screens/helpdesk_list_view.dart';
import '../../features/leave/presentation/screens/leave_dashboard_view.dart';
import '../../features/notifications/presentation/screens/notification_list_view.dart';
import '../../features/payroll/presentation/screens/payroll_overview_view.dart';
import '../../features/performance/presentation/screens/performance_view.dart';
import '../../features/recruitment/presentation/screens/recruitment_view.dart';
import '../../features/settings/presentation/screens/settings_view.dart';
import '../../features/shift/presentation/screens/shift_roster_view.dart';
import '../../features/task/presentation/screens/task_list_view.dart';
import 'main_scaffold.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);
  final isHR = ref.watch(isHRorAdminProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final isAuth = authState.status == AuthStatus.authenticated;
      final isUnauth = authState.status == AuthStatus.unauthenticated;
      final isLoggingIn = state.matchedLocation == '/login';
      final isSplashing = state.matchedLocation == '/splash';

      if (authState.status == AuthStatus.initial) {
        return isSplashing ? null : '/splash';
      }

      if (isUnauth) {
        return isLoggingIn ? null : '/login';
      }

      if (isAuth) {
        return (isLoggingIn || isSplashing) ? '/dashboard' : null;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainScaffold(navigationShell: navigationShell);
        },
        branches: [
          // Branch 1: Dashboard Home
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dashboard',
                builder: (context, state) => const DashboardView(),
              ),
            ],
          ),
          // Branch 2: Attendance
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/attendance',
                builder: (context, state) => const AttendanceView(),
              ),
            ],
          ),
          // Branch 3: Employees (HR) or Leave (Employee)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/third-tab',
                builder: (context, state) {
                  return isHR ? const EmployeeListView() : const LeaveDashboardView();
                },
              ),
            ],
          ),
          // Branch 4: Payroll
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/payroll',
                builder: (context, state) => const PayrollOverviewView(),
              ),
            ],
          ),
          // Branch 5: Settings
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsView(),
              ),
            ],
          ),
        ],
      ),

      // Standalone Routes
      GoRoute(
        path: '/profile',
        builder: (context, state) => const UserProfileScreen(),
      ),
      GoRoute(
        path: '/employee',
        builder: (context, state) => const EmployeeListView(),
        routes: [
          GoRoute(
            path: ':id',
            builder: (context, state) {
              final id = state.pathParameters['id'] ?? '';
              final emp = state.extra as EmployeeModel?;
              return EmployeeProfileView(employeeId: id, initialEmployee: emp);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/leave',
        builder: (context, state) => const LeaveDashboardView(),
      ),
      GoRoute(
        path: '/shift',
        builder: (context, state) => const ShiftRosterView(),
      ),
      GoRoute(
        path: '/tasks',
        builder: (context, state) => const TaskListView(),
      ),
      GoRoute(
        path: '/assets',
        builder: (context, state) => const MyAssetsView(),
      ),
      GoRoute(
        path: '/performance',
        builder: (context, state) => const PerformanceView(),
      ),
      GoRoute(
        path: '/recruitment',
        builder: (context, state) => const RecruitmentView(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationListView(),
      ),
      GoRoute(
        path: '/helpdesk',
        builder: (context, state) => const HelpdeskListView(),
      ),
    ],
  );
});
