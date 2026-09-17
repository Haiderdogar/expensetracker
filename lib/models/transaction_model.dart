class TransactionModel {
  const TransactionModel({
    required this.id,
    this.userId = 'default_user',
    required this.subcategory,
    required this.amount,
    required this.type,
    required this.categoryId,
    required this.walletId,
    required this.date,
    this.note,
    this.isSynced = false,
    this.updatedAt,
  });

  final String id;
  final String userId;
  final String subcategory;
  final double amount;
  final String type;
  final String categoryId;
  final String walletId;
  final String date;
  final String? note;
  final bool isSynced;
  final String? updatedAt;

  bool get isIncome => type == 'income';
  bool get isExpense => type == 'expense';

  TransactionModel copyWith({
    String? id,
    String? userId,
    String? subcategory,
    double? amount,
    String? type,
    String? categoryId,
    String? walletId,
    String? date,
    String? note,
    bool? isSynced,
    String? updatedAt,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      subcategory: subcategory ?? this.subcategory,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      categoryId: categoryId ?? this.categoryId,
      walletId: walletId ?? this.walletId,
      date: date ?? this.date,
      note: note ?? this.note,
      isSynced: isSynced ?? this.isSynced,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'user_id': userId,
    'title': subcategory,
    'subcategory': subcategory,
    'amount': amount,
    'type': type,
    'category_id': categoryId,
    'wallet_id': walletId,
    'date': date,
    'note': note,
    'is_synced': isSynced ? 1 : 0,
    'updated_at': updatedAt ?? DateTime.now().toUtc().toIso8601String(),
  };

  Map<String, dynamic> toFirestore() => {
    'subcategory': subcategory,
    'amount': amount,
    'type': type,
    'categoryId': categoryId,
    'date': date,
    'note': note,
    'updatedAt': updatedAt ?? DateTime.now().toUtc().toIso8601String(),
  };

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as String,
      userId: (map['user_id'] as String?) ?? 'default_user',
      subcategory: (map['subcategory'] as String?)?.trim().isNotEmpty == true
          ? map['subcategory'] as String
          : (map['title'] as String?) ?? '',
      amount: (map['amount'] as num).toDouble(),
      type: map['type'] as String,
      categoryId: map['category_id'] as String,
      walletId: map['wallet_id'] as String,
      date: map['date'] as String,
      note: map['note'] as String?,
      isSynced: (map['is_synced'] as int?) == 1,
      updatedAt: map['updated_at'] as String?,
    );
  }

  factory TransactionModel.fromFirestore(
    Map<String, dynamic> data,
    String docId,
  ) {
    return TransactionModel(
      id: docId,
      userId: 'default_user',
      subcategory: (data['subcategory'] as String?) ?? '',
      amount: ((data['amount'] as num?) ?? 0).toDouble(),
      type: (data['type'] as String?) ?? 'expense',
      categoryId: (data['categoryId'] as String?) ?? '',
      walletId: '',
      date: (data['date'] as String?) ?? DateTime.now().toIso8601String(),
      note: data['note'] as String?,
      isSynced: true,
      updatedAt: data['updatedAt'] as String?,
    );
  }
}
