part of 'theme_bloc.dart';

abstract class ThemeEvent extends Equatable {
  const ThemeEvent();

  @override
  List<Object?> get props => [];
}

class ToggleTheme extends ThemeEvent {
  final bool isDark;
  const ToggleTheme(this.isDark);

  @override
  List<Object?> get props => [isDark];
}
