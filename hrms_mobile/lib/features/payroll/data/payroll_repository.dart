import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../domain/models/payroll_model.dart';

final payrollRepositoryProvider = Provider<PayrollRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return PayrollRepository(apiClient: apiClient);
});

class PayrollRepository {
  final ApiClient _apiClient;

  PayrollRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<List<PayslipModel>> getPayslips() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.payslips);
      final data = response['data'] ?? response;
      if (data is List) {
        return data.map((item) => PayslipModel.fromJson(item is Map<String, dynamic> ? item : {})).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<PayslipModel?> getPayslipDetail(String id) async {
    try {
      final response = await _apiClient.get(ApiEndpoints.payslipDetail(id));
      final data = response['data'] ?? response;
      return PayslipModel.fromJson(data is Map<String, dynamic> ? data : {});
    } catch (_) {
      return null;
    }
  }
}
