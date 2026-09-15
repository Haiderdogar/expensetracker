class SubcategoryModel {
  const SubcategoryModel({
    required this.id,
    this.userId = 'default_user',
    required this.categoryId,
    required this.name,
    this.isSynced = false,
    this.updatedAt,
  });

  final String id;
  final String userId;
  final String categoryId;
  final String name;
  final bool isSynced;
  final String? updatedAt;

  SubcategoryModel copyWith({
    String? id,
    String? userId,
    String? categoryId,
    String? name,
    bool? isSynced,
    String? updatedAt,
  }) {
    return SubcategoryModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      isSynced: isSynced ?? this.isSynced,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'category_id': categoryId,
        'name': name,
        'is_synced': isSynced ? 1 : 0,
        'updated_at': updatedAt ?? DateTime.now().toUtc().toIso8601String(),
      };

  Map<String, dynamic> toFirestore() => {
        'id': id,
        'userId': userId,
        'categoryId': categoryId,
        'name': name,
        'updatedAt': updatedAt ?? DateTime.now().toUtc().toIso8601String(),
      };

  factory SubcategoryModel.fromMap(Map<String, dynamic> map) {
    return SubcategoryModel(
      id: map['id'] as String,
      userId: (map['user_id'] as String?) ?? 'default_user',
      categoryId: map['category_id'] as String,
      name: map['name'] as String,
      isSynced: (map['is_synced'] as int?) == 1,
      updatedAt: map['updated_at'] as String?,
    );
  }

  factory SubcategoryModel.fromFirestore(Map<String, dynamic> data, String docId) {
    return SubcategoryModel(
      id: (data['id'] as String?) ?? docId,
      userId: (data['userId'] as String?) ?? 'default_user',
      categoryId: (data['categoryId'] as String?) ?? '',
      name: (data['name'] as String?) ?? '',
      isSynced: true,
      updatedAt: data['updatedAt'] as String?,
    );
  }
}
