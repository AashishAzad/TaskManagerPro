import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/repositories/task_repository.dart';

/// Widget showing user statistics
class StatisticsCard extends StatefulWidget {
  const StatisticsCard({super.key});

  @override
  State<StatisticsCard> createState() => _StatisticsCardState();
}

class _StatisticsCardState extends State<StatisticsCard> {
  final _taskRepository = sl<TaskRepository>();
  int _totalTasks = 0;
  int _completedTasks = 0;
  int _pendingTasks = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    final result = await _taskRepository.getStatistics();

    result.fold(
          (error) {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      },
          (stats) {
        if (mounted) {
          setState(() {
            _totalTasks = stats.total;
            _completedTasks = stats.completed;
            _pendingTasks = stats.pending;
            _isLoading = false;
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Center(
            child: CircularProgressIndicator(
              color: AppColors.primary,
            ),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.bar_chart, color: AppColors.primary),
                SizedBox(width: 12),
                Text(
                  'Your Statistics',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimaryDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  'Total',
                  _totalTasks.toString(),
                  AppColors.primary,
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: AppColors.borderDark,
                ),
                _buildStatItem(
                  'Done',
                  _completedTasks.toString(),
                  AppColors.success,
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: AppColors.borderDark,
                ),
                _buildStatItem(
                  'Pending',
                  _pendingTasks.toString(),
                  AppColors.warning,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 28,
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
}