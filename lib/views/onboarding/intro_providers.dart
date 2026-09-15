import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'intro_providers.g.dart';

@riverpod
class IntroPageIndex extends _$IntroPageIndex {
  @override
  int build() => 0;

  void setIndex(int index) => state = index;
}

@riverpod
class IntroCompleting extends _$IntroCompleting {
  @override
  bool build() => false;

  void setCompleting(bool value) => state = value;
}

@riverpod
PageController introPageController(Ref ref) {
  final controller = PageController();
  ref.onDispose(controller.dispose);
  return controller;
}
