import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../domain/models/task_model.dart';

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return TaskRepository(apiClient: apiClient);
});

class TaskRepository {
  final ApiClient _apiClient;

  TaskRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<List<TaskModel>> getTasks() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.taskList);
      final data = response['data'] ?? response;
      if (data is List) {
        return data.map((item) => TaskModel.fromJson(item is Map<String, dynamic> ? item : {})).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<bool> updateTaskStatus(String id, String status) async {
    final response = await _apiClient.patch(
      '${ApiEndpoints.taskList}/$id',
      data: {'status': status},
    );
    return response['success'] == true;
  }
}
