import 'package:dio/dio.dart';
import '../constants/env.dart';

/// HTTP client wrapper with error handling
class HttpClient {
  final Dio _dio;

  HttpClient()
      : _dio = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
          headers: {
            'Accept': 'application/json',
          },
        )) {
    // Add interceptors for logging and error handling
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      error: true,
      logPrint: (obj) => print('[HTTP] $obj'),
    ));
  }

  /// GET request
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// POST request
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Download file with progress
  Future<void> downloadFile(
    String url,
    String savePath, {
    void Function(int received, int total)? onProgress,
  }) async {
    try {
      await _dio.download(
        url,
        savePath,
        onReceiveProgress: onProgress,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  ApiException _handleError(DioException e) {
    String message = 'An error occurred';
    int? statusCode;

    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      message = 'Connection timeout. Please check your internet.';
    } else if (e.type == DioExceptionType.connectionError) {
      message = 'No internet connection.';
    } else if (e.response != null) {
      statusCode = e.response?.statusCode;
      switch (statusCode) {
        case 400:
          message = 'Bad request.';
          break;
        case 401:
          message = 'Unauthorized.';
          break;
        case 403:
          message = 'Forbidden.';
          break;
        case 404:
          message = 'Resource not found.';
          break;
        case 500:
          message = 'Server error.';
          break;
        default:
          message = 'Error: $statusCode';
      }
    }

    return ApiException(message: message, statusCode: statusCode, originalError: e);
  }

  /// Cancel all requests
  void cancelAll() {
    _dio.close(force: true);
  }
}

/// Custom exception class
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final Object? originalError;

  ApiException({
    required this.message,
    this.statusCode,
    this.originalError,
  });

  @override
  String toString() => 'ApiException: $message (status: $statusCode)';
}
