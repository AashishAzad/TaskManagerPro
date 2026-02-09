import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/models/task_model.dart';
import '../bloc/tasks_bloc.dart';
import '../bloc/tasks_event.dart';
import 'edit_task_dialog.dart';

/// Bottom sheet showing task actions
class TaskActionsSheet extends StatelessWidget {
  final TaskModel task;

  const TaskActionsSheet({
    super.key,
    required this.task,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: const BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textSecondaryDark,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Task title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              task.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimaryDark,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          const SizedBox(height: 20),
          const Divider(height: 1, color: AppColors.borderDark),

          // Actions
          _buildActionTile(
            context,
            icon: task.completed ? Icons.cancel : Icons.check_circle,
            title: task.completed ? 'Mark as Incomplete' : 'Mark as Complete',
            color: task.completed ? AppColors.warning : AppColors.success,
            onTap: () {
              context.read<TasksBloc>().add(ToggleTaskCompletionEvent(task.id));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    task.completed
                        ? 'Task marked as incomplete'
                        : 'Task completed! 🎉',
                  ),
                  backgroundColor: task.completed ? AppColors.warning : AppColors.success,
                ),
              );
            },
          ),

          _buildActionTile(
            context,
            icon: Icons.edit,
            title: 'Edit Task',
            color: AppColors.primary,
            onTap: () {
              Navigator.pop(context);
              showDialog(
                context: context,
                builder: (dialogContext) => BlocProvider.value(
                  value: context.read<TasksBloc>(),
                  child: EditTaskDialog(task: task),
                ),
              );
            },
          ),

          _buildActionTile(
            context,
            icon: Icons.copy,
            title: 'Duplicate Task',
            color: AppColors.info,
            onTap: () {
              final duplicatedTask = task.copyWith(
                id: const Uuid().v4(),
                title: '${task.title} (Copy)',
                completed: false,
                completedAt: null,
                createdAt: DateTime.now(),
              );

              context.read<TasksBloc>().add(AddTaskEvent(duplicatedTask));
              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Task duplicated'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
          ),
          const Divider(height: 1, color: AppColors.borderDark),
          _buildActionTile(
            context,
            icon: Icons.delete,
            title: 'Delete Task',
            color: AppColors.error,
            onTap: () {
              _showDeleteConfirmation(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(
      BuildContext context, {
        required IconData icon,
        required String title,
        required Color color,
        required VoidCallback onTap,
      }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    // Save all references before showing dialog
    final tasksBloc = context.read<TasksBloc>();
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

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
              // Close dialog
              Navigator.pop(dialogContext);

              // Close bottom sheet using saved navigator
              navigator.pop();

              // Delete task using saved BLoC reference
              tasksBloc.add(DeleteTaskEvent(task.id));

              // Show confirmation using saved messenger
              scaffoldMessenger.showSnackBar(
                const SnackBar(
                  content: Text('Task deleted'),
                  backgroundColor: AppColors.error,
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