// lib/domain/repositories/task_repository.dart

import 'package:dartz/dartz.dart';
import 'package:task_management/core/errors/failure.dart';
import 'package:task_management/domain/enitities/task.dart';

abstract class TaskRepository {
  /// Watch tasks stream
  Stream<Either<Failure, List<TaskEntity>>> watchTasks();

  /// Create a new task
  Future<Either<Failure, void>> createTask(TaskEntity task);

  /// Update an existing task
  Future<Either<Failure, void>> updateTask(TaskEntity task);

  /// Delete a task by ID
  Future<Either<Failure, void>> deleteTask(String id);

  /// Synchronize local tasks with remote
  Future<Either<Failure, void>> syncTasks();

  Future<List<TaskEntity>> getUnsyncedTasks();

  /// Set offline mode
  void setOfflineMode(bool isOffline);
}
