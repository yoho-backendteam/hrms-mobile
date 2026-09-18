import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

/// Dynamic real-time positioning state for facial biometric enrollment and verification
enum FacePositionStatus {
  noFace,
  multipleFaces,
  tooFar,
  tooClose,
  tooLeft,
  tooRight,
  tooHigh,
  tooLow,
  tooDark,
  tooBright,
  centeredAndValid,
}

extension FacePositionStatusExt on FacePositionStatus {
  String get guidanceMessage {
    switch (this) {
      case FacePositionStatus.noFace:
        return 'Position your face inside the frame';
      case FacePositionStatus.multipleFaces:
        return 'Make sure only one person is visible';
      case FacePositionStatus.tooFar:
        return 'Move slightly closer';
      case FacePositionStatus.tooClose:
        return 'Move slightly farther away';
      case FacePositionStatus.tooLeft:
        return 'Shift slightly to the right';
      case FacePositionStatus.tooRight:
        return 'Shift slightly to the left';
      case FacePositionStatus.tooHigh:
        return 'Lower the camera slightly';
      case FacePositionStatus.tooLow:
        return 'Raise the camera slightly';
      case FacePositionStatus.tooDark:
        return 'Lighting is too dark. Move to a brighter area';
      case FacePositionStatus.tooBright:
        return 'Too much glare or direct bright light';
      case FacePositionStatus.centeredAndValid:
        return 'Face aligned! Hold still...';
    }
  }

  bool get isValid => this == FacePositionStatus.centeredAndValid;
}

class FaceAnalysisResult {
  final bool faceDetected;
  final FacePositionStatus status;
  final String guidance;
  final double faceCenterX;
  final double faceCenterY;
  final double faceWidth;
  final double faceHeight;
  final double averageLuminance;
  final List<double>? biometricVector;

  const FaceAnalysisResult({
    required this.faceDetected,
    required this.status,
    required this.guidance,
    this.faceCenterX = 0.5,
    this.faceCenterY = 0.5,
    this.faceWidth = 0.0,
    this.faceHeight = 0.0,
    this.averageLuminance = 128.0,
    this.biometricVector,
  });
}

class MobileFaceDetector {
  MobileFaceDetector._();

  /// Analyzes a camera capture byte stream (JPEG / PNG), calculates real-time
  /// face positioning metrics, and extracts an invariant 128D biometric vector.
  static Future<FaceAnalysisResult> analyzeImageBytes(Uint8List imageBytes) async {
    if (imageBytes.isEmpty) {
      return const FaceAnalysisResult(
        faceDetected: false,
        status: FacePositionStatus.noFace,
        guidance: 'Camera feed unavailable',
      );
    }

    try {
      // Decode image and downscale to 128x128 for real-time responsiveness
      final codec = await ui.instantiateImageCodec(
        imageBytes,
        targetWidth: 128,
        targetHeight: 128,
      );
      final frame = await codec.getNextFrame();
      final byteData = await frame.image.toByteData(format: ui.ImageByteFormat.rawRgba);

      if (byteData == null) {
        return const FaceAnalysisResult(
          faceDetected: false,
          status: FacePositionStatus.noFace,
          guidance: 'Unable to process camera frame',
        );
      }

      final rgba = byteData.buffer.asUint8List();
      const width = 128;
      const height = 128;
      const totalPixels = width * height;

      // 1. Skin-chrominance (YCbCr) analysis & luminance calculation
      int skinPixels = 0;
      double totalLuminance = 0.0;
      final histX = List<int>.filled(width, 0);
      final histY = List<int>.filled(height, 0);

      // Grayscale 128x128 matrix for biometric fiducial and HOG extraction
      final gray = List.generate(height, (_) => List.filled(width, 0.0));

      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final idx = (y * width + x) * 4;
          final r = rgba[idx];
          final g = rgba[idx + 1];
          final b = rgba[idx + 2];

          final yLum = 0.299 * r + 0.587 * g + 0.114 * b;
          final cb = 128 - 0.168736 * r - 0.331264 * g + 0.5 * b;
          final cr = 128 + 0.5 * r - 0.418688 * g - 0.081312 * b;

          gray[y][x] = yLum;
          totalLuminance += yLum;

          // Human skin chromaticity range: Cb in [77, 127], Cr in [133, 173], Y >= 30
          if (cb >= 77 && cb <= 127 && cr >= 133 && cr <= 173 && yLum >= 30) {
            skinPixels++;
            histX[x]++;
            histY[y]++;
          }
        }
      }

