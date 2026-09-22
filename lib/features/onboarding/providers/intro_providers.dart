
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'intro_providers.g.dart';

/// Manages the current onboarding page.
///
/// 0 = first page
/// 1 = second page
/// 2 = third page
@riverpod
class IntroPageIndex extends _$IntroPageIndex {
  @override
  int build() {
    return 0;
  }

  /// Updates the current onboarding page.
  void setIndex(int index) {
    state = index;
  }

  /// Resets onboarding to the first page.
  void reset() {
    state = 0;
  }
}

/// Manages the loading state while onboarding
/// completion is being saved.
@riverpod
class IntroCompleting extends _$IntroCompleting {
  @override
  bool build() {
    return false;
  }

  /// Updates the completion/loading state.
  void setCompleting(bool value) {
    state = value;
  }
}

/// Provides the PageController used by the onboarding PageView.
///
/// The controller is disposed automatically when the
/// generated provider is disposed.
@riverpod
PageController introPageController(Ref ref) {
  final controller = PageController();

  ref.onDispose(controller.dispose);

  return controller;
}

