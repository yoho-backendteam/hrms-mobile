import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../domain/models/leave_model.dart';

final leaveRepositoryProvider = Provider<LeaveRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return LeaveRepository(apiClient: apiClient);
});

class LeaveRepository {
  final ApiClient _apiClient;

  LeaveRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<List<LeaveBalanceModel>> getBalances() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.leaveBalances);
      final data = response['data'] ?? response;
      if (data is List) {
        return data.map((item) => LeaveBalanceModel.fromJson(item is Map<String, dynamic> ? item : {})).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<List<LeaveRequestModel>> getMyRequests() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.leaveMyRequests);
      final data = response['data'] ?? response;
      if (data is List) {
        return data.map((item) => LeaveRequestModel.fromJson(item is Map<String, dynamic> ? item : {})).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<List<LeaveRequestModel>> getPendingApprovals() async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.leaveRequests,
        queryParameters: {'status': 'PENDING'},
      );
      final data = response['data'] ?? response;
      if (data is List) {
        return data.map((item) => LeaveRequestModel.fromJson(item is Map<String, dynamic> ? item : {})).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<bool> applyLeave({
    required String leaveType,
    required String startDate,
    required String endDate,
    required String reason,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.leaveApply,
      data: {
        'leaveType': leaveType,
        'startDate': startDate,
        'endDate': endDate,
        'reason': reason,
      },
    );
    return response['success'] == true;
  }

  Future<bool> approveLeave(String id) async {
    final response = await _apiClient.patch(ApiEndpoints.leaveApprove(id));
    return response['success'] == true;
  }

  Future<bool> rejectLeave(String id, String? reason) async {
    final response = await _apiClient.patch(
      ApiEndpoints.leaveReject(id),
      data: {'reason': reason ?? 'Rejected by supervisor'},
    );
    return response['success'] == true;
  }

  Future<List<HolidayModel>> getHolidays() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.leaveHolidays);
      final data = response['data'] ?? response;
      if (data is List) {
        final list = data.map((item) => HolidayModel.fromJson(item is Map<String, dynamic> ? item : {})).toList();
        list.sort((a, b) => a.startDate.compareTo(b.startDate));
        return list;
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<List<HolidayModel>> getUpcomingHolidays({int limit = 3}) async {
    final all = await getHolidays();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final upcoming = all.where((h) => !h.startDate.isBefore(today)).toList();
    if (upcoming.isNotEmpty) {
      return upcoming.take(limit).toList();
    }
    return [];
  }
}

final holidaysListProvider =
    FutureProvider.autoDispose<List<HolidayModel>>((ref) async {
  return ref.watch(leaveRepositoryProvider).getHolidays();
});

final upcomingHolidaysProvider =
    FutureProvider.autoDispose<List<HolidayModel>>((ref) async {
  return ref.watch(leaveRepositoryProvider).getUpcomingHolidays(limit: 3);
});
