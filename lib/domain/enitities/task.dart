import 'package:equatable/equatable.dart';

class TaskEntity extends Equatable {
  final String id;
  final String? userId; // Added user ID
  final String title;
  final String description;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? lastModifiedBy;
  final int localVersion;

  const TaskEntity({
    required this.id,
    this.userId, // Required user ID
    required this.title,
    required this.description,
    this.isCompleted = false,
    required this.createdAt,
    this.updatedAt,
    this.lastModifiedBy,
    this.localVersion = 0,
  });

  TaskEntity copyWith({
    String? title,
    String? description,
    bool? isCompleted,
    DateTime? updatedAt,
    String? lastModifiedBy,
    int? localVersion,
  }) {
    return TaskEntity(
      id: id,
      userId: userId, // Preserve user ID
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastModifiedBy: lastModifiedBy ?? this.lastModifiedBy,
      localVersion: localVersion ?? this.localVersion,
    );
  }

  @override
  List<Object?> get props => [];
}
