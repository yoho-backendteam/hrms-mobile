import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../domain/models/notification_model.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return NotificationRepository(apiClient: apiClient);
});

class NotificationRepository {
  final ApiClient _apiClient;

  NotificationRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<List<NotificationModel>> getNotifications() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.notifications);
      final data = response['data'] ?? response;
      if (data is List) {
        return data.map((item) => NotificationModel.fromJson(item is Map<String, dynamic> ? item : {})).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<bool> markAllAsRead() async {
    final response = await _apiClient.post(ApiEndpoints.notificationMarkAllRead);
    return response['success'] == true;
  }
}
