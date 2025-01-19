import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:task_management/core/errors/failure.dart';
import 'package:task_management/domain/enitities/task.dart';
import 'package:task_management/domain/repo/task_repo.dart';
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

part 'task_state.dart';
part 'task_events.dart';

class TaskBloc extends Bloc<TaskEvent, TaskState> {
  final TaskRepository repository;
  final Connectivity connectivity;
  StreamSubscription<Either<Failure, List<TaskEntity>>>? _tasksSubscription;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  TaskBloc({
    required this.repository,
    required this.connectivity,
  }) : super(TaskInitial()) {
    on<LoadTasks>(_onLoadTasks);
    on<AddTask>(_onAddTask);
    on<UpdateTask>(_onUpdateTask);
    on<DeleteTask>(_onDeleteTask);
    on<ToggleOfflineMode>(_onToggleOfflineMode);
    on<SyncTasks>(_onSyncTasks);
    on<TaskDataReceived>(_onTaskDataReceived);
    on<TaskErrorReceived>(_onTaskErrorReceived);

    // Initial load
    add(LoadTasks());

    // Listen to connectivity changes
    _connectivitySubscription = connectivity.onConnectivityChanged.listen((ConnectivityResult result) {
      if (result != ConnectivityResult.none && state is TasksLoaded) {
        final currentState = state as TasksLoaded;
        if (currentState.isOffline) {
          add(SyncTasks());
        }
      }
    });
  }

  void _onTaskDataReceived(TaskDataReceived event, Emitter<TaskState> emit) {
    if (state is TasksLoaded) {
      final currentState = state as TasksLoaded;
      emit(currentState.copyWith(tasks: event.tasks));
    } else {
      emit(TasksLoaded(tasks: event.tasks));
    }
  }

  void _onTaskErrorReceived(TaskErrorReceived event, Emitter<TaskState> emit) {
    emit(TaskError(_mapFailureToMessage(event.failure)));
  }

  Future<void> _onAddTask(AddTask event, Emitter<TaskState> emit) async {
    if (state is TasksLoaded) {
      final currentState = state as TasksLoaded;
      final updatedTasks = List<TaskEntity>.from(currentState.tasks)..add(event.task);

      // Add task to syncing set
      final syncingIds = Set<String>.from(currentState.syncingTaskIds)..add(event.task.id);

      emit(TasksLoaded(
        tasks: updatedTasks,
        isOffline: currentState.isOffline,
        syncingTaskIds: syncingIds,
      ));

      final result = await repository.createTask(event.task);

      if (!emit.isDone) {
        if (result.isLeft()) {
          emit(currentState);
          emit(TaskError(_mapFailureToMessage(result.fold((l) => l, (r) => null)!)));
          emit(currentState);
        } else {
          // Remove task from syncing set
          final syncingIds = Set<String>.from(currentState.syncingTaskIds)..remove(event.task.id);

          emit(TasksLoaded(
            tasks: updatedTasks,
            isOffline: currentState.isOffline,
            syncingTaskIds: syncingIds,
          ));
        }
      }
    }
  }

  Future<void> _onUpdateTask(UpdateTask event, Emitter<TaskState> emit) async {
    if (state is TasksLoaded) {
      final currentState = state as TasksLoaded;
      final taskIndex = currentState.tasks.indexWhere((t) => t.id == event.task.id);

      if (taskIndex != -1) {
        final updatedTasks = List<TaskEntity>.from(currentState.tasks)..[taskIndex] = event.task;

        // Add task to syncing set
        final syncingIds = Set<String>.from(currentState.syncingTaskIds)..add(event.task.id);

        emit(TasksLoaded(
          tasks: updatedTasks,
          isOffline: currentState.isOffline,
          syncingTaskIds: syncingIds,
        ));

        final result = await repository.updateTask(event.task);

        if (!emit.isDone) {
          if (result.isLeft()) {
            emit(currentState);
            emit(TaskError(_mapFailureToMessage(result.fold((l) => l, (r) => null)!)));
            emit(currentState);
          } else {
            // Remove task from syncing set
            final syncingIds = Set<String>.from(currentState.syncingTaskIds)..remove(event.task.id);

            emit(TasksLoaded(
              tasks: updatedTasks,
              isOffline: currentState.isOffline,
              syncingTaskIds: syncingIds,
            ));
          }
        }
      }
    }
  }

