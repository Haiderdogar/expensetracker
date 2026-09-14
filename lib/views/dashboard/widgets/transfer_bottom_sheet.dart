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

class TransferBottomSheet extends ConsumerStatefulWidget {
  const TransferBottomSheet({super.key});

  @override
  ConsumerState<TransferBottomSheet> createState() => _TransferBottomSheetState();
}

class _TransferBottomSheetState extends ConsumerState<TransferBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  String? _fromWalletId;
  String? _toWalletId;
  DateTime _date = DateTime.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final currentSelected = ref.read(selectedWalletIdProvider);
    final wallets = ref.read(walletsProvider).value ?? const <WalletModel>[];

    if (wallets.isNotEmpty) {
      if (currentSelected != null && wallets.any((w) => w.id == currentSelected)) {
        _fromWalletId = currentSelected;
      } else {
        _fromWalletId = wallets.first.id;
      }

      final otherWallets = wallets.where((w) => w.id != _fromWalletId).toList();
      if (otherWallets.isNotEmpty) {
        _toWalletId = otherWallets.first.id;
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wallets = ref.watch(walletsProvider).value ?? const <WalletModel>[];
    final symbol = ref.watch(currencySymbolProvider).value ?? '\$';
    final colors = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    final fromWallet = wallets.where((w) => w.id == _fromWalletId).firstOrNull;
    final toWallet = wallets.where((w) => w.id == _toWalletId).firstOrNull;

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
      child: Form(
        key: _formKey,
        child: ListView(
          shrinkWrap: true,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: colors.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Transfer Between Wallets',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Source Wallet ("From")
            _buildWalletSelector(
              label: 'From Account',
              selectedWallet: fromWallet,
              wallets: wallets,
              symbol: symbol,
              onSelected: (id) {
                setState(() {
                  _fromWalletId = id;
                  if (_toWalletId == id) {
                    _toWalletId = wallets.firstWhere((w) => w.id != id).id;
                  }
                });
              },
            ),

            // Swap icon indicator
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Center(
                child: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerHighest,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.swap_vert_rounded, color: colors.primary, size: 22),
                  ),
                  tooltip: 'Swap accounts',
                  onPressed: () {
                    setState(() {
                      final temp = _fromWalletId;
                      _fromWalletId = _toWalletId;
                      _toWalletId = temp;
                    });
                  },
                ),
              ),
            ),

            // Target Wallet ("To")
            _buildWalletSelector(
              label: 'To Account',
              selectedWallet: toWallet,
              wallets: wallets.where((w) => w.id != _fromWalletId).toList(),
              symbol: symbol,
              onSelected: (id) {
                setState(() {
                  _toWalletId = id;
                });
              },
            ),
            const SizedBox(height: 20),

            // Amount Input
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Transfer Amount',
                prefixText: '$symbol ',
                prefixStyle: TextStyle(
                  color: colors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              validator: (val) {
                if (val == null || val.trim().isEmpty) return 'Please enter an amount';
                final amount = double.tryParse(val.trim());
                if (amount == null || amount <= 0) return 'Please enter a valid positive amount';
                if (fromWallet != null && amount > fromWallet.balance) {
                  return 'Insufficient funds (Available: ${Formatters.currency(fromWallet.balance, symbol: symbol)})';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),

            // Quick Preset Amount Chips
            if (fromWallet != null && fromWallet.balance > 0)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final preset in [25, 50, 100, 250])
                      if (preset <= fromWallet.balance)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ActionChip(
                            label: Text('+$symbol$preset'),
                            onPressed: () {
                              _amountController.text = preset.toString();
                            },
                          ),
                        ),
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ActionChip(
                        label: const Text('All Balance'),
                        onPressed: () {
                          _amountController.text = fromWallet.balance.toStringAsFixed(2);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),

            // Date picker tile
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: colors.outlineVariant),
              ),
              leading: Icon(Icons.calendar_today_rounded, color: colors.primary),
              title: const Text('Transfer Date', style: TextStyle(fontSize: 13)),
              subtitle: Text(
                Formatters.date(_date),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) setState(() => _date = picked);
              },
            ),
            const SizedBox(height: 12),

            // Note (Optional)
            TextFormField(
              controller: _noteController,
              decoration: InputDecoration(
                labelText: 'Note (Optional)',
                hintText: 'e.g. ATM cash withdrawal, emergency fund deposit',
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
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
                onPressed: _isLoading ? null : _submitTransfer,
                child: _isLoading
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
      ),
    );
  }

  Widget _buildWalletSelector({
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

  Future<void> _submitTransfer() async {
    if (!_formKey.currentState!.validate()) return;
    if (_fromWalletId == null || _toWalletId == null) return;
    if (_fromWalletId == _toWalletId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Source and destination accounts must be different')),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(transactionsProvider.notifier).transfer(
            fromWalletId: _fromWalletId!,
            toWalletId: _toWalletId!,
            amount: amount,
            note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
            date: _date,
          );
      if (!mounted) return;
      Navigator.of(context).pop('transferred');
      showSuccessSnackBar(context, 'Transfer completed successfully');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorHandler.message(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
