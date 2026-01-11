import 'package:dartz/dartz.dart';
import 'storage_service.dart';
import 'analytics_calculator.dart';
import '../../shared/models/task_model.dart';

/// Service for tracking analytics and generating insights
/// Processes real task data to generate metrics
class AnalyticsService {
  final StorageService _storageService;

  Map<String, dynamic> _analyticsData = {};
  bool _isInitialized = false;

  AnalyticsService({required StorageService storageService})
      : _storageService = storageService;

  bool get isInitialized => _isInitialized;
  Map<String, dynamic> get analyticsData => Map.unmodifiable(_analyticsData);

  /// Initialize analytics from storage and compute initial metrics
  Future<Either<String, bool>> initialize() async {
    try {
      // Load existing analytics data
      final result = await _storageService.getAnalyticsData();

      result.fold(
            (error) => null,
            (data) {
          if (data != null) {
            _analyticsData = data;
          }
        },
      );

      // Initialize with default structure if empty
      if (_analyticsData.isEmpty) {
        _analyticsData = {
          'metrics': {},
          'events': [],
          'sessions': [],
          'last_update': DateTime.now().toIso8601String(),
          'version': '1.0',
        };
      }

      _isInitialized = true;
      return const Right(true);
    } catch (e) {
      return Left('Analytics initialization failed: ${e.toString()}');
    }
  }

  /// Process and compute analytics from real task data
  Future<Either<String, Map<String, dynamic>>> processAnalytics() async {
    try {
      // Load tasks for analysis
      final tasksResult = await _storageService.getTasks();
      final tasksJson = tasksResult.getOrElse(() => null) ?? [];

      final tasks = tasksJson
          .map((json) => TaskModel.fromJson(json))
          .toList();

      // Compute metrics using real data
      final totalTasks = tasks.length;
      final completedTasks = tasks.where((t) => t.completed).length;
      final pendingTasks = tasks.where((t) => !t.completed).length;
      final overdueTasks = tasks.where((t) => t.isOverdue && !t.completed).length;

      final completionRate = AnalyticsCalculator.calculateCompletionRate(tasks);
      final avgCompletionTime = AnalyticsCalculator.calculateAverageCompletionTime(tasks);
      final productivityScore = AnalyticsCalculator.calculateProductivityScore(tasks);
      final taskVelocity = AnalyticsCalculator.calculateTaskVelocity(tasks);
      final completionStreak = AnalyticsCalculator.getCompletionStreak(tasks);

      final metrics = {
        'total_tasks': totalTasks,
        'completed_tasks': completedTasks,
        'pending_tasks': pendingTasks,
        'overdue_tasks': overdueTasks,
        'completion_rate': completionRate,
        'average_completion_time': avgCompletionTime,
        'productivity_score': productivityScore,
        'task_velocity': taskVelocity,
        'completion_streak': completionStreak,
        'daily_activity': AnalyticsCalculator.generateDailyActivity(tasks),
        'category_distribution': AnalyticsCalculator.getCategoryDistribution(tasks),
        'priority_breakdown': AnalyticsCalculator.getPriorityBreakdown(tasks),
        'weekly_trends': AnalyticsCalculator.generateWeeklyTrends(tasks),
        'last_processed': DateTime.now().toIso8601String(),
      };

      // Update analytics data
      _analyticsData['metrics'] = metrics;
      _analyticsData['last_update'] = DateTime.now().toIso8601String();
      _analyticsData['version'] = '1.0';

      // Save to storage
      await _storageService.saveAnalyticsData(_analyticsData);

      return Right(metrics);
    } catch (e) {
      return Left('Analytics processing failed: ${e.toString()}');
    }
  }

  /// Track an event
  Future<Either<String, bool>> trackEvent(
      String eventName,
      Map<String, dynamic>? properties,
      ) async {
    try {
      final events = _analyticsData['events'] as List<dynamic>? ?? [];

      events.add({
        'name': eventName,
        'properties': properties ?? {},
        'timestamp': DateTime.now().toIso8601String(),
      });

      // Keep only last 100 events
      if (events.length > 100) {
        events.removeRange(0, events.length - 100);
      }

      _analyticsData['events'] = events;
      await _storageService.saveAnalyticsData(_analyticsData);

      return const Right(true);
    } catch (e) {
      return Left('Event tracking failed: ${e.toString()}');
    }
  }

  /// Get insights based on analytics data
  Map<String, dynamic> getInsights() {
    final metrics = _analyticsData['metrics'] as Map<String, dynamic>?;
    if (metrics == null) return {};

    final productivityScore = metrics['productivity_score'] as double? ?? 0.0;
    final completionRate = metrics['completion_rate'] as double? ?? 0.0;

    return {
      'performance_level': AnalyticsCalculator.getPerformanceLevel(productivityScore),
      'completion_trend': AnalyticsCalculator.getCompletionTrend(completionRate),
      'recommendations': AnalyticsCalculator.generateRecommendations(metrics),
      'achievements': AnalyticsCalculator.checkAchievements(metrics),
    };
  }
}