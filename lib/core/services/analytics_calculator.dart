import '../../shared/models/task_model.dart';

/// Helper class for calculating task analytics
class AnalyticsCalculator {
  /// Calculate completion rate
  static double calculateCompletionRate(List<TaskModel> tasks) {
    if (tasks.isEmpty) return 0.0;
    final completed = tasks.where((t) => t.completed).length;
    return (completed / tasks.length) * 100;
  }

  /// Calculate average completion time in hours
  static double calculateAverageCompletionTime(List<TaskModel> tasks) {
    final completedTasks = tasks.where((t) => t.completed && t.completedAt != null).toList();
    if (completedTasks.isEmpty) return 0.0;

    int totalHours = 0;
    for (final task in completedTasks) {
      final duration = task.completedAt!.difference(task.createdAt);
      totalHours += duration.inHours;
    }

    return totalHours / completedTasks.length;
  }

  /// Calculate productivity score (0-100)
  static double calculateProductivityScore(List<TaskModel> tasks) {
    if (tasks.isEmpty) return 0.0;

    final completionRate = calculateCompletionRate(tasks);
    final totalTasks = tasks.length;

    // Count high priority completed tasks
    final highPriorityCompleted = tasks
        .where((t) =>
    (t.priority == TaskPriority.high || t.priority == TaskPriority.urgent) &&
        t.completed)
        .length;

    // Count overdue tasks (penalty)
    final overdueTasks = tasks.where((t) => t.isOverdue && !t.completed).length;

    // Base score from completion rate
    double score = completionRate;

    // Volume bonus (up to 20 points)
    final volumeBonus = (totalTasks / 10).clamp(0, 20);
    score += volumeBonus;

    // Priority bonus (5 points per high priority completed)
    final priorityBonus = (highPriorityCompleted * 5).toDouble().clamp(0, 30);
    score += priorityBonus;

    // Overdue penalty (-10 points per overdue task)
    final overduePenalty = (overdueTasks * 10).toDouble();
    score -= overduePenalty;

    return score.clamp(0, 100);
  }

  /// Get category distribution
  static Map<String, int> getCategoryDistribution(List<TaskModel> tasks) {
    final distribution = <String, int>{};

    for (final task in tasks) {
      final category = task.category.displayName;
      distribution[category] = (distribution[category] ?? 0) + 1;
    }

    return distribution;
  }

  /// Get priority breakdown
  static Map<String, int> getPriorityBreakdown(List<TaskModel> tasks) {
    final breakdown = <String, int>{
      'urgent': 0,
      'high': 0,
      'medium': 0,
      'low': 0,
    };

    for (final task in tasks) {
      breakdown[task.priority.value] = (breakdown[task.priority.value] ?? 0) + 1;
    }

    return breakdown;
  }

  /// Generate daily activity for last 7 days
  static Map<String, int> generateDailyActivity(List<TaskModel> tasks) {
    final activity = <String, int>{};
    final now = DateTime.now();

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateKey = '${date.month}/${date.day}';

      final count = tasks.where((t) {
        return t.createdAt.year == date.year &&
            t.createdAt.month == date.month &&
            t.createdAt.day == date.day;
      }).length;

      activity[dateKey] = count;
    }

