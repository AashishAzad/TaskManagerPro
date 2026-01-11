import 'package:equatable/equatable.dart';
import '../../../shared/models/task_model.dart';
import '../widgets/sort_options_sheet.dart';

/// Base class for all Tasks states
abstract class TasksState extends Equatable {
  const TasksState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class TasksInitial extends TasksState {
  const TasksInitial();
}

/// Loading state
class TasksLoading extends TasksState {
  const TasksLoading();
}

/// Tasks loaded successfully
class TasksLoaded extends TasksState {
  final List<TaskModel> tasks;
  final List<TaskModel> filteredTasks;
  final TaskCategory? categoryFilter;
  final TaskPriority? priorityFilter;
  final String? searchQuery;
  final TaskSortOption? sortOption;

  const TasksLoaded({
    required this.tasks,
    required this.filteredTasks,
    this.categoryFilter,
    this.priorityFilter,
    this.searchQuery,
    this.sortOption,
  });

  @override
  List<Object?> get props => [
    tasks,
    filteredTasks,
    categoryFilter,
    priorityFilter,
    searchQuery,
    sortOption,
  ];

  TasksLoaded copyWith({
    List<TaskModel>? tasks,
    List<TaskModel>? filteredTasks,
    TaskCategory? categoryFilter,
    TaskPriority? priorityFilter,
    String? searchQuery,
    TaskSortOption? sortOption,
    bool clearCategoryFilter = false,
    bool clearPriorityFilter = false,
    bool clearSearchQuery = false,
    bool clearSortOption = false,
  }) {
    return TasksLoaded(
      tasks: tasks ?? this.tasks,
      filteredTasks: filteredTasks ?? this.filteredTasks,
      categoryFilter: clearCategoryFilter ? null : (categoryFilter ?? this.categoryFilter),
      priorityFilter: clearPriorityFilter ? null : (priorityFilter ?? this.priorityFilter),
      searchQuery: clearSearchQuery ? null : (searchQuery ?? this.searchQuery),
      sortOption: clearSortOption ? null : (sortOption ?? this.sortOption),
    );
  }

  // Helper getters
  List<TaskModel> get completedTasks =>
      filteredTasks.where((task) => task.completed).toList();

  List<TaskModel> get pendingTasks =>
      filteredTasks.where((task) => !task.completed).toList();

  List<TaskModel> get overdueTasks =>
      filteredTasks.where((task) => task.isOverdue).toList();

  List<TaskModel> get todayTasks =>
      filteredTasks.where((task) => task.isDueToday).toList();

  int get totalTasks => filteredTasks.length;
  int get completedCount => completedTasks.length;
  int get pendingCount => pendingTasks.length;
  double get completionRate =>
      totalTasks > 0 ? (completedCount / totalTasks) * 100 : 0.0;

  bool get hasActiveFilters =>
      categoryFilter != null || priorityFilter != null || (searchQuery?.isNotEmpty ?? false);
}

/// Error state
class TasksError extends TasksState {
  final String message;

  const TasksError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Operation in progress (add, update, delete)
class TasksOperationInProgress extends TasksState {
  final String operation;

  const TasksOperationInProgress(this.operation);

  @override
  List<Object?> get props => [operation];
}

/// Operation successful
class TasksOperationSuccess extends TasksState {
  final String message;
  final List<TaskModel> tasks;

  const TasksOperationSuccess({
    required this.message,
    required this.tasks,
  });

  @override
  List<Object?> get props => [message, tasks];
}