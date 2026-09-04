class TransactionModel {
  const TransactionModel({
    required this.id,
    required this.subcategory,
    required this.amount,
    required this.type,
    required this.categoryId,
    required this.walletId,
    required this.date,
    this.note,
  });

  final String id;
  final String subcategory;
  final double amount;
  final String type;
  final String categoryId;
  final String walletId;
  final String date;
  final String? note;

  bool get isIncome => type == 'income';
  bool get isExpense => type == 'expense';

  TransactionModel copyWith({
    String? id,
    String? subcategory,
    double? amount,
    String? type,
    String? categoryId,
    String? walletId,
    String? date,
    String? note,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      subcategory: subcategory ?? this.subcategory,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      categoryId: categoryId ?? this.categoryId,
      walletId: walletId ?? this.walletId,
      date: date ?? this.date,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        // Keep the legacy column populated for databases upgraded from v2.
        'title': subcategory,
        'subcategory': subcategory,
        'amount': amount,
        'type': type,
        'category_id': categoryId,
        'wallet_id': walletId,
        'date': date,
        'note': note,
      };

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as String,
      subcategory: (map['subcategory'] as String?)?.trim().isNotEmpty == true
          ? map['subcategory'] as String
          : (map['title'] as String?) ?? '',
      amount: (map['amount'] as num).toDouble(),
      type: map['type'] as String,
      categoryId: map['category_id'] as String,
      walletId: map['wallet_id'] as String,
      date: map['date'] as String,
      note: map['note'] as String?,
    );
  }
}
