import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../domain/models/shift_model.dart';

final shiftRepositoryProvider = Provider<ShiftRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ShiftRepository(apiClient: apiClient);
});

class ShiftRepository {
  final ApiClient _apiClient;

  ShiftRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<List<ShiftModel>> getAssignedShifts() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.shiftAssigned);
      final data = response['data'] ?? response;
      if (data is List) {
        return data.map((item) => ShiftModel.fromJson(item)).toList();
      }
      return [
        ShiftModel(id: '1', name: 'Standard Day Shift', startTime: '09:00 AM', endTime: '06:00 PM', isDefault: true),
        ShiftModel(id: '2', name: 'Flexible Shift', startTime: '10:00 AM', endTime: '07:00 PM'),
      ];
    } catch (_) {
      return [
        ShiftModel(id: '1', name: 'Standard Day Shift', startTime: '09:00 AM', endTime: '06:00 PM', isDefault: true),
      ];
    }
  }

  Future<ShiftModel?> getTodayShift() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.shiftToday);
      final data = response['data'] ?? response;
      if (data is Map<String, dynamic> && data.isNotEmpty) {
        return ShiftModel.fromJson(data);
      }
      return ShiftModel(id: '1', name: 'General Shift', startTime: '09:00 AM', endTime: '06:00 PM', isDefault: true);
    } catch (_) {
      return ShiftModel(id: '1', name: 'General Shift', startTime: '09:00 AM', endTime: '06:00 PM', isDefault: true);
    }
  }
}
