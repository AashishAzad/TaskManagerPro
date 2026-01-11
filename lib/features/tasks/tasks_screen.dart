import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_colors.dart';
import '../../core/di/service_locator.dart';
import '../../core/repositories/task_repository.dart';
import '../../shared/models/task_model.dart';
import 'bloc/tasks_bloc.dart';
import 'bloc/tasks_event.dart';
import 'bloc/tasks_state.dart';
import 'widgets/task_item.dart';
import 'widgets/add_task_dialog.dart';
import 'widgets/quick_filters.dart';
import 'widgets/bulk_actions_bar.dart';
import 'widgets/sort_options_sheet.dart';

/// Tasks screen displaying all tasks with filters
class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => TasksBloc(taskRepository: sl<TaskRepository>())
        ..add(const LoadTasksEvent()),
      child: const TasksView(),
    );
  }
}

class TasksView extends StatelessWidget {
  const TasksView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearchDialog(context),
          ),
          BlocBuilder<TasksBloc, TasksState>(
            builder: (context, state) {
              return IconButton(
                icon: Icon(
                  Icons.sort,
                  color: state is TasksLoaded && state.sortOption != null
                      ? AppColors.primary
                      : null,
                ),
                onPressed: () => _showSortSheet(context),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterSheet(context),
          ),
        ],
      ),
      body: BlocBuilder<TasksBloc, TasksState>(
        builder: (context, state) {
          if (state is TasksLoading) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
              ),
            );
          }

          if (state is TasksError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppColors.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    state.message,
                    style: const TextStyle(color: AppColors.textSecondaryDark),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<TasksBloc>().add(const LoadTasksEvent());
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is TasksLoaded) {
            if (state.filteredTasks.isEmpty) {
              return _buildEmptyState(context, state.hasActiveFilters);
            }

            return Column(
              children: [
                _buildStatsBar(state),
                const QuickFilters(),
                if (state.hasActiveFilters) _buildActiveFiltersChips(context, state),
                BulkActionsBar(
                  completedCount: state.completedCount,
                  onRefresh: () {
                    context.read<TasksBloc>().add(const RefreshTasksEvent());
                  },
                ),
                Expanded(
                  child: _buildTasksList(context, state),
                ),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTaskDialog(context),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add),
        label: const Text('New Task'),
      ),
    );
  }

  Widget _buildStatsBar(TasksLoaded state) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.surfaceDark,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            'Total',
            state.totalTasks.toString(),
            AppColors.primary,
          ),
          _buildStatItem(
            'Pending',
            state.pendingCount.toString(),
            AppColors.warning,
          ),
          _buildStatItem(
            'Completed',
            state.completedCount.toString(),
            AppColors.success,
          ),
          _buildStatItem(
            'Rate',
            '${state.completionRate.toStringAsFixed(0)}%',
            AppColors.info,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondaryDark,
          ),
        ),
      ],
    );
  }

  Widget _buildActiveFiltersChips(BuildContext context, TasksLoaded state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 8,
        children: [
          if (state.categoryFilter != null)
            Chip(
              label: Text(state.categoryFilter!.displayName),
              deleteIcon: const Icon(Icons.close, size: 16),
              onDeleted: () {
                context.read<TasksBloc>().add(
                  const FilterTasksByCategoryEvent(null),
                );
              },
              backgroundColor: AppColors.primary.withOpacity(0.2),
            ),
          if (state.priorityFilter != null)
            Chip(
              label: Text(state.priorityFilter!.value.toUpperCase()),
              deleteIcon: const Icon(Icons.close, size: 16),
              onDeleted: () {
                context.read<TasksBloc>().add(
                  const FilterTasksByPriorityEvent(null),
                );
              },
              backgroundColor: AppColors.secondary.withOpacity(0.2),
            ),
          if (state.searchQuery != null && state.searchQuery!.isNotEmpty)
            Chip(
              label: Text('"${state.searchQuery}"'),
              deleteIcon: const Icon(Icons.close, size: 16),
              onDeleted: () {
                context.read<TasksBloc>().add(const SearchTasksEvent(''));
              },
              backgroundColor: AppColors.accent.withOpacity(0.2),
            ),
          if (state.hasActiveFilters)
            ActionChip(
              label: const Text('Clear All'),
              onPressed: () {
                context.read<TasksBloc>().add(const ClearFiltersEvent());
              },
            ),
        ],
      ),
    );
  }

  Widget _buildTasksList(BuildContext context, TasksLoaded state) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<TasksBloc>().add(const RefreshTasksEvent());
        await Future.delayed(const Duration(seconds: 1));
      },
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: state.filteredTasks.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final task = state.filteredTasks[index];
          return TaskItem(task: task);
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool hasFilters) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            hasFilters ? Icons.search_off : Icons.task_alt,
            size: 64,
            color: AppColors.textSecondaryDark,
          ),
          const SizedBox(height: 16),
          Text(
            hasFilters ? 'No tasks match filters' : 'No tasks yet',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimaryDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasFilters
                ? 'Try adjusting your filters'
                : 'Create your first task to get started',
            style: const TextStyle(
              color: AppColors.textSecondaryDark,
            ),
          ),
          if (hasFilters) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                context.read<TasksBloc>().add(const ClearFiltersEvent());
              },
              child: const Text('Clear Filters'),
            ),
          ],
        ],
      ),
    );
  }

  void _showAddTaskDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: context.read<TasksBloc>(),
        child: const AddTaskDialog(),
      ),
    );
  }

  void _showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        String query = '';
        return AlertDialog(
          title: const Text('Search Tasks'),
          content: TextField(
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Enter search query...',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (value) => query = value,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                context.read<TasksBloc>().add(SearchTasksEvent(query));
                Navigator.pop(dialogContext);
              },
              child: const Text('Search'),
            ),
          ],
        );
      },
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => BlocProvider.value(
        value: context.read<TasksBloc>(),
        child: const FilterBottomSheet(),
      ),
    );
  }

  void _showSortSheet(BuildContext context) {
    final currentState = context.read<TasksBloc>().state;
    final currentSort = currentState is TasksLoaded ? currentState.sortOption : null;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => SortOptionsSheet(
        currentSort: currentSort,
        onSortSelected: (sortOption) {
          context.read<TasksBloc>().add(SortTasksEvent(sortOption));
        },
      ),
    );
  }
}

class FilterBottomSheet extends StatelessWidget {
  const FilterBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filter Tasks',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimaryDark,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Category',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimaryDark,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: TaskCategory.values.map((category) {
              return FilterChip(
                label: Text(category.displayName),
                onSelected: (selected) {
                  context.read<TasksBloc>().add(
                    FilterTasksByCategoryEvent(selected ? category : null),
                  );
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          const Text(
            'Priority',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimaryDark,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: TaskPriority.values.map((priority) {
              return FilterChip(
                label: Text(priority.value.toUpperCase()),
                onSelected: (selected) {
                  context.read<TasksBloc>().add(
                    FilterTasksByPriorityEvent(selected ? priority : null),
                  );
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}