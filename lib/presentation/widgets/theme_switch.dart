// lib/presentation/widgets/theme_switch.dart
// lib/presentation/widgets/animated_theme_switch.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/theme/theme_bloc.dart';
import '../../core/constants/theme.dart';

class AnimatedThemeSwitch extends StatelessWidget {
  const AnimatedThemeSwitch({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, state) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: AppTheme.quickAnimation,
              transitionBuilder: (child, animation) {
                return RotationTransition(
                  turns: animation,
                  child: ScaleTransition(
                    scale: animation,
                    child: child,
                  ),
                );
              },
              child: Icon(
                state.isDark ? Icons.dark_mode : Icons.light_mode,
                key: ValueKey(state.isDark),
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                context.read<ThemeBloc>().add(ToggleTheme(!state.isDark));
              },
              child: AnimatedContainer(
                duration: AppTheme.quickAnimation,
                width: 44,
                height: 24,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: state.isDark
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.5)
                      : Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                ),
                child: Stack(
                  children: [
                    AnimatedAlign(
                      duration: AppTheme.quickAnimation,
                      curve: Curves.easeInOut,
                      alignment: state.isDark ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
