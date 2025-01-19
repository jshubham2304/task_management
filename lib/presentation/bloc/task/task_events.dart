// lib/presentation/bloc/task_event.dart

part of 'task_bloc.dart';

abstract class TaskEvent extends Equatable {
  const TaskEvent();

  @override
  List<Object?> get props => [];
}

class LoadTasks extends TaskEvent {}

class AddTask extends TaskEvent {
  final TaskEntity task;

  const AddTask(this.task);

  @override
  List<Object?> get props => [task];
}

class UpdateTask extends TaskEvent {
  final TaskEntity task;

  const UpdateTask(this.task);

  @override
  List<Object?> get props => [task];
}

class DeleteTask extends TaskEvent {
  final String taskId;

  const DeleteTask(this.taskId);

  @override
  List<Object?> get props => [taskId];
}

class ToggleOfflineMode extends TaskEvent {
  final bool isOffline;

  const ToggleOfflineMode(this.isOffline);

  @override
  List<Object?> get props => [isOffline];
}

class SyncTasks extends TaskEvent {}

class TaskDataReceived extends TaskEvent {
  final List<TaskEntity> tasks;

  const TaskDataReceived(this.tasks);

  @override
  List<Object?> get props => [tasks];
}

class TaskErrorReceived extends TaskEvent {
  final Failure failure;

  const TaskErrorReceived(this.failure);

  @override
  List<Object?> get props => [failure];
}
