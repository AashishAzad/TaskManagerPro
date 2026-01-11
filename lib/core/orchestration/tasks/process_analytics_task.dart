import 'package:dartz/dartz.dart';
import 'package:logger/logger.dart';
import '../startup_task.dart';
import '../../di/service_locator.dart';
import '../../services/analytics_service.dart';

/// Low priority task: Process and compute analytics
/// This is a heavy computational task but not critical for startup
class ProcessAnalyticsTask extends StartupTask {
  final Logger _logger = Logger();

  ProcessAnalyticsTask()
      : super(
    id: 'process_analytics',
    name: 'Process Analytics',
    priority: TaskPriority.low,
    dependencies: ['sync_data'],
    timeout: const Duration(seconds: 40),
  );

  @override
  Future<Either<String, bool>> execute() async {
    try {
      _logger.i('📊 Processing analytics data...');

      final analyticsService = sl<AnalyticsService>();

      // Initialize analytics service
      await analyticsService.initialize();

      // Process analytics (heavy computation)
      _logger.i('Computing metrics and insights...');
      final result = await analyticsService.processAnalytics();

      return result.fold(
            (error) {
          _logger.e('Analytics processing failed: $error');
          return Left(error);
        },
            (metrics) {
          _logger.i('✅ Analytics processed successfully');
          _logger.i('Total tasks: ${metrics['total_tasks']}');
          _logger.i('Completion rate: ${metrics['completion_rate']?.toStringAsFixed(1)}%');
          _logger.i('Productivity score: ${metrics['productivity_score']?.toStringAsFixed(1)}');
          return const Right(true);
        },
      );
    } catch (e, stackTrace) {
      _logger.e('Analytics processing error', error: e, stackTrace: stackTrace);
      return Left('Analytics processing failed: ${e.toString()}');
    }
  }

  @override
  Future<void> onComplete() async {
    final analyticsService = sl<AnalyticsService>();
    final insights = analyticsService.getInsights();

    if (insights.isNotEmpty) {
      _logger.i('Performance level: ${insights['performance_level']}');
      final achievements = insights['achievements'] as List?;
      if (achievements != null && achievements.isNotEmpty) {
        _logger.i('Achievements: ${achievements.join(', ')}');
      }
    }
  }

  @override
  Future<void> onError(String error) async {
    _logger.w('Analytics will be processed later in background');
  }
}