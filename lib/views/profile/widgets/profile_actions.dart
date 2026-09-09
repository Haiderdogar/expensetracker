import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_tables.dart';
import '../../../core/utils/app_snackbars.dart';
import '../../../providers/database_provider.dart';
import '../../../providers/wallet_provider.dart';
import '../profile_draft_provider.dart';

class ProfileActions extends StatelessWidget {
  const ProfileActions({super.key, required this.draft});

  final ProfileDraft draft;

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        if (!draft.isEditing) {
          return SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => ref.read(profileDraftProvider.notifier).state = draft.copyWith(isEditing: true),
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Edit profile'),
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
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
      },
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
      final helper = ref.read(databaseHelperProvider);
      await helper.setSetting('profile_name', name);
      await helper.setSetting('profile_email', email);
      if (draft.walletId != null) {
        final database = await ref.read(databaseProvider.future);
        await database.update(
          DatabaseTables.wallets,
          {'name': walletName},
          where: 'id = ?',
          whereArgs: [draft.walletId],
        );
        ref.invalidate(walletsProvider);
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
