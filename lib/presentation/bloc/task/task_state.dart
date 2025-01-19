// States

// lib/presentation/bloc/task_state.dart

part of 'task_bloc.dart';

abstract class TaskState extends Equatable {
  const TaskState();

  @override
  List<Object?> get props => [];
}

class TaskInitial extends TaskState {}

class TaskLoading extends TaskState {}

class TasksLoaded extends TaskState {
  final List<TaskEntity> tasks;
  final bool isOffline;
  final Set<String> syncingTaskIds; // Track which tasks are currently syncing

  const TasksLoaded({
    required this.tasks,
    this.isOffline = false,
    this.syncingTaskIds = const {},
  });

  bool get isSyncing => syncingTaskIds.isNotEmpty;

  TasksLoaded copyWith({
    List<TaskEntity>? tasks,
    bool? isOffline,
    Set<String>? syncingTaskIds,
  }) {
    return TasksLoaded(
      tasks: tasks ?? this.tasks,
      isOffline: isOffline ?? this.isOffline,
      syncingTaskIds: syncingTaskIds ?? this.syncingTaskIds,
    );
  }

  @override
  List<Object?> get props => [tasks, isOffline, syncingTaskIds];
}

class TaskError extends TaskState {
  final String message;

  const TaskError(this.message);

  @override
  List<Object?> get props => [message];
}
