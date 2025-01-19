import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:task_management/core/constants/strings.dart';
import 'package:task_management/domain/enitities/task.dart';
import 'package:task_management/presentation/bloc/auth/auth_bloc.dart';
import 'package:task_management/presentation/bloc/auth/auth_events.dart';
import 'package:task_management/presentation/bloc/auth/auth_state.dart';
import 'package:task_management/presentation/pages/splash_screen.dart';
import 'package:task_management/presentation/pages/task_details_page.dart';
import 'package:task_management/presentation/widgets/task_card.dart';
import 'package:task_management/presentation/widgets/theme_switch.dart';
import '../bloc/task/task_bloc.dart';
import '../../core/constants/theme.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late AnimationController _fabController;
  late Animation<double> _fabScaleAnimation;
  late Animation<double> _fabRotateAnimation;
  ConnectivityResult? _lastConnectivity;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _setupConnectivityListener();
  }

  void _setupAnimations() {
    _fabController = AnimationController(
      duration: AppTheme.normalAnimation,
      vsync: this,
    );

    _fabScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fabController,
      curve: Curves.elasticOut,
    ));

    _fabRotateAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fabController,
      curve: Curves.elasticOut,
    ));

    _fabController.forward();
  }

  void _setupConnectivityListener() {
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      if (_lastConnectivity != result && mounted) {
        _lastConnectivity = result;
        final isOffline = result == ConnectivityResult.none;

        // Update bloc state without loading indicator
        context.read<TaskBloc>().add(ToggleOfflineMode(isOffline));

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  isOffline ? Icons.cloud_off : Icons.cloud_done,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Text(isOffline ? AppStrings.offlineMode : AppStrings.onlineMode),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            backgroundColor: isOffline ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.secondary,
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, authState) {
        if (authState is Unauthenticated) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const SplashScreen()),
            (route) => false,
          );
        }
      },
      child: Scaffold(
        body: CustomScrollView(
          slivers: [
            SliverAppBar.large(
              title: BlocBuilder<AuthBloc, AuthState>(
                builder: (context, authState) {
                  if (authState is Authenticated) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(AppStrings.tasks),
                        Text(
                          'Hello, ${authState.user.displayName}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    );
                  }
                  return const Text(AppStrings.tasks);
                },
              ),
              actions: [
                const AnimatedThemeSwitch(),
                const SizedBox(width: 8),
                // Existing sync status indicator
                BlocBuilder<TaskBloc, TaskState>(
                  builder: (context, state) {
                    if (state is TasksLoaded) {
                      return AnimatedSwitcher(
                        duration: AppTheme.quickAnimation,
                        child: state.isSyncing
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Icon(
                                state.isOffline ? Icons.cloud_off : Icons.cloud_done,
                                key: ValueKey(state.isOffline),
                                size: 20,
                                color: theme.colorScheme.primary,
                              ),
                      );
                    }
                    return const SizedBox();
                  },
                ),
                const SizedBox(width: 8),
                // User Profile Menu
                BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    if (state is Authenticated) {
                      return PopupMenuButton(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: CircleAvatar(
                            radius: 16,
                            backgroundImage: state.user.photoURL != null ? NetworkImage(state.user.photoURL!) : null,
                            child: state.user.photoURL == null
                                ? Text(state.user.displayName?[0].toUpperCase() ?? 'U')
                                : null,
                          ),
                        ),
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            enabled: false,
                            child: Text(state.user.email ?? '', style: theme.textTheme.bodySmall),
                          ),
                          PopupMenuItem(
                            onTap: () => context.read<AuthBloc>().add(SignOut()),
                            child: Row(
                              children: [
                                Icon(Icons.logout, color: theme.colorScheme.error),
                                const SizedBox(width: 8),
                                Text('Sign Out', style: TextStyle(color: theme.colorScheme.error)),
                              ],
                            ),
                          ),
                        ],
                      );
                    }
                    return const SizedBox();
                  },
                ),
                const SizedBox(width: 8),
              ],
            ),
            BlocBuilder<TaskBloc, TaskState>(
              builder: (context, state) {
                if (state is TaskLoading) {
                  return const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (state is TasksLoaded) {
                  if (state.tasks.isEmpty) {
                    return SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.task_outlined,
                              size: 64,
                              color: theme.colorScheme.secondary.withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              AppStrings.noTasks,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: theme.colorScheme.secondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              AppStrings.createTaskPrompt,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.secondary.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return SliverList.builder(
                    itemCount: state.tasks.length,
                    itemBuilder: (context, index) {
                      final task = state.tasks[index];
                      return Padding(
                        padding: EdgeInsets.fromLTRB(
                          16,
                          index == 0 ? 16 : 8,
                          16,
                          index == state.tasks.length - 1 ? 88 : 8,
                        ),
                        child: TaskCard(
                          task: task,
                          onTap: () => _openTaskDetail(context, task),
                          onStatusChanged: (value) {
                            if (value != null) {
                              context.read<TaskBloc>().add(
                                    UpdateTask(
                                      task.copyWith(
                                        isCompleted: value,
                                        updatedAt: DateTime.now(),
                                      ),
                                    ),
                                  );
                            }
                          },
                          onDelete: () {
                            context.read<TaskBloc>().add(DeleteTask(task.id));
                          },
                        ),
                      );
                    },
                  );
                }

                if (state is TaskError) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: theme.colorScheme.error,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            state.message,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.error,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          FilledButton.tonal(
                            onPressed: () {
                              context.read<TaskBloc>().add(LoadTasks());
                            },
                            child: const Text('Try Again'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              },
            ),
          ],
        ),
        floatingActionButton: ScaleTransition(
          scale: _fabScaleAnimation,
          child: RotationTransition(
            turns: _fabRotateAnimation,
            child: FloatingActionButton(
              onPressed: () => _openTaskDetail(context),
              child: const Icon(Icons.add),
            ),
          ),
        ),
      ),
    );
  }

  void _openTaskDetail(BuildContext context, [TaskEntity? task]) {
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) {
            return FadeTransition(
              opacity: animation,
              child: TaskDetailPage(
                task: task,
                userId: authState.user.uid,
              ),
            );
          },
          transitionDuration: AppTheme.normalAnimation,
        ),
      );
    }
  }
}
