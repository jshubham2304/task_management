import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:task_management/data/datasources/task_local_datasources.dart';
import 'package:task_management/data/model/task_model.dart';
import '../../data/datasources/task_remote_datasource.dart';

class SyncService {
  final TaskLocalDataSource localDataSource;
  final TaskRemoteDataSource remoteDataSource;
  final Connectivity connectivity;

  Timer? _syncTimer;
  bool _isSyncing = false;
  final _pendingOperations = <PendingOperation>[];

  SyncService({
    required this.localDataSource,
    required this.remoteDataSource,
    required this.connectivity,
  });

  Future<void> scheduleSyncIfNeeded() async {
    if (_pendingOperations.isEmpty) return;

    _syncTimer?.cancel();
    _syncTimer = Timer(const Duration(seconds: 5), () {
      syncPendingOperations();
    });
  }

  Future<void> syncPendingOperations() async {
    if (_isSyncing) return;

    final connectivityResult = await connectivity.checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) return;

    _isSyncing = true;

    try {
      while (_pendingOperations.isNotEmpty) {
        final operation = _pendingOperations.removeAt(0);

        try {
          await operation.execute(remoteDataSource);
          await localDataSource.markAsSynced(operation.taskId);
        } catch (e) {
          _pendingOperations.insert(0, operation);
          break;
        }
      }
    } finally {
      _isSyncing = false;
    }

    if (_pendingOperations.isNotEmpty) {
      scheduleSyncIfNeeded();
    }
  }

  void addPendingOperation(PendingOperation operation) {
    _pendingOperations.add(operation);
    scheduleSyncIfNeeded();
  }

  Future<void> dispose() async {
    _syncTimer?.cancel();
    await syncPendingOperations();
  }
}

abstract class PendingOperation {
  final String taskId;
  final DateTime timestamp;

  PendingOperation(this.taskId) : timestamp = DateTime.now();

  Future<void> execute(TaskRemoteDataSource remoteDataSource);
}

class CreateOperation extends PendingOperation {
  final TaskModel task;

  CreateOperation(this.task) : super(task.id);

  @override
  Future<void> execute(TaskRemoteDataSource remoteDataSource) {
    return remoteDataSource.createTask(task);
  }
}

class UpdateOperation extends PendingOperation {
  final TaskModel task;

  UpdateOperation(this.task) : super(task.id);

  @override
  Future<void> execute(TaskRemoteDataSource remoteDataSource) {
    return remoteDataSource.updateTask(task);
  }
}

class DeleteOperation extends PendingOperation {
  DeleteOperation(String taskId) : super(taskId);

  @override
  Future<void> execute(TaskRemoteDataSource remoteDataSource) {
    return remoteDataSource.deleteTask(taskId);
  }
}
