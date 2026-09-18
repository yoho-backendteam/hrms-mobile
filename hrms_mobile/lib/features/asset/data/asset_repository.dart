import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../domain/models/asset_model.dart';

final assetRepositoryProvider = Provider<AssetRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AssetRepository(apiClient: apiClient);
});

class AssetRepository {
  final ApiClient _apiClient;

  AssetRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<List<AssetModel>> getMyAssets() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.assetMy);
      final data = response['data'] ?? response;
      if (data is List) {
        return data.map((item) => AssetModel.fromJson(item is Map<String, dynamic> ? item : {})).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }
}
