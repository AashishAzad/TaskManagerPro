import 'package:dartz/dartz.dart';
import '../network/api_client.dart';
import 'storage_service.dart';
import 'analytics_service.dart';

/// Service for synchronizing data between local and remote
/// Handles multi-step sync process during startup
class SyncService {
  final ApiClient _apiClient;
  final StorageService _storageService;
  final AnalyticsService _analyticsService;

  bool _isSyncing = false;
  DateTime? _lastSyncTime;
  int _syncVersion = 0;

  SyncService({
    required ApiClient apiClient,
    required StorageService storageService,
    required AnalyticsService analyticsService,
  })  : _apiClient = apiClient,
        _storageService = storageService,
        _analyticsService = analyticsService;

  bool get isSyncing => _isSyncing;
  DateTime? get lastSyncTime => _lastSyncTime;
  int get syncVersion => _syncVersion;

  /// Initialize sync state from storage
  Future<Either<String, bool>> initializeSyncState() async {
    try {
      final lastSyncResult = await _storageService.getLastSyncTime();

      lastSyncResult.fold(
            (error) => null,
            (time) => _lastSyncTime = time,
      );

      return const Right(true);
    } catch (e) {
      return Left('Sync state initialization failed: ${e.toString()}');
    }
  }

  /// Perform full synchronization (heavy operation)
  /// This is a multi-step process that can take several seconds
  Future<Either<String, SyncResult>> performFullSync() async {
    if (_isSyncing) {
      return const Left('Sync already in progress');
    }

    try {
      _isSyncing = true;
      final steps = <String, bool>{};
      final startTime = DateTime.now();

      // Step 1: Sync user profile
      final profileResult = await _syncUserProfile();
      steps['user_profile'] = profileResult.isRight();
      if (profileResult.isLeft()) {
        return Left('Profile sync failed: ${profileResult.fold((l) => l, (r) => '')}');
      }
      await Future.delayed(const Duration(milliseconds: 500));

      // Step 2: Sync tasks
      final tasksResult = await _syncTasks();
      steps['tasks'] = tasksResult.isRight();
      if (tasksResult.isLeft()) {
        return Left('Tasks sync failed: ${tasksResult.fold((l) => l, (r) => '')}');
      }
      await Future.delayed(const Duration(milliseconds: 800));

      // Step 3: Sync analytics
      final analyticsResult = await _syncAnalytics();
      steps['analytics'] = analyticsResult.isRight();
      if (analyticsResult.isLeft()) {
        return Left('Analytics sync failed: ${analyticsResult.fold((l) => l, (r) => '')}');
      }
      await Future.delayed(const Duration(milliseconds: 600));

      // Step 4: Sync settings
      final settingsResult = await _syncSettings();
      steps['settings'] = settingsResult.isRight();
      if (settingsResult.isLeft()) {
        return Left('Settings sync failed: ${settingsResult.fold((l) => l, (r) => '')}');
      }
      await Future.delayed(const Duration(milliseconds: 400));

      // Step 5: Sync attachments metadata
      final attachmentsResult = await _syncAttachments();
      steps['attachments'] = attachmentsResult.isRight();
      // Non-critical, continue even if fails

      _lastSyncTime = DateTime.now();
      _syncVersion++;
      await _storageService.saveLastSyncTime(_lastSyncTime!);

      final duration = DateTime.now().difference(startTime);

      final result = SyncResult(
        success: true,
        syncedItems: steps.values.where((v) => v).length,
        totalItems: steps.length,
        duration: duration,
        steps: steps,
        timestamp: _lastSyncTime!,
      );

      return Right(result);
    } catch (e) {
      return Left('Full sync failed: ${e.toString()}');
    } finally {
      _isSyncing = false;
    }
  }

  /// Perform incremental sync (only changed data)
  Future<Either<String, SyncResult>> performIncrementalSync() async {
    if (_isSyncing) {
      return const Left('Sync already in progress');
    }

    try {
      _isSyncing = true;
      final steps = <String, bool>{};
      final startTime = DateTime.now();

      // Only sync data that changed since last sync
      if (_lastSyncTime == null) {
        return performFullSync();
      }

      // Simulate incremental sync (lighter operation)
      await Future.delayed(const Duration(seconds: 1));

      final changedTasks = await _getChangedTasks(_lastSyncTime!);
      if (changedTasks.isNotEmpty) {
        final syncResult = await _syncChangedTasks(changedTasks);
        steps['tasks'] = syncResult.isRight();
      }

      _lastSyncTime = DateTime.now();
      _syncVersion++;
      await _storageService.saveLastSyncTime(_lastSyncTime!);

      final duration = DateTime.now().difference(startTime);

      final result = SyncResult(
        success: true,
        syncedItems: steps.values.where((v) => v).length,
        totalItems: steps.length,
        duration: duration,
        steps: steps,
        timestamp: _lastSyncTime!,
      );

      return Right(result);
    } catch (e) {
      return Left('Incremental sync failed: ${e.toString()}');
    } finally {
      _isSyncing = false;
    }
  }

