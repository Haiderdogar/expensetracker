import 'package:flutter/material.dart';

import '../profile_draft_provider.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key, required this.draft});

  final ProfileDraft draft;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final name = draft.name.trim();
    final wallet = draft.walletName.trim();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: BoxDecoration(color: colors.primaryContainer, borderRadius: BorderRadius.circular(24)),
      child: Column(
        children: [
          CircleAvatar(
            radius: 42,
            backgroundColor: colors.primary,
            child: Text(
              name.isEmpty ? 'U' : name[0].toUpperCase(),
              style: TextStyle(color: colors.onPrimary, fontSize: 34, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            name.isEmpty ? 'Your profile' : name,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: colors.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            wallet.isEmpty ? 'Set up your wallet' : wallet,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colors.onPrimaryContainer.withValues(alpha: 0.72),
            ),
          ),
        ],
      ),
    );
  }
}
