import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:task_management/core/errors/failure.dart';
import 'package:task_management/data/model/task_model.dart';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:task_management/service/firebase_config.dart';

abstract class TaskRemoteDataSource {
  Stream<List<TaskModel>> watchTasks();
  Future<void> createTask(TaskModel task);
  Future<void> updateTask(TaskModel task);
  Future<void> deleteTask(String id);
  Future<void> enableSync();
  Future<void> disableSync();
  // Add getter for current user ID
  String get userId;
}

class TaskRemoteDataSourceImpl implements TaskRemoteDataSource {
  final FirebaseFirestore _firestore;
  @override
  final String userId; // Make userId public through getter
  final Connectivity _connectivity;

  TaskRemoteDataSourceImpl({
    required FirebaseFirestore firestore,
    required String userId,
    required Connectivity connectivity,
  })  : _firestore = firestore,
        userId = userId,
        _connectivity = connectivity;

  CollectionReference<Map<String, dynamic>> get _tasksCollection => _firestore.collection('users/$userId/tasks');

  @override
  Stream<List<TaskModel>> watchTasks() {
    try {
      return _tasksCollection
          .orderBy('updatedAt', descending: true)
          .withConverter<TaskModel>(
            fromFirestore: (snapshot, _) => TaskModel.fromJson({
              ...snapshot.data()!,
              'id': snapshot.id,
              'userId': userId, // Add userId to the task data
            }),
            toFirestore: (task, _) => {
              ...task.toJson(),
              'userId': userId, // Always include userId in Firebase document
              'lastModifiedAt': FieldValue.serverTimestamp(),
            },
          )
          .snapshots()
          .handleError((error) {
        if (error is FirebaseException) {
          if (error.code == 'unavailable') {
            return [];
          }
        }
        throw error;
      }).map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
    } catch (e) {
      return Stream.value([]);
    }
  }

  @override
  Future<void> createTask(TaskModel task) async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        throw const ConnectionFailure();
      }

      // Ensure task has correct userId
      final taskData = {
        ...task.toJson(),
        'userId': userId,
        'createdAt': FieldValue.serverTimestamp(),
        'lastModifiedAt': FieldValue.serverTimestamp(),
      };

      await _tasksCollection.doc(task.id).set(taskData);
    } on FirebaseException catch (e) {
      if (e.code == 'unavailable') {
        throw const ConnectionFailure();
      }
      throw ServerFailure(e.message);
    } catch (e) {
      if (e is ConnectionFailure) rethrow;
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<void> updateTask(TaskModel task) async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        throw const ConnectionFailure();
      }

      // Verify task belongs to current user
      if (task.userId != userId) {
        throw const ServerFailure('Unauthorized to modify this task');
      }

      final taskData = {
        ...task.toJson(),
        'lastModifiedAt': FieldValue.serverTimestamp(),
      };

      await _tasksCollection.doc(task.id).update(taskData);
    } on FirebaseException catch (e) {
      if (e.code == 'unavailable') {
        throw const ConnectionFailure();
      }
      throw ServerFailure(e.message);
    } catch (e) {
      if (e is ConnectionFailure) rethrow;
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<void> deleteTask(String id) async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        throw const ConnectionFailure();
      }

      // Get the task first to verify ownership
      final taskDoc = await _tasksCollection.doc(id).get();
      if (taskDoc.exists) {
        final taskData = taskDoc.data();
        if (taskData != null && taskData['userId'] == userId) {
          await _tasksCollection.doc(id).delete();
        } else {
          throw const ServerFailure('Unauthorized to delete this task');
        }
      }
    } on FirebaseException catch (e) {
      if (e.code == 'unavailable') {
        throw const ConnectionFailure();
      }
      throw ServerFailure(e.message);
    } catch (e) {
      if (e is ConnectionFailure) rethrow;
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<void> enableSync() async {
    await FirebaseConfig.enableNetwork();
  }

  @override
  Future<void> disableSync() async {
    await FirebaseConfig.disableNetwork();
  }
}
