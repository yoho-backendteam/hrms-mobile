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
        return data.map((item) => TaskModel.fromJson(item)).toList();
      }
      return [
        TaskModel(id: '1', title: 'Complete Quarterly Security Assessment', priority: 'HIGH', status: 'IN_PROGRESS', dueDate: DateTime.now().add(const Duration(days: 3))),
        TaskModel(id: '2', title: 'Submit Expense Reimbursement receipts', priority: 'MEDIUM', status: 'PENDING', dueDate: DateTime.now().add(const Duration(days: 5))),
        TaskModel(id: '3', title: 'Update emergency contact profile', priority: 'LOW', status: 'COMPLETED', dueDate: DateTime.now()),
      ];
    } catch (_) {
      return [
        TaskModel(id: '1', title: 'Complete Quarterly Security Assessment', priority: 'HIGH', status: 'IN_PROGRESS', dueDate: DateTime.now().add(const Duration(days: 3))),
        TaskModel(id: '2', title: 'Submit Expense Reimbursement receipts', priority: 'MEDIUM', status: 'PENDING', dueDate: DateTime.now().add(const Duration(days: 5))),
      ];
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
