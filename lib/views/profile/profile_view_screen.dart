import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../core/constants/app_strings.dart';
import '../../core/database/database_tables.dart';
import '../../providers/database_provider.dart';
import '../../providers/wallet_provider.dart';

class _ProfileDraft {
  const _ProfileDraft({
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
      name.trim() != savedName ||
      email.trim() != savedEmail ||
      walletName.trim() != savedWalletName;

  _ProfileDraft copyWith({
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
    return _ProfileDraft(
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

final _profileDraftProvider = StateProvider.autoDispose<_ProfileDraft>(
  (ref) => const _ProfileDraft(),
);

class ProfileViewScreen extends StatelessWidget {
  const ProfileViewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final draft = ref.watch(_profileDraftProvider);
        if (!draft.isInitialized) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _loadProfile(ref);
          });
        }
        return _ProfileContent(draft: draft);
      },
    );
  }

  static Future<void> _loadProfile(WidgetRef ref) async {
    final notifier = ref.read(_profileDraftProvider.notifier);
    final current = ref.read(_profileDraftProvider);
    if (current.isInitialized) return;
    notifier.state = current.copyWith(isInitialized: true);

    final db = ref.read(databaseHelperProvider);
    final values = await Future.wait<String?>([
      db.getSetting('profile_name'),
      db.getSetting('profile_email'),
    ]);
    final wallets = await ref.read(walletsProvider.future);
    final selectedId = ref.read(selectedWalletIdProvider);
    final matching = wallets
        .where((wallet) => wallet.id == selectedId)
        .toList();
    final wallet = matching.isNotEmpty
        ? matching.first
        : (wallets.isNotEmpty ? wallets.first : null);

    notifier.state = _ProfileDraft(
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
}

class _ProfileContent extends ConsumerWidget {
  const _ProfileContent({required this.draft});

  final _ProfileDraft draft;

  Future<void> _saveProfile(BuildContext context, WidgetRef ref) async {
    final email = draft.email.trim();
    if (email.isNotEmpty &&
        !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter a valid email')));
      return;
    }

    final db = ref.read(databaseHelperProvider);
    final name = draft.name.trim();
    final walletName = draft.walletName.trim();
    await db.setSetting('profile_name', name);
    await db.setSetting('profile_email', email);
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

    ref.read(_profileDraftProvider.notifier).state = _ProfileDraft(
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile saved')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final initial = draft.name.trim().isNotEmpty
        ? draft.name.trim()[0].toUpperCase()
        : 'U';

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text(AppStrings.profile),
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
      ),
      body: draft.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 28,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 42,
                          backgroundColor: colorScheme.primary,
                          child: Text(
                            initial,
                            style: TextStyle(
                              color: colorScheme.onPrimary,
                              fontSize: 34,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          draft.name.trim().isEmpty
                              ? 'Your profile'
                              : draft.name.trim(),
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          draft.walletName.trim().isEmpty
                              ? 'Set up your wallet'
                              : draft.walletName.trim(),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: colorScheme.onPrimaryContainer
                                    .withValues(alpha: 0.72),
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Personal details',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _field(
                    context,
                    label: 'Full name',
                    value: draft.name,
                    icon: Icons.person_outline_rounded,
                    enabled: draft.isEditing,
                    onChanged: (value) =>
                        ref.read(_profileDraftProvider.notifier).state = draft
                            .copyWith(name: value),
                  ),
                  const SizedBox(height: 14),
                  _field(
                    context,
                    label: 'Email address',
                    value: draft.email,
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    enabled: draft.isEditing,
                    onChanged: (value) =>
                        ref.read(_profileDraftProvider.notifier).state = draft
                            .copyWith(email: value),
                  ),
                  const SizedBox(height: 14),
                  _field(
                    context,
                    label: 'Wallet name',
                    value: draft.walletName,
                    icon: Icons.account_balance_wallet_outlined,
                    enabled: draft.isEditing && draft.walletId != null,
                    onChanged: (value) =>
                        ref.read(_profileDraftProvider.notifier).state = draft
                            .copyWith(walletName: value),
                  ),
                  if (!draft.isEditing) ...[
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () =>
                            ref.read(_profileDraftProvider.notifier).state =
                                draft.copyWith(isEditing: true),
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Edit profile'),
                        style: FilledButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                  if (draft.isEditing && draft.hasChanges) ...[
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => _saveProfile(context, ref),
                        icon: const Icon(Icons.check_rounded),
                        label: const Text('Save changes'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _field(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required ValueChanged<String> onChanged,
    TextInputType? keyboardType,
    bool enabled = false,
  }) {
    final colors = Theme.of(context).colorScheme;
    final borderRadius = BorderRadius.circular(16);
    final border = OutlineInputBorder(
      borderRadius: borderRadius,
      borderSide: BorderSide(color: colors.outlineVariant),
    );
    return TextFormField(
      initialValue: value,
      enabled: enabled,
      keyboardType: keyboardType,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: enabled ? colors.onSurfaceVariant : colors.onSurfaceVariant,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Icon(
          icon,
          color: enabled ? colors.primary : colors.onSurfaceVariant,
        ),
        filled: true,
        fillColor: enabled
            ? colors.surfaceContainerHighest
            : colors.surfaceContainerHighest.withValues(alpha: 0.55),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        enabledBorder: border,
        disabledBorder: border.copyWith(
          borderSide: BorderSide(
            color: colors.outlineVariant.withValues(alpha: 0.6),
          ),
        ),
        focusedBorder: border.copyWith(
          borderSide: BorderSide(color: colors.primary, width: 2),
        ),
        errorBorder: border.copyWith(
          borderSide: BorderSide(color: colors.error),
        ),
        focusedErrorBorder: border.copyWith(
          borderSide: BorderSide(color: colors.error, width: 2),
        ),
      ),
    );
  }
}
