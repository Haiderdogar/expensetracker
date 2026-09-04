import 'dart:async';

import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../providers/database_provider.dart';
import '../utils/error_handler.dart';

part 'theme_provider.g.dart';

enum AppThemeMode { light, dark, system }

@Riverpod(keepAlive: true)
class ThemeModeController extends _$ThemeModeController {
  @override
  AppThemeMode build() {
    unawaited(_restoreSavedMode());
    return AppThemeMode.system;
  }

  bool _userChangedMode = false;

  Future<void> _restoreSavedMode() async {
    String? savedMode;
    try {
      savedMode = await ref.read(databaseHelperProvider).getThemeMode();
    } on AppException catch (error) {
      debugPrint('Unable to restore saved theme mode: $error');
      return;
    }
    if (_userChangedMode) return;

    final restoredMode = switch (savedMode) {
      'light' => AppThemeMode.light,
      'dark' => AppThemeMode.dark,
      'system' => AppThemeMode.system,
      _ => null,
    };
    if (restoredMode != null) state = restoredMode;
  }

  Future<void> setMode(AppThemeMode mode) async {
    _userChangedMode = true;
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
