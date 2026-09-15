import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/app_snackbars.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/wallet_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/transaction_provider.dart';
import '../../../providers/wallet_provider.dart';
import 'transfer_providers.dart';

class TransferBottomSheet extends ConsumerWidget {
  const TransferBottomSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallets = ref.watch(walletsProvider).value ?? const <WalletModel>[];
    final symbol = ref.watch(currencySymbolProvider).value ?? '\$';
    final colors = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final draft = ref.watch(transferDraftProvider);

    // Initialize default source and destination wallets if not set
    if (wallets.isNotEmpty && draft.fromWalletId == null && draft.toWalletId == null) {
      final currentSelected = ref.read(selectedWalletIdProvider);
      final fromId = (currentSelected != null && wallets.any((w) => w.id == currentSelected))
          ? currentSelected
          : wallets.first.id;
      final otherWallets = wallets.where((w) => w.id != fromId).toList();
      final toId = otherWallets.isNotEmpty ? otherWallets.first.id : null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(transferDraftProvider.notifier).initWallets(fromId, toId);
      });
    }

    final fromWallet = wallets.where((w) => w.id == draft.fromWalletId).firstOrNull;
    final toWallet = wallets.where((w) => w.id == draft.toWalletId).firstOrNull;

    if (wallets.length < 2) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.info_outline, size: 48, color: Colors.orange),
            const SizedBox(height: 16),
            const Text(
              'At least two wallets are required to perform a transfer.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, bottomInset + 20),
      child: ListView(
        shrinkWrap: true,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: colors.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            'Transfer Funds',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          // Source Wallet
          _buildWalletSelector(
            context: context,
            label: 'From Account',
            selectedWallet: fromWallet,
            wallets: wallets,
            symbol: symbol,
            onSelected: (id) {
              ref.read(transferDraftProvider.notifier).setFromWallet(id);
              if (id == draft.toWalletId) {
                final alternate = wallets.firstWhere((w) => w.id != id);
                ref.read(transferDraftProvider.notifier).setToWallet(alternate.id);
              }
            },
          ),
          const SizedBox(height: 12),

          // Swap icon
          Center(
            child: IconButton(
              icon: const Icon(Icons.swap_vert_rounded),
              onPressed: () {
                if (draft.fromWalletId != null && draft.toWalletId != null) {
                  final prevFrom = draft.fromWalletId!;
                  final prevTo = draft.toWalletId!;
                  ref.read(transferDraftProvider.notifier).setFromWallet(prevTo);
                  ref.read(transferDraftProvider.notifier).setToWallet(prevFrom);
                }
              },
            ),
          ),
          const SizedBox(height: 12),

          // Destination Wallet
          _buildWalletSelector(
            context: context,
            label: 'To Account',
            selectedWallet: toWallet,
            wallets: wallets,
            symbol: symbol,
            onSelected: (id) {
              ref.read(transferDraftProvider.notifier).setToWallet(id);
              if (id == draft.fromWalletId) {
                final alternate = wallets.firstWhere((w) => w.id != id);
                ref.read(transferDraftProvider.notifier).setFromWallet(alternate.id);
              }
            },
          ),
          const SizedBox(height: 16),

          // Amount Field
          TextFormField(
            initialValue: draft.amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Transfer Amount',
              prefixText: '$symbol ',
              filled: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onChanged: (val) => ref.read(transferDraftProvider.notifier).setAmount(val),
          ),
          const SizedBox(height: 16),

          // Date Picker Tile
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.calendar_today_rounded),
            title: const Text('Transfer Date', style: TextStyle(fontSize: 13)),
            subtitle: Text(
              Formatters.date(draft.date),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: draft.date,
                firstDate: DateTime(2000),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (picked != null) {
                ref.read(transferDraftProvider.notifier).setDate(picked);
              }
            },
          ),
          const SizedBox(height: 12),

          // Note (Optional)
          TextFormField(
            initialValue: draft.note,
            decoration: InputDecoration(
              labelText: 'Note (Optional)',
              hintText: 'e.g. ATM cash withdrawal, emergency fund deposit',
              filled: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onChanged: (val) => ref.read(transferDraftProvider.notifier).setNote(val),
          ),
          const SizedBox(height: 24),

          // Submit Button
          SizedBox(
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryEmerald,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: draft.isLoading
                  ? null
                  : () => _submitTransfer(context, ref, draft),
              child: draft.isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text(
                      'Confirm Transfer',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletSelector({
    required BuildContext context,
    required String label,
    required WalletModel? selectedWallet,
    required List<WalletModel> wallets,
    required String symbol,
    required ValueChanged<String> onSelected,
  }) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: selectedWallet?.id,
              icon: const Icon(Icons.keyboard_arrow_down_rounded),
              items: wallets.map((w) {
                return DropdownMenuItem<String>(
                  value: w.id,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(w.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(
                        Formatters.currency(w.balance, symbol: '$symbol '),
                        style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (id) {
                if (id != null) onSelected(id);
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitTransfer(
    BuildContext context,
    WidgetRef ref,
    TransferDraft draft,
  ) async {
    if (draft.fromWalletId == null || draft.toWalletId == null) return;
    if (draft.fromWalletId == draft.toWalletId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Source and destination accounts must be different')),
      );
      return;
    }

    final amount = double.tryParse(draft.amount.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid transfer amount')),
      );
      return;
    }

    ref.read(transferDraftProvider.notifier).setLoading(true);
    try {
      await ref.read(transactionsProvider.notifier).transfer(
            fromWalletId: draft.fromWalletId!,
            toWalletId: draft.toWalletId!,
            amount: amount,
            note: draft.note.trim().isEmpty ? null : draft.note.trim(),
            date: draft.date,
          );
      if (!context.mounted) return;
      Navigator.of(context).pop('transferred');
      showSuccessSnackBar(context, 'Transfer completed successfully');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorHandler.message(e))),
        );
      }
    } finally {
      ref.read(transferDraftProvider.notifier).setLoading(false);
    }
  }
}
