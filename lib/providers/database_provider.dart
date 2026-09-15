import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sqflite/sqflite.dart';

import '../core/database/database_helper.dart';
import '../core/security/secure_storage_service.dart';
import '../core/sync/sync_repository.dart';

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

@Riverpod(keepAlive: true)
SyncRepository syncRepository(Ref ref) {
  final repo = SyncRepository();
  ref.onDispose(repo.dispose);
  return repo;
}

/// Bumped after remote reconcile so local-first providers refresh from SQLite.
@Riverpod(keepAlive: true)
class LocalDataEpoch extends _$LocalDataEpoch {
  @override
  int build() => 0;

  void bump() => state++;
}
