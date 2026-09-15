import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'transfer_providers.g.dart';

class TransferDraft {
  const TransferDraft({
    this.fromWalletId,
    this.toWalletId,
    this.amount = '',
    this.note = '',
    required this.date,
    this.isLoading = false,
  });

  final String? fromWalletId;
  final String? toWalletId;
  final String amount;
  final String note;
  final DateTime date;
  final bool isLoading;

  TransferDraft copyWith({
    String? fromWalletId,
    String? toWalletId,
    String? amount,
    String? note,
    DateTime? date,
    bool? isLoading,
  }) {
    return TransferDraft(
      fromWalletId: fromWalletId ?? this.fromWalletId,
      toWalletId: toWalletId ?? this.toWalletId,
      amount: amount ?? this.amount,
      note: note ?? this.note,
      date: date ?? this.date,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

@riverpod
class TransferDraftNotifier extends _$TransferDraftNotifier {
  @override
  TransferDraft build() => TransferDraft(date: DateTime.now());

  void initWallets(String? fromId, String? toId) {
    if (state.fromWalletId == null && state.toWalletId == null) {
      state = state.copyWith(fromWalletId: fromId, toWalletId: toId);
    }
  }

  void setFromWallet(String id) => state = state.copyWith(fromWalletId: id);
  void setToWallet(String id) => state = state.copyWith(toWalletId: id);
  void setAmount(String amount) => state = state.copyWith(amount: amount);
  void setNote(String note) => state = state.copyWith(note: note);
  void setDate(DateTime date) => state = state.copyWith(date: date);
  void setLoading(bool loading) => state = state.copyWith(isLoading: loading);
}
