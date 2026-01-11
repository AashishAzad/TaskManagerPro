import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';
import '../../../shared/models/task_model.dart';
import '../../../core/repositories/task_repository.dart';
import '../widgets/sort_options_sheet.dart';
import 'tasks_event.dart';
import 'tasks_state.dart';

/// BLoC for managing tasks
class TasksBloc extends Bloc<TasksEvent, TasksState> {
  final TaskRepository _taskRepository;
  final Logger _logger = Logger();

  TasksBloc({required TaskRepository taskRepository})
      : _taskRepository = taskRepository,
        super(const TasksInitial()) {
    on<LoadTasksEvent>(_onLoadTasks);
    on<AddTaskEvent>(_onAddTask);
    on<UpdateTaskEvent>(_onUpdateTask);
    on<DeleteTaskEvent>(_onDeleteTask);
    on<ToggleTaskCompletionEvent>(_onToggleTaskCompletion);
    on<FilterTasksByCategoryEvent>(_onFilterByCategory);
    on<FilterTasksByPriorityEvent>(_onFilterByPriority);
    on<SearchTasksEvent>(_onSearchTasks);
    on<ClearFiltersEvent>(_onClearFilters);
    on<RefreshTasksEvent>(_onRefreshTasks);
    on<SortTasksEvent>(_onSortTasks);
  }

  Future<void> _onLoadTasks(
      LoadTasksEvent event,
      Emitter<TasksState> emit,
      ) async {
    try {
      emit(const TasksLoading());

      final result = await _taskRepository.getAllTasks();  // ✅ CORRECT

      result.fold(
            (error) {
          _logger.e('Failed to load tasks: $error');
          // Start with empty list on error
          emit(const TasksLoaded(
            tasks: [],
            filteredTasks: [],
          ));
        },
            (tasks) {  // ✅ Note: This is already List<TaskModel>, not JSON
          _logger.i('Loaded ${tasks.length} tasks');

          emit(TasksLoaded(
            tasks: tasks,
            filteredTasks: tasks,
          ));
        },
      );
    } catch (e) {
      _logger.e('Error loading tasks', error: e);
      // Start with empty list on error
      emit(const TasksLoaded(
        tasks: [],
        filteredTasks: [],
      ));
    }
  }

