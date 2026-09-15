import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'auth_provider.dart';
import 'database_provider.dart';

part 'currency_provider.g.dart';

@riverpod
Future<String?> currencyCode(Ref ref) async {
  final userId = ref.watch(currentUserIdProvider);
  final helper = ref.read(databaseHelperProvider);
  final perUser = await helper.getSetting('currency_code_$userId');
  if (perUser != null && perUser.isNotEmpty) return perUser;
  return helper.getSetting('currency_code');
}
