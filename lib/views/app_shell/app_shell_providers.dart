import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../providers/auth_provider.dart';
import '../../providers/database_provider.dart';

part 'app_shell_providers.g.dart';

class AppShellProfile {
  const AppShellProfile({required this.name, required this.email});
  final String name;
  final String email;
}

@riverpod
class AppShellNavigationIndex extends _$AppShellNavigationIndex {
  @override
  int build() => 0;

  @override
  set state(int value) => super.state = value;
  void setIndex(int value) => state = value;
}

@riverpod
class AppShellVisitedIndexes extends _$AppShellVisitedIndexes {
  @override
  Set<int> build() => {0};

  @override
  set state(Set<int> value) => super.state = value;
  void addIndex(int index) => state = {...state, index};
}

@riverpod
class AppShellLogoutInProgress extends _$AppShellLogoutInProgress {
  @override
  bool build() => false;

  @override
  set state(bool value) => super.state = value;
}

@riverpod
Future<AppShellProfile> appShellProfile(Ref ref) async {
  final user = ref.watch(currentUserProvider);
  final userId = ref.watch(currentUserIdProvider);
  if (user != null && user.displayName != null && user.displayName!.isNotEmpty) {
    return AppShellProfile(
      name: user.displayName ?? '',
      email: user.email ?? '',
    );
  }
  final database = ref.watch(databaseHelperProvider);
  final settings = await Future.wait([
    database.getSetting('profile_name_$userId'),
    database.getSetting('profile_email_$userId'),
  ]);
  return AppShellProfile(name: settings[0] ?? '', email: settings[1] ?? '');
}
