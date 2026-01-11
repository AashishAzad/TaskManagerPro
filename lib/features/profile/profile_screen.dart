import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/di/service_locator.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/sync_service.dart';
import '../../core/services/cache_service.dart';
import '../../core/services/config_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/repositories/task_repository.dart';
import 'widgets/statistics_card.dart';

/// Profile screen showing user info and app settings
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

@override
State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = sl<AuthService>();
  final _syncService = sl<SyncService>();
  final _cacheService = sl<CacheService>();
  final _configService = sl<ConfigService>();
  final _storageService = sl<StorageService>();
  final _taskRepository = sl<TaskRepository>();

  @override
  Widget build(BuildContext context) {
    final userProfile = _authService.userProfile;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildProfileHeader(userProfile),
            const SizedBox(height: 24),
            const StatisticsCard(),
            const SizedBox(height: 16),
            _buildSyncSection(),
            const SizedBox(height: 16),
            _buildCacheSection(),
            const SizedBox(height: 16),
            _buildDataSection(),
            const SizedBox(height: 16),
            _buildSettingsSection(),
            const SizedBox(height: 16),
            _buildAboutSection(),
            const SizedBox(height: 24),
            _buildLogoutButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(Map<String, dynamic>? profile) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: AppColors.primary,
              backgroundImage: profile?['avatar'] != null
                  ? NetworkImage(profile!['avatar'])
                  : null,
              child: profile?['avatar'] == null
                  ? const Icon(Icons.person, size: 50, color: Colors.white)
                  : null,
            ),
            const SizedBox(height: 16),
            Text(
              profile?['name'] ?? 'Guest User',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimaryDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              profile?['email'] ?? 'not logged in',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondaryDark,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _authService.isAuthenticated
                    ? AppColors.success.withOpacity(0.2)
                    : AppColors.error.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _authService.isAuthenticated ? Icons.check_circle : Icons.error,
                    size: 16,
                    color: _authService.isAuthenticated
                        ? AppColors.success
                        : AppColors.error,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _authService.isAuthenticated ? 'Active' : 'Offline',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _authService.isAuthenticated
                          ? AppColors.success
                          : AppColors.error,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncSection() {
    final syncStatus = _syncService.getSyncStatus();
    final lastSync = syncStatus['last_sync_time'] as String?;

    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.sync, color: AppColors.primary),
            title: const Text('Sync Status'),
            subtitle: Text(
              lastSync != null
                  ? 'Last synced: ${_formatDateTime(lastSync)}'
                  : 'Never synced',
            ),
            trailing: syncStatus['is_syncing'] == true
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : null,
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.cloud_upload, color: AppColors.info),
            title: const Text('Sync Now'),
            subtitle: const Text('Synchronize all data'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _performSync,
          ),
        ],
      ),
    );
  }

  Widget _buildCacheSection() {
    final cacheStats = _cacheService.getStats();

    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.storage, color: AppColors.secondary),
            title: const Text('Cache'),
            subtitle: Text(
              '${cacheStats['valid_entries']} entries cached',
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: AppColors.error),
            title: const Text('Clear Cache'),
            subtitle: const Text('Free up storage space'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _clearCache,
          ),
        ],
      ),
    );
  }

  Widget _buildDataSection() {
    return Card(
      child: Column(
        children: [
          const ListTile(
            leading: Icon(Icons.data_usage, color: AppColors.info),
            title: Text('Data Management'),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.backup, color: AppColors.success),
            title: const Text('Export Data'),
            subtitle: const Text('Backup your tasks (Coming soon)'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Export feature coming soon!'),
                  backgroundColor: AppColors.info,
                ),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.restore, color: AppColors.warning),
            title: const Text('Import Data'),
            subtitle: const Text('Restore from backup (Coming soon)'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Import feature coming soon!'),
                  backgroundColor: AppColors.info,
                ),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: AppColors.error),
            title: const Text('Clear All Data'),
            subtitle: const Text('Delete all tasks and reset app'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _clearAllData,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Card(
      child: Column(
        children: [
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode, color: AppColors.primary),
            title: const Text('Dark Mode'),
            subtitle: const Text('Use dark theme'),
            value: _configService.isFeatureEnabled('enable_dark_mode'),
            onChanged: (value) {
              _configService.updateFeatureFlag('enable_dark_mode', value);
              setState(() {});
            },
          ),
          const Divider(height: 1),
          SwitchListTile(
            secondary: const Icon(Icons.notifications, color: AppColors.warning),
            title: const Text('Notifications'),
            subtitle: const Text('Enable push notifications'),
            value: _configService.getBool('enable_push_notifications'),
            onChanged: (value) {
              setState(() {});
            },
          ),
          const Divider(height: 1),
          SwitchListTile(
            secondary: const Icon(Icons.analytics, color: AppColors.accent),
            title: const Text('Advanced Analytics'),
            subtitle: const Text('Detailed insights and reports'),
            value: _configService.isFeatureEnabled('enable_advanced_analytics'),
            onChanged: (value) {
              _configService.updateFeatureFlag('enable_advanced_analytics', value);
              setState(() {});
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection() {
    return Card(
      child: Column(
        children: [
          const ListTile(
            leading: Icon(Icons.info, color: AppColors.info),
            title: Text('App Version'),
            subtitle: Text('1.0.0 (Build 1)'),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.architecture, color: AppColors.secondary),
            title: const Text('Architecture'),
            subtitle: const Text('Clean Architecture + Orchestration Pattern'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showArchitectureInfo(),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.code, color: AppColors.primary),
            title: const Text('Tech Stack'),
            subtitle: const Text('Flutter + BLoC + Clean Architecture'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showTechStackInfo(),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    if (!_authService.isAuthenticated) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _logout,
        icon: const Icon(Icons.logout),
        label: const Text('Logout'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.error,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  String _formatDateTime(String isoString) {
    try {
      final dateTime = DateTime.parse(isoString);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inHours < 1) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inDays < 1) {
        return '${difference.inHours}h ago';
      } else {
        return '${difference.inDays}d ago';
      }
    } catch (e) {
      return 'Unknown';
    }
  }

  Future<void> _performSync() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    final result = await _syncService.forceSyncNow();

    if (mounted) {
      Navigator.pop(context);

      result.fold(
            (error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Sync failed: $error'),
              backgroundColor: AppColors.error,
            ),
          );
        },
            (syncResult) {
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Synced ${syncResult.syncedItems}/${syncResult.totalItems} items',
              ),
              backgroundColor: AppColors.success,
            ),
          );
        },
      );
    }
  }

  Future<void> _clearCache() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text('Are you sure you want to clear the cache?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _cacheService.clear();

      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cache cleared successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  Future<void> _clearAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
          'This will delete all your tasks and reset the app to its initial state. '
              'This action cannot be undone!\n\n'
              'Are you absolutely sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Delete Everything'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Delete all tasks
      final tasksResult = await _taskRepository.getAllTasks();
      await tasksResult.fold(
            (error) async => null,
            (tasks) async {
          for (final task in tasks) {
            await _taskRepository.deleteTask(task.id);
          }
        },
      );

      // Clear cache
      await _cacheService.clear();

      // Clear analytics
      await _storageService.remove('analytics_data');

      // Mark as first launch to recreate sample data
      await _storageService.setFirstLaunch(true);

      if (mounted) {
        Navigator.pop(context); // Close loading

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All data cleared! Restart the app to see sample data.'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _showArchitectureInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Architecture Info'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Startup Orchestration Pattern',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'The app uses a centralized orchestrator to manage startup tasks with dependency resolution, priority-based execution, and real-time progress tracking.',
              ),
              SizedBox(height: 16),
              Text(
                'Clean Architecture',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Organized in layers: Core (services, orchestration), Features (UI + BLoC), and Shared (models, widgets).',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showTechStackInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tech Stack'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('• Flutter SDK'),
              Text('• BLoC State Management'),
              Text('• GetIt (Service Locator)'),
              Text('• Hive (Local Database)'),
              Text('• Dartz (Functional Programming)'),
              Text('• Logger (Logging)'),
              Text('• Equatable (Value Equality)'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _authService.logout();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logged out successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }
}