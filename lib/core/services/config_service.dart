import 'package:dartz/dartz.dart';
import 'storage_service.dart';

/// Service for managing app configuration and feature flags
/// This simulates remote config like Firebase Remote Config
class ConfigService {
  final StorageService _storageService;

  Map<String, dynamic> _featureFlags = {};
  Map<String, dynamic> _remoteConfig = {};
  DateTime? _lastFetchTime;

  ConfigService(this._storageService);

  Map<String, dynamic> get featureFlags => Map.unmodifiable(_featureFlags);
  Map<String, dynamic> get remoteConfig => Map.unmodifiable(_remoteConfig);
  DateTime? get lastFetchTime => _lastFetchTime;

  /// Initialize config from local storage
  Future<Either<String, bool>> initializeFromStorage() async {
    try {
      // Load cached feature flags
      final flagsResult = await _storageService.getFeatureFlags();

      flagsResult.fold(
            (error) => null,
            (flags) {
          if (flags != null) {
            _featureFlags = flags;
          }
        },
      );

      // Set default configs if none exist
      if (_featureFlags.isEmpty) {
        _featureFlags = _getDefaultFeatureFlags();
        await _storageService.saveFeatureFlags(_featureFlags);
      }

      return const Right(true);
    } catch (e) {
      return Left('Config initialization failed: ${e.toString()}');
    }
  }

  /// Fetch fresh config from remote (simulated)
  Future<Either<String, bool>> fetchRemoteConfig() async {
    try {
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 2));

      // Mock remote config data
      final mockRemoteConfig = {
        'api_base_url': 'https://api.example.com/v1',
        'max_tasks_per_user': 100,
        'enable_analytics': true,
        'sync_interval_minutes': 15,
        'cache_ttl_hours': 24,
        'enable_push_notifications': true,
        'maintenance_mode': false,
        'min_app_version': '1.0.0',
        'show_premium_features': false,
      };

      // Mock feature flags
      final mockFeatureFlags = {
        'enable_dark_mode': true,
        'enable_advanced_analytics': true,
        'enable_task_collaboration': false,
        'enable_ai_suggestions': true,
        'enable_offline_mode': true,
        'enable_export_feature': true,
        'show_beta_features': false,
        'enable_voice_input': false,
      };

      _remoteConfig = mockRemoteConfig;
      _featureFlags = mockFeatureFlags;
      _lastFetchTime = DateTime.now();

      // Save to storage
      await _storageService.saveFeatureFlags(_featureFlags);

      return const Right(true);
    } catch (e) {
      return Left('Remote config fetch failed: ${e.toString()}');
    }
  }

  /// Get default feature flags
  Map<String, dynamic> _getDefaultFeatureFlags() {
    return {
      'enable_dark_mode': true,
      'enable_advanced_analytics': false,
      'enable_task_collaboration': false,
      'enable_ai_suggestions': false,
      'enable_offline_mode': true,
      'enable_export_feature': true,
      'show_beta_features': false,
      'enable_voice_input': false,
    };
  }

  /// Check if a feature is enabled
  bool isFeatureEnabled(String featureName) {
    return _featureFlags[featureName] == true;
  }

  /// Get config value with type safety
  T? getConfigValue<T>(String key, {T? defaultValue}) {
    final value = _remoteConfig[key];
    if (value is T) return value;
    return defaultValue;
  }

  /// Get string config value
  String getString(String key, {String defaultValue = ''}) {
    return getConfigValue<String>(key, defaultValue: defaultValue) ?? defaultValue;
  }

  /// Get int config value
  int getInt(String key, {int defaultValue = 0}) {
    return getConfigValue<int>(key, defaultValue: defaultValue) ?? defaultValue;
  }

  /// Get bool config value
  bool getBool(String key, {bool defaultValue = false}) {
    return getConfigValue<bool>(key, defaultValue: defaultValue) ?? defaultValue;
  }

  /// Get double config value
  double getDouble(String key, {double defaultValue = 0.0}) {
    return getConfigValue<double>(key, defaultValue: defaultValue) ?? defaultValue;
  }

  /// Update feature flag (for testing/debugging)
  Future<Either<String, bool>> updateFeatureFlag(
      String flagName,
      bool enabled,
      ) async {
    try {
      _featureFlags[flagName] = enabled;
      await _storageService.saveFeatureFlags(_featureFlags);
      return const Right(true);
    } catch (e) {
      return Left('Failed to update feature flag: ${e.toString()}');
    }
  }

  /// Check if app needs update based on version
  bool needsUpdate(String currentVersion) {
    final minVersion = getString('min_app_version', defaultValue: '1.0.0');
    return _compareVersions(currentVersion, minVersion) < 0;
  }

  /// Compare version strings (simple implementation)
  int _compareVersions(String v1, String v2) {
    final parts1 = v1.split('.').map(int.parse).toList();
    final parts2 = v2.split('.').map(int.parse).toList();

    for (int i = 0; i < 3; i++) {
      final p1 = i < parts1.length ? parts1[i] : 0;
      final p2 = i < parts2.length ? parts2[i] : 0;
      if (p1 != p2) return p1.compareTo(p2);
    }
    return 0;
  }

  /// Check if app is in maintenance mode
  bool isMaintenanceMode() {
    return getBool('maintenance_mode', defaultValue: false);
  }

  /// Get all enabled features
  List<String> getEnabledFeatures() {
    return _featureFlags.entries
        .where((entry) => entry.value == true)
        .map((entry) => entry.key)
        .toList();
  }

  /// Reset to defaults
  Future<Either<String, bool>> resetToDefaults() async {
    try {
      _featureFlags = _getDefaultFeatureFlags();
      _remoteConfig = {};
      await _storageService.saveFeatureFlags(_featureFlags);
      return const Right(true);
    } catch (e) {
      return Left('Reset failed: ${e.toString()}');
    }
  }
}