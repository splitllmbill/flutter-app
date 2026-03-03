import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../constants/constants.dart';
import 'auth_service.dart';

/// Dio-based HTTP client with Firebase Auth token injection.
class ApiClient {
  late final Dio _dio;
  final AuthService _authService;
  VoidCallback? onUnauthorized;

  ApiClient({
    required AuthService authService,
    this.onUnauthorized,
  }) : _authService = authService {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.apiBaseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Cache-Control': 'no-cache, no-store, must-revalidate',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: _onRequest,
        onError: _onError,
      ),
    );

    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
        ),
      );
    }
  }

  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      final token = await _authService.getIdToken();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    } catch (e) {
      debugPrint('Failed to get auth token: $e');
    }
    handler.next(options);
  }

  void _onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      _authService.signOut();
      onUnauthorized?.call();
    }
    handler.next(err);
  }

  // --- HTTP Methods ---

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) {
    return _dio.get(path, queryParameters: queryParameters);
  }

  Future<Response> post(
    String path, {
    dynamic data,
    bool jsonBody = true,
  }) {
    return _dio.post(
      path,
      data: data,
      options: jsonBody ? null : Options(contentType: 'multipart/form-data'),
    );
  }

  Future<Response> put(
    String path, {
    dynamic data,
  }) {
    return _dio.put(path, data: data);
  }

  Future<Response> delete(
    String path, {
    dynamic data,
  }) {
    return _dio.delete(path, data: data);
  }
}
