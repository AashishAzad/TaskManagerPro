import 'package:dartz/dartz.dart';
import 'package:logger/logger.dart';
import '../services/storage_service.dart';
import '../../shared/models/task_model.dart';

/// Repository for managing task data operations
class TaskRepository {
  final StorageService _storageService;
  final Logger _logger = Logger();

  TaskRepository(this._storageService);

  /// Get all tasks
  Future<Either<String, List<TaskModel>>> getAllTasks() async {
    try {
      final result = await _storageService.getTasks();

      return result.fold(
            (error) => Left(error),
            (tasksJson) {
          if (tasksJson == null) {
            return const Right([]);
          }

          final tasks = tasksJson
              .map((json) => TaskModel.fromJson(json))
              .toList();

          return Right(tasks);
        },
      );
    } catch (e) {
      _logger.e('Error getting tasks', error: e);
      return Left('Failed to get tasks: ${e.toString()}');
    }
  }

  /// Get task by ID
  Future<Either<String, TaskModel?>> getTaskById(String id) async {
    try {
      final result = await getAllTasks();

      return result.fold(
            (error) => Left(error),
            (tasks) {
          final task = tasks.where((t) => t.id == id).firstOrNull;
          return Right(task);
        },
      );
    } catch (e) {
      _logger.e('Error getting task by id', error: e);
      return Left('Failed to get task: ${e.toString()}');
    }
  }

  /// Add a new task
  Future<Either<String, TaskModel>> addTask(TaskModel task) async {
    try {
      final tasksResult = await getAllTasks();

      return await tasksResult.fold(
            (error) => Left(error),
            (tasks) async {
          final updatedTasks = List<TaskModel>.from(tasks)..add(task);
          final saveResult = await _saveTasks(updatedTasks);

          return saveResult.fold(
                (error) => Left(error),
                (_) {
              _logger.i('Task added: ${task.id}');
              return Right(task);
            },
          );
        },
      );
    } catch (e) {
      _logger.e('Error adding task', error: e);
      return Left('Failed to add task: ${e.toString()}');
    }
  }

  /// Update an existing task
  Future<Either<String, TaskModel>> updateTask(TaskModel task) async {
    try {
      final tasksResult = await getAllTasks();

      return await tasksResult.fold(
            (error) => Left(error),
            (tasks) async {
          final updatedTasks = tasks.map((t) {
            return t.id == task.id ? task : t;
          }).toList();

          final saveResult = await _saveTasks(updatedTasks);

          return saveResult.fold(
                (error) => Left(error),
                (_) {
              _logger.i('Task updated: ${task.id}');
              return Right(task);
            },
          );
        },
      );
    } catch (e) {
      _logger.e('Error updating task', error: e);
      return Left('Failed to update task: ${e.toString()}');
    }
  }

  /// Delete a task
  Future<Either<String, bool>> deleteTask(String taskId) async {
    try {
      _logger.i('Attempting to delete task: $taskId');

      final tasksResult = await getAllTasks();

      return await tasksResult.fold(
            (error) => Left(error),
            (tasks) async {
          // Check if task exists
          final taskExists = tasks.any((t) => t.id == taskId);
          if (!taskExists) {
            _logger.w('Task not found: $taskId');
            return const Right(true); // Return success even if not found
          }

          final updatedTasks = tasks.where((t) => t.id != taskId).toList();

          _logger.i('Tasks before delete: ${tasks.length}, after: ${updatedTasks.length}');

          final saveResult = await _saveTasks(updatedTasks);

          return saveResult.fold(
                (error) {
              _logger.e('Failed to save after delete: $error');
              return Left(error);
            },
                (_) {
              _logger.i('Task deleted successfully: $taskId');
              return const Right(true);
            },
          );
        },
      );
    } catch (e, stackTrace) {
      _logger.e('Error deleting task', error: e, stackTrace: stackTrace);
      return Left('Failed to delete task: ${e.toString()}');
    }
  }

  /// Toggle task completion
  Future<Either<String, TaskModel>> toggleTaskCompletion(String taskId) async {
    try {
      final taskResult = await getTaskById(taskId);

      return await taskResult.fold(
            (error) => Left(error),
            (task) async {
          if (task == null) {
            return const Left('Task not found');
          }

          final updatedTask = task.copyWith(
            completed: !task.completed,
            completedAt: !task.completed ? DateTime.now() : null,
          );

          return await updateTask(updatedTask);
        },
      );
    } catch (e) {
      _logger.e('Error toggling task completion', error: e);
      return Left('Failed to toggle task: ${e.toString()}');
    }
  }

