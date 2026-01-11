import 'package:equatable/equatable.dart';

/// Task model representing a single task
class TaskModel extends Equatable {
  final String id;
  final String title;
  final String description;
  final bool completed;
  final TaskPriority priority;
  final TaskCategory category;
  final DateTime createdAt;
  final DateTime? completedAt;
  final DateTime? dueDate;
  final List<String> tags;

  const TaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.completed,
    required this.priority,
    required this.category,
    required this.createdAt,
    this.completedAt,
    this.dueDate,
    this.tags = const [],
  });

  // Factory constructor from JSON
  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      completed: json['completed'] as bool? ?? false,
      priority: TaskPriority.fromString(json['priority'] as String? ?? 'medium'),
      category: TaskCategory.fromString(json['category'] as String? ?? 'personal'),
      createdAt: DateTime.parse(json['createdAt'] as String),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      dueDate: json['dueDate'] != null
          ? DateTime.parse(json['dueDate'] as String)
          : null,
      tags: (json['tags'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ?? [],
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'completed': completed,
      'priority': priority.value,
      'category': category.value,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'dueDate': dueDate?.toIso8601String(),
      'tags': tags,
    };
  }

  // CopyWith method for immutability
  TaskModel copyWith({
    String? id,
    String? title,
    String? description,
    bool? completed,
    TaskPriority? priority,
    TaskCategory? category,
    DateTime? createdAt,
    DateTime? completedAt,
    DateTime? dueDate,
    List<String>? tags,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      completed: completed ?? this.completed,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      dueDate: dueDate ?? this.dueDate,
      tags: tags ?? this.tags,
    );
  }

  // Helper methods
  bool get isOverdue {
    if (completed || dueDate == null) return false;
    return DateTime.now().isAfter(dueDate!);
  }

  bool get isDueToday {
    if (dueDate == null) return false;
    final now = DateTime.now();
    return dueDate!.year == now.year &&
        dueDate!.month == now.month &&
        dueDate!.day == now.day;
  }

  Duration? get timeUntilDue {
    if (dueDate == null) return null;
    return dueDate!.difference(DateTime.now());
  }

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    completed,
    priority,
    category,
    createdAt,
    completedAt,
    dueDate,
    tags,
  ];
}

/// Task priority enum
enum TaskPriority {
  low('low'),
  medium('medium'),
  high('high'),
  urgent('urgent');

  final String value;
  const TaskPriority(this.value);

  static TaskPriority fromString(String value) {
    return TaskPriority.values.firstWhere(
          (e) => e.value == value.toLowerCase(),
      orElse: () => TaskPriority.medium,
    );
  }
}

/// Task category enum
enum TaskCategory {
  work('work'),
  personal('personal'),
  shopping('shopping'),
  health('health'),
  education('education'),
  finance('finance'),
  other('other');

  final String value;
  const TaskCategory(this.value);

  static TaskCategory fromString(String value) {
    return TaskCategory.values.firstWhere(
          (e) => e.value == value.toLowerCase(),
      orElse: () => TaskCategory.personal,
    );
  }

  String get displayName {
    return value[0].toUpperCase() + value.substring(1);
  }
}