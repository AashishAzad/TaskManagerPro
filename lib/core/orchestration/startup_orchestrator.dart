import 'dart:async';
import 'package:logger/logger.dart';
import 'startup_task.dart';
import 'orchestrator_config.dart';

/// The central orchestrator that manages all startup tasks
/// This is the brain of the startup process - "kaun kab chalega, kaun kisko call karega"
class StartupOrchestrator {
  final OrchestratorConfig config;
  final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 80,
      colors: true,
      printEmojis: true,
    ),
  );

  final List<StartupTask> _tasks = [];
  final Map<String, TaskResult> _results = {};
  final List<String> _errors = [];
  final List<String> _warnings = [];

  DateTime? _startTime;
  DateTime? _endTime;

  // Stream controllers for real-time progress updates
  final StreamController<TaskProgressEvent> _progressController =
  StreamController<TaskProgressEvent>.broadcast();

  Stream<TaskProgressEvent> get progressStream => _progressController.stream;

  StartupOrchestrator({
    required this.config,
  });

  /// Register a task to be executed during startup
  void registerTask(StartupTask task) {
    if (_tasks.any((t) => t.id == task.id)) {
      _logger.w('Task ${task.id} already registered. Skipping.');
      return;
    }
    _tasks.add(task);
    _log('Registered task: ${task.name} [Priority: ${task.priority.name}]');
  }

  /// Register multiple tasks at once
  void registerTasks(List<StartupTask> tasks) {
    for (final task in tasks) {
      registerTask(task);
    }
  }

  /// Start the orchestration process
  /// Returns the result of all task executions
  Future<OrchestrationResult> orchestrate() async {
    _startTime = DateTime.now();
    _log('🚀 Starting application orchestration...', level: Level.info);
    _broadcastProgress(TaskProgressEvent.started());

    try {
      // Validate dependencies
      _validateDependencies();

      // Sort tasks by priority and dependencies
      final sortedTasks = _topologicalSort();

      // Group tasks by priority for execution strategy
      final criticalTasks = sortedTasks
          .where((t) => t.priority == TaskPriority.critical)
          .toList();
      final highPriorityTasks = sortedTasks
          .where((t) => t.priority == TaskPriority.high)
          .toList();
      final mediumPriorityTasks = sortedTasks
          .where((t) => t.priority == TaskPriority.medium)
          .toList();
      final lowPriorityTasks = sortedTasks
          .where((t) => t.priority == TaskPriority.low)
          .toList();

      // Execute critical tasks sequentially (must complete)
      await _executeTasksSequentially(criticalTasks, allowFailure: false);

      // Execute high priority tasks (can run in parallel if enabled)
      if (config.enableParallelExecution) {
        await _executeTasksInParallel(highPriorityTasks);
      } else {
        await _executeTasksSequentially(highPriorityTasks);
      }

      // Execute medium priority tasks in background
      if (config.enableParallelExecution) {
        _executeTasksInBackground(mediumPriorityTasks);
      } else {
        await _executeTasksSequentially(mediumPriorityTasks);
      }

      // Execute low priority tasks in background (fire and forget)
      _executeTasksInBackground(lowPriorityTasks);

      _endTime = DateTime.now();
      final result = _buildResult();

      _log(
        '✅ Orchestration completed in ${result.totalTime.inMilliseconds}ms',
        level: Level.info,
      );
      _log(
        'Tasks: ${result.completedTasks} completed, ${result.failedTasks} failed',
        level: Level.info,
      );

      _broadcastProgress(TaskProgressEvent.completed(result));

      return result;
    } catch (e, stackTrace) {
      _logger.e('Fatal orchestration error', error: e, stackTrace: stackTrace);
      _errors.add('Fatal error: ${e.toString()}');
      _endTime = DateTime.now();

      final result = _buildResult(success: false);
      _broadcastProgress(TaskProgressEvent.failed(result));

      return result;
    } finally {
      await _progressController.close();
    }
  }

  /// Execute tasks one by one
  Future<void> _executeTasksSequentially(
      List<StartupTask> tasks, {
        bool allowFailure = true,
      }) async {
    for (final task in tasks) {
      await _executeTask(task, allowFailure: allowFailure);
    }
  }

  /// Execute tasks in parallel
  Future<void> _executeTasksInParallel(List<StartupTask> tasks) async {
    final futures = tasks.map((task) => _executeTask(task));
    await Future.wait(futures);
  }

  /// Execute tasks in background (don't wait)
  void _executeTasksInBackground(List<StartupTask> tasks) {
    for (final task in tasks) {
      _executeTask(task).catchError((e) {
        _logger.w('Background task ${task.id} failed: $e');
      });
    }
  }

  /// Execute a single task
  Future<void> _executeTask(
      StartupTask task, {
        bool allowFailure = true,
      }) async {
    _log('▶️  Executing: ${task.name}');
    _broadcastProgress(TaskProgressEvent.taskStarted(task.id, task.name));

    final result = await task.run();

    result.fold(
          (error) {
        _log('❌ Failed: ${task.name} - $error', level: Level.error);
        _errors.add('${task.name}: $error');
        _results[task.id] = TaskResult.fromTask(task);
        _broadcastProgress(TaskProgressEvent.taskFailed(task.id, task.name, error));

        if (!allowFailure && task.priority == TaskPriority.critical) {
          throw Exception('Critical task failed: ${task.name}');
        }
      },
          (success) {
        _log('✅ Completed: ${task.name} in ${task.executionTime?.inMilliseconds}ms');
        _results[task.id] = TaskResult.fromTask(task);
        _broadcastProgress(TaskProgressEvent.taskCompleted(task.id, task.name));
      },
    );
  }

  /// Validate that all task dependencies are registered
  void _validateDependencies() {
    for (final task in _tasks) {
      for (final depId in task.dependencies) {
        if (!_tasks.any((t) => t.id == depId)) {
          throw Exception(
            'Task ${task.id} depends on $depId which is not registered',
          );
        }
      }
    }
  }

  /// Sort tasks using topological sort (respecting dependencies)
  List<StartupTask> _topologicalSort() {
    final sorted = <StartupTask>[];
    final visited = <String>{};
    final visiting = <String>{};

    void visit(StartupTask task) {
      if (visited.contains(task.id)) return;
      if (visiting.contains(task.id)) {
        throw Exception('Circular dependency detected involving ${task.id}');
      }

      visiting.add(task.id);

      for (final depId in task.dependencies) {
        final depTask = _tasks.firstWhere((t) => t.id == depId);
        visit(depTask);
      }

      visiting.remove(task.id);
      visited.add(task.id);
      sorted.add(task);
    }

    // Sort by priority first, then apply topological sort
    final tasksByPriority = List<StartupTask>.from(_tasks)
      ..sort((a, b) => a.priority.index.compareTo(b.priority.index));

    for (final task in tasksByPriority) {
      visit(task);
    }

    return sorted;
  }

  /// Build the final orchestration result
  OrchestrationResult _buildResult({bool success = true}) {
    final totalTime = _endTime!.difference(_startTime!);

    return OrchestrationResult(
      success: success && _errors.isEmpty,
      totalTime: totalTime,
      taskResults: Map.from(_results),
      errors: List.from(_errors),
      warnings: List.from(_warnings),
    );
  }

  /// Log message with optional level
  void _log(String message, {Level level = Level.debug}) {
    if (!config.enableDetailedLogging && level == Level.debug) return;

    switch (level) {
      case Level.debug:
        _logger.d(message);
        break;
      case Level.info:
        _logger.i(message);
        break;
      case Level.warning:
        _logger.w(message);
        break;
      case Level.error:
        _logger.e(message);
        break;
      default:
        _logger.d(message);
    }
  }

  /// Broadcast progress event
  void _broadcastProgress(TaskProgressEvent event) {
    if (!_progressController.isClosed) {
      _progressController.add(event);
    }
  }

  /// Dispose resources
  void dispose() {
    _progressController.close();
  }
}

