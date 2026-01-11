import 'package:dartz/dartz.dart';
import 'package:logger/logger.dart';
import '../startup_task.dart';
import '../../di/service_locator.dart';
import '../../services/config_service.dart';

/// High priority task: Load configuration and feature flags
class LoadConfigTask extends StartupTask {
  final Logger _logger = Logger();

  LoadConfigTask()
      : super(
    id: 'load_config',
    name: 'Load Configuration',
    priority: TaskPriority.high,
    dependencies: ['initialize_services', 'initialize_storage'],
    timeout: const Duration(seconds: 20),
  );

  @override
  Future<Either<String, bool>> execute() async {
    try {
      _logger.i('⚙️  Loading app configuration...');

      final configService = sl<ConfigService>();

      // Step 1: Load cached config from storage
      final storageResult = await configService.initializeFromStorage();
      if (storageResult.isLeft()) {
        _logger.w('Failed to load cached config, using defaults');
      }

      // Step 2: Fetch fresh config from remote (simulated API)
      _logger.i('Fetching remote configuration...');
      final remoteResult = await configService.fetchRemoteConfig();

      return remoteResult.fold(
            (error) {
          _logger.w('Remote config fetch failed: $error');
          _logger.i('Using cached/default configuration');
          // Non-critical failure - can continue with cached config
          return const Right(true);
        },
            (success) {
          _logger.i('✅ Remote configuration loaded successfully');
          final enabledFeatures = configService.getEnabledFeatures();
          _logger.i('Enabled features: ${enabledFeatures.length}');
          return const Right(true);
        },
      );
    } catch (e, stackTrace) {
      _logger.e('Config loading error', error: e, stackTrace: stackTrace);
      return Left('Configuration loading failed: ${e.toString()}');
    }
  }

  @override
  Future<void> onComplete() async {
    final configService = sl<ConfigService>();
    final flags = configService.featureFlags;
    _logger.i('Feature flags loaded: ${flags.keys.join(', ')}');

    // Log important config values
    if (configService.isMaintenanceMode()) {
      _logger.w('⚠️  App is in maintenance mode');
    }
  }
}