  Future<void> _onDeleteTask(DeleteTask event, Emitter<TaskState> emit) async {
    if (state is TasksLoaded) {
      final currentState = state as TasksLoaded;
      final updatedTasks = List<TaskEntity>.from(currentState.tasks)..removeWhere((t) => t.id == event.taskId);

      // Add task to syncing set
      final syncingIds = Set<String>.from(currentState.syncingTaskIds)..add(event.taskId);

      emit(TasksLoaded(
        tasks: updatedTasks,
        isOffline: currentState.isOffline,
        syncingTaskIds: syncingIds,
      ));

      final result = await repository.deleteTask(event.taskId);

      if (!emit.isDone) {
        if (result.isLeft()) {
          emit(currentState);
          emit(TaskError(_mapFailureToMessage(result.fold((l) => l, (r) => null)!)));
          emit(currentState);
        } else {
          // Remove task from syncing set
          final syncingIds = Set<String>.from(currentState.syncingTaskIds)..remove(event.taskId);

          emit(TasksLoaded(
            tasks: updatedTasks,
            isOffline: currentState.isOffline,
            syncingTaskIds: syncingIds,
          ));
        }
      }
    }
  }

  Future<void> _onToggleOfflineMode(
    ToggleOfflineMode event,
    Emitter<TaskState> emit,
  ) async {
    if (state is TasksLoaded) {
      final currentState = state as TasksLoaded;

      // Set offline mode in repository
      repository.setOfflineMode(event.isOffline);

      // First emit state with updated offline status
      emit(TasksLoaded(
        tasks: currentState.tasks,
        isOffline: event.isOffline,
        syncingTaskIds: currentState.syncingTaskIds,
      ));

      // If going online, sync pending changes
      if (!event.isOffline) {
        try {
          // Get unsynced tasks
          final unsynced = await repository.getUnsyncedTasks();

          if (unsynced.isNotEmpty) {
            // Update state to show syncing for unsynced tasks
            emit(TasksLoaded(
              tasks: currentState.tasks,
              isOffline: false,
              syncingTaskIds: unsynced.map((task) => task.id).toSet(),
            ));

            // Perform sync
            final result = await repository.syncTasks();

            if (!emit.isDone) {
              result.fold(
                (failure) {
                  // On failure, show error and return to previous state
                  emit(TaskError(_mapFailureToMessage(failure)));
                  emit(currentState.copyWith(isOffline: false));
                },
                (_) {
                  // On success, clear syncing status
                  emit(TasksLoaded(
                    tasks: currentState.tasks,
                    isOffline: false,
                    syncingTaskIds: const {}, // Clear syncing status
                  ));
                },
              );
            }
          } else {
            // No tasks to sync, just update offline status
            emit(TasksLoaded(
              tasks: currentState.tasks,
              isOffline: false,
              syncingTaskIds: const {},
            ));
          }
        } catch (e) {
          // Handle any sync errors
          if (!emit.isDone) {
            emit(const TaskError('Failed to sync tasks'));
            emit(currentState.copyWith(isOffline: false));
          }
        }
      }
    }
  }

  void _onLoadTasks(LoadTasks event, Emitter<TaskState> emit) async {
    if (state is! TasksLoaded) {
      emit(TaskLoading());
    }

    await _tasksSubscription?.cancel();

    _tasksSubscription = repository.watchTasks().listen(
      (failureOrTasks) {
        failureOrTasks.fold(
          (failure) => add(TaskErrorReceived(failure)),
          (tasks) => add(TaskDataReceived(tasks)),
        );
      },
    );
  }

  Future<void> _onSyncTasks(SyncTasks event, Emitter<TaskState> emit) async {
    if (state is TasksLoaded) {
      final currentState = state as TasksLoaded;

      try {
        // Get unsynced tasks first
        final unsynced = await repository.getUnsyncedTasks();

        if (unsynced.isEmpty) {
          // If no unsynced tasks, just emit current state without syncing
          emit(currentState.copyWith(syncingTaskIds: {}));
          return;
        }

        // Update state to show which tasks are syncing
        emit(currentState.copyWith(
          syncingTaskIds: unsynced.map((task) => task.id).toSet(),
        ));

        // Perform sync
        final result = await repository.syncTasks();

        if (!emit.isDone) {
          result.fold(
            (failure) {
              // On failure, show error and clear sync status
              emit(TaskError(_mapFailureToMessage(failure)));
              emit(currentState.copyWith(syncingTaskIds: {}));
            },
            (_) {
              // On success, clear sync status
              emit(currentState.copyWith(
                syncingTaskIds: {},
              ));
            },
          );
        }
      } catch (e) {
        if (!emit.isDone) {
          // Handle any unexpected errors
          emit(TaskError('Failed to sync tasks: ${e.toString()}'));
          emit(currentState.copyWith(syncingTaskIds: {}));
        }
      }
    }
  }

  String _mapFailureToMessage(Failure failure) {
    switch (failure.runtimeType) {
      case ServerFailure:
        return (failure as ServerFailure).message ?? 'Failed to connect to server';
      case CacheFailure:
        return (failure as CacheFailure).message ?? 'Failed to load data from cache';
      case ConnectionFailure:
        return 'No internet connection';
      case ValidationFailure:
        return (failure as ValidationFailure).message;
      default:
        return 'Unexpected error';
    }
  }

  @override
  Future<void> close() {
    _tasksSubscription?.cancel();
    _connectivitySubscription?.cancel();
    return super.close();
  }
}
