import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/attendance_repository.dart';
import '../../domain/models/attendance_model.dart';
import '../../domain/models/face_profile_model.dart';
import '../../domain/models/location_model.dart';

class AttendanceStateModel {
  final bool isLoading;
  final AttendanceModel? todayAttendance;
  final FaceProfileStatusModel? faceStatus;
  final String? errorMessage;

  AttendanceStateModel({
    this.isLoading = false,
    this.todayAttendance,
    this.faceStatus,
    this.errorMessage,
  });

  AttendanceStateModel copyWith({
    bool? isLoading,
    AttendanceModel? todayAttendance,
    FaceProfileStatusModel? faceStatus,
    String? errorMessage,
  }) {
    return AttendanceStateModel(
      isLoading: isLoading ?? this.isLoading,
      todayAttendance: todayAttendance ?? this.todayAttendance,
      faceStatus: faceStatus ?? this.faceStatus,
      errorMessage: errorMessage,
    );
  }
}

final attendanceNotifierProvider =
    StateNotifierProvider<AttendanceNotifier, AttendanceStateModel>((ref) {
  final repository = ref.watch(attendanceRepositoryProvider);
  return AttendanceNotifier(repository: repository);
});

class AttendanceNotifier extends StateNotifier<AttendanceStateModel> {
  final AttendanceRepository _repository;

  AttendanceNotifier({required AttendanceRepository repository})
      : _repository = repository,
        super(AttendanceStateModel()) {
    fetchStatus();
  }

  Future<void> fetchStatus() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final today = await _repository.getTodayAttendance();
      final face = await _repository.getFaceStatus();
      state = state.copyWith(
        isLoading: false,
        todayAttendance: today,
        faceStatus: face,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<bool> clockIn({
    String method = 'face',
    List<double>? faceTemplate,
    LocationCoords? location,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final result = await _repository.clockIn(
        method: method,
        faceTemplate: faceTemplate,
        location: location,
      );
      state = state.copyWith(isLoading: false, todayAttendance: result);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> breakIn({LocationCoords? location}) async {
    if (state.todayAttendance == null) return false;
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final result = await _repository.breakIn(
        attendanceId: state.todayAttendance!.id,
        location: location,
      );
      state = state.copyWith(isLoading: false, todayAttendance: result);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> breakOut({LocationCoords? location}) async {
    if (state.todayAttendance == null) return false;
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final result = await _repository.breakOut(
        attendanceId: state.todayAttendance!.id,
        location: location,
      );
      state = state.copyWith(isLoading: false, todayAttendance: result);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> clockOut({LocationCoords? location}) async {
    if (state.todayAttendance == null) return false;
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final result = await _repository.clockOut(
        attendanceId: state.todayAttendance!.id,
        location: location,
      );
      state = state.copyWith(isLoading: false, todayAttendance: result);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }
}
