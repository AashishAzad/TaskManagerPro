import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dartz/dartz.dart';

/// Service for handling local data persistence
/// Wraps SharedPreferences with error handling and type safety
class StorageService {
  final SharedPreferences _prefs;

  StorageService(this._prefs);

  // Storage keys
  static const String _keyAuthToken = 'auth_token';
  static const String _keyUserId = 'user_id';
  static const String _keyUserProfile = 'user_profile';
  static const String _keyTasks = 'tasks';
  static const String _keyAnalyticsData = 'analytics_data';
  static const String _keyLastSyncTime = 'last_sync_time';
  static const String _keyFeatureFlags = 'feature_flags';
  static const String _keyAppVersion = 'app_version';
  static const String _keyFirstLaunch = 'first_launch';

  /// Generic methods for different data types

  Future<Either<String, bool>> saveString(String key, String value) async {
    try {
      final result = await _prefs.setString(key, value);
      return Right(result);
    } catch (e) {
      return Left('Failed to save string: ${e.toString()}');
    }
  }

  Future<Either<String, String?>> getString(String key) async {
    try {
      final value = _prefs.getString(key);
      return Right(value);
    } catch (e) {
      return Left('Failed to get string: ${e.toString()}');
    }
  }

  Future<Either<String, bool>> saveInt(String key, int value) async {
    try {
      final result = await _prefs.setInt(key, value);
      return Right(result);
    } catch (e) {
      return Left('Failed to save int: ${e.toString()}');
    }
  }

  Future<Either<String, int?>> getInt(String key) async {
    try {
      final value = _prefs.getInt(key);
      return Right(value);
    } catch (e) {
      return Left('Failed to get int: ${e.toString()}');
    }
  }

  Future<Either<String, bool>> saveBool(String key, bool value) async {
    try {
      final result = await _prefs.setBool(key, value);
      return Right(result);
    } catch (e) {
      return Left('Failed to save bool: ${e.toString()}');
    }
  }

  Future<Either<String, bool?>> getBool(String key) async {
    try {
      final value = _prefs.getBool(key);
      return Right(value);
    } catch (e) {
      return Left('Failed to get bool: ${e.toString()}');
    }
  }

  Future<Either<String, bool>> saveJson(String key, Map<String, dynamic> json) async {
    try {
      final jsonString = jsonEncode(json);
      final result = await _prefs.setString(key, jsonString);
      return Right(result);
    } catch (e) {
      return Left('Failed to save JSON: ${e.toString()}');
    }
  }

  Future<Either<String, Map<String, dynamic>?>> getJson(String key) async {
    try {
      final jsonString = _prefs.getString(key);
      if (jsonString == null) return const Right(null);

      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return Right(json);
    } catch (e) {
      return Left('Failed to get JSON: ${e.toString()}');
    }
  }

  Future<Either<String, bool>> saveList(String key, List<String> list) async {
    try {
      final result = await _prefs.setStringList(key, list);
      return Right(result);
    } catch (e) {
      return Left('Failed to save list: ${e.toString()}');
    }
  }

  Future<Either<String, List<String>?>> getList(String key) async {
    try {
      final value = _prefs.getStringList(key);
      return Right(value);
    } catch (e) {
      return Left('Failed to get list: ${e.toString()}');
    }
  }

  Future<Either<String, bool>> remove(String key) async {
    try {
      final result = await _prefs.remove(key);
      return Right(result);
    } catch (e) {
      return Left('Failed to remove key: ${e.toString()}');
    }
  }

  Future<Either<String, bool>> clear() async {
    try {
      final result = await _prefs.clear();
      return Right(result);
    } catch (e) {
      return Left('Failed to clear storage: ${e.toString()}');
    }
  }

  bool containsKey(String key) => _prefs.containsKey(key);

  /// Domain-specific methods

  // Auth related
  Future<Either<String, bool>> saveAuthToken(String token) =>
      saveString(_keyAuthToken, token);

  Future<Either<String, String?>> getAuthToken() =>
      getString(_keyAuthToken);

  Future<Either<String, bool>> clearAuthToken() =>
      remove(_keyAuthToken);

  Future<Either<String, bool>> saveUserId(String userId) =>
      saveString(_keyUserId, userId);

  Future<Either<String, String?>> getUserId() =>
      getString(_keyUserId);

  // User profile
  Future<Either<String, bool>> saveUserProfile(Map<String, dynamic> profile) =>
      saveJson(_keyUserProfile, profile);

  Future<Either<String, Map<String, dynamic>?>> getUserProfile() =>
      getJson(_keyUserProfile);

  // Tasks
  Future<Either<String, bool>> saveTasks(List<Map<String, dynamic>> tasks) async {
    try {
      final jsonString = jsonEncode(tasks);
      return saveString(_keyTasks, jsonString);
    } catch (e) {
      return Left('Failed to save tasks: ${e.toString()}');
    }
  }

  Future<Either<String, List<Map<String, dynamic>>?>> getTasks() async {
    try {
      final result = await getString(_keyTasks);
      return result.fold(
            (error) => Left(error),
            (jsonString) {
          if (jsonString == null) return const Right(null);
          final list = jsonDecode(jsonString) as List;
          final tasks = list.map((e) => e as Map<String, dynamic>).toList();
          return Right(tasks);
        },
      );
    } catch (e) {
      return Left('Failed to get tasks: ${e.toString()}');
    }
  }

  // Analytics
  Future<Either<String, bool>> saveAnalyticsData(Map<String, dynamic> data) =>
      saveJson(_keyAnalyticsData, data);

  Future<Either<String, Map<String, dynamic>?>> getAnalyticsData() =>
      getJson(_keyAnalyticsData);

  // Last sync time
  Future<Either<String, bool>> saveLastSyncTime(DateTime time) =>
      saveString(_keyLastSyncTime, time.toIso8601String());

  Future<Either<String, DateTime?>> getLastSyncTime() async {
    final result = await getString(_keyLastSyncTime);
    return result.fold(
          (error) => Left(error),
          (timeString) {
        if (timeString == null) return const Right(null);
        try {
          return Right(DateTime.parse(timeString));
        } catch (e) {
          return Left('Failed to parse sync time: ${e.toString()}');
        }
      },
    );
  }

  // Feature flags
  Future<Either<String, bool>> saveFeatureFlags(Map<String, dynamic> flags) =>
      saveJson(_keyFeatureFlags, flags);

  Future<Either<String, Map<String, dynamic>?>> getFeatureFlags() =>
      getJson(_keyFeatureFlags);

  // App version
  Future<Either<String, bool>> saveAppVersion(String version) =>
      saveString(_keyAppVersion, version);

  Future<Either<String, String?>> getAppVersion() =>
      getString(_keyAppVersion);

  // First launch flag
  Future<Either<String, bool>> setFirstLaunch(bool isFirst) =>
      saveBool(_keyFirstLaunch, isFirst);

  Future<Either<String, bool>> isFirstLaunch() async {
    final result = await getBool(_keyFirstLaunch);
    return result.fold(
          (error) => const Right(true), // Default to true if error
          (value) => Right(value ?? true),
    );
  }
}