import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sqflite/sqflite.dart';

import '../core/database/database_helper.dart';
import '../core/security/secure_storage_service.dart';

part 'database_provider.g.dart';

@Riverpod(keepAlive: true)
Future<Database> database(Ref ref) async {
  return DatabaseHelper.instance.database;
}

@Riverpod(keepAlive: true)
DatabaseHelper databaseHelper(Ref ref) {
  return DatabaseHelper.instance;
}

@Riverpod(keepAlive: true)
SecureStorageService secureStorage(Ref ref) {
  return SecureStorageService();
}
