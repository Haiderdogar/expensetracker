import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../providers/auth_provider.dart';
import '../../providers/database_provider.dart';

part 'app_shell_providers.g.dart';

class AppShellProfile {
  const AppShellProfile({
    required this.name,
    required this.email,
    this.photoUrl,
  });
  final String name;
  final String email;
  final String? photoUrl;
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
  final database = ref.watch(databaseHelperProvider);
  final settings = await Future.wait([
    database.getSetting('profile_name_$userId'),
    database.getSetting('profile_email_$userId'),
    database.getSetting('profile_photo_url_$userId'),
  ]);
  return AppShellProfile(
    name: settings[0]?.isNotEmpty == true
        ? settings[0]!
        : (user?.displayName ?? ''),
    email: settings[1]?.isNotEmpty == true ? settings[1]! : (user?.email ?? ''),
    photoUrl: settings[2]?.isNotEmpty == true ? settings[2] : user?.photoURL,
  );
}
