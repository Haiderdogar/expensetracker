import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/router/app_router.dart';
import '../../../features/google_sign_in/providers/auth_provider.dart';
import '../../../app/app_startup.dart';
import '../../app_shell/app_shell_providers.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/backup_provider.dart';
import '../../../providers/budget_provider.dart';
import '../../../providers/category_provider.dart';
import '../../../features/wallet_currency/providers/currency_provider.dart';
import '../../../providers/database_provider.dart';
import '../../../providers/note_provider.dart';
import '../../../providers/transaction_provider.dart';
import '../../../features/wallet_currency/providers/wallet_provider.dart';

class SettingsAccountSection extends ConsumerStatefulWidget {
  const SettingsAccountSection({super.key});

  @override
  ConsumerState<SettingsAccountSection> createState() =>
      _SettingsAccountSectionState();
}

class _SettingsAccountSectionState
    extends ConsumerState<SettingsAccountSection> {
  bool _isDeleting = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? colors.error.withValues(alpha: 0.07)
            : colors.errorContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colors.error.withValues(alpha: isDark ? 0.18 : 0.25),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            // ── Icon ─────────────────────────────────────────────────────
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: colors.error.withValues(alpha: isDark ? 0.22 : 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: _isDeleting
                  ? Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: colors.error,
                        ),
                      ),
                    )
                  : Icon(
                      Icons.delete_forever_rounded,
                      size: 22,
                      color: colors.error,
                    ),
            ),
            const SizedBox(width: 12),
            // ── Label ────────────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.deleteAccount,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colors.error,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Permanently removes all data',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // ── Button ───────────────────────────────────────────────────
            FilledButton(
              onPressed: _isDeleting ? null : () => _confirmAndDelete(context),
              style: FilledButton.styleFrom(
                backgroundColor: colors.error,
                foregroundColor: colors.onError,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: const Text('Delete'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmAndDelete(BuildContext context) async {
    // ── Step 1: First confirmation dialog ──────────────────────────────────
    final firstConfirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: Icon(
          Icons.warning_amber_rounded,
          color: Theme.of(ctx).colorScheme.error,
          size: 36,
        ),
        title: const Text(
          AppStrings.deleteAccountConfirmTitle,
          textAlign: TextAlign.center,
        ),
        content: const Text(
          AppStrings.deleteAccountConfirmBody,
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(AppStrings.cancel),
          ),
          const SizedBox(width: 8),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );

    if (firstConfirmed != true || !context.mounted) return;

    // ── Step 2: Final type-to-confirm dialog ───────────────────────────────
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const _DeleteConfirmDialog(),
    );

    if (confirmed != true || !context.mounted) return;

    // ── Step 3: Perform deletion ───────────────────────────────────────────
    setState(() => _isDeleting = true);

    try {
      final result = await ref
          .read(authControllerProvider.notifier)
          .deleteAccountAndData();

      if (!context.mounted) return;

      switch (result) {
        case DeleteAccountResult.success:
          _invalidateAccountScopedProviders();
          ref.invalidate(appStartupControllerProvider);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppStrings.deleteAccountSuccess),
              backgroundColor: AppColors.incomeGreen,
            ),
          );
          if (context.mounted) {
            context.go(AppRoutes.bootstrap);
          }
        case DeleteAccountResult.incorrectEmail:
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppStrings.deleteAccountWrongEmail)),
          );
        case DeleteAccountResult.reauthFailed:
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppStrings.deleteAccountReauthFailed)),
          );
        case DeleteAccountResult.failed:
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppStrings.deleteAccountFailed)),
          );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  void _invalidateAccountScopedProviders() {
    ref.invalidate(transactionsProvider);
    ref.invalidate(categoriesProvider);
    ref.invalidate(walletsProvider);
    ref.invalidate(budgetsProvider);
    ref.invalidate(notesProvider);
    ref.invalidate(backupServiceProvider);
    ref.invalidate(selectedWalletIdProvider);
    ref.invalidate(currencySymbolProvider);
    ref.invalidate(currencyCodeProvider);
    ref.invalidate(currentUserProvider);
    ref.invalidate(currentUserIdProvider);
    ref.invalidate(appShellProfileProvider);
    ref.read(appShellNavigationIndexProvider.notifier).state = 0;
    ref.read(appShellVisitedIndexesProvider.notifier).state = {0};
  }
}

class _DeleteConfirmDialog extends StatefulWidget {
  const _DeleteConfirmDialog();

  @override
  State<_DeleteConfirmDialog> createState() => _DeleteConfirmDialogState();
}

class _DeleteConfirmDialogState extends State<_DeleteConfirmDialog> {
  late final TextEditingController _typeController;
  late final FocusNode _focusNode;
  bool _isMatch = false;

  @override
  void initState() {
    super.initState();
    _typeController = TextEditingController();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _typeController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged(String value) {
    final matches = value.trim().toUpperCase() == 'DELETE';
    if (_isMatch != matches) {
      setState(() => _isMatch = matches);
    }
  }

  void _handleConfirm() {
    if (!_isMatch) return;
    _focusNode.unfocus();
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: const Text('Confirm Deletion'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Type DELETE to confirm',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _typeController,
              focusNode: _focusNode,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                hintText: 'DELETE',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: _onTextChanged,
              onSubmitted: (_) => _handleConfirm(),
            ),
          ],
        ),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        OutlinedButton(
          onPressed: () {
            _focusNode.unfocus();
            Navigator.of(context).pop(false);
          },
          child: const Text(AppStrings.cancel),
        ),
        const SizedBox(width: 8),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: _isMatch
                ? colors.error
                : colors.error.withValues(alpha: 0.4),
          ),
          onPressed: _isMatch ? _handleConfirm : null,
          child: const Text('Delete Forever'),
        ),
      ],
    );
  }
}