  /// Get tasks by category
  Future<Either<String, List<TaskModel>>> getTasksByCategory(
      TaskCategory category,
      ) async {
    try {
      final result = await getAllTasks();

      return result.fold(
            (error) => Left(error),
            (tasks) {
          final filtered = tasks.where((t) => t.category == category).toList();
          return Right(filtered);
        },
      );
    } catch (e) {
      return Left('Failed to get tasks by category: ${e.toString()}');
    }
  }

  /// Get tasks by priority
  Future<Either<String, List<TaskModel>>> getTasksByPriority(
      TaskPriority priority,
      ) async {
    try {
      final result = await getAllTasks();

      return result.fold(
            (error) => Left(error),
            (tasks) {
          final filtered = tasks.where((t) => t.priority == priority).toList();
          return Right(filtered);
        },
      );
    } catch (e) {
      return Left('Failed to get tasks by priority: ${e.toString()}');
    }
  }

  /// Get completed tasks
  Future<Either<String, List<TaskModel>>> getCompletedTasks() async {
    try {
      final result = await getAllTasks();

      return result.fold(
            (error) => Left(error),
            (tasks) {
          final completed = tasks.where((t) => t.completed).toList();
          return Right(completed);
        },
      );
    } catch (e) {
      return Left('Failed to get completed tasks: ${e.toString()}');
    }
  }

  /// Get pending tasks
  Future<Either<String, List<TaskModel>>> getPendingTasks() async {
    try {
      final result = await getAllTasks();

      return result.fold(
            (error) => Left(error),
            (tasks) {
          final pending = tasks.where((t) => !t.completed).toList();
          return Right(pending);
        },
      );
    } catch (e) {
      return Left('Failed to get pending tasks: ${e.toString()}');
    }
  }

  /// Get overdue tasks
  Future<Either<String, List<TaskModel>>> getOverdueTasks() async {
    try {
      final result = await getAllTasks();

      return result.fold(
            (error) => Left(error),
            (tasks) {
          final overdue = tasks.where((t) => t.isOverdue).toList();
          return Right(overdue);
        },
      );
    } catch (e) {
      return Left('Failed to get overdue tasks: ${e.toString()}');
    }
  }

  /// Search tasks
  Future<Either<String, List<TaskModel>>> searchTasks(String query) async {
    try {
      final result = await getAllTasks();

      return result.fold(
            (error) => Left(error),
            (tasks) {
          final lowerQuery = query.toLowerCase();
          final filtered = tasks.where((t) {
            return t.title.toLowerCase().contains(lowerQuery) ||
                t.description.toLowerCase().contains(lowerQuery) ||
                t.tags.any((tag) => tag.toLowerCase().contains(lowerQuery));
          }).toList();
          return Right(filtered);
        },
      );
    } catch (e) {
      return Left('Failed to search tasks: ${e.toString()}');
    }
  }

  /// Delete all completed tasks
  Future<Either<String, int>> deleteCompletedTasks() async {
    try {
      final tasksResult = await getAllTasks();

      return await tasksResult.fold(
            (error) => Left(error),
            (tasks) async {
          final completedCount = tasks.where((t) => t.completed).length;
          final remainingTasks = tasks.where((t) => !t.completed).toList();

          final saveResult = await _saveTasks(remainingTasks);

          return saveResult.fold(
                (error) => Left(error),
                (_) {
              _logger.i('Deleted $completedCount completed tasks');
              return Right(completedCount);
            },
          );
        },
      );
    } catch (e) {
      return Left('Failed to delete completed tasks: ${e.toString()}');
    }
  }

  /// Private helper to save tasks
  Future<Either<String, bool>> _saveTasks(List<TaskModel> tasks) async {
    try {
      final tasksJson = tasks.map((t) => t.toJson()).toList();
      return await _storageService.saveTasks(tasksJson);
    } catch (e) {
      _logger.e('Error saving tasks', error: e);
      return Left('Failed to save tasks: ${e.toString()}');
    }
  }

  /// Get task statistics
  Future<Either<String, TaskStatistics>> getStatistics() async {
    try {
      final result = await getAllTasks();

      return result.fold(
            (error) => Left(error),
            (tasks) {
          final stats = TaskStatistics(
            total: tasks.length,
            completed: tasks.where((t) => t.completed).length,
            pending: tasks.where((t) => !t.completed).length,
            overdue: tasks.where((t) => t.isOverdue).length,
            dueToday: tasks.where((t) => t.isDueToday).length,
          );
          return Right(stats);
        },
      );
    } catch (e) {
      return Left('Failed to get statistics: ${e.toString()}');
    }
  }
}

/// Task statistics model
class TaskStatistics {
  final int total;
  final int completed;
  final int pending;
  final int overdue;
  final int dueToday;

  TaskStatistics({
    required this.total,
    required this.completed,
    required this.pending,
    required this.overdue,
    required this.dueToday,
  });

  double get completionRate =>
      total > 0 ? (completed / total) * 100 : 0.0;
}