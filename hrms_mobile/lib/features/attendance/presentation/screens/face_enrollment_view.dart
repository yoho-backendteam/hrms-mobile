import 'dart:async';
import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../data/attendance_repository.dart';
import '../../data/mobile_face_detector.dart';
import '../controllers/attendance_notifier.dart';

enum EnrollmentPhase {
  instructions,
  permissionCheck,
  cameraInitializing,
  scanning,
  positionValid,
  extractingBiometrics,
  enrolledSuccess,
  error,
}

class FaceEnrollmentView extends ConsumerStatefulWidget {
  const FaceEnrollmentView({super.key});

  static Future<void> show(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const FaceEnrollmentView(),
      ),
    );
  }

  @override
  ConsumerState<FaceEnrollmentView> createState() => _FaceEnrollmentViewState();
}

class _FaceEnrollmentViewState extends ConsumerState<FaceEnrollmentView>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  EnrollmentPhase _phase = EnrollmentPhase.instructions;
  FacePositionStatus _positionStatus = FacePositionStatus.noFace;
  String _guidanceMessage = 'Initializing HD camera...';
  String? _errorMessage;

  Timer? _analysisTimer;
  bool _isAnalyzingFrame = false;
  int _consecutiveValidFrames = 0;
  double _progressPercent = 0.0;
  bool _permissionDenied = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
    if (_phase == EnrollmentPhase.instructions) return;
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      _stopAnalysisLoop();
      _disposeCamera();
    } else if (state == AppLifecycleState.resumed) {
      _checkPermissionAndStartCamera();
    }
  }

  void _disposeCamera() {
    _cameraController?.dispose();
    _cameraController = null;
  }

  void _stopAnalysisLoop() {
    _analysisTimer?.cancel();
    _analysisTimer = null;
  }

  Future<void> _checkPermissionAndStartCamera() async {
    setState(() {
      _phase = EnrollmentPhase.permissionCheck;
      _guidanceMessage = 'Requesting camera access...';
      _errorMessage = null;
    });

    final status = await Permission.camera.status;
    if (status.isGranted) {
      await _initializeCamera();
    } else {
      final request = await Permission.camera.request();
      if (request.isGranted) {
        await _initializeCamera();
      } else {
        if (mounted) {
          setState(() {
            _phase = EnrollmentPhase.error;
            _permissionDenied = true;
            _guidanceMessage = 'Camera permission required';
            _errorMessage = 'Camera access is required for biometric face enrollment. Please grant permission to continue.';
          });
        }
      }
    }
  }

  Future<void> _initializeCamera() async {
    if (!mounted) return;
    setState(() {
      _phase = EnrollmentPhase.cameraInitializing;
      _guidanceMessage = 'Starting biometric camera...';
    });

    try {
      final cameras = await availableCameras();
      CameraDescription? frontCam;
      for (final cam in cameras) {
        if (cam.lensDirection == CameraLensDirection.front) {
          frontCam = cam;
          break;
        }
      }
      frontCam ??= cameras.isNotEmpty ? cameras.first : null;

      if (frontCam == null) {
        throw Exception('No camera found on this device');
      }

      final controller = CameraController(
        frontCam,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      _cameraController = controller;
      await controller.initialize();

      if (mounted) {
        setState(() {
          _phase = EnrollmentPhase.scanning;
          _guidanceMessage = 'Position your face inside the frame';
          _errorMessage = null;
        });

        _startContinuousFaceAnalysis();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _phase = EnrollmentPhase.error;
          _errorMessage = 'Failed to initialize camera: ${e.toString().replaceAll("Exception: ", "")}';
        });
      }
    }
  }

  void _startContinuousFaceAnalysis() {
    _stopAnalysisLoop();

    // Analyze frames periodically (every 400ms) to ensure smooth UI and real-time guidance
    _analysisTimer = Timer.periodic(const Duration(milliseconds: 400), (_) async {
      if (!mounted || _isAnalyzingFrame) return;
      if (_phase == EnrollmentPhase.extractingBiometrics || _phase == EnrollmentPhase.enrolledSuccess) return;
      if (_cameraController == null || !_cameraController!.value.isInitialized) return;

      _isAnalyzingFrame = true;
      try {
        final file = await _cameraController!.takePicture();
        final bytes = await file.readAsBytes();

        final result = await MobileFaceDetector.analyzeImageBytes(bytes);

        if (!mounted) return;

        setState(() {
          _positionStatus = result.status;
          _guidanceMessage = result.guidance;
        });

        if (result.status.isValid && result.biometricVector != null) {
          _consecutiveValidFrames++;
          setState(() {
            _phase = EnrollmentPhase.positionValid;
            _progressPercent = math.min(0.9, _consecutiveValidFrames * 0.35);
          });

          // Automatically enroll once face is stably positioned for 2 consecutive captures
          if (_consecutiveValidFrames >= 2) {
            _stopAnalysisLoop();
            await _autoEnrollBiometricVector(result.biometricVector!);
          }
        } else {
          _consecutiveValidFrames = 0;
          if (_phase == EnrollmentPhase.positionValid) {
            setState(() {
              _phase = EnrollmentPhase.scanning;
              _progressPercent = 0.0;
            });
          }
        }
      } catch (_) {
        // Continue loop gracefully
      } finally {
        _isAnalyzingFrame = false;
      }
    });
  }

  Future<void> _autoEnrollBiometricVector(List<double> vector) async {
    if (_phase == EnrollmentPhase.extractingBiometrics) return;

    setState(() {
      _phase = EnrollmentPhase.extractingBiometrics;
      _guidanceMessage = 'Registering biometric profile...';
      _progressPercent = 0.95;
    });

    try {
      final repository = ref.read(attendanceRepositoryProvider);
      final ok = await repository.registerFace(
        template: vector,
        consent: true,
      );

      if (!mounted) return;

      if (ok) {
        setState(() {
          _phase = EnrollmentPhase.enrolledSuccess;
          _progressPercent = 1.0;
          _guidanceMessage = 'Face registered successfully!';
        });

        ref.read(attendanceNotifierProvider.notifier).fetchStatus();

        await Future.delayed(const Duration(milliseconds: 1400));
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✓ Biometric face profile enrolled successfully!'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        throw Exception('Server rejected biometric registration');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _phase = EnrollmentPhase.error;
          _guidanceMessage = 'Enrollment failed';
          _errorMessage = e.toString().replaceAll('Exception: ', '').trim();
          _consecutiveValidFrames = 0;
        });
      }
    }
  }

  void _retryEnrollment() {
    setState(() {
      _phase = EnrollmentPhase.scanning;
      _errorMessage = null;
      _consecutiveValidFrames = 0;
      _progressPercent = 0.0;
    });
    _startContinuousFaceAnalysis();
  }

  Color get _guideColor {
    switch (_phase) {
      case EnrollmentPhase.enrolledSuccess:
        return AppColors.success;
      case EnrollmentPhase.extractingBiometrics:
      case EnrollmentPhase.positionValid:
        return AppColors.info;
      case EnrollmentPhase.error:
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
    if (_phase == EnrollmentPhase.instructions) {
      return _buildInstructionScreen();
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Face Biometric Enrollment'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Guidance Banner
            _buildTopGuidanceBanner(),

            // Large, High-Quality Camera Preview with Biometric Frame Guide
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                child: _buildCameraContainer(),
              ),
            ),

            // Bottom Status & Information Area
            _buildBottomControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionScreen() {
    const instructions = [
      ('Position your face inside the frame.', Icons.crop_free_rounded),
      ('Remove sunglasses, masks, or anything covering your face.', Icons.masks_outlined),
      ('Make sure your face is clearly visible.', Icons.visibility_outlined),
      ('Use a well-lit area.', Icons.wb_sunny_outlined),
      ('Keep the camera at eye level.', Icons.smartphone_rounded),
      ('Hold still during scanning.', Icons.motion_photos_off_rounded),
      ('Only one person should be visible.', Icons.person_outline_rounded),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Face Enrollment'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              Center(
                child: Container(
                  width: 76,
                  height: 76,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.face_retouching_natural_rounded,
                    size: 40,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Center(
                child: Text(
                  'Face Enrollment',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.4,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              const Center(
                child: Text(
                  'Please follow these guidelines for quick, accurate biometric registration.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.3,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Instruction Items List
              Expanded(
                child: ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  itemCount: instructions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final item = instructions[i];
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: const BoxDecoration(
                              color: AppColors.primaryLight,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(item.$2, size: 17, color: AppColors.primary),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              item.$1,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                                height: 1.25,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),
              PrimaryButton(
                text: 'Continue',
                onPressed: () {
                  _checkPermissionAndStartCamera();
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopGuidanceBanner() {
    IconData icon;
    Color iconColor;
    Color bgColor;

    if (_phase == EnrollmentPhase.enrolledSuccess) {
      icon = Icons.check_circle;
      iconColor = AppColors.success;
      bgColor = AppColors.successLight;
    } else if (_phase == EnrollmentPhase.extractingBiometrics) {
      icon = Icons.fingerprint;
      iconColor = AppColors.info;
      bgColor = AppColors.infoLight;
    } else if (_phase == EnrollmentPhase.error) {
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
                  _phase == EnrollmentPhase.enrolledSuccess
                      ? 'Enrollment Complete'
                      : _phase == EnrollmentPhase.extractingBiometrics
                          ? 'Processing Biometrics'
                          : _positionStatus.isValid
                              ? 'Position Verified'
                              : 'Face Alignment',
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
          if (_phase == EnrollmentPhase.extractingBiometrics || _phase == EnrollmentPhase.cameraInitializing)
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
                'Please enable camera permissions in your system settings to enroll your biometric profile.',
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

          // Biometric Centered Face Positioning Frame Guide
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
                  // 4 Dynamic Curved Corner Accents
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

          // Progress Overlay if Auto-Capturing
          if (_progressPercent > 0.0 && _phase != EnrollmentPhase.enrolledSuccess)
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
                    'Automatic verification in progress...',
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

  Widget _buildBottomControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.borderLight, width: 1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_phase == EnrollmentPhase.error) ...[
            PrimaryButton(
              text: 'Retry Enrollment',
              icon: const Icon(Icons.refresh, size: 18, color: Colors.white),
              onPressed: _retryEnrollment,
            ),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.auto_awesome,
                  size: 16,
                  color: _positionStatus.isValid ? AppColors.success : AppColors.textMuted,
                ),
                const SizedBox(width: 8),
                Text(
                  _positionStatus.isValid
                      ? 'Position valid — registering automatically'
                      : 'Automatic biometric capture enabled',
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
