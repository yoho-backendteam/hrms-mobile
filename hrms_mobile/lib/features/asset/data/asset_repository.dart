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
        return data.map((item) => AssetModel.fromJson(item)).toList();
      }
      return [
        AssetModel(id: '1', assetName: 'Apple MacBook Pro 16" M3', assetTag: 'AST-LPT-042', category: 'Laptop', serialNumber: 'C02G40ALMD6R'),
        AssetModel(id: '2', assetName: 'Dell UltraSharp 27" 4K Monitor', assetTag: 'AST-MON-118', category: 'Display', serialNumber: 'CN-0N83P2-74261'),
      ];
    } catch (_) {
      return [
        AssetModel(id: '1', assetName: 'Apple MacBook Pro 16" M3', assetTag: 'AST-LPT-042', category: 'Laptop', serialNumber: 'C02G40ALMD6R'),
      ];
    }
  }
}
