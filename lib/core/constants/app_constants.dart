/// Application-wide constants
class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'Task Manager Pro';
  static const String appVersion = '1.0.0';
  static const int appBuildNumber = 1;

  // API Configuration
  static const String apiBaseUrl = 'https://api.example.com/v1';
  static const Duration apiTimeout = Duration(seconds: 30);

  // Storage Keys
  static const String keyAuthToken = 'auth_token';
  static const String keyUserId = 'user_id';
  static const String keyThemeMode = 'theme_mode';

  // Feature Flags Keys
  static const String flagDarkMode = 'enable_dark_mode';
  static const String flagAnalytics = 'enable_advanced_analytics';
  static const String flagOfflineMode = 'enable_offline_mode';

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Cache
  static const Duration cacheTtl = Duration(hours: 24);
  static const int maxCacheSize = 100;

  // Sync
  static const Duration syncInterval = Duration(minutes: 30);
  static const Duration syncTimeout = Duration(seconds: 45);

  // UI
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration splashMinDuration = Duration(seconds: 2);
  static const double defaultPadding = 16.0;
  static const double defaultRadius = 12.0;

  // Task Limits
  static const int maxTaskTitleLength = 100;
  static const int maxTaskDescriptionLength = 500;
  static const int maxTasksPerUser = 1000;

  // Date Formats
  static const String dateFormat = 'MMM dd, yyyy';
  static const String timeFormat = 'hh:mm a';
  static const String dateTimeFormat = 'MMM dd, yyyy hh:mm a';
}