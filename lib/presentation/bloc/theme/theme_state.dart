part of 'theme_bloc.dart';

// States

class ThemeState extends Equatable {
  final ThemeData themeData;
  final bool isDark;

  const ThemeState({
    required this.themeData,
    required this.isDark,
  });

  @override
  List<Object> get props => [isDark];

  ThemeState copyWith({
    ThemeData? themeData,
    bool? isDark,
  }) {
    return ThemeState(
      themeData: themeData ?? this.themeData,
      isDark: isDark ?? this.isDark,
    );
  }
}
