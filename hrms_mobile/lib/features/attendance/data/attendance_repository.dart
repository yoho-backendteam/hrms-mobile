import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../domain/models/attendance_model.dart';
import '../domain/models/face_profile_model.dart';
import '../domain/models/location_model.dart';
import 'geo_location_service.dart';

final geoLocationServiceProvider = Provider<GeoLocationService>((ref) {
  return GeoLocationService();
});

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final geoService = ref.watch(geoLocationServiceProvider);
  return AttendanceRepository(apiClient: apiClient, geoService: geoService);
});

class AttendanceRepository {
  final ApiClient _apiClient;
  final GeoLocationService _geoService;

  AttendanceRepository({
    required ApiClient apiClient,
    required GeoLocationService geoService,
  })  : _apiClient = apiClient,
        _geoService = geoService;

  Future<AttendanceModel?> getTodayAttendance() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.attendanceToday);
      if (response is Map<String, dynamic>) {
        final rawData = response['data'];
        final topState = response['state']?.toString();
        if (rawData is Map<String, dynamic> && rawData.isNotEmpty) {
          final map = Map<String, dynamic>.from(rawData);
          if (topState != null && !map.containsKey('attendance_state') && !map.containsKey('state')) {
            map['attendance_state'] = topState;
          }
          return AttendanceModel.fromJson(map);
        }
        if (rawData == null && topState != null) {
          return AttendanceModel.fromJson({
            'attendance_state': topState,
            'state': topState,
            'status': 'NOT_STARTED',
          });
        }
        if (response.containsKey('clock_in') || response.containsKey('clockIn')) {
          return AttendanceModel.fromJson(response);
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<AttendanceModel> clockIn({
    String? shiftId,
    String method = 'manual',
    List<double>? faceTemplate,
    LocationCoords? location,
  }) async {
    final effectiveLocation = location ?? await _geoService.getCurrentLocation();

    final response = await _apiClient.post(
      ApiEndpoints.attendanceClockIn,
      data: {
        'method': method,
        if (shiftId != null) 'shiftId': shiftId,
        if (effectiveLocation != null) 'location': effectiveLocation.toJson(),
        if (faceTemplate != null) 'faceTemplate': faceTemplate,
      },
    );

    final data = response['data'] ?? response;
    return AttendanceModel.fromJson(data is Map<String, dynamic> ? data : {});
  }

  Future<AttendanceModel> breakIn({
    required String attendanceId,
    String breakType = 'lunch',
    String method = 'manual',
    LocationCoords? location,
  }) async {
    final effectiveLocation = location ?? await _geoService.getCurrentLocation();

    final response = await _apiClient.post(
      ApiEndpoints.attendanceBreakIn,
      data: {
        'attendanceId': attendanceId,
        'breakType': breakType,
        'method': method,
        if (effectiveLocation != null) 'location': effectiveLocation.toJson(),
      },
    );

    final data = response['data'] ?? response;
    return AttendanceModel.fromJson(data is Map<String, dynamic> ? data : {});
  }

  Future<AttendanceModel> breakOut({
    required String attendanceId,
    LocationCoords? location,
  }) async {
    final effectiveLocation = location ?? await _geoService.getCurrentLocation();

    final response = await _apiClient.post(
      ApiEndpoints.attendanceBreakOut,
      data: {
        'attendanceId': attendanceId,
        if (effectiveLocation != null) 'location': effectiveLocation.toJson(),
      },
    );

    final data = response['data'] ?? response;
    return AttendanceModel.fromJson(data is Map<String, dynamic> ? data : {});
  }

  Future<AttendanceModel> clockOut({
    required String attendanceId,
    LocationCoords? location,
  }) async {
    final effectiveLocation = location ?? await _geoService.getCurrentLocation();

    final response = await _apiClient.post(
      ApiEndpoints.attendanceClockOut,
      data: {
        'attendanceId': attendanceId,
        if (effectiveLocation != null) 'location': effectiveLocation.toJson(),
      },
    );

    final data = response['data'] ?? response;
    return AttendanceModel.fromJson(data is Map<String, dynamic> ? data : {});
  }

  Future<List<AttendanceModel>> getMyLogs() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.attendanceMyLogs);
      final data = response['data'] ?? response;
      if (data is List) {
        return data.map((item) => AttendanceModel.fromJson(item)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  // Face Recognition Biometric API Calls
  Future<FaceProfileStatusModel> getFaceStatus() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.faceStatus);
      final data = response['data'] ?? response;
      return FaceProfileStatusModel.fromJson(data is Map<String, dynamic> ? data : {});
    } catch (_) {
      return FaceProfileStatusModel(isEnrolled: false, status: 'NOT_REGISTERED');
    }
  }

  Future<bool> registerFace({
    required List<double> template,
    bool consent = true,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.faceRegister,
      data: {
        'template': template,
        'modelName': 'mediapipe-tasks-vision',
        'modelVersion': '0.10.x',
        'consent': consent,
      },
    );
    return response['success'] == true || response['status'] == 'active';
  }

  Future<bool> verifyFace({
    required List<double> template,
    Map<String, dynamic>? livenessData,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.faceVerify,
      data: {
        'template': template,
        'livenessData': livenessData ?? {
          'timestamp': DateTime.now().toIso8601String(),
          'blinkDetected': true,
          'centerAngle': true,
        },
      },
    );

    final data = response['data'] ?? response;
    return data['verified'] == true;
  }

  Future<bool> revokeFace() async {
    final response = await _apiClient.post(ApiEndpoints.faceRevoke);
    return response['success'] == true;
  }
}