  Future<void> _onAddTask(
      AddTaskEvent event,
      Emitter<TasksState> emit,
      ) async {
    try {
      if (state is! TasksLoaded) return;

      final currentState = state as TasksLoaded;

      final result = await _taskRepository.addTask(event.task);

      result.fold(
            (error) {
          _logger.e('Error adding task: $error');
          emit(TasksError(error));
        },
            (_) {
          final updatedTasks = List<TaskModel>.from(currentState.tasks)
            ..add(event.task);

          _logger.i('Task added: ${event.task.title}');

          emit(currentState.copyWith(
            tasks: updatedTasks,
            filteredTasks: _applyFilters(
              updatedTasks,
              currentState.categoryFilter,
              currentState.priorityFilter,
              currentState.searchQuery,
            ),
          ));
        },
      );
    } catch (e) {
      _logger.e('Error adding task', error: e);
      emit(TasksError('Failed to add task: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateTask(
      UpdateTaskEvent event,
      Emitter<TasksState> emit,
      ) async {
    try {
      if (state is! TasksLoaded) return;

      final currentState = state as TasksLoaded;

      final result = await _taskRepository.updateTask(event.task);

      result.fold(
            (error) {
          _logger.e('Error updating task: $error');
          emit(TasksError(error));
        },
            (_) {
          final updatedTasks = currentState.tasks.map((task) {
            return task.id == event.task.id ? event.task : task;
          }).toList();

          _logger.i('Task updated: ${event.task.title}');

          emit(currentState.copyWith(
            tasks: updatedTasks,
            filteredTasks: _applyFilters(
              updatedTasks,
              currentState.categoryFilter,
              currentState.priorityFilter,
              currentState.searchQuery,
            ),
          ));
        },
      );
    } catch (e) {
      _logger.e('Error updating task', error: e);
      emit(TasksError('Failed to update task: ${e.toString()}'));
    }
  }

  Future<void> _onDeleteTask(
      DeleteTaskEvent event,
      Emitter<TasksState> emit,
      ) async {
    try {
      if (state is! TasksLoaded) return;

      final currentState = state as TasksLoaded;

      final result = await _taskRepository.deleteTask(event.taskId);

      result.fold(
            (error) {
          _logger.e('Error deleting task: $error');
          emit(TasksError(error));
        },
            (_) {
          final updatedTasks = currentState.tasks
              .where((task) => task.id != event.taskId)
              .toList();

          _logger.i('Task deleted: ${event.taskId}');

          emit(currentState.copyWith(
            tasks: updatedTasks,
            filteredTasks: _applyFilters(
              updatedTasks,
              currentState.categoryFilter,
              currentState.priorityFilter,
              currentState.searchQuery,
            ),
          ));
        },
      );
    } catch (e) {
      _logger.e('Error deleting task', error: e);
      emit(TasksError('Failed to delete task: ${e.toString()}'));
    }
  }

  Future<void> _onToggleTaskCompletion(
      ToggleTaskCompletionEvent event,
      Emitter<TasksState> emit,
      ) async {
    try {
      if (state is! TasksLoaded) return;

      final currentState = state as TasksLoaded;

      final result = await _taskRepository.toggleTaskCompletion(event.taskId);

      result.fold(
            (error) {
          _logger.e('Error toggling task: $error');
          emit(TasksError(error));
        },
            (updatedTask) {
          final updatedTasks = currentState.tasks.map((task) {
            return task.id == event.taskId ? updatedTask : task;
          }).toList();

          emit(currentState.copyWith(
            tasks: updatedTasks,
            filteredTasks: _applyFilters(
              updatedTasks,
              currentState.categoryFilter,
              currentState.priorityFilter,
              currentState.searchQuery,
            ),
          ));
        },
      );
    } catch (e) {
      _logger.e('Error toggling task completion', error: e);
      emit(TasksError('Failed to toggle task: ${e.toString()}'));
    }
  }

  Future<void> _onFilterByCategory(
      FilterTasksByCategoryEvent event,
      Emitter<TasksState> emit,
      ) async {
    if (state is! TasksLoaded) return;

    final currentState = state as TasksLoaded;

    emit(currentState.copyWith(
      categoryFilter: event.category,
      filteredTasks: _applyFilters(
        currentState.tasks,
        event.category,
        currentState.priorityFilter,
        currentState.searchQuery,
      ),
    ));
  }

  Future<void> _onFilterByPriority(
      FilterTasksByPriorityEvent event,
      Emitter<TasksState> emit,
      ) async {
    if (state is! TasksLoaded) return;

    final currentState = state as TasksLoaded;

    emit(currentState.copyWith(
      priorityFilter: event.priority,
      filteredTasks: _applyFilters(
        currentState.tasks,
        currentState.categoryFilter,
        event.priority,
        currentState.searchQuery,
      ),
    ));
  }

  Future<void> _onSearchTasks(
      SearchTasksEvent event,
      Emitter<TasksState> emit,
      ) async {
    if (state is! TasksLoaded) return;

    final currentState = state as TasksLoaded;

    emit(currentState.copyWith(
      searchQuery: event.query,
      filteredTasks: _applyFilters(
        currentState.tasks,
        currentState.categoryFilter,
        currentState.priorityFilter,
        event.query,
      ),
    ));
  }

  Future<void> _onClearFilters(
      ClearFiltersEvent event,
      Emitter<TasksState> emit,
      ) async {
    if (state is! TasksLoaded) return;

    final currentState = state as TasksLoaded;

    emit(TasksLoaded(
      tasks: currentState.tasks,
      filteredTasks: currentState.tasks,
    ));
  }

  Future<void> _onRefreshTasks(
      RefreshTasksEvent event,
      Emitter<TasksState> emit,
      ) async {
    add(const LoadTasksEvent());
  }

  Future<void> _onSortTasks(
      SortTasksEvent event,
      Emitter<TasksState> emit,
      ) async {
    if (state is! TasksLoaded) return;

    final currentState = state as TasksLoaded;
    final sortedTasks = _sortTasks(currentState.filteredTasks, event.sortOption);

    emit(currentState.copyWith(
      filteredTasks: sortedTasks,
      sortOption: event.sortOption,
    ));
  }

  /// Apply all active filters
  List<TaskModel> _applyFilters(
      List<TaskModel> tasks,
      TaskCategory? categoryFilter,
      TaskPriority? priorityFilter,
      String? searchQuery,
      ) {
    var filtered = tasks;

    // Apply category filter
    if (categoryFilter != null) {
      filtered = filtered.where((t) => t.category == categoryFilter).toList();
    }

    // Apply priority filter
    if (priorityFilter != null) {
      filtered = filtered.where((t) => t.priority == priorityFilter).toList();
    }

    // Apply search query
    if (searchQuery != null && searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      filtered = filtered.where((t) {
        return t.title.toLowerCase().contains(query) ||
            t.description.toLowerCase().contains(query) ||
            t.tags.any((tag) => tag.toLowerCase().contains(query));
      }).toList();
    }

    return filtered;
  }

  /// Sort tasks based on sort option
  List<TaskModel> _sortTasks(List<TaskModel> tasks, TaskSortOption sortOption) {
    final sorted = List<TaskModel>.from(tasks);

    switch (sortOption) {
      case TaskSortOption.dateCreatedNewest:
        sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case TaskSortOption.dateCreatedOldest:
        sorted.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case TaskSortOption.dueDateSoonest:
        sorted.sort((a, b) {
          if (a.dueDate == null && b.dueDate == null) return 0;
          if (a.dueDate == null) return 1;
          if (b.dueDate == null) return -1;
          return a.dueDate!.compareTo(b.dueDate!);
        });
        break;
      case TaskSortOption.dueDateLatest:
        sorted.sort((a, b) {
          if (a.dueDate == null && b.dueDate == null) return 0;
          if (a.dueDate == null) return 1;
          if (b.dueDate == null) return -1;
          return b.dueDate!.compareTo(a.dueDate!);
        });
        break;
      case TaskSortOption.priorityHighest:
        sorted.sort((a, b) => _getPriorityValue(b.priority).compareTo(_getPriorityValue(a.priority)));
        break;
      case TaskSortOption.priorityLowest:
        sorted.sort((a, b) => _getPriorityValue(a.priority).compareTo(_getPriorityValue(b.priority)));
        break;
      case TaskSortOption.titleAZ:
        sorted.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
      case TaskSortOption.titleZA:
        sorted.sort((a, b) => b.title.toLowerCase().compareTo(a.title.toLowerCase()));
        break;
    }

    return sorted;
  }

  /// Get numeric value for priority (for sorting)
  int _getPriorityValue(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.urgent:
        return 4;
      case TaskPriority.high:
        return 3;
      case TaskPriority.medium:
        return 2;
      case TaskPriority.low:
        return 1;
    }
  }
}