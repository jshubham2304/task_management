// lib/presentation/widgets/task_card.dart

import 'package:flutter/material.dart';
import 'package:task_management/domain/enitities/task.dart';

import '../../core/constants/theme.dart';

class TaskCard extends StatefulWidget {
  final TaskEntity task;
  final VoidCallback onTap;
  final ValueChanged<bool?> onStatusChanged;
  final VoidCallback onDelete;

  const TaskCard({
    Key? key,
    required this.task,
    required this.onTap,
    required this.onStatusChanged,
    required this.onDelete,
  }) : super(key: key);

  @override
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isDeleting = false;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppTheme.normalAnimation,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ScaleTransition(
      scale: _scaleAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Dismissible(
          key: Key(widget.task.id),
          direction: DismissDirection.endToStart,
          onDismissed: (_) {
            if (!_isDeleting) {
              setState(() => _isDeleting = true);
              widget.onDelete();
            }
          },
          background: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.error,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 16.0),
            child: const Icon(
              Icons.delete_outline,
              color: Colors.white,
            ),
          ),
          child: Card(
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                  duration: AppTheme.quickAnimation,
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: widget.task.isCompleted ? theme.colorScheme.primary.withOpacity(0.5) : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    children: [
                      AnimatedScale(
                        duration: AppTheme.quickAnimation,
                        scale: widget.task.isCompleted ? 1.1 : 1.0,
                        child: Checkbox(
                          value: widget.task.isCompleted,
                          onChanged: widget.onStatusChanged,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.task.title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                decoration: widget.task.isCompleted ? TextDecoration.lineThrough : null,
                                color: widget.task.isCompleted
                                    ? theme.colorScheme.primary.withOpacity(0.7)
                                    : theme.colorScheme.primary,
                              ),
                            ),
                            if (widget.task.description.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                widget.task.description,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.secondary,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: 14,
                                  color: theme.colorScheme.secondary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _formatDate(widget.task.updatedAt ?? widget.task.createdAt),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.secondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (_isDeleting)
                        const Padding(
                          padding: EdgeInsets.only(left: 16),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                    ],
                  )),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
