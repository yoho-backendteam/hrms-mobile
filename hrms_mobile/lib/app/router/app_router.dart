import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/permissions/permission_provider.dart';
import '../../features/asset/presentation/screens/my_assets_view.dart';
import '../../features/attendance/presentation/screens/attendance_view.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/welcome_screen.dart';
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
      final loc = state.matchedLocation;
      final isLoggingIn = loc == '/login';
      final isWelcoming = loc == '/welcome';
      final isSplashing = loc == '/splash';

      // While loading or initial, do not redirect away
      if (authState.status == AuthStatus.loading || authState.status == AuthStatus.initial) {
        return null;
      }

      // If user is authenticated and on auth screens, send to dashboard
      if (isAuth) {
        if (isLoggingIn || isWelcoming || isSplashing) {
          return '/dashboard';
        }
        return null;
      }

      // If unauthenticated:
      if (isUnauth) {
        if (isSplashing) {
          return '/welcome';
        }
        // Let the user stay on /login, /welcome without looping!
        if (isLoggingIn || isWelcoming || loc.startsWith('/verify-otp')) {
          return null;
        }
        // If trying to access internal routes while unauthenticated, redirect to login
        return '/login';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
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
          // Branch 5: Settings / Menu
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
      // Standalone modal / sub-routes
      GoRoute(
        path: '/profile',
        builder: (context, state) => const UserProfileScreen(),
      ),
      GoRoute(
        path: '/employee-detail',
        builder: (context, state) {
          final employee = state.extra as EmployeeModel?;
          return EmployeeProfileView(
            employeeId: employee?.id ?? '',
            initialEmployee: employee,
          );
        },
      ),
      GoRoute(
        path: '/leave',
        builder: (context, state) => const LeaveDashboardView(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationListView(),
      ),
      GoRoute(
        path: '/helpdesk',
        builder: (context, state) => const HelpdeskListView(),
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
    ],
  );
});
