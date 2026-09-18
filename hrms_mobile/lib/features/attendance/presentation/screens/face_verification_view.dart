import 'dart:async';
import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../data/attendance_repository.dart';
import '../../data/face_verification_service.dart';
import '../../data/geo_location_service.dart';
import '../../data/mobile_face_detector.dart';
import '../../domain/models/location_model.dart';

enum AttendanceModalAction {
  clockIn,
  breakIn,
  breakOut,
  clockOut,
}

extension AttendanceModalActionExt on AttendanceModalAction {
  String get name {
    switch (this) {
      case AttendanceModalAction.clockIn:
        return 'Clock In';
      case AttendanceModalAction.breakIn:
        return 'Break In';
      case AttendanceModalAction.breakOut:
        return 'Break Out';
      case AttendanceModalAction.clockOut:
        return 'Clock Out';
    }
  }
}

enum VerificationPhase {
  cameraInitializing,
  scanning,
  positionValid,
  verifyingBiometrics,
  verifiedSuccess,
  error,
}

class FaceVerificationView extends ConsumerStatefulWidget {
  final AttendanceModalAction action;
  final Function(LocationCoords? coords, List<double>? template) onVerified;

  const FaceVerificationView({
    super.key,
    required this.action,
    required this.onVerified,
  });

  static Future<void> show({
    required BuildContext context,
    required AttendanceModalAction action,
    required Function(LocationCoords? coords, List<double>? template) onVerified,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => FaceVerificationView(
          action: action,
          onVerified: onVerified,
        ),
      ),
    );
  }

  @override
  ConsumerState<FaceVerificationView> createState() => _FaceVerificationViewState();
}

