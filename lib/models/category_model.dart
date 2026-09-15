class CategoryModel {
  const CategoryModel({
    required this.id,
    this.userId = 'default_user',
    required this.name,
    required this.type,
    required this.icon,
    required this.color,
    this.isSynced = false,
    this.updatedAt,
  });

  final String id;
  final String userId;
  final String name;
  final String type;
  final String icon;
  final String color;
  final bool isSynced;
  final String? updatedAt;

  bool get isIncome => type == 'income';
  bool get isExpense => type == 'expense';

  CategoryModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? type,
    String? icon,
    String? color,
    bool? isSynced,
    String? updatedAt,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      type: type ?? this.type,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isSynced: isSynced ?? this.isSynced,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'name': name,
        'type': type,
        'icon': icon,
        'color': color,
        'is_synced': isSynced ? 1 : 0,
        'updated_at': updatedAt ?? DateTime.now().toUtc().toIso8601String(),
      };

  Map<String, dynamic> toFirestore() => {
        'id': id,
        'userId': userId,
        'name': name,
        'type': type,
        'icon': icon,
        'color': color,
        'updatedAt': updatedAt ?? DateTime.now().toUtc().toIso8601String(),
      };

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'] as String,
      userId: (map['user_id'] as String?) ?? 'default_user',
      name: map['name'] as String,
      type: map['type'] as String,
      icon: map['icon'] as String,
      color: map['color'] as String,
      isSynced: (map['is_synced'] as int?) == 1,
      updatedAt: map['updated_at'] as String?,
    );
  }

  factory CategoryModel.fromFirestore(Map<String, dynamic> data, String docId) {
    return CategoryModel(
      id: (data['id'] as String?) ?? docId,
      userId: (data['userId'] as String?) ?? 'default_user',
      name: (data['name'] as String?) ?? '',
      type: (data['type'] as String?) ?? 'expense',
      icon: (data['icon'] as String?) ?? 'folder',
      color: (data['color'] as String?) ?? '#3B82F6',
      isSynced: true,
      updatedAt: data['updatedAt'] as String?,
    );
  }
}