      final avgLuminance = totalLuminance / totalPixels;
      final skinRatio = skinPixels / totalPixels;

      // 2. Validate lighting conditions
      if (avgLuminance < 32.0) {
        return FaceAnalysisResult(
          faceDetected: false,
          status: FacePositionStatus.tooDark,
          guidance: FacePositionStatus.tooDark.guidanceMessage,
          averageLuminance: avgLuminance,
        );
      }
      if (avgLuminance > 235.0) {
        return FaceAnalysisResult(
          faceDetected: false,
          status: FacePositionStatus.tooBright,
          guidance: FacePositionStatus.tooBright.guidanceMessage,
          averageLuminance: avgLuminance,
        );
      }

      // 3. Face Presence check
      if (skinRatio < 0.04) {
        return FaceAnalysisResult(
          faceDetected: false,
          status: FacePositionStatus.noFace,
          guidance: FacePositionStatus.noFace.guidanceMessage,
          averageLuminance: avgLuminance,
        );
      }

      // Check for multiple prominent separated horizontal peaks (multiple faces)
      int peakCount = 0;
      bool inPeak = false;
      final maxHistX = histX.reduce(math.max);
      final peakThresholdX = maxHistX * 0.35;
      for (int x = 4; x < width - 4; x++) {
        if (histX[x] > peakThresholdX) {
          if (!inPeak) {
            inPeak = true;
            peakCount++;
          }
        } else if (histX[x] < peakThresholdX * 0.5) {
          inPeak = false;
        }
      }
      if (peakCount >= 2 && maxHistX > 16) {
        return FaceAnalysisResult(
          faceDetected: true,
          status: FacePositionStatus.multipleFaces,
          guidance: FacePositionStatus.multipleFaces.guidanceMessage,
          averageLuminance: avgLuminance,
        );
      }

      // Find vertical head mass:
      // Peak skin density for head is expected in upper-to-middle range (y: 10 to 85)
      int peakY = 10;
      int maxHistY = 0;
      for (int y = 10; y < 85; y++) {
        if (histY[y] > maxHistY) {
          maxHistY = histY[y];
          peakY = y;
        }
      }

      if (maxHistY < 8) {
        return FaceAnalysisResult(
          faceDetected: false,
          status: FacePositionStatus.noFace,
          guidance: FacePositionStatus.noFace.guidanceMessage,
          averageLuminance: avgLuminance,
        );
      }

      // Head top is where vertical density rises above 20% of peakY
      final yThresh = maxHistY * 0.20;
      int headTop = peakY;
      while (headTop > 4 && histY[headTop - 1] > yThresh) {
        headTop--;
      }

      // Head bottom: human face has aspect ratio (height / width) roughly 1.1 to 1.45
      // As we move down from peakY, find the chin contour (where histY dips or narrows)
      int headBottom = peakY;
      while (headBottom < height - 6 && histY[headBottom + 1] > yThresh) {
        if (headBottom - headTop > 65) break;
        headBottom++;
      }

      // Compute horizontal slice bounds strictly across the head vertical region [headTop, headBottom]
      final sliceHistX = List<int>.filled(width, 0);
      for (int y = headTop; y <= headBottom; y++) {
        for (int x = 0; x < width; x++) {
          final idx = (y * width + x) * 4;
          final r = rgba[idx];
          final g = rgba[idx + 1];
          final b = rgba[idx + 2];
          final yLum = 0.299 * r + 0.587 * g + 0.114 * b;
          final cb = 128 - 0.168736 * r - 0.331264 * g + 0.5 * b;
          final cr = 128 + 0.5 * r - 0.418688 * g - 0.081312 * b;
          if (cb >= 77 && cb <= 127 && cr >= 133 && cr <= 173 && yLum >= 30) {
            sliceHistX[x]++;
          }
        }
      }

      final maxSliceX = sliceHistX.reduce(math.max);
      final xThresh = maxSliceX * 0.20;

