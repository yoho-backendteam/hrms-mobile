import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/permissions/permission_constants.dart';
import '../../core/permissions/permission_provider.dart';
import '../../core/widgets/access_restricted_view.dart';
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
  final userPermissions = ref.watch(userPermissionsProvider);
  final isOwner = ref.watch(isTenantOwnerProvider);

  bool hasPerm(String perm) {
    if (isOwner) return true;
    if (userPermissions.contains(AppPermissions.all)) return true;
    return userPermissions.contains(perm);
  }

  bool hasAnyPerm(List<String> perms) {
    if (isOwner) return true;
    if (userPermissions.contains(AppPermissions.all)) return true;
    return perms.any((p) => userPermissions.contains(p));
  }

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final isAuth = authState.status == AuthStatus.authenticated;
      final isUnauth = authState.status == AuthStatus.unauthenticated;
      final loc = state.matchedLocation;
      final isLoggingIn = loc == '/login';
      final isWelcoming = loc == '/welcome';
      final isSplashing = loc == '/splash';

      // If user is authenticated and on auth/welcome/splash screens, send immediately to dashboard
      if (isAuth) {
        if (isLoggingIn || isWelcoming || isSplashing) {
          return '/dashboard';
        }
        return null;
      }

      // If initial launch / checking session, allow splash screen to display and check session
      if (authState.status == AuthStatus.initial) {
        if (isSplashing) {
          return null;
        }
        if (isWelcoming) {
          return '/splash';
        }
        return null;
      }

      // If unauthenticated: bypass welcome/splash and navigate directly to login
      if (isUnauth) {
        if (isSplashing || isWelcoming) {
          return '/login';
        }
        if (isLoggingIn || loc.startsWith('/verify-otp')) {
          return null;
        }
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
          // Branch 0: Dashboard Home
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dashboard',
                builder: (context, state) => const DashboardView(),
              ),
            ],
          ),
          // Branch 1: Attendance
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/attendance',
                builder: (context, state) => const AttendanceView(),
              ),
            ],
          ),
          // Branch 2: Leave
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/leave',
                builder: (context, state) => const LeaveDashboardView(),
              ),
            ],
          ),
          // Branch 3: Payroll
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/payroll',
                builder: (context, state) {
                  return hasAnyPerm([AppPermissions.payrollRead, AppPermissions.payslipRead])
                      ? const PayrollOverviewView()
                      : const AccessRestrictedView(
                          moduleName: 'Payroll & Payslips',
                          requiredPermission: AppPermissions.payrollRead,
                        );
                },
              ),
            ],
          ),
          // Branch 4: Employees
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/employees',
                builder: (context, state) {
                  return hasPerm(AppPermissions.employeeRead)
                      ? const EmployeeListView()
                      : const AccessRestrictedView(
                          moduleName: 'Employee Directory',
                          requiredPermission: AppPermissions.employeeRead,
                        );
                },
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
          if (!hasPerm(AppPermissions.employeeRead)) {
            return const AccessRestrictedView(
              moduleName: 'Employee Directory',
              requiredPermission: AppPermissions.employeeRead,
            );
          }
          final employee = state.extra as EmployeeModel?;
          return EmployeeProfileView(
            employeeId: employee?.id ?? '',
            initialEmployee: employee,
          );
        },
      ),
      GoRoute(
        path: '/third-tab',
        redirect: (context, state) => '/employees',
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationListView(),
      ),
      GoRoute(
        path: '/helpdesk',
        builder: (context, state) {
          return hasPerm(AppPermissions.helpdeskRead)
              ? const HelpdeskListView()
              : const AccessRestrictedView(
                  moduleName: 'Helpdesk & Support',
                  requiredPermission: AppPermissions.helpdeskRead,
                );
        },
      ),
      GoRoute(
        path: '/shift',
        builder: (context, state) {
          return hasAnyPerm([AppPermissions.shiftRead, AppPermissions.shiftRosterRead])
              ? const ShiftRosterView()
              : const AccessRestrictedView(
                  moduleName: 'Shift & Rostering',
                  requiredPermission: AppPermissions.shiftRead,
                );
        },
      ),
      GoRoute(
        path: '/tasks',
        builder: (context, state) => const TaskListView(),
      ),
      GoRoute(
        path: '/assets',
        builder: (context, state) {
          return hasAnyPerm([AppPermissions.assetRead, AppPermissions.assetRequestRead])
              ? const MyAssetsView()
              : const AccessRestrictedView(
                  moduleName: 'Asset Inventory',
                  requiredPermission: AppPermissions.assetRead,
                );
        },
      ),
      GoRoute(
        path: '/performance',
        builder: (context, state) {
          return hasPerm(AppPermissions.performanceRead)
              ? const PerformanceView()
              : const AccessRestrictedView(
                  moduleName: 'Performance Reviews',
                  requiredPermission: AppPermissions.performanceRead,
                );
        },
      ),
      GoRoute(
        path: '/recruitment',
        builder: (context, state) {
          return hasPerm(AppPermissions.recruitmentRead)
              ? const RecruitmentView()
              : const AccessRestrictedView(
                  moduleName: 'Recruitment & ATS',
                  requiredPermission: AppPermissions.recruitmentRead,
                );
        },
      ),
    ],
  );
});
