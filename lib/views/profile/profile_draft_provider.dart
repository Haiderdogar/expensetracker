import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../providers/database_provider.dart';
import '../../providers/wallet_provider.dart';

class ProfileDraft {
  const ProfileDraft({
    this.name = '',
    this.email = '',
    this.walletName = '',
    this.savedName = '',
    this.savedEmail = '',
    this.savedWalletName = '',
    this.walletId,
    this.isEditing = false,
    this.isLoading = true,
    this.isInitialized = false,
  });

  final String name;
  final String email;
  final String walletName;
  final String savedName;
  final String savedEmail;
  final String savedWalletName;
  final String? walletId;
  final bool isEditing;
  final bool isLoading;
  final bool isInitialized;

  bool get hasChanges =>
      name.trim() != savedName || email.trim() != savedEmail || walletName.trim() != savedWalletName;

  ProfileDraft copyWith({
    String? name,
    String? email,
    String? walletName,
    String? savedName,
    String? savedEmail,
    String? savedWalletName,
    String? walletId,
    bool? isEditing,
    bool? isLoading,
    bool? isInitialized,
  }) {
    return ProfileDraft(
      name: name ?? this.name,
      email: email ?? this.email,
      walletName: walletName ?? this.walletName,
      savedName: savedName ?? this.savedName,
      savedEmail: savedEmail ?? this.savedEmail,
      savedWalletName: savedWalletName ?? this.savedWalletName,
      walletId: walletId ?? this.walletId,
      isEditing: isEditing ?? this.isEditing,
      isLoading: isLoading ?? this.isLoading,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }
}

final profileDraftProvider = StateProvider.autoDispose<ProfileDraft>(
  (ref) => const ProfileDraft(),
);

Future<void> loadProfile(WidgetRef ref) async {
  final current = ref.read(profileDraftProvider);
  if (current.isInitialized) return;
  ref.read(profileDraftProvider.notifier).state = current.copyWith(isInitialized: true);
  final database = ref.read(databaseHelperProvider);
  final values = await Future.wait<String?>([
    database.getSetting('profile_name'),
    database.getSetting('profile_email'),
  ]);
  final wallets = await ref.read(walletsProvider.future);
  final selectedId = ref.read(selectedWalletIdProvider);
  final matching = wallets.where((wallet) => wallet.id == selectedId).toList();
  final wallet = matching.isNotEmpty ? matching.first : (wallets.isNotEmpty ? wallets.first : null);
  ref.read(profileDraftProvider.notifier).state = ProfileDraft(
    name: values[0] ?? '',
    email: values[1] ?? '',
    walletName: wallet?.name ?? '',
    savedName: values[0] ?? '',
    savedEmail: values[1] ?? '',
    savedWalletName: wallet?.name ?? '',
    walletId: wallet?.id,
    isInitialized: true,
    isLoading: false,
  );
}