class _FaceVerificationViewState extends ConsumerState<FaceVerificationView>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  VerificationPhase _phase = VerificationPhase.cameraInitializing;
  FacePositionStatus _positionStatus = FacePositionStatus.noFace;
  String _guidanceMessage = 'Starting camera...';
  String? _errorMessage;

  LocationCoords? _location;
  Timer? _analysisTimer;
  bool _isAnalyzingFrame = false;
  int _consecutiveValidFrames = 0;
  double _progressPercent = 0.0;
  bool _permissionDenied = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fetchLocationAndStartCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopAnalysisLoop();
    _disposeCamera();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      _stopAnalysisLoop();
      _disposeCamera();
    } else if (state == AppLifecycleState.resumed) {
      _fetchLocationAndStartCamera();
    }
  }

  void _disposeCamera() {
    ref.read(faceVerificationServiceProvider).dispose();
    _cameraController = null;
  }

  void _stopAnalysisLoop() {
    _analysisTimer?.cancel();
    _analysisTimer = null;
  }

  Future<void> _fetchLocationAndStartCamera() async {
    // Acquire GPS location in parallel
    GeoLocationService().getCurrentLocation().then((loc) {
      _location = loc;
    });

    final status = await Permission.camera.status;
    if (status.isGranted) {
      await _initCamera();
    } else {
      final res = await Permission.camera.request();
      if (res.isGranted) {
        await _initCamera();
      } else {
        if (mounted) {
          setState(() {
            _phase = VerificationPhase.error;
            _permissionDenied = true;
            _guidanceMessage = 'Camera permission required';
            _errorMessage = 'Camera access is required for identity verification. Please enable camera in device settings.';
          });
        }
      }
    }
  }

  Future<void> _initCamera() async {
    if (!mounted) return;
    setState(() {
      _phase = VerificationPhase.cameraInitializing;
      _guidanceMessage = 'Starting biometric camera...';
    });

    try {
      final service = ref.read(faceVerificationServiceProvider);
      final controller = await service.initializeCamera();

      if (mounted) {
        setState(() {
          _cameraController = controller;
          _phase = VerificationPhase.scanning;
          _guidanceMessage = 'Position your face inside the frame';
          _errorMessage = null;
        });

        _startContinuousFaceAnalysis();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _phase = VerificationPhase.error;
          _errorMessage = 'Failed to initialize camera: ${e.toString().replaceAll("Exception: ", "")}';
        });
      }
    }
  }

  void _startContinuousFaceAnalysis() {
    _stopAnalysisLoop();

    _analysisTimer = Timer.periodic(const Duration(milliseconds: 380), (_) async {
      if (!mounted || _isAnalyzingFrame) return;
      if (_phase == VerificationPhase.verifyingBiometrics || _phase == VerificationPhase.verifiedSuccess) return;
      final service = ref.read(faceVerificationServiceProvider);
      if (!service.isCameraReady) return;

      _isAnalyzingFrame = true;
      try {
        final result = await service.captureAndAnalyzeFrame();

        if (!mounted) return;

        setState(() {
          _positionStatus = result.status;
          _guidanceMessage = result.guidance;
        });

        if (result.status.isValid && result.biometricVector != null) {
          _consecutiveValidFrames++;
          setState(() {
            _phase = VerificationPhase.positionValid;
            _progressPercent = math.min(0.9, _consecutiveValidFrames * 0.45);
          });

          // Automatically verify once face is stably positioned for 2 captures
          if (_consecutiveValidFrames >= 2) {
            _stopAnalysisLoop();
            await _autoVerifyBiometricVector(result.biometricVector!);
          }
        } else {
          _consecutiveValidFrames = 0;
          if (_phase == VerificationPhase.positionValid) {
            setState(() {
              _phase = VerificationPhase.scanning;
              _progressPercent = 0.0;
            });
          }
        }
      } catch (_) {
        // Continue gracefully
      } finally {
        _isAnalyzingFrame = false;
      }
    });
  }

  Future<void> _autoVerifyBiometricVector(List<double> vector) async {
    if (_phase == VerificationPhase.verifyingBiometrics) return;

    setState(() {
      _phase = VerificationPhase.verifyingBiometrics;
      _guidanceMessage = 'Verifying your identity...';
      _progressPercent = 0.95;
    });

    try {
      final service = ref.read(faceVerificationServiceProvider);
      final isLivenessValid = service.evaluatePassiveLiveness();

      final repository = ref.read(attendanceRepositoryProvider);
      final verified = await repository.verifyFace(
        template: vector,
        livenessData: {
          'centerAngle': true,
          'passiveLiveness': isLivenessValid,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      if (!mounted) return;

      if (verified) {
        setState(() {
          _phase = VerificationPhase.verifiedSuccess;
          _progressPercent = 1.0;
          _guidanceMessage = 'Identity verified successfully!';
        });

        await Future.delayed(const Duration(milliseconds: 900));
        if (mounted) {
          Navigator.of(context).pop();
          widget.onVerified(_location, vector);
        }
      } else {
        throw Exception('Face identity does not match enrolled profile');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _phase = VerificationPhase.error;
          _guidanceMessage = 'Verification failed';
          _errorMessage = e.toString().replaceAll('Exception: ', '').trim();
          _consecutiveValidFrames = 0;
        });
      }
    }
  }

  void _retryVerification() {
    setState(() {
      _phase = VerificationPhase.scanning;
      _errorMessage = null;
      _consecutiveValidFrames = 0;
      _progressPercent = 0.0;
    });
    _startContinuousFaceAnalysis();
  }

  Color get _guideColor {
    switch (_phase) {
      case VerificationPhase.verifiedSuccess:
        return AppColors.success;
      case VerificationPhase.verifyingBiometrics:
      case VerificationPhase.positionValid:
        return AppColors.info;
      case VerificationPhase.error:
        return AppColors.error;
      default:
        if (_positionStatus == FacePositionStatus.noFace) {
          return Colors.white.withValues(alpha: 0.85);
        } else if (_positionStatus.isValid) {
          return AppColors.success;
        } else {
          return AppColors.warning;
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('${widget.action.name} — Face Verification'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Guidance Banner
            _buildGuidanceBanner(),

            // High-Quality Camera Preview with Centered Face Guide
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                child: _buildCameraContainer(),
              ),
            ),

            // Bottom Information / Controls
            _buildBottomArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildGuidanceBanner() {
    IconData icon;
    Color iconColor;
    Color bgColor;

    if (_phase == VerificationPhase.verifiedSuccess) {
      icon = Icons.check_circle;
      iconColor = AppColors.success;
      bgColor = AppColors.successLight;
    } else if (_phase == VerificationPhase.verifyingBiometrics) {
      icon = Icons.security;
      iconColor = AppColors.info;
      bgColor = AppColors.infoLight;
    } else if (_phase == VerificationPhase.error) {
      icon = Icons.error_outline;
      iconColor = AppColors.error;
      bgColor = AppColors.errorLight;
    } else if (_positionStatus.isValid) {
      icon = Icons.face_retouching_natural;
      iconColor = AppColors.success;
      bgColor = AppColors.successLight;
    } else if (_positionStatus != FacePositionStatus.noFace) {
      icon = Icons.warning_amber_rounded;
      iconColor = AppColors.warning;
      bgColor = AppColors.warningLight;
    } else {
      icon = Icons.face;
      iconColor = AppColors.primary;
      bgColor = AppColors.primaryLight;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _phase == VerificationPhase.verifiedSuccess
                      ? 'Identity Verified'
                      : _phase == VerificationPhase.verifyingBiometrics
                          ? 'Checking Biometric Template'
                          : _positionStatus.isValid
                              ? 'Face Aligned'
                              : 'Positioning Guidance',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: iconColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _errorMessage ?? _guidanceMessage,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          if (_phase == VerificationPhase.verifyingBiometrics || _phase == VerificationPhase.cameraInitializing)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
            ),
        ],
      ),
    );
  }

  Widget _buildCameraContainer() {
    final controller = _cameraController;

    if (_permissionDenied) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.no_photography_outlined, size: 56, color: AppColors.error),
            const SizedBox(height: 16),
            const Text(
              'Camera Permission Required',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32.0),
              child: Text(
                'Please enable camera permissions to verify your face for attendance.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: openAppSettings,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Open Settings', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    if (controller == null || !controller.value.isInitialized) {
      return Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Live Camera Preview
          Center(
            child: CameraPreview(controller),
          ),

          // Centered Face Guide
          Center(
            child: Container(
              width: 230,
              height: 290,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(36),
                border: Border.all(color: _guideColor, width: 2.5),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: -2,
                    left: -2,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: _guideColor, width: 4.5),
                          left: BorderSide(color: _guideColor, width: 4.5),
                        ),
                        borderRadius: const BorderRadius.only(topLeft: Radius.circular(36)),
                      ),
                    ),
                  ),
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: _guideColor, width: 4.5),
                          right: BorderSide(color: _guideColor, width: 4.5),
                        ),
                        borderRadius: const BorderRadius.only(topRight: Radius.circular(36)),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -2,
                    left: -2,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: _guideColor, width: 4.5),
                          left: BorderSide(color: _guideColor, width: 4.5),
                        ),
                        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(36)),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -2,
                    right: -2,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: _guideColor, width: 4.5),
                          right: BorderSide(color: _guideColor, width: 4.5),
                        ),
                        borderRadius: const BorderRadius.only(bottomRight: Radius.circular(36)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Progress Indicator during Auto-Verification
          if (_progressPercent > 0.0 && _phase != VerificationPhase.verifiedSuccess)
            Positioned(
              bottom: 20,
              left: 32,
              right: 32,
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: _progressPercent,
                      minHeight: 6,
                      backgroundColor: Colors.white30,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Verifying biometric match...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      shadows: [Shadow(blurRadius: 4, color: Colors.black)],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.borderLight, width: 1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_phase == VerificationPhase.error) ...[
            PrimaryButton(
              text: 'Try Again',
              icon: const Icon(Icons.refresh, size: 18, color: Colors.white),
              onPressed: _retryVerification,
            ),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.verified_user_outlined,
                  size: 16,
                  color: _positionStatus.isValid ? AppColors.success : AppColors.textMuted,
                ),
                const SizedBox(width: 8),
                Text(
                  _positionStatus.isValid
                      ? 'Face aligned — verifying automatically'
                      : 'Align face inside frame to verify',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _positionStatus.isValid ? AppColors.success : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
