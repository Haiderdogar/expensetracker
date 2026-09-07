import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../models/transaction_model.dart';

final transactionSearchProvider = StateProvider.autoDispose<String>((ref) => '');
final transactionTypeFilterProvider = StateProvider.autoDispose<String?>(
  (ref) => null,
);
final transactionCategoryFilterProvider = StateProvider.autoDispose<List<String>?>(
  (ref) => null,
);
final transactionCategoryFilterDraftProvider =
    StateProvider.autoDispose<List<String>>((ref) => []);

class TransactionFormDraft {
  const TransactionFormDraft({
    required this.type,
    required this.categoryId,
    required this.subcategory,
    required this.date,
    required this.amount,
    required this.note,
    this.isSaving = false,
  });

  factory TransactionFormDraft.fromTransaction(TransactionModel? transaction) {
    final type = transaction?.type;
    return TransactionFormDraft(
      type: type == 'income' || type == 'expense' ? type! : 'expense',
      categoryId: transaction?.categoryId.isNotEmpty == true
          ? transaction!.categoryId
          : null,
      subcategory: transaction?.subcategory.isNotEmpty == true
          ? transaction!.subcategory
          : null,
      date: DateTime.tryParse(transaction?.date ?? '') ?? DateTime.now(),
      amount: transaction?.amount.toString() ?? '',
      note: transaction?.note ?? '',
    );
  }

  final String type;
  final String? categoryId;
  final String? subcategory;
  final DateTime date;
  final String amount;
  final String note;
  final bool isSaving;

  TransactionFormDraft copyWith({
    String? type,
    String? categoryId,
    String? subcategory,
    DateTime? date,
    String? amount,
    String? note,
    bool? isSaving,
  }) {
    return TransactionFormDraft(
      type: type ?? this.type,
      categoryId: categoryId ?? this.categoryId,
      subcategory: subcategory ?? this.subcategory,
      date: date ?? this.date,
      amount: amount ?? this.amount,
      note: note ?? this.note,
      isSaving: isSaving ?? this.isSaving,
    );
  }

  TransactionFormDraft clearCategory() => TransactionFormDraft(
    type: type,
    categoryId: null,
    subcategory: null,
    date: date,
    amount: amount,
    note: note,
    isSaving: isSaving,
  );

  TransactionFormDraft selectCategory(String categoryId) => TransactionFormDraft(
    type: type,
    categoryId: categoryId,
    subcategory: null,
    date: date,
    amount: amount,
    note: note,
    isSaving: isSaving,
  );
}

final transactionFormProvider = StateProvider.autoDispose
    .family<TransactionFormDraft, TransactionModel?>(
      (ref, transaction) => TransactionFormDraft.fromTransaction(transaction),
    );
