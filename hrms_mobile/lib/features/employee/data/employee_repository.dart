import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../domain/models/employee_model.dart';

final employeeRepositoryProvider = Provider<EmployeeRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return EmployeeRepository(apiClient: apiClient);
});

class EmployeeRepository {
  final ApiClient _apiClient;

  EmployeeRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<List<EmployeeModel>> getEmployees({
    String? search,
    String? departmentId,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.employeeList,
        queryParameters: {
          if (search != null && search.isNotEmpty) 'search': search,
          if (departmentId != null) 'departmentId': departmentId,
          'page': page,
          'limit': limit,
        },
      );

      final data = response['data'] ?? response;
      if (data is List) {
        return data.map((e) => EmployeeModel.fromJson(e is Map<String, dynamic> ? e : {})).toList();
      } else if (data is Map && data['employees'] is List) {
        return (data['employees'] as List)
            .map((e) => EmployeeModel.fromJson(e is Map<String, dynamic> ? e : {}))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>> getEmployeeProfileBff(String employeeId) async {
    final response = await _apiClient.get(
      ApiEndpoints.employeeProfileBff(employeeId),
    );
    return response['data'] ?? response;
  }
}
