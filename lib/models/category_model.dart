class CategoryModel {
  static String builtInId(String userId, String type, String name) {
    final key = name.toLowerCase().replaceAll(RegExp('[^a-z0-9]+'), '_');
    return 'builtin_${userId}_${type}_$key';
  }

  const CategoryModel({
    required this.id,
    this.userId = '',
    this.walletId = '',
    required this.name,
    required this.type,
    required this.icon,
    required this.color,
    this.isSynced = false,
    this.isBuiltIn = false,
    this.isHidden = false,
    this.isArchived = false,
    this.updatedAt,
  });

  final String id;
  final String userId;
  final String walletId;
  final String name;
  final String type;
  final String icon;
  final String color;
  final bool isSynced;
  final bool isBuiltIn;
  final bool isHidden;
  final bool isArchived;
  final String? updatedAt;

  bool get isIncome => type == 'income';
  bool get isExpense => type == 'expense';

  CategoryModel copyWith({
    String? id,
    String? userId,
    String? walletId,
    String? name,
    String? type,
    String? icon,
    String? color,
    bool? isSynced,
    bool? isBuiltIn,
    bool? isHidden,
    bool? isArchived,
    String? updatedAt,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      walletId: walletId ?? this.walletId,
      name: name ?? this.name,
      type: type ?? this.type,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isSynced: isSynced ?? this.isSynced,
      isBuiltIn: isBuiltIn ?? this.isBuiltIn,
      isHidden: isHidden ?? this.isHidden,
      isArchived: isArchived ?? this.isArchived,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'wallet_id': walletId,
        'name': name,
        'type': type,
        'icon': icon,
        'color': color,
        'is_synced': isSynced ? 1 : 0,
        'is_builtin': isBuiltIn ? 1 : 0,
        'is_hidden': isHidden ? 1 : 0,
        'is_archived': isArchived ? 1 : 0,
        'updated_at': updatedAt ?? DateTime.now().toUtc().toIso8601String(),
      };

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'type': type,
        'icon': icon,
        'color': color,
        'isArchived': isArchived,
        'updatedAt': updatedAt ?? DateTime.now().toUtc().toIso8601String(),
      };

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'] as String,
      userId: (map['user_id'] as String?) ?? '',
      walletId: (map['wallet_id'] as String?) ?? '',
      name: map['name'] as String,
      type: map['type'] as String,
      icon: map['icon'] as String,
      color: map['color'] as String,
      isSynced: (map['is_synced'] as int?) == 1,
      isBuiltIn: (map['is_builtin'] as int?) == 1,
      isHidden: (map['is_hidden'] as int?) == 1,
      isArchived: (map['is_archived'] as int?) == 1,
      updatedAt: map['updated_at'] as String?,
    );
  }

  factory CategoryModel.fromFirestore(Map<String, dynamic> data, String docId) {
    return CategoryModel(
      id: docId,
      userId: '',
      walletId: '',
      name: (data['name'] as String?) ?? '',
      type: (data['type'] as String?) ?? 'expense',
      icon: (data['icon'] as String?) ?? 'folder',
      color: (data['color'] as String?) ?? '#3B82F6',
      isSynced: true,
      isArchived: data['isArchived'] == true,
      updatedAt: data['updatedAt'] as String?,
    );
  }
}
