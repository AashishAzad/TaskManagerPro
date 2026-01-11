import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/repositories/task_repository.dart';

/// Widget for bulk task actions
class BulkActionsBar extends StatelessWidget {
  final int completedCount;
  final VoidCallback onRefresh;

  const BulkActionsBar({
    super.key,
    required this.completedCount,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (completedCount == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.borderDark,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline,
            color: AppColors.info,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$completedCount completed ${completedCount == 1 ? 'task' : 'tasks'}',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimaryDark,
              ),
            ),
          ),
          TextButton.icon(
            onPressed: () => _showClearCompletedDialog(context),
            icon: const Icon(Icons.delete_sweep, size: 18),
            label: const Text('Clear'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
            ),
          ),
        ],
      ),
    );
  }

  void _showClearCompletedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Clear Completed Tasks'),
        content: Text(
          'Are you sure you want to delete all $completedCount completed ${completedCount == 1 ? 'task' : 'tasks'}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _clearCompletedTasks(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  Future<void> _clearCompletedTasks(BuildContext context) async {
    final repository = sl<TaskRepository>();

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    final result = await repository.deleteCompletedTasks();

    if (context.mounted) {
      Navigator.pop(context); // Close loading

      result.fold(
            (error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to clear tasks: $error'),
              backgroundColor: AppColors.error,
            ),
          );
        },
            (deletedCount) {
          onRefresh();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Cleared $deletedCount completed ${deletedCount == 1 ? 'task' : 'tasks'}'),
              backgroundColor: AppColors.success,
            ),
          );
        },
      );
    }
  }
}