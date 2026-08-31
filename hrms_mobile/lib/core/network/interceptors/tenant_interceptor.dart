import 'package:dio/dio.dart';
import '../../storage/secure_storage_service.dart';

class TenantInterceptor extends Interceptor {
  final SecureStorageService _storage;

  TenantInterceptor({required SecureStorageService storage}) : _storage = storage;

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    final tenant = await _storage.getTenant();
    final tenantId = await _storage.getTenantId();

    if (tenant != null && tenant.isNotEmpty) {
      options.headers['X-Tenant'] = tenant;
      options.headers['x-tenant'] = tenant;
      if (tenantId != null && tenantId.isNotEmpty) {
        options.headers['x-tenant-id'] = tenantId;
      }
    } else if (tenantId != null && tenantId.isNotEmpty) {
      options.headers['X-Tenant'] = tenantId;
      options.headers['x-tenant'] = tenantId;
      options.headers['x-tenant-id'] = tenantId;
    }

    handler.next(options);
  }
}
