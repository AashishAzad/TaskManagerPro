import 'package:dartz/dartz.dart';
import 'package:logger/logger.dart';
import '../startup_task.dart';
import '../../di/service_locator.dart';
import '../../services/sync_service.dart';
import '../../services/auth_service.dart';

/// Medium priority task: Synchronize data with backend
/// This is a heavy multi-step operation
class SyncDataTask extends StartupTask {
  final Logger _logger = Logger();

  SyncDataTask()
      : super(
    id: 'sync_data',
    name: 'Synchronize Data',
    priority: TaskPriority.medium,
    dependencies: ['validate_auth', 'load_config'],
    timeout: const Duration(seconds: 45),
  );

  @override
  Future<bool> shouldRun() async {
    // Only run if user is authenticated
    final authService = sl<AuthService>();
    return authService.isAuthenticated;
  }

  @override
  Future<Either<String, bool>> execute() async {
    try {
      _logger.i('🔄 Starting data synchronization...');

      final syncService = sl<SyncService>();

      // Initialize sync state
      await syncService.initializeSyncState();

      // Check if sync is needed
      if (!syncService.needsSync()) {
        _logger.i('Data is up to date, skipping sync');
        return const Right(true);
      }

      // Perform full synchronization
      _logger.i('Performing full sync...');
      final result = await syncService.performFullSync();

      return result.fold(
            (error) {
          _logger.e('Sync failed: $error');
          // Non-critical - user can still work with local data
          return Left(error);
        },
            (syncResult) {
          _logger.i('✅ Sync completed successfully');
          _logger.i('Synced ${syncResult.syncedItems}/${syncResult.totalItems} items in ${syncResult.duration.inSeconds}s');

          if (!syncResult.isComplete) {
            _logger.w('Some sync steps failed: ${syncResult.failedSteps.join(', ')}');
          }

          return const Right(true);
        },
      );
    } catch (e, stackTrace) {
      _logger.e('Sync error', error: e, stackTrace: stackTrace);
      return Left('Data synchronization failed: ${e.toString()}');
    }
  }

  @override
  Future<void> onComplete() async {
    final syncService = sl<SyncService>();
    final status = syncService.getSyncStatus();
    _logger.i('Last sync: ${status['last_sync_time']}');
  }

  @override
  Future<void> onError(String error) async {
    _logger.w('App will continue with local data only');
  }
}