import 'package:dio/dio.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? code;
  final dynamic details;

  ApiException({
    required this.message,
    this.statusCode,
    this.code,
    this.details,
  });

  factory ApiException.fromDioError(DioException error) {
    String message = 'An unexpected error occurred. Please try again.';
    int? statusCode = error.response?.statusCode;
    String? code;
    dynamic details = error.response?.data;

    if (error.response?.data is Map<String, dynamic>) {
      final data = error.response!.data as Map<String, dynamic>;
      message = data['message']?.toString() ??
          data['error']?.toString() ??
          message;
      code = data['code']?.toString();
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        message = 'Connection timed out. Please check your internet connection.';
        break;
      case DioExceptionType.connectionError:
        message = 'Unable to connect to the HRMS server. Please verify network access.';
        break;
      case DioExceptionType.badResponse:
        if (statusCode == 401) {
          message = 'Session expired or unauthorized. Please log in again.';
        } else if (statusCode == 403) {
          message = message.contains('permission') || message.contains('forbidden')
              ? message
              : 'You do not have permission to perform this action.';
        } else if (statusCode == 404) {
          message = 'The requested HRMS resource was not found.';
        } else if (statusCode == 409) {
          message = message.isNotEmpty ? message : 'Conflict in operation state.';
        } else if (statusCode != null && statusCode >= 500) {
          message = 'Server encountered an error. Please contact HR administrator.';
        }
        break;
      case DioExceptionType.cancel:
        message = 'Request was cancelled.';
        break;
      default:
        break;
    }

    return ApiException(
      message: message,
      statusCode: statusCode,
      code: code,
      details: details,
    );
  }

  @override
  String toString() => message;
}
