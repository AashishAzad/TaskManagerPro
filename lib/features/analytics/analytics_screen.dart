import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/di/service_locator.dart';
import '../../core/services/analytics_service.dart';
import '../../core/services/storage_service.dart';
import 'package:fl_chart/fl_chart.dart';

/// Analytics screen displaying task statistics and insights
class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final _analyticsService = sl<AnalyticsService>();
  bool _isLoading = true;
  Map<String, dynamic> _metrics = {};
  Map<String, dynamic> _insights = {};

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);

    if (!_analyticsService.isInitialized) {
      await _analyticsService.initialize();
    }

    final result = await _analyticsService.processAnalytics();

    result.fold(
          (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: AppColors.error),
        );
      },
          (metrics) {
        setState(() {
          _metrics = metrics;
          _insights = _analyticsService.getInsights();
          _isLoading = false;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalytics,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      )
          : RefreshIndicator(
        onRefresh: _loadAnalytics,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildOverviewCards(),
              const SizedBox(height: 24),
              _buildCompletionChart(),
              const SizedBox(height: 24),
              _buildCategoryDistribution(),
              const SizedBox(height: 24),
              _buildPriorityBreakdown(),
              const SizedBox(height: 24),
              _buildInsightsSection(),
              const SizedBox(height: 24),
              _buildRecommendations(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewCards() {
    final totalTasks = _metrics['total_tasks'] ?? 0;
    final completedTasks = _metrics['completed_tasks'] ?? 0;
    final pendingTasks = _metrics['pending_tasks'] ?? 0;
    final overdueTasks = _metrics['overdue_tasks'] ?? 0;
    final completionRate = _metrics['completion_rate'] ?? 0.0;
    final productivityScore = _metrics['productivity_score'] ?? 0.0;
    final taskVelocity = _metrics['task_velocity'] ?? 0.0;
    final completionStreak = _metrics['completion_streak'] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Overview',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimaryDark,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Tasks',
                totalTasks.toString(),
                Icons.task_alt,
                AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Completed',
                completedTasks.toString(),
                Icons.check_circle,
                AppColors.success,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Pending',
                pendingTasks.toString(),
                Icons.pending,
                AppColors.warning,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Overdue',
                overdueTasks.toString(),
                Icons.warning_amber,
                AppColors.error,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Completion Rate',
                '${completionRate.toStringAsFixed(0)}%',
                Icons.trending_up,
                AppColors.info,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Daily Velocity',
                taskVelocity.toStringAsFixed(1),
                Icons.speed,
                AppColors.accent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (completionStreak > 0)
          _buildStreakCard(completionStreak),
        const SizedBox(height: 12),
        _buildProductivityCard(productivityScore),
      ],
    );
  }

  Widget _buildStatCard(
      String title,
      String value,
      IconData icon,
      Color color,
      ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondaryDark,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductivityCard(double score) {
    final performanceLevel = _insights['performance_level'] ?? 'Average';
    Color scoreColor;

    if (score >= 80) {
      scoreColor = AppColors.success;
    } else if (score >= 60) {
      scoreColor = AppColors.info;
    } else if (score >= 40) {
      scoreColor = AppColors.warning;
    } else {
      scoreColor = AppColors.error;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.emoji_events, color: AppColors.accent, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Productivity Score',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondaryDark,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: scoreColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    performanceLevel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: scoreColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  score.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: scoreColor,
                  ),
                ),
                const Text(
                  ' / 100',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondaryDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: score / 100,
                backgroundColor: AppColors.surfaceDark,
                valueColor: AlwaysStoppedAnimation(scoreColor),
                minHeight: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakCard(int streak) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.local_fire_department,
                color: AppColors.accent,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Completion Streak',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondaryDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$streak ${streak == 1 ? 'day' : 'days'}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.accent,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.textSecondaryDark,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletionChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Task Distribution',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimaryDark,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: _buildPieChart(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChart() {
    final completedTasks = (_metrics['completed_tasks'] ?? 0) as int;
    final pendingTasks = (_metrics['pending_tasks'] ?? 0) as int;

    if (completedTasks == 0 && pendingTasks == 0) {
      return const Center(
        child: Text(
          'No data available',
          style: TextStyle(color: AppColors.textSecondaryDark),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              sections: [
                PieChartSectionData(
                  value: completedTasks.toDouble(),
                  title: '$completedTasks',
                  color: AppColors.success,
                  radius: 60,
                  titleStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                PieChartSectionData(
                  value: pendingTasks.toDouble(),
                  title: '$pendingTasks',
                  color: AppColors.warning,
                  radius: 60,
                  titleStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
              sectionsSpace: 2,
              centerSpaceRadius: 40,
            ),
          ),
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLegendItem('Completed', AppColors.success),
            const SizedBox(height: 8),
            _buildLegendItem('Pending', AppColors.warning),
          ],
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textPrimaryDark,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryDistribution() {
    final distribution = _metrics['category_distribution'] as Map<String, dynamic>?;

    if (distribution == null || distribution.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tasks by Category',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimaryDark,
              ),
            ),
            const SizedBox(height: 16),
            ...distribution.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildDistributionBar(
                  entry.key,
                  entry.value,
                  (_metrics['total_tasks'] ?? 1) as int,
                  AppColors.primary,
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityBreakdown() {
    final breakdown = _metrics['priority_breakdown'] as Map<String, dynamic>?;

    if (breakdown == null || breakdown.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tasks by Priority',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimaryDark,
              ),
            ),
            const SizedBox(height: 16),
            _buildDistributionBar(
              'High',
              breakdown['high'] ?? 0,
              (_metrics['total_tasks'] ?? 1) as int,
              AppColors.priorityHigh,
            ),
            const SizedBox(height: 12),
            _buildDistributionBar(
              'Medium',
              breakdown['medium'] ?? 0,
              (_metrics['total_tasks'] ?? 1) as int,
              AppColors.priorityMedium,
            ),
            const SizedBox(height: 12),
            _buildDistributionBar(
              'Low',
              breakdown['low'] ?? 0,
              (_metrics['total_tasks'] ?? 1) as int,
              AppColors.priorityLow,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDistributionBar(String label, int count, int total, Color color) {
    final percentage = total > 0 ? (count / total) * 100 : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimaryDark,
              ),
            ),
            Text(
              '$count (${percentage.toStringAsFixed(0)}%)',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondaryDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: AppColors.surfaceDark,
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildInsightsSection() {
    final achievements = _insights['achievements'] as List<dynamic>? ?? [];

    if (achievements.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.emoji_events, color: AppColors.accent),
                SizedBox(width: 8),
                Text(
                  'Achievements',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimaryDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: achievements.map((achievement) {
                return Chip(
                  avatar: const Icon(Icons.star, size: 16, color: AppColors.accent),
                  label: Text(achievement.toString()),
                  backgroundColor: AppColors.accent.withOpacity(0.1),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendations() {
    final recommendations = _insights['recommendations'] as List<dynamic>? ?? [];

    if (recommendations.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.lightbulb, color: AppColors.warning),
                SizedBox(width: 8),
                Text(
                  'Recommendations',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimaryDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...recommendations.map((rec) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.arrow_right,
                      size: 20,
                      color: AppColors.textSecondaryDark,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        rec.toString(),
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textPrimaryDark,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}