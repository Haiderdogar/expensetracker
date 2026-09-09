import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../providers/database_provider.dart';

final appShellNavigationIndexProvider = StateProvider.autoDispose<int>((_) => 0);
final appShellVisitedIndexesProvider = StateProvider.autoDispose<Set<int>>(
  (_) => {0},
);
final appShellProfileProvider = FutureProvider.autoDispose<AppShellProfile>(
  (ref) async {
    final database = ref.watch(databaseHelperProvider);
    final settings = await Future.wait([
      database.getSetting('profile_name'),
      database.getSetting('profile_email'),
    ]);
    return AppShellProfile(name: settings[0] ?? '', email: settings[1] ?? '');
  },
);
final appShellLogoutInProgressProvider = StateProvider.autoDispose<bool>(
  (_) => false,
);

class AppShellProfile {
  const AppShellProfile({required this.name, required this.email});
  final String name;
  final String email;
}
