import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../models/transaction_model.dart';

part 'transactions_ui_providers.g.dart';

/// A generated provider-backed controller for the transaction search field.
///
/// The controller is disposed with the provider, keeping ephemeral widget input
/// out of stateful widgets while still using Riverpod code generation.
@riverpod
TextEditingController transactionSearchTextController(Ref ref) {
  final controller =
      TextEditingController(text: ref.read(transactionSearchProvider));
  ref.onDispose(controller.dispose);
  return controller;
}

@riverpod
class TransactionSearch extends _$TransactionSearch {
  @override
  String build() => '';

  @override
  set state(String value) => super.state = value;
}

@riverpod
class TransactionTypeFilter extends _$TransactionTypeFilter {
  @override
  String? build() => null;

  @override
  set state(String? value) => super.state = value;
}

@riverpod
class SelectedCategoryFilters extends _$SelectedCategoryFilters {
  @override
  List<String>? build() => null;

  @override
  set state(List<String>? value) => super.state = value;
}

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

@riverpod
class TransactionCategoryFilterDraft extends _$TransactionCategoryFilterDraft {
  @override
  List<String> build() => [];

  @override
  set state(List<String> value) => super.state = value;
}

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

  factory TransactionFormDraft.fromTransaction(
    TransactionModel? transaction, {
    String? initialType,
  }) {
    final type = transaction?.type ?? initialType;
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

  TypeDraft get _active => type == 'income' ? incomeDraft : expenseDraft;

  String? get categoryId => _active.categoryId;
  String? get subcategory => _active.subcategory;
  String get amount => _active.amount;

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

@riverpod
class TransactionInitialType extends _$TransactionInitialType {
  @override
  String build() => 'expense';

  @override
  set state(String value) => super.state = value;
}

@riverpod
class TransactionFormNotifier extends _$TransactionFormNotifier {
  @override
  TransactionFormDraft build(TransactionModel? transaction) {
    final initialType = ref.watch(transactionInitialTypeProvider);
    return TransactionFormDraft.fromTransaction(
      transaction,
      initialType: initialType,
    );
  }

  @override
  set state(TransactionFormDraft value) => super.state = value;
}

@riverpod
class UnifiedCategoryFilterDraft extends _$UnifiedCategoryFilterDraft {
  @override
  Set<String> build() => {};

  void init(List<String>? initial) =>
      state = Set<String>.from(initial ?? const []);

  void toggle(String id) {
    if (state.contains(id)) {
      state = Set<String>.from(state)..remove(id);
    } else {
      state = Set<String>.from(state)..add(id);
    }
  }

  void setAll(Iterable<String> ids, bool select) {
    final next = Set<String>.from(state);
    if (select) {
      next.addAll(ids);
    } else {
      next.removeAll(ids);
    }
    state = next;
  }

  void clear() => state = {};
}
