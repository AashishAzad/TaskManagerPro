import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/models/task_model.dart';
import '../bloc/tasks_bloc.dart';
import '../bloc/tasks_event.dart';
import 'task_actions_sheet.dart';

/// Widget to display a single task item
class TaskItem extends StatelessWidget {
  final TaskModel task;

  const TaskItem({
    super.key,
    required this.task,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: task.isOverdue
              ? AppColors.error.withOpacity(0.3)
              : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () => _showTaskDetails(context),
        onLongPress: () => _showActionsSheet(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  // Checkbox
                  InkWell(
                    onTap: () {
                      context.read<TasksBloc>().add(
                        ToggleTaskCompletionEvent(task.id),
                      );
                    },
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: task.completed
                            ? AppColors.success
                            : Colors.transparent,
                        border: Border.all(
                          color: task.completed
                              ? AppColors.success
                              : AppColors.textSecondaryDark,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: task.completed
                          ? const Icon(
                        Icons.check,
                        size: 16,
                        color: Colors.white,
                      )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Title
                  Expanded(
                    child: Text(
                      task.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimaryDark,
                        decoration: task.completed
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Priority badge
                  _buildPriorityBadge(),
                ],
              ),

              // Description
              if (task.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  task.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondaryDark,
                    decoration: task.completed
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              const SizedBox(height: 12),

              // Footer row
              Row(
                children: [
                  // Category
                  _buildCategoryChip(),

                  const SizedBox(width: 8),

                  // Due date
                  if (task.dueDate != null) ...[
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: task.isOverdue
                          ? AppColors.error
                          : AppColors.textSecondaryDark,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('MMM dd').format(task.dueDate!),
                      style: TextStyle(
                        fontSize: 12,
                        color: task.isOverdue
                            ? AppColors.error
                            : AppColors.textSecondaryDark,
                        fontWeight: task.isDueToday
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ],

                  const Spacer(),

                  // Actions - More options button
                  IconButton(
                    icon: const Icon(Icons.more_vert, size: 20),
                    color: AppColors.textSecondaryDark,
                    onPressed: () => _showActionsSheet(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),

              // Overdue warning
              if (task.isOverdue && !task.completed) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.warning_amber,
                        size: 14,
                        color: AppColors.error,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Overdue',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityBadge() {
    Color color;
    switch (task.priority) {
      case TaskPriority.urgent:
        color = AppColors.priorityUrgent;
        break;
      case TaskPriority.high:
        color = AppColors.priorityHigh;
        break;
      case TaskPriority.medium:
        color = AppColors.priorityMedium;
        break;
      case TaskPriority.low:
        color = AppColors.priorityLow;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        task.priority.value.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildCategoryChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        task.category.displayName,
        style: const TextStyle(
          fontSize: 12,
          color: AppColors.primary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  void _showTaskDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(task.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (task.description.isNotEmpty) ...[
                const Text(
                  'Description',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(task.description),
                const SizedBox(height: 16),
              ],
              _buildDetailRow('Category', task.category.displayName),
              _buildDetailRow('Priority', task.priority.value.toUpperCase()),
              _buildDetailRow(
                'Status',
                task.completed ? 'Completed' : 'Pending',
              ),
              if (task.dueDate != null)
                _buildDetailRow(
                  'Due Date',
                  DateFormat('MMM dd, yyyy').format(task.dueDate!),
                ),
              _buildDetailRow(
                'Created',
                DateFormat('MMM dd, yyyy').format(task.createdAt),
              ),
              if (task.completedAt != null)
                _buildDetailRow(
                  'Completed',
                  DateFormat('MMM dd, yyyy').format(task.completedAt!),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: AppColors.textSecondaryDark,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimaryDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showActionsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => BlocProvider.value(
        value: context.read<TasksBloc>(),
        child: TaskActionsSheet(task: task),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Task'),
        content: Text('Are you sure you want to delete "${task.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Close dialog first
              Navigator.pop(dialogContext);

              // Then delete task
              context.read<TasksBloc>().add(DeleteTaskEvent(task.id));

              // Show confirmation
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Task deleted'),
                  backgroundColor: AppColors.error,
                  duration: Duration(seconds: 2),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}