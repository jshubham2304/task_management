// lib/data/models/task_model.dart

import 'package:hive/hive.dart';
import 'package:task_management/domain/enitities/task.dart';
part 'task_model.g.dart';

@HiveType(typeId: 0)
class TaskModel extends TaskEntity {
  @override
  @HiveField(0)
  final String id;

  @override
  @HiveField(1)
  final String title;

  @override
  @HiveField(2)
  final String description;

  @override
  @HiveField(3)
  final bool isCompleted;

  @override
  @HiveField(4)
  final DateTime createdAt;

  @override
  @HiveField(5)
  final DateTime? updatedAt;

  @override
  @HiveField(6)
  final String? lastModifiedBy;

  @override
  @HiveField(7)
  final int localVersion;
  @override
  @HiveField(9)
  final String userId;

  const TaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.isCompleted,
    required this.createdAt,
    required this.userId,
    this.updatedAt,
    this.lastModifiedBy,
    this.localVersion = 0,
  }) : super(
          id: id,
          title: title,
          description: description,
          isCompleted: isCompleted,
          createdAt: createdAt,
          updatedAt: updatedAt,
          userId: userId,
          lastModifiedBy: lastModifiedBy,
          localVersion: localVersion,
        );

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      isCompleted: json['isCompleted'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : null,
      lastModifiedBy: json['lastModifiedBy'] as String?,
      localVersion: json['localVersion'] as int? ?? 0,
      userId: json['userId'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'isCompleted': isCompleted,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'lastModifiedBy': lastModifiedBy,
      'localVersion': localVersion,
    };
  }

  @override
  TaskModel copyWith(
      {String? title,
      String? description,
      bool? isCompleted,
      DateTime? updatedAt,
      String? lastModifiedBy,
      int? localVersion,
      String? userId}) {
    return TaskModel(
        id: id,
        title: title ?? this.title,
        description: description ?? this.description,
        isCompleted: isCompleted ?? this.isCompleted,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        lastModifiedBy: lastModifiedBy ?? this.lastModifiedBy,
        localVersion: localVersion ?? this.localVersion,
        userId: userId ?? this.userId);
  }

  factory TaskModel.fromTask(TaskEntity task) {
    return TaskModel(
      id: task.id,
      title: task.title,
      description: task.description,
      isCompleted: task.isCompleted,
      createdAt: task.createdAt,
      updatedAt: task.updatedAt,
      lastModifiedBy: task.lastModifiedBy,
      localVersion: task.localVersion,
      userId: task.userId ?? '',
    );
  }
}
