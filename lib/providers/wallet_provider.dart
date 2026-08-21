import 'package:flutter_riverpod/legacy.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../core/database/database_tables.dart';
import '../core/utils/error_handler.dart';
import '../models/wallet_model.dart';
import 'database_provider.dart';

part 'wallet_provider.g.dart';

final selectedWalletIdProvider = StateProvider<String?>((ref) => null);

@riverpod
String activeWalletName(Ref ref) {
  final selectedId = ref.watch(selectedWalletIdProvider);
  final wallets = ref.watch(walletsProvider).value ?? const <WalletModel>[];
  if (selectedId != null) {
    for (final wallet in wallets) {
      if (wallet.id == selectedId) return wallet.name;
    }
  }
  if (wallets.isNotEmpty) return wallets.first.name;
  return 'Wallet';
}

@Riverpod(keepAlive: true)
class Wallets extends _$Wallets {
  @override
  Future<List<WalletModel>> build() => _fetchAll();

  Future<List<WalletModel>> _fetchAll() async {
    try {
      final db = await ref.read(databaseProvider.future);
      final rows = await db.query(DatabaseTables.wallets, orderBy: 'name ASC');
      return rows.map(WalletModel.fromMap).toList();
    } catch (e) {
      throw ErrorHandler.from(e);
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetchAll);
  }

  Future<WalletModel> create({required String name, double balance = 0}) async {
    try {
      const uuid = Uuid();
      final wallet = WalletModel(id: uuid.v4(), name: name, balance: balance);
      final db = await ref.read(databaseProvider.future);
      await db.insert(DatabaseTables.wallets, wallet.toMap());
      await refresh();
      return wallet;
    } catch (e) {
      throw ErrorHandler.from(e);
    }
  }

  Future<void> updateBalance(String walletId, double delta) async {
    try {
      final db = await ref.read(databaseProvider.future);
      await db.rawUpdate(
        'UPDATE ${DatabaseTables.wallets} SET balance = balance + ? WHERE id = ?',
        [delta, walletId],
      );
      await refresh();
    } catch (e) {
      throw ErrorHandler.from(e);
    }
  }
}

@riverpod
Future<double> totalBalance(Ref ref) async {
  final wallets = await ref.watch(walletsProvider.future);
  return wallets.fold<double>(0, (sum, w) => sum + w.balance);
}