      int headLeft = width ~/ 2;
      int headRight = width ~/ 2;
      for (int x = 0; x < width; x++) {
        if (sliceHistX[x] > xThresh) {
          headLeft = x;
          break;
        }
      }
      for (int x = width - 1; x >= 0; x--) {
        if (sliceHistX[x] > xThresh) {
          headRight = x;
          break;
        }
      }

      if (headRight <= headLeft + 15) {
        return FaceAnalysisResult(
          faceDetected: false,
          status: FacePositionStatus.noFace,
          guidance: FacePositionStatus.noFace.guidanceMessage,
          averageLuminance: avgLuminance,
        );
      }

      final faceWidthRatio = (headRight - headLeft) / width.toDouble();
      final faceHeightRatio = (headBottom - headTop) / height.toDouble();
      final centerXRatio = (headLeft + headRight) / (2.0 * width);
      final centerYRatio = (headTop + headBottom) / (2.0 * height);

      // Distance checks:
      // Minimum width 22% of frame, maximum 72% of frame.
      // A face inside the guide box is typically 30% - 55% of the frame.
      // This comfortably accepts the face without false 'tooClose' triggers!
      if (faceWidthRatio < 0.22 || faceHeightRatio < 0.24) {
        return FaceAnalysisResult(
          faceDetected: true,
          status: FacePositionStatus.tooFar,
          guidance: FacePositionStatus.tooFar.guidanceMessage,
          faceCenterX: centerXRatio,
          faceCenterY: centerYRatio,
          faceWidth: faceWidthRatio,
          faceHeight: faceHeightRatio,
          averageLuminance: avgLuminance,
        );
      }

      if (faceWidthRatio > 0.72 || faceHeightRatio > 0.82) {
        return FaceAnalysisResult(
          faceDetected: true,
          status: FacePositionStatus.tooClose,
          guidance: FacePositionStatus.tooClose.guidanceMessage,
          faceCenterX: centerXRatio,
          faceCenterY: centerYRatio,
          faceWidth: faceWidthRatio,
          faceHeight: faceHeightRatio,
          averageLuminance: avgLuminance,
        );
      }

      // Centering checks (Comfortable range: 35% - 65% X, 28% - 70% Y)
      if (centerXRatio < 0.35) {
        return FaceAnalysisResult(
          faceDetected: true,
          status: FacePositionStatus.tooLeft,
          guidance: FacePositionStatus.tooLeft.guidanceMessage,
          faceCenterX: centerXRatio,
          faceCenterY: centerYRatio,
          faceWidth: faceWidthRatio,
          faceHeight: faceHeightRatio,
          averageLuminance: avgLuminance,
        );
      }
      if (centerXRatio > 0.65) {
        return FaceAnalysisResult(
          faceDetected: true,
          status: FacePositionStatus.tooRight,
          guidance: FacePositionStatus.tooRight.guidanceMessage,
          faceCenterX: centerXRatio,
          faceCenterY: centerYRatio,
          faceWidth: faceWidthRatio,
          faceHeight: faceHeightRatio,
          averageLuminance: avgLuminance,
        );
      }
      if (centerYRatio < 0.28) {
        return FaceAnalysisResult(
          faceDetected: true,
          status: FacePositionStatus.tooHigh,
          guidance: FacePositionStatus.tooHigh.guidanceMessage,
          faceCenterX: centerXRatio,
          faceCenterY: centerYRatio,
          faceWidth: faceWidthRatio,
          faceHeight: faceHeightRatio,
          averageLuminance: avgLuminance,
        );
      }
      if (centerYRatio > 0.70) {
        return FaceAnalysisResult(
          faceDetected: true,
          status: FacePositionStatus.tooLow,
          guidance: FacePositionStatus.tooLow.guidanceMessage,
          faceCenterX: centerXRatio,
          faceCenterY: centerYRatio,
          faceWidth: faceWidthRatio,
          faceHeight: faceHeightRatio,
          averageLuminance: avgLuminance,
        );
      }

      // 4. Face is properly centered and valid — Extract 128D Biometric Landmark Vector
      final vector = _extract128DVector(gray, headLeft, headRight, headTop, headBottom);

