import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../domain/models/organization_model.dart';
import '../controllers/auth_controller.dart';

class OrganizationSelectorSheet extends ConsumerStatefulWidget {
  final List<OrganizationModel> organizations;
  final bool isSwitchMode;

  const OrganizationSelectorSheet({
    super.key,
    required this.organizations,
    this.isSwitchMode = false,
  });

  static Future<void> show(
    BuildContext context, {
    required List<OrganizationModel> organizations,
    bool isSwitchMode = false,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => OrganizationSelectorSheet(
        organizations: organizations,
        isSwitchMode: isSwitchMode,
      ),
    );
  }

  @override
  ConsumerState<OrganizationSelectorSheet> createState() =>
      _OrganizationSelectorSheetState();
}

class _OrganizationSelectorSheetState
    extends ConsumerState<OrganizationSelectorSheet> {
  String? _selectedTenantId;
  bool _isSubmitting = false;

  Future<void> _handleSelect(String tenantId) async {
    setState(() {
      _selectedTenantId = tenantId;
      _isSubmitting = true;
    });

    try {
      bool success = false;
      if (widget.isSwitchMode) {
        success = await ref
            .read(authControllerProvider.notifier)
            .switchOrganization(tenantId);
      } else {
        success = await ref
            .read(authControllerProvider.notifier)
            .selectTenant(tenantId);
      }

      if (mounted) {
        if (success) {
          Navigator.of(context).pop();
          AppToast.showSuccess(context, 'Workspace selected successfully!');
          context.go('/dashboard');
        } else {
          AppToast.showError(context, 'Failed to select workspace. Please try again.');
          setState(() {
            _isSubmitting = false;
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.business_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.isSwitchMode
                          ? 'Switch Organization'
                          : 'Select Organization',
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Choose which workspace to access',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: widget.organizations.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final org = widget.organizations[index];
                final isSelected = _selectedTenantId == org.id;

                return InkWell(
                  onTap: _isSubmitting ? null : () => _handleSelect(org.id),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.06)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : Colors.grey.shade200,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                          child: Text(
                            org.name.isNotEmpty ? org.name[0].toUpperCase() : 'O',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                org.name,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                org.domain ?? (org.code.isNotEmpty ? org.code : ''),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected && _isSubmitting)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(AppColors.primary),
                            ),
                          )
                        else
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: Colors.grey,
                            size: 18,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
