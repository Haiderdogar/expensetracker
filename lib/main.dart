import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/database/database_helper.dart';
import 'core/security/secure_storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = SecureStorageService();
  await DatabaseHelper.instance.initializeInstallationIdentity(storage);
  runApp(const ProviderScope(child: ExpenseTrackerApp()));
}
