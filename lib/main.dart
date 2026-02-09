import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'core/orchestration/startup_orchestrator.dart';
import 'core/orchestration/orchestrator_config.dart';
import 'core/orchestration/tasks/initialize_services_task.dart';
import 'core/orchestration/tasks/initialize_storage_task.dart';
import 'core/orchestration/tasks/validate_auth_task.dart';
import 'core/orchestration/tasks/load_config_task.dart';
import 'core/orchestration/tasks/sync_data_task.dart';
import 'core/orchestration/tasks/process_analytics_task.dart';
import 'core/constants/app_colors.dart';
import 'core/orchestration/tasks/warmup_cache_task.dart';
import 'features/home/home_screen.dart';
import 'features/splash/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI overlay style, It is for status bar of the mobile device.
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task Manager Pro',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      // System settings ke hisaab se apne aap switch karega, But we have to create Ligth and Dark theme separately, currently we only have dark theme.
      // themeMode: ThemeMode.system,
      home: const AppInitializer(),
      // Firebase Integration at every cost. For data storage, analytics, testing and many more functions.
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: AppColors.backgroundDark,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surfaceDark,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceDark,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}

/// Widget that handles app initialization using the orchestrator
class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  final Logger _logger = Logger();
  late StartupOrchestrator _orchestrator;
  bool _isInitialized = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      _logger.i('🚀 Starting app initialization...');

      // Create orchestrator with configuration
      _orchestrator = StartupOrchestrator(
        config: OrchestratorConfig.development(),
      );

      // Register all startup tasks
      // The orchestrator will handle dependencies and execution order
      _orchestrator.registerTasks([
        InitializeServicesTask(),
        InitializeStorageTask(),
        ValidateAuthTask(),
        LoadConfigTask(),
        WarmupCacheTask(),
        SyncDataTask(),
        ProcessAnalyticsTask(),
      ]);

      // Start orchestration
      final result = await _orchestrator.orchestrate();

      if (result.success) {
        _logger.i('✅ App initialized successfully');
        setState(() {
          _isInitialized = true;
        });
      } else {
        _logger.e('❌ App initialization failed');
        setState(() {
          _errorMessage = result.errors.join('\n');
        });
      }
    } catch (e, stackTrace) {
      _logger.e('Fatal initialization error', error: e, stackTrace: stackTrace);
      setState(() {
        _errorMessage = 'Fatal error: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return _buildErrorScreen();
    }

    if (!_isInitialized) {
      return SplashScreen(
        orchestrator: _orchestrator,
      );
    }

    return const HomeScreen();
  }

  Widget _buildErrorScreen() {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: AppColors.error,
                size: 64,
              ),
              const SizedBox(height: 24),
              const Text(
                'Initialization Failed',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimaryDark,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage ?? 'Unknown error',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondaryDark,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _errorMessage = null;
                    _isInitialized = false;
                  });
                  _initializeApp();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _orchestrator.dispose();
    super.dispose();
  }
}