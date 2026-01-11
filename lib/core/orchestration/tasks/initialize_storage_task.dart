import 'package:dartz/dartz.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';
import '../startup_task.dart';
import '../../di/service_locator.dart';
import '../../services/storage_service.dart';

/// Critical task: Initialize Hive database and check storage health
class InitializeStorageTask extends StartupTask {
  final Logger _logger = Logger();

  InitializeStorageTask()
      : super(
    id: 'initialize_storage',
    name: 'Initialize Storage',
    priority: TaskPriority.critical,
    dependencies: ['initialize_services'],
    timeout: const Duration(seconds: 10),
  );

  @override
  Future<Either<String, bool>> execute() async {
    try {
      _logger.i('💾 Initializing local storage...');

      // Initialize Hive
      await Hive.initFlutter();

      // Open required boxes
      await Hive.openBox('app_data');
      await Hive.openBox('cache');
      await Hive.openBox('user_data');

      // Verify storage service is available
      final storageService = sl<StorageService>();

      // Check if this is first launch
      final isFirstLaunchResult = await storageService.isFirstLaunch();
      final isFirstLaunch = isFirstLaunchResult.getOrElse(() => true);

      if (isFirstLaunch) {
        _logger.i('First app launch detected - creating sample data');
        await storageService.setFirstLaunch(false);
        await _initializeDefaultData(storageService);
      }

      _logger.i('✅ Storage initialized successfully');
      return const Right(true);
    } catch (e, stackTrace) {
      _logger.e('Failed to initialize storage', error: e, stackTrace: stackTrace);
      return Left('Storage initialization failed: ${e.toString()}');
    }
  }

  Future<void> _initializeDefaultData(StorageService storage) async {
    // Set default app version
    await storage.saveAppVersion('1.0.0');

    // Create sample tasks to demonstrate the app
    final now = DateTime.now();
    final uuid = const Uuid();

    final sampleTasks = [
      {
        'id': uuid.v4(),
        'title': 'Welcome to Task Manager Pro!',
        'description': 'This is a sample task. Feel free to edit or delete it.',
        'completed': false,
        'priority': 'medium',
        'category': 'personal',
        'createdAt': now.toIso8601String(),
        'dueDate': now.add(const Duration(days: 3)).toIso8601String(),
        'tags': [],
      },
      {
        'id': uuid.v4(),
        'title': 'Complete project documentation',
        'description': 'Write comprehensive docs for the Flutter project',
        'completed': false,
        'priority': 'high',
        'category': 'work',
        'createdAt': now.subtract(const Duration(days: 2)).toIso8601String(),
        'dueDate': now.add(const Duration(days: 1)).toIso8601String(),
        'tags': [],
      },
      {
        'id': uuid.v4(),
        'title': 'Buy groceries',
        'description': 'Milk, eggs, bread, vegetables',
        'completed': false,
        'priority': 'medium',
        'category': 'shopping',
        'createdAt': now.subtract(const Duration(days: 1)).toIso8601String(),
        'dueDate': now.toIso8601String(),
        'tags': [],
      },
      {
        'id': uuid.v4(),
        'title': 'Morning workout',
        'description': '30 minutes cardio + stretching',
        'completed': true,
        'priority': 'high',
        'category': 'health',
        'createdAt': now.subtract(const Duration(days: 1)).toIso8601String(),
        'completedAt': now.subtract(const Duration(hours: 2)).toIso8601String(),
        'tags': [],
      },
      {
        'id': uuid.v4(),
        'title': 'Review code changes',
        'description': 'Check PR #123 and provide feedback',
        'completed': true,
        'priority': 'high',
        'category': 'work',
        'createdAt': now.subtract(const Duration(days: 3)).toIso8601String(),
        'completedAt': now.subtract(const Duration(days: 2)).toIso8601String(),
        'tags': [],
      },
      {
        'id': uuid.v4(),
        'title': 'Read Flutter documentation',
        'description': 'Learn about state management best practices',
        'completed': false,
        'priority': 'low',
        'category': 'education',
        'createdAt': now.subtract(const Duration(days: 4)).toIso8601String(),
        'dueDate': now.add(const Duration(days: 7)).toIso8601String(),
        'tags': [],
      },
      {
        'id': uuid.v4(),
        'title': 'Pay electricity bill',
        'description': 'Due date is approaching',
        'completed': false,
        'priority': 'urgent',
        'category': 'finance',
        'createdAt': now.subtract(const Duration(days: 5)).toIso8601String(),
        'dueDate': now.add(const Duration(days: 2)).toIso8601String(),
        'tags': [],
      },
      {
        'id': uuid.v4(),
        'title': 'Prepare presentation',
        'description': 'Quarterly review presentation for team meeting',
        'completed': false,
        'priority': 'high',
        'category': 'work',
        'createdAt': now.subtract(const Duration(days: 1)).toIso8601String(),
        'dueDate': now.add(const Duration(days: 5)).toIso8601String(),
        'tags': [],
      },
    ];

    await storage.saveTasks(sampleTasks);

    _logger.i('Created ${sampleTasks.length} sample tasks');
  }

  @override
  Future<void> onComplete() async {
    _logger.i('Hive boxes opened: ${Hive.box('app_data').name}, ${Hive.box('cache').name}');
  }
}