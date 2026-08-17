import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'theme_provider.g.dart';

enum AppThemeMode { light, dark, system }

@Riverpod(keepAlive: true)
class ThemeModeController extends _$ThemeModeController {
  @override
  AppThemeMode build() => AppThemeMode.system;

  void setMode(AppThemeMode mode) => state = mode;

  ThemeMode get flutterThemeMode {
    return switch (state) {
      AppThemeMode.light => ThemeMode.light,
      AppThemeMode.dark => ThemeMode.dark,
      AppThemeMode.system => ThemeMode.system,
    };
  }
}
