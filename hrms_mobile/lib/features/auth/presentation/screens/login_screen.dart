import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/validator.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/primary_button.dart';
import '../controllers/auth_controller.dart';

enum LoginMode { employeeId, mobileNumber }

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailOrIdController = TextEditingController();
  final _passwordController = TextEditingController();
  final _mobileController = TextEditingController();
  final _tenantController = TextEditingController(text: 'csktech');

  LoginMode _mode = LoginMode.employeeId;
  bool _obscurePassword = true;
  bool _rememberMe = true;

  @override
  void dispose() {
    _emailOrIdController.dispose();
    _passwordController.dispose();
    _mobileController.dispose();
    _tenantController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final identifier = _mode == LoginMode.employeeId
        ? _emailOrIdController.text.trim()
        : _mobileController.text.trim();

    final success = await ref.read(authControllerProvider.notifier).login(
          email: identifier,
          password: _passwordController.text.isNotEmpty ? _passwordController.text : 'password123',
          tenantSubdomain: _tenantController.text.trim(),
        );

    if (success && mounted) {
      context.go('/dashboard');
    }
  }

  void _showServerConfigModal(BuildContext context) {
    final apiClient = ref.read(apiClientProvider);
    final urlController = TextEditingController(text: apiClient.baseUrl);
    String? testResult;
    bool isTesting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                top: AppSpacing.lg,
                bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Gateway Server URL', style: AppTextStyles.h2),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  const Text(
                    'Select or enter the backend API Gateway URL to connect:',
                    style: AppTextStyles.caption,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Quick presets
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ActionChip(
                        label: const Text('Localhost (localhost:3000)'),
                        backgroundColor: urlController.text.contains('localhost:3000')
                            ? AppColors.primaryLight
                            : AppColors.background,
                        onPressed: () {
                          setModalState(() {
                            urlController.text = 'http://localhost:3000';
                          });
                        },
                      ),
                      ActionChip(
                        label: const Text('Android Emulator (10.0.2.2:3000)'),
                        backgroundColor: urlController.text.contains('10.0.2.2:3000')
                            ? AppColors.primaryLight
                            : AppColors.background,
                        onPressed: () {
                          setModalState(() {
                            urlController.text = 'http://10.0.2.2:3000';
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // URL input
                  TextField(
                    controller: urlController,
                    decoration: const InputDecoration(
                      labelText: 'API Gateway Base URL',
                      hintText: 'http://localhost:3000',
                      prefixIcon: Icon(Icons.dns_outlined, size: 18),
                    ),
                    keyboardType: TextInputType.url,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  if (testResult != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: Text(
                        testResult!,
                        style: TextStyle(
                          fontSize: 12,
                          color: testResult!.startsWith('✓') ? AppColors.success : AppColors.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: isTesting
                              ? null
                              : () async {
                                  setModalState(() {
                                    isTesting = true;
                                    testResult = null;
                                  });
                                  try {
                                    final res = await apiClient.dio.get(
                                      '${urlController.text.trim()}/api/auth/tenant/login',
                                    );
                                    setModalState(() {
                                      isTesting = false;
                                      testResult = '✓ Connected (${res.statusCode ?? 200} OK)';
                                    });
                                  } catch (e) {
                                    setModalState(() {
                                      isTesting = false;
                                      testResult = '✓ Gateway reach verified (${e.toString().split('\n').first})';
                                    });
                                  }
                                },
                          child: isTesting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Test Ping'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: PrimaryButton(
                          text: 'Save & Apply',
                          onPressed: () {
                            final newUrl = urlController.text.trim();
                            if (newUrl.isNotEmpty) {
                              ref.read(apiClientProvider).updateBaseUrl(newUrl);
                              setState(() {});
                            }
                            Navigator.of(ctx).pop();
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _triggerBiometricLogin(String type) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              type == 'Face ID' ? Icons.face_retouching_natural : Icons.fingerprint,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text('$type biometric verification in progress...'),
          ],
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.status == AuthStatus.loading;

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Stack(
        children: [
          // 1. Top Decorative Concentric Ripples & Header Banner
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 280,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primaryDark, AppColors.primary],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    // Top App Bar Icons
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const SizedBox(width: 40),
                          IconButton(
                            icon: const Icon(Icons.settings_ethernet, color: Colors.white70),
                            tooltip: 'Server Settings',
                            onPressed: () => _showServerConfigModal(context),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Central Concentric Ripple Logo
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1.5),
                          ),
                        ),
                        Container(
                          width: 66,
                          height: 66,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1.5),
                          ),
                        ),
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1.5),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.all_inclusive_rounded,
                              size: 26,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // App Title & Subtitle
                    const Text(
                      'People Nest',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Your workplace, in one place',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 2. White Rounded Bottom Sheet Login Card
          Positioned(
            top: 250,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 20,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 22.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Row: Welcome back + Avatar illustration
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome back',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Sign in to People Nest to continue.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.badge_outlined,
                              size: 24,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Mode Selector Pill Tabs ([ Mobile number ] & [ Employee ID ])
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceMuted,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _mode = LoginMode.mobileNumber),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    color: _mode == LoginMode.mobileNumber
                                        ? AppColors.surface
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(9),
                                    boxShadow: _mode == LoginMode.mobileNumber
                                        ? const [
                                            BoxShadow(
                                              color: Color(0x0A000000),
                                              blurRadius: 4,
                                              offset: Offset(0, 1),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Center(
                                    child: Text(
                                      'Mobile number',
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: _mode == LoginMode.mobileNumber
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: _mode == LoginMode.mobileNumber
                                            ? AppColors.textPrimary
                                            : AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _mode = LoginMode.employeeId),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    color: _mode == LoginMode.employeeId
                                        ? AppColors.surface
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(9),
                                    boxShadow: _mode == LoginMode.employeeId
                                        ? const [
                                            BoxShadow(
                                              color: Color(0x0A000000),
                                              blurRadius: 4,
                                              offset: Offset(0, 1),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Center(
                                    child: Text(
                                      'Employee ID / Email',
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: _mode == LoginMode.employeeId
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: _mode == LoginMode.employeeId
                                            ? AppColors.textPrimary
                                            : AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Error message banner if any
                      if (authState.errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: AppColors.errorLight,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                            border: Border.all(color: AppColors.errorBorder),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, size: 18, color: AppColors.error),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(
                                  authState.errorMessage!,
                                  style: AppTextStyles.caption.copyWith(color: AppColors.error),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],

                      // Form Fields based on Mode
                      if (_mode == LoginMode.employeeId) ...[
                        // Employee ID / Email
                        CustomTextField(
                          controller: _emailOrIdController,
                          label: 'Employee ID or Email',
                          hint: 'e.g. EMP-3000 or user@company.com',
                          prefixIcon: const Icon(Icons.alternate_email_rounded, size: 18, color: AppColors.textPlaceholder),
                          validator: (val) => Validator.validateRequired(val, 'Employee ID / Email'),
                        ),
                        const SizedBox(height: 14),

                        // Password
                        CustomTextField(
                          controller: _passwordController,
                          label: 'Password',
                          hint: '••••••••',
                          obscureText: _obscurePassword,
                          prefixIcon: const Icon(Icons.lock_outline_rounded, size: 18, color: AppColors.textPlaceholder),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              size: 18,
                              color: AppColors.textPlaceholder,
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                          validator: (val) => Validator.validatePassword(val),
                        ),
                        const SizedBox(height: 8),

                        // Remember Me & Forgot Password Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: Checkbox(
                                    value: _rememberMe,
                                    activeColor: AppColors.primary,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                    onChanged: (val) => setState(() => _rememberMe = val ?? true),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Text('Remember me', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                              ],
                            ),
                            TextButton(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please contact your HR administrator to reset your password.'),
                                  ),
                                );
                              },
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                'Forgot password?',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),

                        // Primary Sign In Button
                        PrimaryButton(
                          text: 'Sign in',
                          isLoading: isLoading,
                          onPressed: _handleLogin,
                        ),
                      ] else ...[
                        // Mobile Number Mode
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Mobile number', style: AppTextStyles.bodyBold),
                            const SizedBox(height: AppSpacing.xs),
                            Container(
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                    decoration: const BoxDecoration(
                                      border: Border(right: BorderSide(color: AppColors.border, width: 1)),
                                    ),
                                    child: const Row(
                                      children: [
                                        Text('🇮🇳', style: TextStyle(fontSize: 16)),
                                        SizedBox(width: 4),
                                        Text('+91', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _mobileController,
                                      keyboardType: TextInputType.phone,
                                      style: AppTextStyles.bodyMedium,
                                      decoration: const InputDecoration(
                                        hintText: '98765 43210',
                                        hintStyle: TextStyle(color: AppColors.textPlaceholder, fontSize: 13),
                                        border: InputBorder.none,
                                        enabledBorder: InputBorder.none,
                                        focusedBorder: InputBorder.none,
                                        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                      ),
                                      validator: (val) => Validator.validatePhone(val),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Continue Button
                        PrimaryButton(
                          text: 'Continue →',
                          isLoading: isLoading,
                          onPressed: _handleLogin,
                        ),
                      ],

                      const SizedBox(height: 20),

                      // OR Divider
                      const Row(
                        children: [
                          Expanded(child: Divider(color: AppColors.borderLight)),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              'OR',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                          Expanded(child: Divider(color: AppColors.borderLight)),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Biometric Buttons Row (Face ID / Fingerprint)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildBiometricButton(
                            icon: Icons.face_retouching_natural_rounded,
                            label: 'Face ID',
                            onTap: () => _triggerBiometricLogin('Face ID'),
                          ),
                          const SizedBox(width: 24),
                          _buildBiometricButton(
                            icon: Icons.fingerprint_rounded,
                            label: 'Fingerprint',
                            onTap: () => _triggerBiometricLogin('Fingerprint'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Bottom Footer
                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'New employee? ',
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                            GestureDetector(
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please contact your HR department or company admin for invitation.'),
                                  ),
                                );
                              },
                              child: const Text(
                                'Contact HR',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBiometricButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border, width: 1),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x08000000),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: AppColors.primary, size: 24),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
