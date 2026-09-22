import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import 'package:expensetracker/core/utils/error_handler.dart';
import 'package:expensetracker/models/wallet_model.dart';
import 'package:expensetracker/features/google_sign_in/providers/auth_provider.dart';
import 'package:expensetracker/providers/database_provider.dart';

part 'wallet_provider.g.dart';

@riverpod
class SelectedWalletId extends _$SelectedWalletId {
  @override
  String? build() => null;

  void setSelectedId(String? id) => state = id;
}

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

@riverpod
String? activeWalletId(Ref ref) {
  final selectedId = ref.watch(selectedWalletIdProvider);
  final wallets = ref.watch(walletsProvider).value ?? const <WalletModel>[];
  if (selectedId != null && wallets.any((wallet) => wallet.id == selectedId)) {
    return selectedId;
  }
  return wallets.isEmpty ? null : wallets.first.id;
}

@Riverpod(keepAlive: true)
class Wallets extends _$Wallets {
  @override
  Future<List<WalletModel>> build() => _fetchAll();

  Future<List<WalletModel>> _fetchAll() async {
    try {
      ref.watch(localDataEpochProvider);
      final userId = ref.watch(currentUserIdProvider);
      final syncRepo = ref.read(syncRepositoryProvider);
      return await syncRepo.getWallets(userId);
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
      final userId = ref.read(currentUserIdProvider);
      final wallet = WalletModel(
        id: uuid.v4(),
        userId: userId,
        name: name,
        balance: balance,
        isSynced: false,
      );
      final syncRepo = ref.read(syncRepositoryProvider);
      await syncRepo.saveWallet(wallet);
      await ref
          .read(databaseHelperProvider)
          .ensureWalletDefaults(userId, wallet.id);
      await refresh();
      return wallet;
    } catch (e) {
      throw ErrorHandler.from(e);
    }
  }

  Future<void> updateWallet(WalletModel wallet) async {
    try {
      final userId = ref.read(currentUserIdProvider);
      final syncRepo = ref.read(syncRepositoryProvider);
      await syncRepo.saveWallet(
        wallet.copyWith(userId: userId, isSynced: false),
      );
      await refresh();
    } catch (e) {
      throw ErrorHandler.from(e);
    }
  }

  Future<void> updateBalance(String walletId, double delta) async {
    try {
      final userId = ref.read(currentUserIdProvider);
      final syncRepo = ref.read(syncRepositoryProvider);
      await syncRepo.updateWalletBalance(walletId, userId, delta);
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
