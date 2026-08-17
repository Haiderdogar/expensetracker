class BudgetModel {
  const BudgetModel({
    required this.id,
    required this.categoryId,
    required this.amount,
    required this.monthYear,
  });

  final String id;
  final String categoryId;
  final double amount;
  final String monthYear;

  BudgetModel copyWith({
    String? id,
    String? categoryId,
    double? amount,
    String? monthYear,
  }) {
    return BudgetModel(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      amount: amount ?? this.amount,
      monthYear: monthYear ?? this.monthYear,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'category_id': categoryId,
        'amount': amount,
        'month_year': monthYear,
      };

  factory BudgetModel.fromMap(Map<String, dynamic> map) {
    return BudgetModel(
      id: map['id'] as String,
      categoryId: map['category_id'] as String,
      amount: (map['amount'] as num).toDouble(),
      monthYear: map['month_year'] as String,
    );
  }
}
