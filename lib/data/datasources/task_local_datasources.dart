// lib/data/datasources/task_local_datasource.dart

import 'package:hive/hive.dart';
import 'package:task_management/data/model/task_model.dart';

abstract class TaskLocalDataSource {
  Future<List<TaskModel>> getTasks();
  Future<void> cacheTask(TaskModel task);
  Future<void> updateTask(TaskModel task);
  Future<void> deleteTask(String id);
  Future<void> syncTasks(List<TaskModel> tasks);
  Future<void> markAsSynced(String taskId);
  Future<List<TaskModel>> getUnsynced();
}

class TaskLocalDataSourceImpl implements TaskLocalDataSource {
  final Box<TaskModel> taskBox;
  final Box<bool> syncBox;

  TaskLocalDataSourceImpl({
    required this.taskBox,
    required this.syncBox,
  });

  @override
  Future<List<TaskModel>> getTasks() async {
    return taskBox.values.toList();
  }

  @override
  Future<void> cacheTask(TaskModel task) async {
    await taskBox.put(task.id, task);
    await syncBox.put(task.id, false); // Mark as unsynced
  }

  @override
  Future<void> updateTask(TaskModel task) async {
    await taskBox.put(task.id, task);
    await syncBox.put(task.id, false); // Mark as unsynced
  }

  @override
  Future<void> deleteTask(String id) async {
    await taskBox.delete(id);
    await syncBox.delete(id);
  }

  @override
  Future<void> syncTasks(List<TaskModel> tasks) async {
    final batch = {for (var task in tasks) task.id: task};
    await taskBox.putAll(batch);
    // Mark all as synced
    await syncBox.putAll({for (var taskId in batch.keys) taskId: true});
  }

  @override
  Future<void> markAsSynced(String taskId) async {
    await syncBox.put(taskId, true);
  }

  @override
  Future<List<TaskModel>> getUnsynced() async {
    final unsynced = <TaskModel>[];
    for (var taskId in taskBox.keys) {
      if (!(syncBox.get(taskId) ?? false)) {
        final task = taskBox.get(taskId);
        if (task != null) {
          unsynced.add(task);
        }
      }
    }
    return unsynced;
  }
}
