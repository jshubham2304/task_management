// lib/presentation/pages/splash_screen.dart

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:task_management/core/constants/strings.dart';
import 'package:task_management/presentation/bloc/auth/auth_bloc.dart';
import 'package:task_management/presentation/bloc/auth/auth_events.dart';
import 'package:task_management/presentation/bloc/auth/auth_state.dart';
import 'package:task_management/presentation/pages/home_pages.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _loadingController;
  late AnimationController _signInButtonController;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoRotateAnimation;
  late Animation<double> _loadingAnimation;
  late List<Animation<double>> _dotAnimations;
  late Animation<double> _fadeAnimation;

  bool _initialAnimationComplete = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startInitialAnimations();
  }

  void _setupAnimations() {
    // Logo animations
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _logoScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.2).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 60.0,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.2, end: 1.0).chain(CurveTween(curve: Curves.easeInOutCubic)),
        weight: 40.0,
      ),
    ]).animate(_logoController);

    _logoRotateAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeOutCubic,
    ));

    // Loading animation
    _loadingController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _loadingAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_loadingController);

    // Sign in button animation
    _signInButtonController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _dotAnimations = List.generate(3, (index) {
      return DelayTween(
        begin: 0.0,
        end: 1.0,
        delay: index * 0.2,
      ).animate(CurvedAnimation(
        parent: _loadingController,
        curve: Curves.easeInOut,
      ));
    });

    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _loadingController,
      curve: const Interval(0.8, 1.0, curve: Curves.easeInOut),
    ));

    // Listen to initial animation completion
    _logoController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _initialAnimationComplete = true;
        });
        if (mounted) {
          context.read<AuthBloc>().add(CheckAuthStatus());
        }
      }
    });
  }

  void _startInitialAnimations() {
    _logoController.forward();
    Future.delayed(const Duration(milliseconds: 500), () {
      _loadingController.repeat();
    });
  }

  void _showSignInButton() {
    _loadingController.stop();
    _signInButtonController.forward();
  }

  void _hideSignInButton() {
    _signInButtonController.reverse();
  }

  Future<void> _navigateToHome() async {
    await _loadingController.reverse();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 500),
          pageBuilder: (context, animation, secondaryAnimation) {
            return FadeTransition(
              opacity: animation,
              child: const HomePage(),
            );
          },
        ),
      );
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _loadingController.dispose();
    _signInButtonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is Authenticated && _initialAnimationComplete) {
          _hideSignInButton();
          _navigateToHome();
        } else if (state is Unauthenticated && _initialAnimationComplete) {
          _showSignInButton();
        } else if (state is AuthError && _initialAnimationComplete) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: theme.colorScheme.error,
            ),
          );
          _showSignInButton();
        }
      },
      builder: (context, state) {
        return AnimatedBuilder(
          animation: Listenable.merge([
            _logoController,
            _loadingController,
            _signInButtonController,
          ]),
          builder: (context, child) {
            return Scaffold(
              backgroundColor: theme.colorScheme.background,
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo
                    Transform.scale(
                      scale: _logoScaleAnimation.value,
                      child: RotationTransition(
                        turns: _logoRotateAnimation,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: theme.colorScheme.primary.withOpacity(0.3),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.check_rounded,
                            size: 60,
                            color: theme.colorScheme.onPrimary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Loading dots
                    if (!_initialAnimationComplete || state is! Unauthenticated)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(3, (index) {
                          return Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Transform.scale(
                              scale: _dotAnimations[index].value,
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withOpacity(1 - index * 0.2),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          );
                        }),
                      ),

                    const SizedBox(height: 32),

                    // App title
                    FadeTransition(
                      opacity: _logoController,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.5),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: _logoController,
                          curve: Curves.easeOutCubic,
                        )),
                        child: Text(
                          'Task Manager',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    // Sign in button
                    if (_initialAnimationComplete && (state is Unauthenticated || state is AuthError))
                      FadeTransition(
                        opacity: _signInButtonController,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 1),
                            end: Offset.zero,
                          ).animate(_signInButtonController),
                          child: Padding(
                            padding: const EdgeInsets.only(top: 48),
                            child: ElevatedButton(
                              onPressed: state is AuthLoading
                                  ? null
                                  : () {
                                      context.read<AuthBloc>().add(SignInWithGoogle());
                                    },
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: state is AuthLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(),
                                    )
                                  : Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const FaIcon(FontAwesomeIcons.google),
                                        const SizedBox(width: 12),
                                        Text(AppStrings.signUpByGoogle),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// Custom Tween for delayed animations
class DelayTween extends Tween<double> {
  final double delay;

  DelayTween({
    required double begin,
    required double end,
    required this.delay,
  }) : super(begin: begin, end: end);

  @override
  double lerp(double t) {
    return super.lerp((math.sin((t - delay) * 2 * math.pi) + 1) / 2);
  }
}