/// Events for tracking orchestration progress
class TaskProgressEvent {
  final TaskProgressType type;
  final String? taskId;
  final String? taskName;
  final String? error;
  final OrchestrationResult? result;

  const TaskProgressEvent({
    required this.type,
    this.taskId,
    this.taskName,
    this.error,
    this.result,
  });

  factory TaskProgressEvent.started() {
    return const TaskProgressEvent(type: TaskProgressType.orchestrationStarted);
  }

  factory TaskProgressEvent.taskStarted(String taskId, String taskName) {
    return TaskProgressEvent(
      type: TaskProgressType.taskStarted,
      taskId: taskId,
      taskName: taskName,
    );
  }

  factory TaskProgressEvent.taskCompleted(String taskId, String taskName) {
    return TaskProgressEvent(
      type: TaskProgressType.taskCompleted,
      taskId: taskId,
      taskName: taskName,
    );
  }

  factory TaskProgressEvent.taskFailed(String taskId, String taskName, String error) {
    return TaskProgressEvent(
      type: TaskProgressType.taskFailed,
      taskId: taskId,
      taskName: taskName,
      error: error,
    );
  }

  factory TaskProgressEvent.completed(OrchestrationResult result) {
    return TaskProgressEvent(
      type: TaskProgressType.orchestrationCompleted,
      result: result,
    );
  }

  factory TaskProgressEvent.failed(OrchestrationResult result) {
    return TaskProgressEvent(
      type: TaskProgressType.orchestrationFailed,
      result: result,
    );
  }
}

enum TaskProgressType {
  orchestrationStarted,
  taskStarted,
  taskCompleted,
  taskFailed,
  orchestrationCompleted,
  orchestrationFailed,
}