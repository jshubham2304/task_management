// lib/presentation/pages/task_detail_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:task_management/domain/enitities/task.dart';
import 'package:task_management/presentation/bloc/auth/auth_bloc.dart';
import 'package:task_management/presentation/bloc/auth/auth_state.dart';
import 'package:task_management/presentation/widgets/bottom_button.dart';
import '../bloc/task/task_bloc.dart';
import '../../core/constants/theme.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/strings.dart';
// lib/presentation/pages/task_detail_page.dart

class TaskDetailPage extends StatefulWidget {
  final TaskEntity? task;
  final String userId; // Add userId parameter

  const TaskDetailPage({
    Key? key,
    this.task,
    required this.userId,
  }) : super(key: key);

  @override
  State<TaskDetailPage> createState() => _TaskDetailPageState();
}

class _TaskDetailPageState extends State<TaskDetailPage> with SingleTickerProviderStateMixin {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late FocusNode _titleFocus;
  late FocusNode _descriptionFocus;
  bool _isCompleted = false;
  bool _isDirty = false;
  final _formKey = GlobalKey<FormState>();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _setupAnimations();
  }

  void _initializeControllers() {
    _titleController = TextEditingController(text: widget.task?.title);
    _descriptionController = TextEditingController(text: widget.task?.description);
    _isCompleted = widget.task?.isCompleted ?? false;
    _titleFocus = FocusNode();
    _descriptionFocus = FocusNode();

    _titleController.addListener(_onFormChanged);
    _descriptionController.addListener(_onFormChanged);
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: AppTheme.normalAnimation,
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _animationController.forward();
  }

  void _onFormChanged() {
    final isDirty = _titleController.text != (widget.task?.title ?? '') ||
        _descriptionController.text != (widget.task?.description ?? '') ||
        _isCompleted != (widget.task?.isCompleted ?? false);

    if (isDirty != _isDirty) {
      setState(() {
        _isDirty = isDirty;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _titleFocus.dispose();
    _descriptionFocus.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    if (!_isDirty) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.discardChanges),
        content: const Text(AppStrings.unsavedChanges),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              AppStrings.discard,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.task != null;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text(isEditing ? AppStrings.editTask : AppStrings.newTask),
          actions: [
            if (isEditing)
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: _showDeleteConfirmation,
              ),
          ],
        ),
        bottomNavigationBar: FadeTransition(
          opacity: _fadeAnimation,
          child: SafeArea(
            child: BottomActionButton(
              onPressed: _isDirty ? _saveTask : null,
              label: isEditing ? AppStrings.update : AppStrings.create,
            ),
          ),
        ),
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Hero(
                  tag: widget.task?.id ?? 'new_task',
                  child: Material(
                    type: MaterialType.transparency,
                    child: TextFormField(
                      controller: _titleController,
                      focusNode: _titleFocus,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        labelText: AppStrings.title,
                        hintText: AppStrings.titleHint,
                        prefixIcon: const Icon(Icons.title),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return AppStrings.titleError;
                        }
                        if (value.length < 3) {
                          return AppStrings.titleLengthError;
                        }
                        return null;
                      },
                      onFieldSubmitted: (_) {
                        _descriptionFocus.requestFocus();
                      },
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  focusNode: _descriptionFocus,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: AppStrings.description,
                    hintText: AppStrings.descriptionHint,
                    alignLabelWithHint: true,
                    prefixIcon: const Icon(Icons.description),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  maxLines: 5,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) {
                    if (_isDirty && (_formKey.currentState?.validate() ?? false)) {
                      _saveTask();
                    }
                  },
                ),
                const SizedBox(height: 16),
                AnimatedContainer(
                  duration: AppTheme.quickAnimation,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.primary.withOpacity(0.2),
                    ),
                  ),
                  child: Material(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        setState(() {
                          _isCompleted = !_isCompleted;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            Icon(
                              _isCompleted ? Icons.check_circle : Icons.check_circle_outline,
                              color: _isCompleted ? theme.colorScheme.primary : theme.colorScheme.secondary,
                            ),
                            const SizedBox(width: 16),
                            Text(
                              AppStrings.markAsCompleted,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: _isCompleted ? theme.colorScheme.primary : null,
                              ),
                            ),
                            const Spacer(),
                            Switch(
                              value: _isCompleted,
                              onChanged: (value) {
                                setState(() {
                                  _isCompleted = value;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation() {
    showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.deleteTask),
        content: const Text(AppStrings.deleteConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<TaskBloc>().add(DeleteTask(widget.task!.id));
              Navigator.pop(context);
            },
            child: Text(
              AppStrings.delete,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  void _saveTask() {
    if (_formKey.currentState?.validate() ?? false) {
      final now = DateTime.now();
      final task = widget.task?.copyWith(
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            isCompleted: _isCompleted,
            updatedAt: now,
          ) ??
          TaskEntity(
            id: const Uuid().v4(),
            userId: widget.userId, // Add user ID to new tasks
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            isCompleted: _isCompleted,
            createdAt: now,
            updatedAt: now,
          );

      final authState = context.read<AuthBloc>().state;
      if (authState is Authenticated) {
        final updatedTask = task.copyWith(
          lastModifiedBy: authState.user.email, // Track who modified the task
        );

        context.read<TaskBloc>().add(
              widget.task != null ? UpdateTask(updatedTask) : AddTask(updatedTask),
            );
      }
      Navigator.pop(context);
    }
  }
}
