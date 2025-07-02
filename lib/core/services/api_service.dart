import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/code_execution_result.dart';
import '../models/api_response.dart';
import 'storage_service.dart';

final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

class ApiService {
  late final Dio _dio;
  static const String baseUrl = 'https://api.dartpad.dev'; // DartPad API as fallback
  
  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));
    
    _setupInterceptors();
  }

  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Add API key if available
          final apiKey = await StorageService.getSecureString(StorageService.apiKeyKey);
          if (apiKey != null && apiKey.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $apiKey';
          }
          handler.next(options);
        },
        onError: (error, handler) {
          // Log error and handle it gracefully
          print('API Error: ${error.message}');
          handler.next(error);
        },
      ),
    );
  }

  Future<CodeExecutionResult> executeCode(String code) async {
    try {
      final response = await _dio.post(
        '/api/dartservices/v2/execute',
        data: {
          'source': code,
          'returnSourceMap': false,
        },
      );

      if (response.statusCode == 200) {
        return CodeExecutionResult.fromJson(response.data);
      } else {
        return CodeExecutionResult(
          success: false,
          output: '',
          error: 'Failed to execute code: ${response.statusMessage}',
          executionTime: 0,
        );
      }
    } on DioException catch (e) {
      return CodeExecutionResult(
        success: false,
        output: '',
        error: _handleDioError(e),
        executionTime: 0,
      );
    } catch (e) {
      return CodeExecutionResult(
        success: false,
        output: '',
        error: 'Unexpected error: $e',
        executionTime: 0,
      );
    }
  }

  Future<ApiResponse<String>> analyzeCode(String code) async {
    try {
      final response = await _dio.post(
        '/api/dartservices/v2/analyze',
        data: {
          'source': code,
        },
      );

      if (response.statusCode == 200) {
        return ApiResponse.success(
          data: response.data['issues']?.toString() ?? 'No issues found',
          message: 'Code analyzed successfully',
        );
      } else {
        return ApiResponse.error(
          message: 'Failed to analyze code: ${response.statusMessage}',
        );
      }
    } on DioException catch (e) {
      return ApiResponse.error(message: _handleDioError(e));
    } catch (e) {
      return ApiResponse.error(message: 'Unexpected error: $e');
    }
  }

  Future<ApiResponse<String>> formatCode(String code) async {
    try {
      final response = await _dio.post(
        '/api/dartservices/v2/format',
        data: {
          'source': code,
        },
      );

      if (response.statusCode == 200) {
        return ApiResponse.success(
          data: response.data['newString'] ?? code,
          message: 'Code formatted successfully',
        );
      } else {
        return ApiResponse.error(
          message: 'Failed to format code: ${response.statusMessage}',
        );
      }
    } on DioException catch (e) {
      return ApiResponse.error(message: _handleDioError(e));
    } catch (e) {
      return ApiResponse.error(message: 'Unexpected error: $e');
    }
  }

  String _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return 'Connection timeout. Please check your internet connection.';
      case DioExceptionType.sendTimeout:
        return 'Send timeout. Please try again.';
      case DioExceptionType.receiveTimeout:
        return 'Receive timeout. Please try again.';
      case DioExceptionType.badResponse:
        return 'Server error: ${e.response?.statusCode} ${e.response?.statusMessage}';
      case DioExceptionType.cancel:
        return 'Request was cancelled.';
      case DioExceptionType.connectionError:
        return 'Connection error. Please check your internet connection.';
      default:
        return 'An unexpected error occurred: ${e.message}';
    }
  }
}