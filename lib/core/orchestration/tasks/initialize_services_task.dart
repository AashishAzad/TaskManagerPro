import 'package:dartz/dartz.dart';
import 'package:logger/logger.dart';
import '../startup_task.dart';
import '../../di/service_locator.dart';

/// Critical task: Initialize core services and dependencies
/// This must run first before any other task
class InitializeServicesTask extends StartupTask {
  final Logger _logger = Logger();

  InitializeServicesTask()
      : super(
    id: 'initialize_services',
    name: 'Initialize Services',
    priority: TaskPriority.critical,
    dependencies: [],
    timeout: const Duration(seconds: 10),
  );

  @override
  Future<Either<String, bool>> execute() async {
    try {
      _logger.i('🔧 Initializing core services...');

      // Step 1: Initialize service locator (SharedPreferences, Logger, etc.)
      await ServiceLocator.init();

      // Step 2: Register all application services
      ServiceLocator.registerServices();

      _logger.i('✅ Services initialized successfully');
      return const Right(true);
    } catch (e, stackTrace) {
      _logger.e('Failed to initialize services', error: e, stackTrace: stackTrace);
      return Left('Service initialization failed: ${e.toString()}');
    }
  }

  // @override
  // Future<void> onComplete() async {
  //   _logger.i('Service locator ready with ${ServiceLocator.sl.allReady().length} services');
  // }

  @override
  Future<void> onError(String error) async {
    _logger.e('Critical: Service initialization failed - app cannot continue');
  }
}