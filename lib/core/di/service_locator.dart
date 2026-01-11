import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../services/config_service.dart';
import '../services/analytics_service.dart';
import '../services/cache_service.dart';
import '../services/sync_service.dart';
import '../network/api_client.dart';
import '../repositories/task_repository.dart';

/// Global service locator instance
/// This is where all services are registered and retrieved
final sl = GetIt.instance;

/// Initialize all services and dependencies
/// This is called during app startup by InitializeServicesTask
class ServiceLocator {
  static final Logger _logger = Logger();

  /// Initialize core services that don't require async setup
  static Future<void> init() async {
    _logger.i('🔧 Initializing Service Locator...');

    // Core utilities
    sl.registerLazySingleton<Logger>(() => Logger(
      printer: PrettyPrinter(
        methodCount: 2,
        errorMethodCount: 8,
        lineLength: 120,
        colors: true,
        printEmojis: true,
      ),
    ));

    // External dependencies
    final sharedPreferences = await SharedPreferences.getInstance();
    sl.registerSingleton<SharedPreferences>(sharedPreferences);

    _logger.i('✅ Service Locator initialized');
  }

  /// Register all application services
  /// Called after core initialization
  static void registerServices() {
    _logger.i('📦 Registering application services...');

    // Network layer
    sl.registerLazySingleton<ApiClient>(
          () => ApiClient(),
    );

    // Core services
    sl.registerLazySingleton<StorageService>(
          () => StorageService(sl()),
    );

    sl.registerLazySingleton<ConfigService>(
          () => ConfigService(sl()),
    );

    sl.registerLazySingleton<CacheService>(
          () => CacheService(),
    );

    sl.registerLazySingleton<AuthService>(
          () => AuthService(
        apiClient: sl(),
        storageService: sl(),
      ),
    );

    sl.registerLazySingleton<AnalyticsService>(
          () => AnalyticsService(
        storageService: sl(),
      ),
    );

    sl.registerLazySingleton<SyncService>(
          () => SyncService(
        apiClient: sl(),
        storageService: sl(),
        analyticsService: sl(),
      ),
    );

    // Repositories
    sl.registerLazySingleton<TaskRepository>(
          () => TaskRepository(sl()),
    );

    _logger.i('✅ All services registered');
  }

  /// Reset all services (useful for testing or logout)
  static Future<void> reset() async {
    _logger.w('🔄 Resetting Service Locator...');
    await sl.reset();
    _logger.i('✅ Service Locator reset complete');
  }

  /// Check if a service is registered
  static bool isRegistered<T extends Object>() {
    return sl.isRegistered<T>();
  }
}