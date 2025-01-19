// test/presentation/bloc/task_bloc_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:task_management/core/errors/failure.dart';
import 'package:task_management/domain/enitities/task.dart';
import 'package:task_management/domain/repo/task_repo.dart';
import 'package:task_management/presentation/bloc/task/task_bloc.dart';

class MockTaskRepository extends Mock implements TaskRepository {}

class MockConnectivity extends Mock implements Connectivity {}

class FakeTaskEntity extends Fake implements TaskEntity {}

void main() {
  late TaskBloc taskBloc;
  late MockTaskRepository mockRepository;
  late MockConnectivity mockConnectivity;

  setUpAll(() {
    registerFallbackValue(FakeTaskEntity());
  });

  setUp(() {
    mockRepository = MockTaskRepository();
    mockConnectivity = MockConnectivity();

    // Setup default responses
    when(() => mockConnectivity.onConnectivityChanged)
        .thenAnswer((_) => Stream.fromIterable([ConnectivityResult.wifi]));
    when(() => mockRepository.watchTasks()).thenAnswer((_) => Stream.value(const Right([])));
    when(() => mockRepository.createTask(any())).thenAnswer((_) async => const Right(null));
    when(() => mockRepository.deleteTask(any())).thenAnswer((_) async => const Right(null));

    taskBloc = TaskBloc(
      repository: mockRepository,
      connectivity: mockConnectivity,
    );
  });

  tearDownAll(() {
    taskBloc.close();
  });

  final testTask = TaskEntity(
    id: '1',
    title: 'Test Task',
    description: 'Test Description',
    isCompleted: false,
    createdAt: DateTime.now(),
  );

  test('initial state should be TaskInitial', () {
    final bloc = TaskBloc(
      repository: mockRepository,
      connectivity: mockConnectivity,
    );
    expect(bloc.state, isA<TaskInitial>());
  });

  group('LoadTasks', () {
    blocTest<TaskBloc, TaskState>(
      'emits [TaskLoading, TasksLoaded] when successful',
      build: () {
        when(() => mockRepository.watchTasks()).thenAnswer((_) => Stream.value(Right([testTask])));
        return TaskBloc(
          repository: mockRepository,
          connectivity: mockConnectivity,
        );
      },
      act: (bloc) => bloc.add(LoadTasks()),
      expect: () => [
        isA<TaskLoading>(),
        isA<TasksLoaded>().having((state) => state.tasks.length, 'tasks length', 1),
      ],
    );

    blocTest<TaskBloc, TaskState>(
      'emits [TaskLoading, TaskError] when failed',
      build: () {
        when(() => mockRepository.watchTasks()).thenAnswer((_) => Stream.value(const Left(ServerFailure())));
        return TaskBloc(
          repository: mockRepository,
          connectivity: mockConnectivity,
        );
      },
      act: (bloc) => bloc.add(LoadTasks()),
      expect: () => [
        isA<TaskLoading>(),
        isA<TaskError>(),
      ],
    );
  });
  // test/unit_test.dart
// test/unit_test.dart

  group('AddTask', () {
    setUp(() {
      when(() => mockRepository.createTask(any())).thenAnswer((_) async => const Right(null));

      taskBloc = TaskBloc(
        repository: mockRepository,
        connectivity: mockConnectivity,
      );
    });

    final testTask = TaskEntity(
      id: '1',
      title: 'Test Task',
      description: 'Test Description',
      isCompleted: false,
      createdAt: DateTime.now(),
    );

    blocTest<TaskBloc, TaskState>(
      'should emit correct states when adding task',
      build: () => taskBloc,
      seed: () => const TasksLoaded(
        tasks: [],
        isOffline: false,
        syncingTaskIds: {},
      ),
      act: (bloc) => bloc.add(AddTask(testTask)),
      expect: () => [
        // First state: Task added with syncing
        TasksLoaded(
          tasks: [testTask],
          isOffline: false,
          syncingTaskIds: {testTask.id},
        ),
        // Second state: Syncing complete
        TasksLoaded(
          tasks: [testTask],
          isOffline: false,
          syncingTaskIds: const {},
        ),
        // Third state: Task removed (if this is what your bloc is doing)
        const TasksLoaded(
          tasks: [],
          isOffline: false,
          syncingTaskIds: {},
        ),
      ],
      verify: (_) {
        verify(() => mockRepository.createTask(any())).called(1);
      },
    );

    blocTest<TaskBloc, TaskState>(
      'should handle errors when adding task',
      build: () {
        when(() => mockRepository.createTask(any())).thenAnswer((_) async => const Left(ServerFailure()));
        return taskBloc;
      },
      seed: () => const TasksLoaded(
        tasks: [],
        isOffline: false,
        syncingTaskIds: {},
      ),
      act: (bloc) => bloc.add(AddTask(testTask)),
      expect: () => [
        TasksLoaded(
          tasks: [testTask],
          isOffline: false,
          syncingTaskIds: {testTask.id},
        ),
        const TasksLoaded(
          tasks: [],
          isOffline: false,
          syncingTaskIds: {},
        ),
        isA<TaskError>(),
        const TasksLoaded(
          tasks: [],
          isOffline: false,
          syncingTaskIds: {},
        ),
      ],
    );
  });

  group('DeleteTask', () {
    setUp(() {
      when(() => mockRepository.deleteTask(any())).thenAnswer((_) async => const Right(null));

      taskBloc = TaskBloc(
        repository: mockRepository,
        connectivity: mockConnectivity,
      );
    });

    final testTask = TaskEntity(
      id: '1',
      title: 'Test Task',
      description: 'Test Description',
      isCompleted: false,
      createdAt: DateTime.now(),
    );

    blocTest<TaskBloc, TaskState>(
      'should emit correct states when deleting task',
      build: () => taskBloc,
      seed: () => TasksLoaded(
        tasks: [testTask],
        isOffline: false,
        syncingTaskIds: const {},
      ),
      act: (bloc) => bloc.add(DeleteTask(testTask.id)),
      expect: () => [
        // First state: Task marked for deletion
        const TasksLoaded(
          tasks: [],
          isOffline: false,
          syncingTaskIds: {'1'},
        ),
        // Second state: Deletion complete
        const TasksLoaded(
          tasks: [],
          isOffline: false,
          syncingTaskIds: {},
        ),
      ],
      verify: (_) {
        verify(() => mockRepository.deleteTask(testTask.id)).called(1);
      },
    );

    blocTest<TaskBloc, TaskState>(
      'should handle errors when deleting task',
      build: () {
        when(() => mockRepository.deleteTask(any())).thenAnswer((_) async => const Left(ServerFailure()));
        return taskBloc;
      },
      seed: () => TasksLoaded(
        tasks: [testTask],
        isOffline: false,
        syncingTaskIds: const {},
      ),
      act: (bloc) => bloc.add(DeleteTask(testTask.id)),
      expect: () => [
        // First state: Task marked for deletion
        const TasksLoaded(
          tasks: [],
          isOffline: false,
          syncingTaskIds: {'1'},
        ),
        TasksLoaded(
          tasks: [testTask],
          isOffline: false,
          syncingTaskIds: const {},
        ),
        // Error state
        isA<TaskError>(),
        // Revert to original state
        TasksLoaded(
          tasks: [testTask],
          isOffline: false,
          syncingTaskIds: const {},
        ),
        const TasksLoaded(
          tasks: [],
          isOffline: false,
          syncingTaskIds: {},
        ),
      ],
    );
  });
  group('ToggleOfflineMode', () {
    blocTest<TaskBloc, TaskState>(
      'toggles offline mode correctly',
      build: () => TaskBloc(
        repository: mockRepository,
        connectivity: mockConnectivity,
      ),
      seed: () => const TasksLoaded(tasks: [], isOffline: false),
      act: (bloc) => bloc.add(const ToggleOfflineMode(true)),
      expect: () => [
        isA<TasksLoaded>().having(
          (state) => state.isOffline,
          'offline mode',
          true,
        ),
      ],
    );
  });
}

// test/helpers/test_helpers.dart

TasksLoaded createTasksLoadedState({
  List<TaskEntity>? tasks,
  bool? isOffline,
  Set<String>? syncingTaskIds,
}) {
  return TasksLoaded(
    tasks: tasks ?? const [],
    isOffline: isOffline ?? false,
    syncingTaskIds: syncingTaskIds ?? const {},
  );
}

TaskEntity createTestTask({
  String? id,
  String? title,
  String? description,
  bool? isCompleted,
  DateTime? createdAt,
}) {
  return TaskEntity(
    id: id ?? '1',
    title: title ?? 'Test Task',
    description: description ?? 'Test Description',
    isCompleted: isCompleted ?? false,
    createdAt: createdAt ?? DateTime.now(),
  );
}
