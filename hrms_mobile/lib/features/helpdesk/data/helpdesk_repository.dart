import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../domain/models/ticket_model.dart';

final helpdeskRepositoryProvider = Provider<HelpdeskRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return HelpdeskRepository(apiClient: apiClient);
});

class HelpdeskRepository {
  final ApiClient _apiClient;

  HelpdeskRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<List<TicketModel>> getTickets({String? status, String? priority}) async {
    final queryParams = <String, dynamic>{};
    if (status != null && status.isNotEmpty && status != 'ALL') {
      queryParams['status'] = status;
    }
    if (priority != null && priority.isNotEmpty && priority != 'ALL') {
      queryParams['priority'] = priority;
    }

    final response = await _apiClient.get(
      ApiEndpoints.ticketList,
      queryParameters: queryParams,
    );

    final data = response['data'] ?? response;
    if (data is List) {
      return data.map((json) => TicketModel.fromJson(json is Map<String, dynamic> ? json : {})).toList();
    }
    return [];
  }

  Future<TicketModel?> getTicketDetail(String id) async {
    final response = await _apiClient.get(ApiEndpoints.ticketDetail(id));
    final data = response['data'] ?? response;
    if (data is Map<String, dynamic>) {
      return TicketModel.fromJson(data);
    }
    return null;
  }

  Future<TicketModel> createTicket({
    required String title,
    required String description,
    required String category,
    String priority = 'MEDIUM',
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.ticketCreate,
      data: {
        'title': title,
        'description': description,
        'category': category,
        'priority': priority,
      },
    );

    final data = response['data'] ?? response;
    return TicketModel.fromJson(data is Map<String, dynamic> ? data : {});
  }

  Future<bool> updateTicketStatus(String id, String status) async {
    final response = await _apiClient.patch(
      ApiEndpoints.ticketUpdate(id),
      data: {'status': status},
    );
    return response['success'] == true || response != null;
  }

  Future<List<TicketCommentModel>> getTicketComments(String ticketId) async {
    final response = await _apiClient.get(ApiEndpoints.ticketComments(ticketId));
    final data = response['data'] ?? response;
    if (data is List) {
      return data.map((json) => TicketCommentModel.fromJson(json is Map<String, dynamic> ? json : {})).toList();
    }
    return [];
  }

  Future<TicketCommentModel> addComment({
    required String ticketId,
    required String message,
    bool isInternal = false,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.ticketComments(ticketId),
      data: {
        'message': message,
        'isInternal': isInternal,
      },
    );

    final data = response['data'] ?? response;
    return TicketCommentModel.fromJson(data is Map<String, dynamic> ? data : {});
  }
}