    return activity;
  }

  /// Generate weekly completion trends
  static List<Map<String, dynamic>> generateWeeklyTrends(List<TaskModel> tasks) {
    final trends = <Map<String, dynamic>>[];
    final now = DateTime.now();

    for (int i = 3; i >= 0; i--) {
      final weekStart = now.subtract(Duration(days: 7 * (i + 1)));
      final weekEnd = now.subtract(Duration(days: 7 * i));

      final weekTasks = tasks.where((t) {
        return t.createdAt.isAfter(weekStart) && t.createdAt.isBefore(weekEnd);
      }).toList();

      final completed = weekTasks.where((t) => t.completed).length;

      trends.add({
        'week': 'Week ${i + 1}',
        'tasks_created': weekTasks.length,
        'tasks_completed': completed,
        'completion_rate': calculateCompletionRate(weekTasks),
      });
    }

    return trends.reversed.toList();
  }

  /// Get performance level based on score
  static String getPerformanceLevel(double score) {
    if (score >= 80) return 'Excellent';
    if (score >= 60) return 'Good';
    if (score >= 40) return 'Average';
    return 'Needs Improvement';
  }

  /// Get completion trend
  static String getCompletionTrend(double rate) {
    if (rate >= 75) return 'Strong';
    if (rate >= 50) return 'Moderate';
    return 'Weak';
  }

  /// Generate recommendations
  static List<String> generateRecommendations(Map<String, dynamic> metrics) {
    final recommendations = <String>[];
    final completionRate = metrics['completion_rate'] as double? ?? 0.0;
    final pendingTasks = metrics['pending_tasks'] as int? ?? 0;
    final overdueTasks = metrics['overdue_tasks'] as int? ?? 0;
    final productivityScore = metrics['productivity_score'] as double? ?? 0.0;

    if (completionRate < 50) {
      recommendations.add('Focus on completing existing tasks before adding new ones');
    }

    if (pendingTasks > 20) {
      recommendations.add('Consider breaking down large tasks into smaller, manageable ones');
    }

    if (overdueTasks > 5) {
      recommendations.add('Review and update due dates for overdue tasks');
    }

    if (completionRate > 80 && productivityScore > 70) {
      recommendations.add('Great job! Keep up the excellent momentum 🎉');
    }

    if (productivityScore < 40) {
      recommendations.add('Try prioritizing high-impact tasks first');
    }

    if (recommendations.isEmpty) {
      recommendations.add('You\'re doing well! Keep maintaining your productivity');
    }

    return recommendations;
  }

  /// Check achievements
  static List<String> checkAchievements(Map<String, dynamic> metrics) {
    final achievements = <String>[];
    final totalTasks = metrics['total_tasks'] as int? ?? 0;
    final completedTasks = metrics['completed_tasks'] as int? ?? 0;
    final completionRate = metrics['completion_rate'] as double? ?? 0.0;
    final productivityScore = metrics['productivity_score'] as double? ?? 0.0;

    if (totalTasks >= 10) achievements.add('🎯 Task Master');
    if (totalTasks >= 50) achievements.add('⭐ Productivity Pro');
    if (totalTasks >= 100) achievements.add('🏆 Task Champion');

    if (completedTasks >= 25) achievements.add('✅ Quarter Century');
    if (completedTasks >= 50) achievements.add('🎖️ Half Century');
    if (completedTasks >= 100) achievements.add('💯 Centurion');

    if (completionRate >= 90) achievements.add('🎓 Perfectionist');
    if (completionRate >= 75) achievements.add('🌟 High Achiever');

    if (productivityScore >= 80) achievements.add('🚀 Peak Performer');

    return achievements;
  }

  /// Calculate task velocity (tasks per day)
  static double calculateTaskVelocity(List<TaskModel> tasks) {
    if (tasks.isEmpty) return 0.0;

    final oldestTask = tasks.reduce((a, b) =>
    a.createdAt.isBefore(b.createdAt) ? a : b);
    final daysSinceOldest = DateTime.now().difference(oldestTask.createdAt).inDays;

    if (daysSinceOldest == 0) return tasks.length.toDouble();

    return tasks.length / daysSinceOldest;
  }

  /// Get task completion streak (consecutive days with completed tasks)
  static int getCompletionStreak(List<TaskModel> tasks) {
    final completedTasks = tasks
        .where((t) => t.completed && t.completedAt != null)
        .toList()
      ..sort((a, b) => b.completedAt!.compareTo(a.completedAt!));

    if (completedTasks.isEmpty) return 0;

    int streak = 0;
    DateTime currentDate = DateTime.now();

    for (int i = 0; i < 30; i++) {
      final hasTaskOnDate = completedTasks.any((t) {
        final completedDate = t.completedAt!;
        return completedDate.year == currentDate.year &&
            completedDate.month == currentDate.month &&
            completedDate.day == currentDate.day;
      });

      if (hasTaskOnDate) {
        streak++;
        currentDate = currentDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    return streak;
  }
}