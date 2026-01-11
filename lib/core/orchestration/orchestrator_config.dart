/// Configuration for the startup orchestrator
class OrchestratorConfig {
  final bool enableParallelExecution;
  final bool continueOnNonCriticalFailure;
  final Duration maxTotalStartupTime;
  final bool enableDetailedLogging;
  final bool showSplashScreen;

  const OrchestratorConfig({
    this.enableParallelExecution = true,
    this.continueOnNonCriticalFailure = true,
    this.maxTotalStartupTime = const Duration(minutes: 2),
    this.enableDetailedLogging = true,
    this.showSplashScreen = true,
  });

  factory OrchestratorConfig.production() {
    return const OrchestratorConfig(
      enableParallelExecution: true,
      continueOnNonCriticalFailure: true,
      maxTotalStartupTime: Duration(seconds: 45),
      enableDetailedLogging: false,
      showSplashScreen: true,
    );
  }

  factory OrchestratorConfig.development() {
    return const OrchestratorConfig(
      enableParallelExecution: true,
      continueOnNonCriticalFailure: true,
      maxTotalStartupTime: Duration(minutes: 2),
      enableDetailedLogging: true,
      showSplashScreen: true,
    );
  }

  factory OrchestratorConfig.testing() {
    return const OrchestratorConfig(
      enableParallelExecution: false,
      continueOnNonCriticalFailure: false,
      maxTotalStartupTime: Duration(seconds: 10),
      enableDetailedLogging: true,
      showSplashScreen: false,
    );
  }
}

/// Result of the orchestration process
class OrchestrationResult {
  final bool success;
  final Duration totalTime;
  final Map<String, TaskResult> taskResults;
  final List<String> errors;
  final List<String> warnings;

  const OrchestrationResult({
    required this.success,
    required this.totalTime,
    required this.taskResults,
    required this.errors,
    required this.warnings,
  });

  bool get hasErrors => errors.isNotEmpty;
  bool get hasWarnings => warnings.isNotEmpty;
  int get completedTasks => taskResults.values
      .where((r) => r.completed)
      .length;
  int get failedTasks => taskResults.values
      .where((r) => r.failed)
      .length;
}

/// Result of individual task execution
class TaskResult {
  final String taskId;
  final String taskName;
  final bool completed;
  final bool failed;
  final bool skipped;
  final Duration? executionTime;
  final String? error;

  const TaskResult({
    required this.taskId,
    required this.taskName,
    required this.completed,
    required this.failed,
    required this.skipped,
    this.executionTime,
    this.error,
  });

  factory TaskResult.fromTask(dynamic task) {
    return TaskResult(
      taskId: task.id,
      taskName: task.name,
      completed: task.status.toString().contains('completed'),
      failed: task.status.toString().contains('failed'),
      skipped: task.status.toString().contains('skipped'),
      executionTime: task.executionTime,
      error: task.errorMessage,
    );
  }
}