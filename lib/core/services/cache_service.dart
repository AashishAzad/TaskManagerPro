import 'package:dartz/dartz.dart';

/// In-memory cache service for frequently accessed data
/// Implements cache warming strategy during startup
class CacheService {
  final Map<String, CacheEntry> _cache = {};
  final Duration _defaultTtl = const Duration(hours: 1);

  bool _isWarmed = false;

  bool get isWarmed => _isWarmed;
  int get cacheSize => _cache.length;

  /// Warm up the cache with frequently accessed data
  /// This is a heavy operation done during startup
  Future<Either<String, bool>> warmupCache() async {
    try {
      // Simulate loading and processing data for cache
      await Future.delayed(const Duration(seconds: 2));

      // Pre-load common data structures
      await _warmupUserPreferences();
      await _warmupAppConstants();
      await _warmupFrequentQueries();

      _isWarmed = true;
      return const Right(true);
    } catch (e) {
      return Left('Cache warmup failed: ${e.toString()}');
    }
  }

  /// Store data in cache
  Future<Either<String, bool>> put<T>(
      String key,
      T data, {
        Duration? ttl,
      }) async {
    try {
      final expiry = DateTime.now().add(ttl ?? _defaultTtl);
      _cache[key] = CacheEntry(
        data: data,
        expiry: expiry,
        createdAt: DateTime.now(),
      );
      return const Right(true);
    } catch (e) {
      return Left('Cache put failed: ${e.toString()}');
    }
  }

  /// Retrieve data from cache
  Future<Either<String, T?>> get<T>(String key) async {
    try {
      final entry = _cache[key];

      if (entry == null) {
        return const Right(null);
      }

      // Check if expired
      if (entry.isExpired) {
        _cache.remove(key);
        return const Right(null);
      }

      if (entry.data is T) {
        return Right(entry.data as T);
      }

      return const Right(null);
    } catch (e) {
      return Left('Cache get failed: ${e.toString()}');
    }
  }

  /// Remove specific key from cache
  Future<Either<String, bool>> remove(String key) async {
    try {
      _cache.remove(key);
      return const Right(true);
    } catch (e) {
      return Left('Cache remove failed: ${e.toString()}');
    }
  }

  /// Clear all cache
  Future<Either<String, bool>> clear() async {
    try {
      _cache.clear();
      _isWarmed = false;
      return const Right(true);
    } catch (e) {
      return Left('Cache clear failed: ${e.toString()}');
    }
  }

  /// Check if key exists in cache
  bool has(String key) {
    final entry = _cache[key];
    return entry != null && !entry.isExpired;
  }

  /// Get all cache keys
  List<String> getKeys() {
    return _cache.keys.toList();
  }

  /// Remove expired entries
  Future<Either<String, int>> cleanExpired() async {
    try {
      final keysToRemove = <String>[];

      _cache.forEach((key, entry) {
        if (entry.isExpired) {
          keysToRemove.add(key);
        }
      });

      for (final key in keysToRemove) {
        _cache.remove(key);
      }

      return Right(keysToRemove.length);
    } catch (e) {
      return Left('Cache cleanup failed: ${e.toString()}');
    }
  }

  /// Get cache statistics
  Map<String, dynamic> getStats() {
    int expiredCount = 0;
    int validCount = 0;

    _cache.forEach((key, entry) {
      if (entry.isExpired) {
        expiredCount++;
      } else {
        validCount++;
      }
    });

    return {
      'total_entries': _cache.length,
      'valid_entries': validCount,
      'expired_entries': expiredCount,
      'is_warmed': _isWarmed,
      'memory_usage_estimate': _cache.length * 1024, // Rough estimate
    };
  }

  /// Private warmup methods

  Future<void> _warmupUserPreferences() async {
    await Future.delayed(const Duration(milliseconds: 500));

    await put('user_theme', 'dark');
    await put('user_language', 'en');
    await put('notifications_enabled', true);
    await put('sync_on_startup', true);
  }

  Future<void> _warmupAppConstants() async {
    await Future.delayed(const Duration(milliseconds: 300));

    final constants = {
      'app_name': 'Task Manager Pro',
      'app_version': '1.0.0',
      'api_version': 'v1',
      'max_file_size': 10485760, // 10MB
      'supported_formats': ['json', 'csv', 'txt'],
    };

    await put('app_constants', constants);
  }

  Future<void> _warmupFrequentQueries() async {
    await Future.delayed(const Duration(milliseconds: 700));

    // Pre-cache frequently used lookup data
    final taskCategories = [
      'Work',
      'Personal',
      'Shopping',
      'Health',
      'Education',
      'Finance',
      'Other',
    ];

    final taskPriorities = ['Low', 'Medium', 'High', 'Urgent'];

    final taskStatuses = ['Todo', 'In Progress', 'Completed', 'Archived'];

    await put('task_categories', taskCategories);
    await put('task_priorities', taskPriorities);
    await put('task_statuses', taskStatuses);
  }

  /// Get cached data or compute and cache it
  Future<Either<String, T>> getOrCompute<T>(
      String key,
      Future<T> Function() compute, {
        Duration? ttl,
      }) async {
    final cached = await get<T>(key);

    return await cached.fold(
          (error) async {
        final computed = await compute();
        await put(key, computed, ttl: ttl);
        return Right(computed);
      },
          (data) async {
        if (data != null) {
          return Right(data);
        }

        final computed = await compute();
        await put(key, computed, ttl: ttl);
        return Right(computed);
      },
    );
  }
}

/// Cache entry model
class CacheEntry {
  final dynamic data;
  final DateTime expiry;
  final DateTime createdAt;

  CacheEntry({
    required this.data,
    required this.expiry,
    required this.createdAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiry);

  Duration get age => DateTime.now().difference(createdAt);

  Duration get timeToLive => expiry.difference(DateTime.now());
}