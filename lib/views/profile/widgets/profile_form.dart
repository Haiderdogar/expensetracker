import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../profile_draft_provider.dart';

class ProfileForm extends ConsumerWidget {
  const ProfileForm({super.key, required this.draft});

  final ProfileDraft draft;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 17, 16, 18),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.manage_accounts_outlined,
                  color: colors.primary,
                  size: 21,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Personal details',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      draft.isEditing
                          ? 'Update your profile information'
                          : 'Your account and wallet information',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (draft.isEditing)
                Icon(
                  Icons.edit_outlined,
                  size: 17,
                  color: colors.primary,
                ),
            ],
          ),
          const SizedBox(height: 19),
          ProfileTextField(
            label: 'Full name',
            value: draft.name,
            icon: Icons.person_outline_rounded,
            enabled: draft.isEditing,
            onChanged: (value) => _update(ref, draft.copyWith(name: value)),
          ),
          const SizedBox(height: 13),
          ProfileTextField(
            label: 'Email address',
            value: draft.email,
            icon: Icons.email_outlined,
            enabled: false,
            keyboardType: TextInputType.emailAddress,
            onChanged: (_) {},
          ),
          const SizedBox(height: 13),
          ProfileTextField(
            label: 'Wallet name',
            value: draft.walletName,
            icon: Icons.account_balance_wallet_outlined,
            enabled: draft.isEditing && draft.walletId != null,
            onChanged: (value) =>
                _update(ref, draft.copyWith(walletName: value)),
          ),
        ],
      ),
    );
  }

  void _update(WidgetRef ref, ProfileDraft value) {
    ref.read(profileDraftProvider.notifier).state = value;
  }
}

class ProfileTextField extends StatelessWidget {
  const ProfileTextField({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.enabled,
    required this.onChanged,
    this.keyboardType,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool enabled;
  final ValueChanged<String> onChanged;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(15);
    final border = OutlineInputBorder(
      borderRadius: radius,
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
          color: colors.onSurfaceVariant,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Icon(
          icon,
          color: enabled ? colors.primary : colors.onSurfaceVariant,
        ),
        filled: true,
        fillColor: enabled
            ? colors.surface
            : colors.surfaceContainerHighest.withValues(alpha: 0.45),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
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
