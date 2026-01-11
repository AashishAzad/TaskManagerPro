import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/models/task_model.dart';
import '../bloc/tasks_bloc.dart';
import '../bloc/tasks_event.dart';
import '../bloc/tasks_state.dart';

/// Quick filter chips for tasks
class QuickFilters extends StatelessWidget {
  const QuickFilters({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TasksBloc, TasksState>(
      builder: (context, state) {
        if (state is! TasksLoaded) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildQuickFilterChip(
                  context,
                  label: 'All',
                  icon: Icons.list,
                  isSelected: !state.hasActiveFilters,
                  onTap: () {
                    context.read<TasksBloc>().add(const ClearFiltersEvent());
                  },
                ),
                const SizedBox(width: 8),
                _buildQuickFilterChip(
                  context,
                  label: 'Work',
                  icon: Icons.work,
                  isSelected: state.categoryFilter == TaskCategory.work,
                  onTap: () {
                    context.read<TasksBloc>().add(
                      FilterTasksByCategoryEvent(
                        state.categoryFilter == TaskCategory.work
                            ? null
                            : TaskCategory.work,
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                _buildQuickFilterChip(
                  context,
                  label: 'Personal',
                  icon: Icons.person,
                  isSelected: state.categoryFilter == TaskCategory.personal,
                  onTap: () {
                    context.read<TasksBloc>().add(
                      FilterTasksByCategoryEvent(
                        state.categoryFilter == TaskCategory.personal
                            ? null
                            : TaskCategory.personal,
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                _buildQuickFilterChip(
                  context,
                  label: 'High Priority',
                  icon: Icons.priority_high,
                  color: AppColors.priorityHigh,
                  isSelected: state.priorityFilter == TaskPriority.high,
                  onTap: () {
                    context.read<TasksBloc>().add(
                      FilterTasksByPriorityEvent(
                        state.priorityFilter == TaskPriority.high
                            ? null
                            : TaskPriority.high,
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                _buildQuickFilterChip(
                  context,
                  label: 'Urgent',
                  icon: Icons.warning,
                  color: AppColors.priorityUrgent,
                  isSelected: state.priorityFilter == TaskPriority.urgent,
                  onTap: () {
                    context.read<TasksBloc>().add(
                      FilterTasksByPriorityEvent(
                        state.priorityFilter == TaskPriority.urgent
                            ? null
                            : TaskPriority.urgent,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickFilterChip(
      BuildContext context, {
        required String label,
        required IconData icon,
        required bool isSelected,
        required VoidCallback onTap,
        Color? color,
      }) {
    final chipColor = color ?? AppColors.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? chipColor.withOpacity(0.2)
              : AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? chipColor : AppColors.borderDark,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? chipColor : AppColors.textSecondaryDark,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? chipColor : AppColors.textPrimaryDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}