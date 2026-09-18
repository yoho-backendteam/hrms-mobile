import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import 'mobile_face_detector.dart';

final faceVerificationServiceProvider = Provider<FaceVerificationService>((ref) {
  return FaceVerificationService();
});

/// Shared face verification & enrollment coordinator
class FaceVerificationService {
  CameraController? _cameraController;
  bool _isProcessing = false;
  CameraDescription? _frontCamera;

  // Liveness temporal history
  final List<double> _luminanceHistory = [];
  final List<double> _centerHistory = [];

  CameraController? get cameraController => _cameraController;
  bool get isCameraReady => _cameraController != null && _cameraController!.value.isInitialized;

  /// Initializes the device front-facing camera in high definition
  Future<CameraController> initializeCamera({
    ResolutionPreset resolution = ResolutionPreset.high,
  }) async {
    final status = await Permission.camera.status;
    if (!status.isGranted) {
      final res = await Permission.camera.request();
      if (!res.isGranted) {
        throw Exception('Camera permission is required for face biometric processing.');
      }
    }

    final cameras = await availableCameras();
    _frontCamera = null;
    for (final cam in cameras) {
      if (cam.lensDirection == CameraLensDirection.front) {
        _frontCamera = cam;
        break;
      }
    }
    _frontCamera ??= cameras.isNotEmpty ? cameras.first : null;

    if (_frontCamera == null) {
      throw Exception('No camera sensor available on this device.');
    }

    final controller = CameraController(
      _frontCamera!,
      resolution,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    await controller.initialize();
    _cameraController = controller;
    _luminanceHistory.clear();
    _centerHistory.clear();
    return controller;
  }

  /// Captures a frame and runs face position, quality, and biometric analysis
  Future<FaceAnalysisResult> captureAndAnalyzeFrame() async {
    if (!isCameraReady || _isProcessing) {
      return const FaceAnalysisResult(
        faceDetected: false,
        status: FacePositionStatus.noFace,
        guidance: 'Camera not ready',
      );
    }

    _isProcessing = true;
    try {
      final file = await _cameraController!.takePicture();
      final bytes = await file.readAsBytes();
      final analysis = await MobileFaceDetector.analyzeImageBytes(bytes);

      // Evaluate passive liveness markers if face was detected
      if (analysis.faceDetected) {
        _luminanceHistory.add(analysis.averageLuminance);
        _centerHistory.add(analysis.faceCenterX);
        if (_luminanceHistory.length > 5) _luminanceHistory.removeAt(0);
        if (_centerHistory.length > 5) _centerHistory.removeAt(0);
      }

      return analysis;
    } finally {
      _isProcessing = false;
    }
  }

  /// Evaluates temporal micro-variations to detect live human presence
  bool evaluatePassiveLiveness() {
    if (_luminanceHistory.length < 3) return true; // Initializing

    // Check luminance micro-variation (natural ambient / blood perfusion changes)
    double lumVariance = 0.0;
    final avgLum = _luminanceHistory.reduce((a, b) => a + b) / _luminanceHistory.length;
    for (final lum in _luminanceHistory) {
      lumVariance += (lum - avgLum) * (lum - avgLum);
    }
    lumVariance /= _luminanceHistory.length;

    // Reject static identical pixels (screen photo replay has 0 variance)
    // or violent flashing (variance > 400)
    return lumVariance >= 0.02 && lumVariance <= 400.0;
  }

  void dispose() {
    _cameraController?.dispose();
    _cameraController = null;
    _isProcessing = false;
    _luminanceHistory.clear();
    _centerHistory.clear();
  }
}
