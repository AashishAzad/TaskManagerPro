import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

enum TaskSortOption {
  dateCreatedNewest,
  dateCreatedOldest,
  dueDateSoonest,
  dueDateLatest,
  priorityHighest,
  priorityLowest,
  titleAZ,
  titleZA,
}

extension TaskSortOptionExtension on TaskSortOption {
  String get label {
    switch (this) {
      case TaskSortOption.dateCreatedNewest:
        return 'Date Created (Newest)';
      case TaskSortOption.dateCreatedOldest:
        return 'Date Created (Oldest)';
      case TaskSortOption.dueDateSoonest:
        return 'Due Date (Soonest)';
      case TaskSortOption.dueDateLatest:
        return 'Due Date (Latest)';
      case TaskSortOption.priorityHighest:
        return 'Priority (Highest)';
      case TaskSortOption.priorityLowest:
        return 'Priority (Lowest)';
      case TaskSortOption.titleAZ:
        return 'Title (A-Z)';
      case TaskSortOption.titleZA:
        return 'Title (Z-A)';
    }
  }

  IconData get icon {
    switch (this) {
      case TaskSortOption.dateCreatedNewest:
      case TaskSortOption.dateCreatedOldest:
        return Icons.calendar_today;
      case TaskSortOption.dueDateSoonest:
      case TaskSortOption.dueDateLatest:
        return Icons.event;
      case TaskSortOption.priorityHighest:
      case TaskSortOption.priorityLowest:
        return Icons.priority_high;
      case TaskSortOption.titleAZ:
      case TaskSortOption.titleZA:
        return Icons.sort_by_alpha;
    }
  }
}

/// Bottom sheet for task sort options
class SortOptionsSheet extends StatelessWidget {
  final TaskSortOption? currentSort;
  final Function(TaskSortOption) onSortSelected;

  const SortOptionsSheet({
    super.key,
    this.currentSort,
    required this.onSortSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: const BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textSecondaryDark,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Title
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(Icons.sort, color: AppColors.primary),
                SizedBox(width: 12),
                Text(
                  'Sort By',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimaryDark,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.borderDark),

          // Sort options - Wrapped in Flexible and ListView
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: TaskSortOption.values.map((option) {
                final isSelected = currentSort == option;
                return ListTile(
                  leading: Icon(
                    option.icon,
                    color: isSelected ? AppColors.primary : AppColors.textSecondaryDark,
                  ),
                  title: Text(
                    option.label,
                    style: TextStyle(
                      color: isSelected ? AppColors.primary : AppColors.textPrimaryDark,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check, color: AppColors.primary)
                      : null,
                  onTap: () {
                    onSortSelected(option);
                    Navigator.pop(context);
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}