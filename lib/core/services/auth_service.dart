import 'package:dartz/dartz.dart';
import '../network/api_client.dart';
import 'storage_service.dart';

/// Service for handling authentication operations
/// Manages user sessions, tokens, and auth state
class AuthService {
  final ApiClient _apiClient;
  final StorageService _storageService;

  bool _isAuthenticated = false;
  String? _currentUserId;
  Map<String, dynamic>? _userProfile;

  AuthService({
    required ApiClient apiClient,
    required StorageService storageService,
  })  : _apiClient = apiClient,
        _storageService = storageService;

  bool get isAuthenticated => _isAuthenticated;
  String? get currentUserId => _currentUserId;
  Map<String, dynamic>? get userProfile => _userProfile;

  /// Initialize auth state from storage
  /// Called during app startup to restore session
  Future<Either<String, bool>> initializeAuthState() async {
    try {
      // Check for stored auth token
      final tokenResult = await _storageService.getAuthToken();

      return await tokenResult.fold(
            (error) => Left('Failed to get auth token: $error'),
            (token) async {
          if (token == null || token.isEmpty) {
            _isAuthenticated = false;
            return const Right(false);
          }

          // Validate token
          final validationResult = await _validateToken(token);

          return validationResult.fold(
                (error) {
              _isAuthenticated = false;
              return Left('Token validation failed: $error');
            },
                (isValid) async {
              if (isValid) {
                // Load user data
                final userIdResult = await _storageService.getUserId();
                final profileResult = await _storageService.getUserProfile();

                _currentUserId = userIdResult.getOrElse(() => null);
                _userProfile = profileResult.getOrElse(() => null);
                _isAuthenticated = true;

                return const Right(true);
              } else {
                _isAuthenticated = false;
                await _storageService.clearAuthToken();
                return const Right(false);
              }
            },
          );
        },
      );
    } catch (e) {
      return Left('Auth initialization error: ${e.toString()}');
    }
  }

  /// Validate auth token with backend (simulated)
  Future<Either<String, bool>> _validateToken(String token) async {
    try {
      // Simulate API call to validate token
      await Future.delayed(const Duration(milliseconds: 800));

      // Mock validation logic
      // In real app, this would call: _apiClient.post('/auth/validate', ...)
      final isValid = token.isNotEmpty && token.length > 10;

      return Right(isValid);
    } catch (e) {
      return Left('Token validation error: ${e.toString()}');
    }
  }

  /// Login user (simulated)
  Future<Either<String, Map<String, dynamic>>> login(
      String email,
      String password,
      ) async {
    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));

      // Mock response
      final mockToken = 'mock_token_${DateTime.now().millisecondsSinceEpoch}';
      final mockUserId = 'user_${email.hashCode.abs()}';
      final mockProfile = {
        'id': mockUserId,
        'email': email,
        'name': 'John Doe',
        'avatar': 'https://i.pravatar.cc/150?u=$email',
        'createdAt': DateTime.now().toIso8601String(),
      };

      // Save to storage
      await _storageService.saveAuthToken(mockToken);
      await _storageService.saveUserId(mockUserId);
      await _storageService.saveUserProfile(mockProfile);

      _isAuthenticated = true;
      _currentUserId = mockUserId;
      _userProfile = mockProfile;

      return Right(mockProfile);
    } catch (e) {
      return Left('Login failed: ${e.toString()}');
    }
  }

  /// Logout user
  Future<Either<String, bool>> logout() async {
    try {
      await _storageService.clearAuthToken();
      await _storageService.remove('user_id');
      await _storageService.remove('user_profile');

      _isAuthenticated = false;
      _currentUserId = null;
      _userProfile = null;

      return const Right(true);
    } catch (e) {
      return Left('Logout failed: ${e.toString()}');
    }
  }

  /// Refresh user profile from backend
  Future<Either<String, Map<String, dynamic>>> refreshProfile() async {
    try {
      if (!_isAuthenticated) {
        return const Left('User not authenticated');
      }

      // Simulate API call
      await Future.delayed(const Duration(milliseconds: 500));

      // Update profile with fresh data
      final updatedProfile = Map<String, dynamic>.from(_userProfile ?? {});
      updatedProfile['lastRefresh'] = DateTime.now().toIso8601String();

      await _storageService.saveUserProfile(updatedProfile);
      _userProfile = updatedProfile;

      return Right(updatedProfile);
    } catch (e) {
      return Left('Profile refresh failed: ${e.toString()}');
    }
  }

  /// Check if user has specific permission
  bool hasPermission(String permission) {
    if (!_isAuthenticated || _userProfile == null) return false;

    final permissions = _userProfile!['permissions'] as List<dynamic>?;
    return permissions?.contains(permission) ?? false;
  }

  /// Update user profile locally
  Future<Either<String, bool>> updateProfile(Map<String, dynamic> updates) async {
    try {
      if (!_isAuthenticated) {
        return const Left('User not authenticated');
      }

      final updatedProfile = Map<String, dynamic>.from(_userProfile ?? {});
      updatedProfile.addAll(updates);
      updatedProfile['updatedAt'] = DateTime.now().toIso8601String();

      await _storageService.saveUserProfile(updatedProfile);
      _userProfile = updatedProfile;

      return const Right(true);
    } catch (e) {
      return Left('Profile update failed: ${e.toString()}');
    }
  }
}