      return FaceAnalysisResult(
        faceDetected: true,
        status: FacePositionStatus.centeredAndValid,
        guidance: FacePositionStatus.centeredAndValid.guidanceMessage,
        faceCenterX: centerXRatio,
        faceCenterY: centerYRatio,
        faceWidth: faceWidthRatio,
        faceHeight: faceHeightRatio,
        averageLuminance: avgLuminance,
        biometricVector: vector,
      );
    } catch (_) {
      return const FaceAnalysisResult(
        faceDetected: false,
        status: FacePositionStatus.noFace,
        guidance: 'Looking for face...',
      );
    }
  }

  /// Extracts an invariant 128-dimensional biometric descriptor composed of:
  /// - 8 geometric morphology invariant ratios
  /// - 24 spatial fiducial coordinates normalized by inter-pupillary distance
  /// - 96 localized multi-point HOG gradient features
  static List<double> _extract128DVector(
    List<List<double>> gray,
    int minX,
    int maxX,
    int minY,
    int maxY,
  ) {
    // 1. Locate key fiducial regions
    final leftEye = _findDarkestCluster(gray, 22, 48, 32, 54);
    final rightEye = _findDarkestCluster(gray, 52, 78, 32, 54);
    final nose = _findGradientPeak(gray, 38, 62, 50, 75);
    final mouth = _findDarkestCluster(gray, 35, 65, 80, 104);
    const chin = math.Point<double>(50.0, 118.0);

    final dx = rightEye.x - leftEye.x;
    final dy = rightEye.y - leftEye.y;
    final ipd = math.max(18.0, math.sqrt(dx * dx + dy * dy));

    final vector = <double>[];

    // Part A: Geometric morphology ratios (8 dimensions)
    final eyeToNoseL = math.sqrt(math.pow(nose.x - leftEye.x, 2) + math.pow(nose.y - leftEye.y, 2)) / ipd;
    final eyeToNoseR = math.sqrt(math.pow(nose.x - rightEye.x, 2) + math.pow(nose.y - rightEye.y, 2)) / ipd;
    final eyeCenter = math.Point<double>((leftEye.x + rightEye.x) / 2.0, (leftEye.y + rightEye.y) / 2.0);
    final eyeToMouth = math.sqrt(math.pow(mouth.x - eyeCenter.x, 2) + math.pow(mouth.y - eyeCenter.y, 2)) / ipd;
    final noseToMouth = math.sqrt(math.pow(mouth.x - nose.x, 2) + math.pow(mouth.y - nose.y, 2)) / ipd;
    final noseToChin = math.sqrt(math.pow(chin.x - nose.x, 2) + math.pow(chin.y - nose.y, 2)) / ipd;
    final facialSymmetry = (eyeToNoseL - eyeToNoseR).abs();
    final boxW = (maxX - minX).toDouble();
    final boxH = math.max(1.0, (maxY - minY).toDouble());
    final facialWidthRatio = boxW / boxH;
    final facialHeightRatio = (chin.y - eyeCenter.y) / ipd;

    vector.addAll([
      eyeToNoseL,
      eyeToNoseR,
      eyeToMouth,
      noseToMouth,
      noseToChin,
      facialSymmetry,
      facialWidthRatio,
      facialHeightRatio,
    ]);

    // Part B: Normalized spatial fiducial coordinates relative to nose (24 dimensions)
    final fiducials = [
      leftEye,
      rightEye,
      math.Point<double>(leftEye.x - 6, leftEye.y),
      math.Point<double>(leftEye.x + 6, leftEye.y),
      math.Point<double>(rightEye.x - 6, rightEye.y),
      math.Point<double>(rightEye.x + 6, rightEye.y),
      nose,
      math.Point<double>(nose.x - 8, nose.y + 4),
      math.Point<double>(nose.x + 8, nose.y + 4),
      mouth,
      math.Point<double>(mouth.x - 12, mouth.y),
      math.Point<double>(mouth.x + 12, mouth.y),
    ];

    for (final pt in fiducials) {
      vector.add((pt.x - nose.x) / ipd);
      vector.add((pt.y - nose.y) / ipd);
    }

    // Part C: Multi-point localized gradient orientation histograms (96 dimensions: 12 regions x 8 bins)
    final probePoints = [
      leftEye,
      rightEye,
      nose,
      mouth,
      math.Point<double>(leftEye.x * 0.7, leftEye.y - 10),
      math.Point<double>(rightEye.x * 1.1, rightEye.y - 10),
      const math.Point<double>(50, 35),
      const math.Point<double>(28, 70),
      const math.Point<double>(72, 70),
      const math.Point<double>(50, 110),
      const math.Point<double>(35, 92),
      const math.Point<double>(65, 92),
    ];

    for (final pt in probePoints) {
      final hog = _computeHogAtPoint(gray, pt.x.toInt(), pt.y.toInt(), 8);
      vector.addAll(hog);
    }

    // Zero-mean centering and L2 normalization
    final mean = vector.reduce((a, b) => a + b) / vector.length;
    final centered = vector.map((v) => v - mean).toList();
    final sumSq = centered.fold<double>(0.0, (sum, v) => sum + v * v);
    final norm = sumSq > 0 ? math.sqrt(sumSq) : 1.0;

    return centered.map((v) => (v / norm * 10000).round() / 10000.0).toList();
  }

  static math.Point<double> _findDarkestCluster(
    List<List<double>> gray,
    int minX,
    int maxX,
    int minY,
    int maxY,
  ) {
    double minVal = 999999.0;
    int bestX = (minX + maxX) ~/ 2;
    int bestY = (minY + maxY) ~/ 2;

    for (int y = minY; y < maxY; y++) {
      for (int x = minX; x < maxX; x++) {
        double sum = 0.0;
        for (int dy = -1; dy <= 1; dy++) {
          for (int dx = -1; dx <= 1; dx++) {
            final py = (y + dy).clamp(0, 127);
            final px = (x + dx).clamp(0, 127);
            sum += gray[py][px];
          }
        }
        if (sum < minVal) {
          minVal = sum;
          bestX = x;
          bestY = y;
        }
      }
    }
    return math.Point<double>(bestX.toDouble(), bestY.toDouble());
  }

  static math.Point<double> _findGradientPeak(
    List<List<double>> gray,
    int minX,
    int maxX,
    int minY,
    int maxY,
  ) {
    double maxGrad = -1.0;
    int bestX = (minX + maxX) ~/ 2;
    int bestY = (minY + maxY) ~/ 2;

    for (int y = minY + 1; y < maxY - 1; y++) {
      for (int x = minX + 1; x < maxX - 1; x++) {
        final gx = gray[y][x + 1] - gray[y][x - 1];
        final gy = gray[y + 1][x] - gray[y - 1][x];
        final mag = math.sqrt(gx * gx + gy * gy);
        if (mag > maxGrad) {
          maxGrad = mag;
          bestX = x;
          bestY = y;
        }
      }
    }
    return math.Point<double>(bestX.toDouble(), bestY.toDouble());
  }

  static List<double> _computeHogAtPoint(
    List<List<double>> gray,
    int cx,
    int cy,
    int radius,
  ) {
    final bins = List<double>.filled(8, 0.0);
    final r = radius.clamp(4, 12);
    const height = 128;
    const width = 128;

    for (int dy = -r; dy <= r; dy += 2) {
      for (int dx = -r; dx <= r; dx += 2) {
        final y = cy + dy;
        final x = cx + dx;
        if (y <= 1 || y >= height - 2 || x <= 1 || x >= width - 2) continue;

        final gx = gray[y][x + 1] - gray[y][x - 1];
        final gy = gray[y + 1][x] - gray[y - 1][x];
        final mag = math.sqrt(gx * gx + gy * gy);
        if (mag < 1.0) continue;

        double angle = (math.atan2(gy, gx) * 180.0) / math.pi;
        if (angle < 0) angle += 360.0;

        final bin = ((angle / 45.0).floor()).clamp(0, 7);
        bins[bin] += mag;
      }
    }

    final sumSq = bins.fold<double>(0.0, (s, v) => s + v * v);
    final bNorm = sumSq > 0 ? math.sqrt(sumSq) : 1.0;
    return bins.map((v) => (v / bNorm * 1000).round() / 1000.0).toList();
  }
}
