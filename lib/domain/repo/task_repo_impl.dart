import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dartz/dartz.dart';
import 'package:task_management/core/errors/failure.dart';
import 'package:task_management/data/datasources/task_local_datasources.dart';
import 'package:task_management/data/datasources/task_remote_datasource.dart';
import 'package:task_management/data/model/task_model.dart';
import 'package:task_management/domain/enitities/task.dart';
import 'package:task_management/domain/repo/task_repo.dart';

import 'package:task_management/service/sync_service.dart';

class TaskRepositoryImpl implements TaskRepository {
  final TaskLocalDataSource localDataSource;
  final TaskRemoteDataSource remoteDataSource;
  final Connectivity connectivity;
  final SyncService syncService;
  bool _isOffline = false;

  TaskRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
    required this.connectivity,
    required this.syncService,
  });

  @override
  void setOfflineMode(bool isOffline) {
    _isOffline = isOffline;
    if (!isOffline) {
      syncService.syncPendingOperations();
    }
  }

  @override
  Stream<Either<Failure, List<TaskEntity>>> watchTasks() async* {
    try {
      // First emit from local storage
      final localTasks = await localDataSource.getTasks();
      yield Right(localTasks);

      if (!_isOffline) {
        try {
          await for (final tasks in remoteDataSource.watchTasks()) {
            // Merge with local unsynced changes
            final unsynced = await localDataSource.getUnsynced();
            final mergedTasks = _mergeTasks(tasks, unsynced);

            await localDataSource.syncTasks(mergedTasks);
            yield Right(mergedTasks);
          }
        } catch (e) {
          // On error, keep serving local data
          final localTasks = await localDataSource.getTasks();
          yield Right(localTasks);
        }
      }
    } catch (e) {
      yield const Left(CacheFailure('Failed to load tasks'));
    }
  }

  @override
  Future<Either<Failure, void>> createTask(TaskEntity task) async {
    try {
      final taskModel = TaskModel.fromTask(task);

      // Save locally first
      await localDataSource.cacheTask(taskModel);

      // Schedule sync
      if (!_isOffline) {
        syncService.addPendingOperation(CreateOperation(taskModel));
      }

      return const Right(null);
    } catch (e) {
      return const Left(CacheFailure('Failed to create task'));
    }
  }

  @override
  Future<Either<Failure, void>> updateTask(TaskEntity task) async {
    try {
      final taskModel = TaskModel.fromTask(task);

      // Update locally first
      await localDataSource.updateTask(taskModel);

      // Schedule sync
      if (!_isOffline) {
        syncService.addPendingOperation(UpdateOperation(taskModel));
      }

      return const Right(null);
    } catch (e) {
      return const Left(CacheFailure('Failed to update task'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteTask(String id) async {
    try {
      // Delete locally first
      await localDataSource.deleteTask(id);

      // Schedule sync
      if (!_isOffline) {
        syncService.addPendingOperation(DeleteOperation(id));
      }

      return const Right(null);
    } catch (e) {
      return const Left(CacheFailure('Failed to delete task'));
    }
  }

  @override
  Future<Either<Failure, void>> syncTasks() async {
    try {
      await syncService.syncPendingOperations();
      return const Right(null);
    } catch (e) {
      return const Left(ConnectionFailure());
    }
  }

  List<TaskModel> _mergeTasks(List<TaskModel> remote, List<TaskModel> unsynced) {
    final Map<String, TaskModel> merged = {};

    // Add remote tasks
    for (final task in remote) {
      merged[task.id] = task;
    }

    // Override with unsynced local tasks
    for (final task in unsynced) {
      merged[task.id] = task;
    }

    return merged.values.toList()..sort((a, b) => b.updatedAt?.compareTo(a.updatedAt ?? a.createdAt) ?? 0);
  }

  @override
  Future<List<TaskEntity>> getUnsyncedTasks() async {
    try {
      return await localDataSource.getUnsynced();
    } catch (e) {
      return [];
    }
  }
}
