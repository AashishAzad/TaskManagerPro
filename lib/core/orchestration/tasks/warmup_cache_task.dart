import 'package:dartz/dartz.dart';
import 'package:logger/logger.dart';
import '../startup_task.dart';
import '../../di/service_locator.dart';
import '../../services/cache_service.dart';

/// Medium priority task: Pre-load frequently accessed data into cache
/// This improves app performance after startup
class WarmupCacheTask extends StartupTask {
  final Logger _logger = Logger();

  WarmupCacheTask()
      : super(
    id: 'warmup_cache',
    name: 'Warmup Cache',
    priority: TaskPriority.medium,
    dependencies: ['initialize_services', 'load_config'],
    timeout: const Duration(seconds: 30),
  );

  @override
  Future<Either<String, bool>> execute() async {
    try {
      _logger.i('🔥 Warming up cache...');

      final cacheService = sl<CacheService>();

      // Warmup cache with frequently accessed data
      final result = await cacheService.warmupCache();

      return result.fold(
            (error) {
          _logger.w('Cache warmup failed: $error');
          // Non-critical - app can work without warmed cache
          return const Right(true);
        },
            (success) {
          _logger.i('✅ Cache warmed successfully');
          final stats = cacheService.getStats();
          _logger.i('Cache entries: ${stats['valid_entries']}');
          return const Right(true);
        },
      );
    } catch (e, stackTrace) {
      _logger.e('Cache warmup error', error: e, stackTrace: stackTrace);
      // Non-critical failure
      return const Right(true);
    }
  }

  @override
  Future<void> onComplete() async {
    final cacheService = sl<CacheService>();
    _logger.i('Cache ready with ${cacheService.cacheSize} entries');
  }
}