import 'package:dartz/dartz.dart';
import 'package:logger/logger.dart';
import '../startup_task.dart';
import '../../di/service_locator.dart';
import '../../services/auth_service.dart';

/// High priority task: Validate and restore user session
class ValidateAuthTask extends StartupTask {
  final Logger _logger = Logger();

  ValidateAuthTask()
      : super(
    id: 'validate_auth',
    name: 'Validate Authentication',
    priority: TaskPriority.high,
    dependencies: ['initialize_services', 'initialize_storage'],
    timeout: const Duration(seconds: 15),
  );

  @override
  Future<Either<String, bool>> execute() async {
    try {
      _logger.i('🔐 Validating authentication state...');

      final authService = sl<AuthService>();

      // Initialize auth state from storage
      final result = await authService.initializeAuthState();

      return result.fold(
            (error) {
          _logger.w('Auth validation failed: $error');
          // Auth failure is not critical - user can login
          return const Right(true);
        },
            (isAuthenticated) {
          if (isAuthenticated) {
            _logger.i('✅ User session restored: ${authService.currentUserId}');
          } else {
            _logger.i('No active session found');
          }
          return const Right(true);
        },
      );
    } catch (e, stackTrace) {
      _logger.e('Auth validation error', error: e, stackTrace: stackTrace);
      // Don't fail critically - user can still use app
      return const Right(true);
    }
  }

  @override
  Future<void> onComplete() async {
    final authService = sl<AuthService>();
    if (authService.isAuthenticated) {
      _logger.i('User authenticated: ${authService.userProfile?['email']}');
    }
  }
}