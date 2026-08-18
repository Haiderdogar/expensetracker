import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../providers/database_provider.dart';

part 'theme_provider.g.dart';

enum AppThemeMode { light, dark, system }

@Riverpod(keepAlive: true)
class ThemeModeController extends _$ThemeModeController {
  @override
  AppThemeMode build() => AppThemeMode.system;

  Future<void> setMode(AppThemeMode mode) async {
    state = mode;
    await ref.read(databaseHelperProvider).setThemeMode(mode.name);
  }

  ThemeMode get flutterThemeMode {
    return switch (state) {
      AppThemeMode.light => ThemeMode.light,
      AppThemeMode.dark => ThemeMode.dark,
      AppThemeMode.system => ThemeMode.system,
    };
  }
}
