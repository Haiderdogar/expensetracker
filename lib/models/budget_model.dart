class BudgetModel {
  const BudgetModel({
    required this.id,
    this.userId = 'default_user',
    required this.categoryId,
    required this.amount,
    required this.monthYear,
    this.isSynced = false,
    this.updatedAt,
  });

  final String id;
  final String userId;
  final String categoryId;
  final double amount;
  final String monthYear;
  final bool isSynced;
  final String? updatedAt;

  BudgetModel copyWith({
    String? id,
    String? userId,
    String? categoryId,
    double? amount,
    String? monthYear,
    bool? isSynced,
    String? updatedAt,
  }) {
    return BudgetModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      categoryId: categoryId ?? this.categoryId,
      amount: amount ?? this.amount,
      monthYear: monthYear ?? this.monthYear,
      isSynced: isSynced ?? this.isSynced,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'category_id': categoryId,
        'amount': amount,
        'month_year': monthYear,
        'is_synced': isSynced ? 1 : 0,
        'updated_at': updatedAt ?? DateTime.now().toUtc().toIso8601String(),
      };

  Map<String, dynamic> toFirestore() => {
        'id': id,
        'userId': userId,
        'categoryId': categoryId,
        'amount': amount,
        'monthYear': monthYear,
        'updatedAt': updatedAt ?? DateTime.now().toUtc().toIso8601String(),
      };

  factory BudgetModel.fromMap(Map<String, dynamic> map) {
    return BudgetModel(
      id: map['id'] as String,
      userId: (map['user_id'] as String?) ?? 'default_user',
      categoryId: map['category_id'] as String,
      amount: (map['amount'] as num).toDouble(),
      monthYear: map['month_year'] as String,
      isSynced: (map['is_synced'] as int?) == 1,
      updatedAt: map['updated_at'] as String?,
    );
  }

  factory BudgetModel.fromFirestore(Map<String, dynamic> data, String docId) {
    return BudgetModel(
      id: (data['id'] as String?) ?? docId,
      userId: (data['userId'] as String?) ?? 'default_user',
      categoryId: (data['categoryId'] as String?) ?? '',
      amount: ((data['amount'] as num?) ?? 0).toDouble(),
      monthYear: (data['monthYear'] as String?) ?? '',
      isSynced: true,
      updatedAt: data['updatedAt'] as String?,
    );
  }
}
