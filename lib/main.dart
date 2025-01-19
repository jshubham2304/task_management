// lib/main.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:nested/nested.dart';
import 'package:path_provider/path_provider.dart';
import 'package:task_management/data/datasources/task_local_datasources.dart';
import 'package:task_management/data/model/task_model.dart';
import 'package:task_management/domain/repo/task_repo_impl.dart';
import 'package:task_management/presentation/bloc/auth/auth_bloc.dart';
import 'package:task_management/presentation/bloc/theme/theme_bloc.dart';
import 'package:task_management/presentation/pages/splash_screen.dart';
import 'package:task_management/service/firebase_config.dart';
import 'package:task_management/service/sync_service.dart';
import 'data/datasources/task_remote_datasource.dart';
import 'presentation/bloc/task/task_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await FirebaseConfig.init();

  // Initialize Hive

  if (!kIsWeb) {
    final appDocumentDir = await getApplicationDocumentsDirectory();
    await Hive.initFlutter(appDocumentDir.path);
  } else {
    await Hive.initFlutter();
  }

  Hive.registerAdapter(TaskModelAdapter());

  // Open Hive box
  final taskBox = await Hive.openBox<TaskModel>('tasks');
  await Hive.openBox<bool>('sync_status');

  runApp(MyApp(taskBox: taskBox));
}

class MyApp extends StatelessWidget {
  final Box<TaskModel> taskBox;

  const MyApp({
    Key? key,
    required this.taskBox,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: _getProviders,
      child: BlocBuilder<ThemeBloc, ThemeState>(builder: (context, themeState) {
        return MaterialApp(
          title: 'Task Manager',
          theme: themeState.themeData,
          home: const SplashScreen(),
          builder: (context, child) {
            return BlocListener<TaskBloc, TaskState>(
              listener: (context, state) {
                if (state is TaskError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: Theme.of(context).colorScheme.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              child: child!,
            );
          },
        );
      }),
    );
  }

  List<SingleChildWidget> get _getProviders {
    return [
      BlocProvider(
        create: (context) => AuthBloc(),
      ),
      BlocProvider(
        create: (context) => ThemeBloc(),
      ),
      BlocProvider<TaskBloc>(
        create: (context) {
          final firestore = FirebaseFirestore.instance;
          final connectivity = Connectivity();

          // Initialize Hive boxes
          final taskBox = Hive.box<TaskModel>('tasks');
          final syncBox = Hive.box<bool>('sync_status');

          final localDataSource = TaskLocalDataSourceImpl(
            taskBox: taskBox,
            syncBox: syncBox,
          );

          final remoteDataSource = TaskRemoteDataSourceImpl(
            firestore: firestore,
            userId: 'demo_user', // Replace with actual user ID
            connectivity: connectivity,
          );

          final syncService = SyncService(
            localDataSource: localDataSource,
            remoteDataSource: remoteDataSource,
            connectivity: connectivity,
          );

          final repository = TaskRepositoryImpl(
            localDataSource: localDataSource,
            remoteDataSource: remoteDataSource,
            connectivity: connectivity,
            syncService: syncService,
          );

          // Initialize BLoC
          return TaskBloc(
            repository: repository,
            connectivity: connectivity,
          );
        },
      ),
    ];
  }
}