  /// Check if sync is needed based on time elapsed
  bool needsSync({Duration threshold = const Duration(minutes: 30)}) {
    if (_lastSyncTime == null) return true;

    final timeSinceSync = DateTime.now().difference(_lastSyncTime!);
    return timeSinceSync > threshold;
  }

  /// Private sync methods for different data types

  Future<Either<String, bool>> _syncUserProfile() async {
    try {
      // Simulate fetching user profile from server
      await Future.delayed(const Duration(milliseconds: 600));

      final mockProfile = {
        'id': 'user_123',
        'name': 'John Doe',
        'email': 'john@example.com',
        'avatar': 'https://i.pravatar.cc/150',
        'preferences': {
          'theme': 'dark',
          'notifications': true,
        },
        'lastSync': DateTime.now().toIso8601String(),
      };

      await _storageService.saveUserProfile(mockProfile);
      return const Right(true);
    } catch (e) {
      return Left('Profile sync error: ${e.toString()}');
    }
  }

  Future<Either<String, bool>> _syncTasks() async {
    try {
      // Simulate fetching tasks from server
      await Future.delayed(const Duration(milliseconds: 1000));

      final mockTasks = List.generate(15, (index) {
        final now = DateTime.now();
        return {
          'id': 'task_$index',
          'title': 'Task ${index + 1}',
          'description': 'Description for task ${index + 1}',
          'completed': index % 3 == 0,
          'priority': ['low', 'medium', 'high'][index % 3],
          'category': ['Work', 'Personal', 'Shopping'][index % 3],
          'createdAt': now.subtract(Duration(days: index)).toIso8601String(),
          'completedAt': index % 3 == 0
              ? now.subtract(Duration(days: index ~/ 2)).toIso8601String()
              : null,
          'dueDate': now.add(Duration(days: 7 - index)).toIso8601String(),
        };
      });

      await _storageService.saveTasks(mockTasks);
      return const Right(true);
    } catch (e) {
      return Left('Tasks sync error: ${e.toString()}');
    }
  }

  Future<Either<String, bool>> _syncAnalytics() async {
    try {
      // Simulate syncing analytics data
      await Future.delayed(const Duration(milliseconds: 800));

      // Trigger analytics processing
      await _analyticsService.processAnalytics();

      return const Right(true);
    } catch (e) {
      return Left('Analytics sync error: ${e.toString()}');
    }
  }

  Future<Either<String, bool>> _syncSettings() async {
    try {
      // Simulate fetching app settings
      await Future.delayed(const Duration(milliseconds: 400));

      final mockSettings = {
        'theme': 'dark',
        'language': 'en',
        'notifications_enabled': true,
        'auto_sync': true,
        'sync_frequency': 'hourly',
      };

      // In real app, would save to storage
      return const Right(true);
    } catch (e) {
      return Left('Settings sync error: ${e.toString()}');
    }
  }

  Future<Either<String, bool>> _syncAttachments() async {
    try {
      // Simulate syncing attachment metadata
      await Future.delayed(const Duration(milliseconds: 600));

      // In real app, would sync file metadata
      return const Right(true);
    } catch (e) {
      return Left('Attachments sync error: ${e.toString()}');
    }
  }

  Future<List<Map<String, dynamic>>> _getChangedTasks(DateTime since) async {
    // Simulate checking for changed tasks
    await Future.delayed(const Duration(milliseconds: 300));

    final tasksResult = await _storageService.getTasks();
    final tasks = tasksResult.getOrElse(() => null) ?? [];

    return tasks.where((task) {
      final updatedAt = DateTime.tryParse(task['updatedAt'] ?? '');
      return updatedAt != null && updatedAt.isAfter(since);
    }).toList();
  }

  Future<Either<String, bool>> _syncChangedTasks(
      List<Map<String, dynamic>> tasks,
      ) async {
    try {
      // Simulate syncing only changed tasks
      await Future.delayed(Duration(milliseconds: tasks.length * 100));
      return const Right(true);
    } catch (e) {
      return Left('Changed tasks sync error: ${e.toString()}');
    }
  }

  /// Force sync now
  Future<Either<String, SyncResult>> forceSyncNow() async {
    return performFullSync();
  }

  /// Get sync status
  Map<String, dynamic> getSyncStatus() {
    return {
      'is_syncing': _isSyncing,
      'last_sync_time': _lastSyncTime?.toIso8601String(),
      'sync_version': _syncVersion,
      'needs_sync': needsSync(),
      'time_since_sync': _lastSyncTime != null
          ? DateTime.now().difference(_lastSyncTime!).inMinutes
          : null,
    };
  }
}

/// Result of a sync operation
class SyncResult {
  final bool success;
  final int syncedItems;
  final int totalItems;
  final Duration duration;
  final Map<String, bool> steps;
  final DateTime timestamp;

  const SyncResult({
    required this.success,
    required this.syncedItems,
    required this.totalItems,
    required this.duration,
    required this.steps,
    required this.timestamp,
  });

  double get successRate =>
      totalItems > 0 ? (syncedItems / totalItems) * 100 : 0;

  bool get isComplete => syncedItems == totalItems;

  List<String> get failedSteps => steps.entries
      .where((entry) => !entry.value)
      .map((entry) => entry.key)
      .toList();
}