import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/widgets/loading_skeleton.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../data/asset_repository.dart';
import '../../domain/models/asset_model.dart';

final myAssetsProvider = FutureProvider.autoDispose<List<AssetModel>>((ref) async {
  return ref.watch(assetRepositoryProvider).getMyAssets();
});

class MyAssetsView extends ConsumerWidget {
  const MyAssetsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assetsAsync = ref.watch(myAssetsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Assigned Assets'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(myAssetsProvider),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            assetsAsync.when(
              loading: () => const ListLoadingSkeleton(count: 3),
              error: (err, _) => Text('Error: $err', style: AppTextStyles.caption),
              data: (assets) {
                if (assets.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: EmptyStateView(
                      icon: Icons.devices_other_outlined,
                      title: 'No Assets Assigned',
                      description: 'You do not have any company hardware assigned yet.',
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: assets.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final item = assets[index];
                    return Container(
                      padding: AppSpacing.cardPadding,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                            ),
                            child: const Icon(Icons.laptop_chromebook, size: 24, color: AppColors.primary),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.assetName, style: AppTextStyles.bodyBold),
                                const SizedBox(height: 2),
                                Text(
                                  'Tag: ${item.assetTag} • S/N: ${item.serialNumber}',
                                  style: AppTextStyles.caption,
                                ),
                                const SizedBox(height: 2),
                                Text('Category: ${item.category}', style: AppTextStyles.caption.copyWith(fontSize: 10)),
                              ],
                            ),
                          ),
                          StatusBadge.fromStatus(item.status),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
