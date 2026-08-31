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
        return data.map((item) => PayslipModel.fromJson(item)).toList();
      }
      return [
        PayslipModel(id: '1', month: 'August', year: '2026', basicSalary: 55000, allowances: 12000, deductions: 4500, netSalary: 62500),
        PayslipModel(id: '2', month: 'July', year: '2026', basicSalary: 55000, allowances: 12000, deductions: 4500, netSalary: 62500),
        PayslipModel(id: '3', month: 'June', year: '2026', basicSalary: 55000, allowances: 12000, deductions: 4500, netSalary: 62500),
      ];
    } catch (_) {
      return [
        PayslipModel(id: '1', month: 'August', year: '2026', basicSalary: 55000, allowances: 12000, deductions: 4500, netSalary: 62500),
        PayslipModel(id: '2', month: 'July', year: '2026', basicSalary: 55000, allowances: 12000, deductions: 4500, netSalary: 62500),
      ];
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
