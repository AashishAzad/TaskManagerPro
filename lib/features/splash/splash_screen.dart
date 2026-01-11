import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../core/orchestration/startup_orchestrator.dart';
import '../../core/constants/app_colors.dart';

/// Splash screen that displays startup orchestration progress
class SplashScreen extends StatefulWidget {
  final StartupOrchestrator orchestrator;

  const SplashScreen({
    super.key,
    required this.orchestrator,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  final List<TaskProgressDisplay> _taskProgress = [];
  String _currentTask = 'Initializing...';
  double _overallProgress = 0.0;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _listenToProgress();
  }

  void _listenToProgress() {
    widget.orchestrator.progressStream.listen((event) {
      if (!mounted) return;

      setState(() {
        switch (event.type) {
          case TaskProgressType.orchestrationStarted:
            _currentTask = 'Starting initialization...';
            break;

          case TaskProgressType.taskStarted:
            _currentTask = 'Running: ${event.taskName}';
            _taskProgress.add(TaskProgressDisplay(
              name: event.taskName ?? '',
              status: TaskStatus.running,
            ));
            break;

          case TaskProgressType.taskCompleted:
            _currentTask = 'Completed: ${event.taskName}';
            final index = _taskProgress.indexWhere(
                  (t) => t.name == event.taskName,
            );
            if (index != -1) {
              _taskProgress[index] = TaskProgressDisplay(
                name: event.taskName ?? '',
                status: TaskStatus.completed,
              );
            }
            _updateProgress();
            break;

          case TaskProgressType.taskFailed:
            _currentTask = 'Failed: ${event.taskName}';
            final index = _taskProgress.indexWhere(
                  (t) => t.name == event.taskName,
            );
            if (index != -1) {
              _taskProgress[index] = TaskProgressDisplay(
                name: event.taskName ?? '',
                status: TaskStatus.failed,
                error: event.error,
              );
            }
            _updateProgress();
            break;

          case TaskProgressType.orchestrationCompleted:
            _currentTask = 'Initialization complete!';
            _overallProgress = 1.0;
            break;

          case TaskProgressType.orchestrationFailed:
            _currentTask = 'Initialization failed';
            break;
        }
      });
    });
  }

  void _updateProgress() {
    final completed = _taskProgress.where((t) =>
    t.status == TaskStatus.completed || t.status == TaskStatus.failed
    ).length;

    _overallProgress = _taskProgress.isEmpty
        ? 0.0
        : completed / _taskProgress.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // App Logo/Icon
              _buildLogo(),

              const SizedBox(height: 48),

              // App Name
              const Text(
                'Task Manager Pro',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimaryDark,
                  letterSpacing: -0.5,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Powered by Orchestration Pattern',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondaryDark,
                ),
              ),

              const SizedBox(height: 64),

              // Loading Spinner
              SpinKitWave(
                color: AppColors.primary,
                size: 50.0,
                controller: _animationController,
              ),

              const SizedBox(height: 32),

              // Current Task
              Text(
                _currentTask,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textPrimaryDark,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              // Progress Bar
              _buildProgressBar(),

              const SizedBox(height: 16),

              // Progress Percentage
              Text(
                '${(_overallProgress * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondaryDark,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const Spacer(),

              // Task List (expandable)
              if (_taskProgress.isNotEmpty) _buildTaskList(),

              const SizedBox(height: 24),

              // Version Info
              const Text(
                'Version 1.0.0',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: const Icon(
        Icons.check_circle_outline,
        size: 60,
        color: Colors.white,
      ),
    );
  }

  Widget _buildProgressBar() {
    return Container(
      width: double.infinity,
      height: 8,
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(4),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: _overallProgress,
          backgroundColor: Colors.transparent,
          valueColor: AlwaysStoppedAnimation<Color>(
            _overallProgress == 1.0 ? AppColors.success : AppColors.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildTaskList() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.borderDark,
          width: 1,
        ),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.all(12),
        itemCount: _taskProgress.length,
        separatorBuilder: (context, index) => const Divider(
          color: AppColors.borderDark,
          height: 16,
        ),
        itemBuilder: (context, index) {
          final task = _taskProgress[index];
          return _buildTaskItem(task);
        },
      ),
    );
  }

  Widget _buildTaskItem(TaskProgressDisplay task) {
    IconData icon;
    Color iconColor;

    switch (task.status) {
      case TaskStatus.running:
        icon = Icons.pending;
        iconColor = AppColors.warning;
        break;
      case TaskStatus.completed:
        icon = Icons.check_circle;
        iconColor = AppColors.success;
        break;
      case TaskStatus.failed:
        icon = Icons.error;
        iconColor = AppColors.error;
        break;
      default:
        icon = Icons.circle_outlined;
        iconColor = AppColors.textSecondaryDark;
    }

    return Row(
      children: [
        Icon(icon, size: 20, color: iconColor),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                task.name,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textPrimaryDark,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (task.error != null)
                Text(
                  task.error!,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.error,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}

/// Helper class to display task progress
class TaskProgressDisplay {
  final String name;
  final TaskStatus status;
  final String? error;

  TaskProgressDisplay({
    required this.name,
    required this.status,
    this.error,
  });
}

enum TaskStatus {
  pending,
  running,
  completed,
  failed,
}