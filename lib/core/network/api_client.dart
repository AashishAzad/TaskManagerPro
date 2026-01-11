import 'package:dartz/dartz.dart';

/// API Client for making HTTP requests
/// Currently mocked, but ready for real implementation
class ApiClient {
  final String baseUrl;
  final Duration timeout;

  Map<String, String> _headers = {};

  ApiClient({
    this.baseUrl = 'https://api.example.com/v1',
    this.timeout = const Duration(seconds: 30),
  }) {
    _headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  /// Set authentication token
  void setAuthToken(String token) {
    _headers['Authorization'] = 'Bearer $token';
  }

  /// Remove authentication token
  void clearAuthToken() {
    _headers.remove('Authorization');
  }

  /// GET request
  Future<Either<ApiError, T>> get<T>(
      String endpoint, {
        Map<String, dynamic>? queryParams,
        Map<String, String>? headers,
      }) async {
    try {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 500));

      // Mock response
      final mockResponse = _getMockResponse(endpoint, 'GET');

      return Right(mockResponse as T);
    } catch (e) {
      return Left(ApiError(
        message: e.toString(),
        statusCode: 500,
      ));
    }
  }

  /// POST request
  Future<Either<ApiError, T>> post<T>(
      String endpoint, {
        Map<String, dynamic>? body,
        Map<String, String>? headers,
      }) async {
    try {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 800));

      // Mock response
      final mockResponse = _getMockResponse(endpoint, 'POST', body: body);

      return Right(mockResponse as T);
    } catch (e) {
      return Left(ApiError(
        message: e.toString(),
        statusCode: 500,
      ));
    }
  }

  /// PUT request
  Future<Either<ApiError, T>> put<T>(
      String endpoint, {
        Map<String, dynamic>? body,
        Map<String, String>? headers,
      }) async {
    try {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 600));

      // Mock response
      final mockResponse = _getMockResponse(endpoint, 'PUT', body: body);

      return Right(mockResponse as T);
    } catch (e) {
      return Left(ApiError(
        message: e.toString(),
        statusCode: 500,
      ));
    }
  }

  /// DELETE request
  Future<Either<ApiError, T>> delete<T>(
      String endpoint, {
        Map<String, String>? headers,
      }) async {
    try {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 400));

      // Mock response
      final mockResponse = _getMockResponse(endpoint, 'DELETE');

      return Right(mockResponse as T);
    } catch (e) {
      return Left(ApiError(
        message: e.toString(),
        statusCode: 500,
      ));
    }
  }

  /// Mock response generator
  dynamic _getMockResponse(
      String endpoint,
      String method, {
        Map<String, dynamic>? body,
      }) {
    // Generate appropriate mock response based on endpoint
    if (endpoint.contains('auth')) {
      return {
        'token': 'mock_token_${DateTime.now().millisecondsSinceEpoch}',
        'user': {
          'id': 'user_123',
          'email': 'user@example.com',
          'name': 'John Doe',
        },
      };
    }

    if (endpoint.contains('tasks')) {
      if (method == 'GET') {
        return {
          'data': List.generate(10, (i) => {
            'id': 'task_$i',
            'title': 'Task $i',
            'completed': i % 2 == 0,
          }),
          'total': 10,
        };
      }
      return {
        'id': 'task_new',
        'title': body?['title'] ?? 'New Task',
        'completed': false,
      };
    }

    if (endpoint.contains('analytics')) {
      return {
        'metrics': {
          'total_tasks': 50,
          'completed': 30,
          'pending': 20,
        },
      };
    }

    return {'success': true, 'message': 'Operation completed'};
  }

  /// Check network connectivity (mocked)
  Future<bool> checkConnectivity() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return true; // Always return true in mock
  }

  /// Ping server to check if it's reachable
  Future<Either<ApiError, bool>> ping() async {
    try {
      await Future.delayed(const Duration(milliseconds: 200));
      return const Right(true);
    } catch (e) {
      return Left(ApiError(
        message: 'Server unreachable',
        statusCode: 0,
      ));
    }
  }
}

/// API Error model
class ApiError {
  final String message;
  final int statusCode;
  final Map<String, dynamic>? details;

  const ApiError({
    required this.message,
    required this.statusCode,
    this.details,
  });

  bool get isNetworkError => statusCode == 0;
  bool get isServerError => statusCode >= 500;
  bool get isClientError => statusCode >= 400 && statusCode < 500;
  bool get isUnauthorized => statusCode == 401;

  @override
  String toString() => 'ApiError($statusCode): $message';
}