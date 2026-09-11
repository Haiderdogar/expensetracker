import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../models/transaction_model.dart';

final transactionSearchProvider = StateProvider.autoDispose<String>((ref) => '');
final transactionTypeFilterProvider = StateProvider.autoDispose<String?>(
  (ref) => null,
);

/// Unified category filter state across all transactions.
final selectedCategoryFiltersProvider = StateProvider.autoDispose<List<String>?>(
  (ref) => null,
);

/// Backwards-compatible aliases
final activeCategoryFilterProvider = selectedCategoryFiltersProvider;
final transactionCategoryFilterProvider = selectedCategoryFiltersProvider;

/// Remove a single category filter
void removeCategoryFilter(WidgetRef ref, String categoryId) {
  final current = ref.read(selectedCategoryFiltersProvider);
  if (current == null) return;
  final updated = current.where((id) => id != categoryId).toList();
  ref.read(selectedCategoryFiltersProvider.notifier).state =
      updated.isEmpty ? null : updated;
}

/// Clear all category filters belonging to a specific type ('expense' or 'income')
void clearCategoryFiltersByType(
  WidgetRef ref,
  String type,
  List<dynamic> allCategories,
) {
  final current = ref.read(selectedCategoryFiltersProvider);
  if (current == null) return;
  final typeIds = allCategories
      .where((c) => c.type == type)
      .map((c) => c.id as String)
      .toSet();
  final updated = current.where((id) => !typeIds.contains(id)).toList();
  ref.read(selectedCategoryFiltersProvider.notifier).state =
      updated.isEmpty ? null : updated;
}

/// Clear all category filters
void clearAllCategoryFilters(WidgetRef ref) {
  ref.read(selectedCategoryFiltersProvider.notifier).state = null;
}

/// Backwards-compatible helpers
void setCategoryFilterForCurrentType(WidgetRef ref, List<String>? categories) {
  ref.read(selectedCategoryFiltersProvider.notifier).state =
      (categories == null || categories.isEmpty) ? null : categories;
}

void removeCategoryFilterForCurrentType(WidgetRef ref, String categoryId) {
  removeCategoryFilter(ref, categoryId);
}

void clearCategoryFilterForCurrentType(WidgetRef ref) {
  clearAllCategoryFilters(ref);
}

final transactionCategoryFilterDraftProvider =
    StateProvider.autoDispose<List<String>>((ref) => []);

/// Holds form state for a single transaction type (expense or income).
class TypeDraft {
  const TypeDraft({
    this.categoryId,
    this.subcategory,
    this.amount = '',
  });

  final String? categoryId;
  final String? subcategory;
  final String amount;

  TypeDraft copyWith({
    String? categoryId,
    String? subcategory,
    String? amount,
  }) {
    return TypeDraft(
      categoryId: categoryId ?? this.categoryId,
      subcategory: subcategory ?? this.subcategory,
      amount: amount ?? this.amount,
    );
  }

  TypeDraft clearCategory() => TypeDraft(amount: amount);

  TypeDraft selectCategory(String id) =>
      TypeDraft(categoryId: id, amount: amount);
}

class TransactionFormDraft {
  const TransactionFormDraft({
    required this.type,
    required this.expenseDraft,
    required this.incomeDraft,
    required this.date,
    required this.note,
    this.isSaving = false,
  });

  factory TransactionFormDraft.fromTransaction(TransactionModel? transaction) {
    final type = transaction?.type;
    final activeType = type == 'income' || type == 'expense' ? type! : 'expense';
    final catId = transaction?.categoryId.isNotEmpty == true
        ? transaction!.categoryId
        : null;
    final sub = transaction?.subcategory.isNotEmpty == true
        ? transaction!.subcategory
        : null;
    final amt = transaction?.amount.toString() ?? '';

    final expenseDraft = activeType == 'expense'
        ? TypeDraft(categoryId: catId, subcategory: sub, amount: amt)
        : const TypeDraft();
    final incomeDraft = activeType == 'income'
        ? TypeDraft(categoryId: catId, subcategory: sub, amount: amt)
        : const TypeDraft();

    return TransactionFormDraft(
      type: activeType,
      expenseDraft: expenseDraft,
      incomeDraft: incomeDraft,
      date: DateTime.tryParse(transaction?.date ?? '') ?? DateTime.now(),
      note: transaction?.note ?? '',
    );
  }

  final String type;
  final TypeDraft expenseDraft;
  final TypeDraft incomeDraft;
  final DateTime date;
  final String note;
  final bool isSaving;

  // ── Convenience accessors for the currently active tab ────────────────────

  TypeDraft get _active => type == 'income' ? incomeDraft : expenseDraft;

  String? get categoryId => _active.categoryId;
  String? get subcategory => _active.subcategory;
  String get amount => _active.amount;

  // ── Mutators ─────────────────────────────────────────────────────────────

  TransactionFormDraft _withActive(TypeDraft updated) {
    return TransactionFormDraft(
      type: type,
      expenseDraft: type == 'expense' ? updated : expenseDraft,
      incomeDraft: type == 'income' ? updated : incomeDraft,
      date: date,
      note: note,
      isSaving: isSaving,
    );
  }

  /// Switch to a different type; preserves each tab's own state.
  TransactionFormDraft switchType(String newType) {
    return TransactionFormDraft(
      type: newType,
      expenseDraft: expenseDraft,
      incomeDraft: incomeDraft,
      date: date,
      note: note,
      isSaving: isSaving,
    );
  }

  TransactionFormDraft copyWith({
    String? type,
    String? categoryId,
    String? subcategory,
    String? amount,
    DateTime? date,
    String? note,
    bool? isSaving,
  }) {
    var draft = this;
    if (type != null && type != this.type) {
      draft = draft.switchType(type);
    }
    var active = draft._active;
    if (categoryId != null) active = active.copyWith(categoryId: categoryId);
    if (subcategory != null) active = active.copyWith(subcategory: subcategory);
    if (amount != null) active = active.copyWith(amount: amount);
    return draft._withActive(active).copyWith2(
      date: date,
      note: note,
      isSaving: isSaving,
    );
  }

  /// Internal helper to update top-level fields without recursion.
  TransactionFormDraft copyWith2({
    DateTime? date,
    String? note,
    bool? isSaving,
  }) {
    return TransactionFormDraft(
      type: type,
      expenseDraft: expenseDraft,
      incomeDraft: incomeDraft,
      date: date ?? this.date,
      note: note ?? this.note,
      isSaving: isSaving ?? this.isSaving,
    );
  }

  TransactionFormDraft clearCategory() => _withActive(_active.clearCategory());

  TransactionFormDraft selectCategory(String categoryId) =>
      _withActive(_active.selectCategory(categoryId));
}

final transactionFormProvider = StateProvider.autoDispose
    .family<TransactionFormDraft, TransactionModel?>(
      (ref, transaction) => TransactionFormDraft.fromTransaction(transaction),
    );
