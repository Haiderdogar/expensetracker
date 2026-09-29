import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/app_snackbars.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/database_provider.dart';
import '../../../features/wallet_currency/providers/wallet_provider.dart';
import '../profile_draft_provider.dart';

class ProfileActions extends ConsumerWidget {
  const ProfileActions({super.key, required this.draft});

  final ProfileDraft draft;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!draft.isGoogleAccount) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton.icon(
            onPressed: () => _upgrade(context, ref),
            icon: const Icon(Icons.account_circle_outlined),
            label: const Text('Connect Google account'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 15),
            ),
          ),
          const SizedBox(height: 10),
          _editButton(context, ref),
        ],
      );
    }
    return _editButton(context, ref);
  }

  Widget _editButton(BuildContext context, WidgetRef ref) {
    if (!draft.isEditing) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () => ref.read(profileDraftProvider.notifier).state = draft
              .copyWith(isEditing: true),
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Edit profile details'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
        ),
      );
    }
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: draft.hasChanges ? () => _save(context, ref) : null,
        icon: Icon(
          draft.hasChanges ? Icons.check_rounded : Icons.edit_note_rounded,
        ),
        label: Text(draft.hasChanges ? 'Save changes' : 'No changes to save'),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
    );
  }

  Future<void> _upgrade(BuildContext context, WidgetRef ref) async {
    final result = await ref
        .read(authControllerProvider.notifier)
        .signInWithGoogle();
    if (!context.mounted) return;
    if (result == GoogleSignInResult.success) {
      ref.read(profileDraftProvider.notifier).state = const ProfileDraft();
      showSuccessSnackBar(context, 'Google account connected successfully');
    } else if (result != GoogleSignInResult.cancelled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to connect your Google account')),
      );
    }
  }

  Future<void> _save(BuildContext context, WidgetRef ref) async {
    final email = draft.email.trim();
    if (email.isNotEmpty &&
        !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter a valid email')));
      return;
    }
    try {
      final name = draft.name.trim();
      final walletName = draft.walletName.trim();
      final userId = ref.read(currentUserIdProvider);
      final helper = ref.read(databaseHelperProvider);
      await helper.setSetting('profile_name_$userId', name);
      if (!draft.isGoogleAccount) {
        await helper.setSetting('profile_email_$userId', '');
      }
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
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }
}
