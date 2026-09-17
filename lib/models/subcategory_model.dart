class SubcategoryModel {
  const SubcategoryModel({
    required this.id,
    this.userId = 'default_user',
    this.walletId = '',
    required this.categoryId,
    required this.name,
    this.isSynced = false,
    this.updatedAt,
  });

  final String id;
  final String userId;
  final String walletId;
  final String categoryId;
  final String name;
  final bool isSynced;
  final String? updatedAt;

  SubcategoryModel copyWith({
    String? id,
    String? userId,
    String? walletId,
    String? categoryId,
    String? name,
    bool? isSynced,
    String? updatedAt,
  }) {
    return SubcategoryModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      walletId: walletId ?? this.walletId,
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      isSynced: isSynced ?? this.isSynced,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'wallet_id': walletId,
        'category_id': categoryId,
        'name': name,
        'is_synced': isSynced ? 1 : 0,
        'updated_at': updatedAt ?? DateTime.now().toUtc().toIso8601String(),
      };

  Map<String, dynamic> toFirestore() => {
        'categoryId': categoryId,
        'name': name,
        'updatedAt': updatedAt ?? DateTime.now().toUtc().toIso8601String(),
      };

  factory SubcategoryModel.fromMap(Map<String, dynamic> map) {
    return SubcategoryModel(
      id: map['id'] as String,
      userId: (map['user_id'] as String?) ?? 'default_user',
      walletId: (map['wallet_id'] as String?) ?? '',
      categoryId: map['category_id'] as String,
      name: map['name'] as String,
      isSynced: (map['is_synced'] as int?) == 1,
      updatedAt: map['updated_at'] as String?,
    );
  }

  factory SubcategoryModel.fromFirestore(Map<String, dynamic> data, String docId) {
    return SubcategoryModel(
      id: docId,
      userId: 'default_user',
      walletId: '',
      categoryId: (data['categoryId'] as String?) ?? '',
      name: (data['name'] as String?) ?? '',
      isSynced: true,
      updatedAt: data['updatedAt'] as String?,
    );
  }
}
