import 'package:dio/dio.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  ApiException({required this.message, this.statusCode, this.data});

  @override
  String toString() => message;

  factory ApiException.fromDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException(
          message: 'Connection timed out. Please check your internet connection.',
          statusCode: 408,
        );
      case DioExceptionType.badResponse:
        final response = error.response;
        if (response != null) {
          final data = response.data;
          if (data is Map<String, dynamic>) {
            final msg = data['message'] ?? data['detail'] ?? 'Server error occurred.';
            return ApiException(
              message: msg.toString(),
              statusCode: response.statusCode,
              data: data,
            );
          }
          if (data is String && (data.contains('ngrok') || data.contains('ERR_NGROK') || response.statusCode == 404)) {
            return ApiException(
              message: 'Server tunnel is offline (404). Please ensure the backend and ngrok are running on your PC.',
              statusCode: response.statusCode,
              data: data,
            );
          }
          return ApiException(
            message: 'Server error (${response.statusCode}). Please try again later.',
            statusCode: response.statusCode,
          );
        }
        return ApiException(message: 'Invalid server response.', statusCode: 500);
      case DioExceptionType.cancel:
        return ApiException(message: 'Request was cancelled.');
      case DioExceptionType.connectionError:
        return ApiException(
          message: "Unable to connect to server. Please ensure backend is running or check your network.",
          statusCode: 503,
        );
      default:
        return ApiException(message: 'An unexpected network error occurred.');
    }
  }
}
