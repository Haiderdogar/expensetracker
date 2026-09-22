import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../providers/auth_provider.dart';
import '../../providers/database_provider.dart';
import '../../features/wallet_currency/providers/wallet_provider.dart';

part 'profile_draft_provider.g.dart';

class ProfileDraft {
  const ProfileDraft({
    this.name = '',
    this.email = '',
    this.walletName = '',
    this.savedName = '',
    this.savedEmail = '',
    this.savedWalletName = '',
    this.walletId,
    this.isGoogleAccount = false,
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
  final bool isGoogleAccount;
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
    bool? isGoogleAccount,
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
      isGoogleAccount: isGoogleAccount ?? this.isGoogleAccount,
      isEditing: isEditing ?? this.isEditing,
      isLoading: isLoading ?? this.isLoading,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }
}

@riverpod
class ProfileDraftNotifier extends _$ProfileDraftNotifier {
  @override
  ProfileDraft build() => const ProfileDraft();

  @override
  set state(ProfileDraft value) => super.state = value;
}

Future<void> loadProfile(WidgetRef ref) async {
  final current = ref.read(profileDraftProvider);
  if (current.isInitialized) return;
  ref.read(profileDraftProvider.notifier).state = current.copyWith(isInitialized: true);

  final user = ref.read(currentUserProvider);
  final userId = ref.read(currentUserIdProvider);
  final database = ref.read(databaseHelperProvider);
  final savedName = await database.getSetting('profile_name_$userId');

  final defaultName = savedName?.isNotEmpty == true
      ? savedName!
      : (user?.displayName ?? '');
  final defaultEmail = user?.email ?? '';

  final wallets = await ref.read(walletsProvider.future);
  final selectedId = ref.read(selectedWalletIdProvider);
  final matching = wallets.where((wallet) => wallet.id == selectedId).toList();
  final wallet = matching.isNotEmpty ? matching.first : (wallets.isNotEmpty ? wallets.first : null);

  ref.read(profileDraftProvider.notifier).state = ProfileDraft(
    name: defaultName,
    email: defaultEmail,
    walletName: wallet?.name ?? '',
    savedName: defaultName,
    savedEmail: defaultEmail,
    savedWalletName: wallet?.name ?? '',
    walletId: wallet?.id,
    isGoogleAccount: user != null,
    isInitialized: true,
    isLoading: false,
  );
}
