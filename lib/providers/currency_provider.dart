import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'database_provider.dart';

final currencyCodeProvider = FutureProvider<String?>((ref) async {
  final code = await ref.read(databaseHelperProvider).getSetting('currency_code');
  return code;
});
