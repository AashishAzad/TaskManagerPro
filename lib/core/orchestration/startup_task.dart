import 'package:dartz/dartz.dart';

/// Represents the priority of a startup task
enum TaskPriority {
  critical, // Must complete before app starts
  high, // Should complete early
  medium, // Can run in background
  low, // Nice to have
}

/// Represents the status of a startup task
enum TaskStatus {
  pending,
  running,
  completed,
  failed,
  skipped,
}

/// Base class for all startup tasks
/// Each task represents a discrete initialization operation
abstract class StartupTask {
  final String id;
  final String name;
  final TaskPriority priority;
  final List<String> dependencies;
  final Duration timeout;

  TaskStatus _status = TaskStatus.pending;
  String? _errorMessage;
  DateTime? _startTime;
  DateTime? _endTime;

  StartupTask({
    required this.id,
    required this.name,
    required this.priority,
    this.dependencies = const [],
    this.timeout = const Duration(seconds: 30),
  });

  /// Execute the task logic
  /// Returns Right(true) on success, Left(errorMessage) on failure
  Future<Either<String, bool>> execute();

  /// Optional: Run after task completes successfully
  Future<void> onComplete() async {}

  /// Optional: Run if task fails
  Future<void> onError(String error) async {}

  /// Optional: Check if task should run based on conditions
  Future<bool> shouldRun() async => true;

  // Getters
  TaskStatus get status => _status;
  String? get errorMessage => _errorMessage;
  DateTime? get startTime => _startTime;
  DateTime? get endTime => _endTime;
  Duration? get executionTime =>
      _startTime != null && _endTime != null
          ? _endTime!.difference(_startTime!)
          : null;

  // Internal state management
  void _markAsRunning() {
    _status = TaskStatus.running;
    _startTime = DateTime.now();
  }

  void _markAsCompleted() {
    _status = TaskStatus.completed;
    _endTime = DateTime.now();
  }

  void _markAsFailed(String error) {
    _status = TaskStatus.failed;
    _errorMessage = error;
    _endTime = DateTime.now();
  }

  void _markAsSkipped() {
    _status = TaskStatus.skipped;
  }

  /// Execute task with proper state management
  Future<Either<String, bool>> run() async {
    try {
      // Check if task should run
      final shouldExecute = await shouldRun();
      if (!shouldExecute) {
        _markAsSkipped();
        return const Right(true);
      }

      _markAsRunning();

      // Execute with timeout
      final result = await execute().timeout(
        timeout,
        onTimeout: () => const Left('Task execution timeout'),
      );

      return result.fold(
            (error) {
          _markAsFailed(error);
          onError(error);
          return Left(error);
        },
            (success) {
          _markAsCompleted();
          onComplete();
          return Right(success);
        },
      );
    } catch (e) {
      final error = 'Unexpected error: ${e.toString()}';
      _markAsFailed(error);
      await onError(error);
      return Left(error);
    }
  }

  @override
  String toString() => 'StartupTask($id: $name, Status: $_status)';
}