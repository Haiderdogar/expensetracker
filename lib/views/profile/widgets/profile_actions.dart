import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/app_snackbars.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/database_provider.dart';
import '../../../providers/wallet_provider.dart';
import '../profile_draft_provider.dart';

class ProfileActions extends ConsumerWidget {
  const ProfileActions({super.key, required this.draft});

  final ProfileDraft draft;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!draft.isEditing) {
      return SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: () => ref.read(profileDraftProvider.notifier).state =
              draft.copyWith(isEditing: true),
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Edit profile'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      );
    }
    if (!draft.hasChanges) return const SizedBox.shrink();
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: () => _save(context, ref),
        icon: const Icon(Icons.check_rounded),
        label: const Text('Save changes'),
      ),
    );
  }

  Future<void> _save(BuildContext context, WidgetRef ref) async {
    final email = draft.email.trim();
    if (email.isNotEmpty && !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid email')));
      return;
    }
    try {
      final name = draft.name.trim();
      final walletName = draft.walletName.trim();
      final userId = ref.read(currentUserIdProvider);
      final helper = ref.read(databaseHelperProvider);
      await helper.setSetting('profile_name_$userId', name);
      await helper.setSetting('profile_email_$userId', email);
      if (draft.walletId != null) {
        final wallets = await ref.read(walletsProvider.future);
        final wallet = wallets.where((w) => w.id == draft.walletId).firstOrNull;
        if (wallet != null) {
          await ref
              .read(walletsProvider.notifier)
              .updateWallet(wallet.copyWith(name: walletName));
        }
      }
      ref.read(profileDraftProvider.notifier).state = ProfileDraft(
        name: name,
        email: email,
        walletName: walletName,
        savedName: name,
        savedEmail: email,
        savedWalletName: walletName,
        walletId: draft.walletId,
        isInitialized: true,
        isLoading: false,
      );
      if (context.mounted) {
        showSuccessSnackBar(context, 'Profile updated successfully');
      }
    } catch (error) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }
}
