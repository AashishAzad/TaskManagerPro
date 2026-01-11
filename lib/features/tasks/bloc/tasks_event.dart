import 'package:equatable/equatable.dart';
import '../../../shared/models/task_model.dart';
import '../widgets/sort_options_sheet.dart';

/// Base class for all Tasks events
abstract class TasksEvent extends Equatable {
  const TasksEvent();

  @override
  List<Object?> get props => [];
}

/// Load all tasks
class LoadTasksEvent extends TasksEvent {
  const LoadTasksEvent();
}

/// Add a new task
class AddTaskEvent extends TasksEvent {
  final TaskModel task;

  const AddTaskEvent(this.task);

  @override
  List<Object?> get props => [task];
}

/// Update an existing task
class UpdateTaskEvent extends TasksEvent {
  final TaskModel task;

  const UpdateTaskEvent(this.task);

  @override
  List<Object?> get props => [task];
}

/// Delete a task
class DeleteTaskEvent extends TasksEvent {
  final String taskId;

  const DeleteTaskEvent(this.taskId);

  @override
  List<Object?> get props => [taskId];
}

/// Toggle task completion status
class ToggleTaskCompletionEvent extends TasksEvent {
  final String taskId;

  const ToggleTaskCompletionEvent(this.taskId);

  @override
  List<Object?> get props => [taskId];
}

/// Filter tasks by category
class FilterTasksByCategoryEvent extends TasksEvent {
  final TaskCategory? category;

  const FilterTasksByCategoryEvent(this.category);

  @override
  List<Object?> get props => [category];
}

/// Filter tasks by priority
class FilterTasksByPriorityEvent extends TasksEvent {
  final TaskPriority? priority;

  const FilterTasksByPriorityEvent(this.priority);

  @override
  List<Object?> get props => [priority];
}

/// Search tasks by query
class SearchTasksEvent extends TasksEvent {
  final String query;

  const SearchTasksEvent(this.query);

  @override
  List<Object?> get props => [query];
}

/// Clear all filters
class ClearFiltersEvent extends TasksEvent {
  const ClearFiltersEvent();
}

/// Refresh tasks from storage/sync
class RefreshTasksEvent extends TasksEvent {
  const RefreshTasksEvent();
}

/// Sort tasks
class SortTasksEvent extends TasksEvent {
  final TaskSortOption sortOption;

  const SortTasksEvent(this.sortOption);

  @override
  List<Object?> get props => [sortOption];
}