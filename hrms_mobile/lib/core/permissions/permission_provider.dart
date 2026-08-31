import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';
import 'permission_constants.dart';

final userPermissionsProvider = Provider<List<String>>((ref) {
  final authState = ref.watch(authControllerProvider);
  return authState.user?.permissions ?? [];
});

final userRolesProvider = Provider<List<String>>((ref) {
  final authState = ref.watch(authControllerProvider);
  return authState.user?.roles.isNotEmpty == true
      ? authState.user!.roles
      : [authState.user?.role ?? 'EMPLOYEE'];
});

final isTenantOwnerProvider = Provider<bool>((ref) {
  final roles = ref.watch(userRolesProvider);
  return roles.any((r) {
    final normalized = r.trim().toUpperCase().replaceAll(RegExp(r'[\s_-]+'), '');
    return normalized == 'TENANTOWNER' ||
        normalized == 'SUPERADMIN' ||
        normalized == 'PLATFORMSUPERADMIN' ||
        normalized == 'TENANTSUPERADMIN';
  });
});

final isAdminOrHRProvider = Provider<bool>((ref) {
  final isOwner = ref.watch(isTenantOwnerProvider);
  if (isOwner) return true;

  final roles = ref.watch(userRolesProvider);
  return roles.any((r) {
    final normalized = r.trim().toUpperCase().replaceAll(RegExp(r'[\s_-]+'), '');
    return normalized == 'HRADMIN' ||
        normalized == 'HRMANAGER' ||
        normalized == 'HREXECUTIVE' ||
        normalized == 'HR' ||
        normalized == 'ADMIN' ||
        normalized == 'PAYROLLADMIN' ||
        normalized == 'PAYROLLMANAGER' ||
        normalized == 'DEPARTMENTMANAGER' ||
        normalized == 'MANAGER';
  });
});

final isHRorAdminProvider = Provider<bool>((ref) {
  return ref.watch(isAdminOrHRProvider);
});

final isEmployeeOnlyProvider = Provider<bool>((ref) {
  final isAdminOrHr = ref.watch(isAdminOrHRProvider);
  return !isAdminOrHr;
});

final hasPermissionProvider = Provider.family<bool, String>((ref, requiredPermission) {
  final isOwner = ref.watch(isTenantOwnerProvider);
  if (isOwner) return true;

  final permissions = ref.watch(userPermissionsProvider);
  if (permissions.contains(AppPermissions.all)) return true;

  return permissions.contains(requiredPermission);
});

final hasAnyPermissionProvider = Provider.family<bool, List<String>>((ref, requiredPermissions) {
  final isOwner = ref.watch(isTenantOwnerProvider);
  if (isOwner) return true;

  final permissions = ref.watch(userPermissionsProvider);
  if (permissions.contains(AppPermissions.all)) return true;

  return requiredPermissions.any((perm) => permissions.contains(perm));
});

final hasAllPermissionsProvider = Provider.family<bool, List<String>>((ref, requiredPermissions) {
  final isOwner = ref.watch(isTenantOwnerProvider);
  if (isOwner) return true;

  final permissions = ref.watch(userPermissionsProvider);
  if (permissions.contains(AppPermissions.all)) return true;

  return requiredPermissions.every((perm) => permissions.contains(perm));
});
