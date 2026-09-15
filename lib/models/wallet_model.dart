class WalletModel {
  const WalletModel({
    required this.id,
    this.userId = 'default_user',
    required this.name,
    required this.balance,
    this.isSynced = false,
    this.updatedAt,
  });

  final String id;
  final String userId;
  final String name;
  final double balance;
  final bool isSynced;
  final String? updatedAt;

  WalletModel copyWith({
    String? id,
    String? userId,
    String? name,
    double? balance,
    bool? isSynced,
    String? updatedAt,
  }) {
    return WalletModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      balance: balance ?? this.balance,
      isSynced: isSynced ?? this.isSynced,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'name': name,
        'balance': balance,
        'is_synced': isSynced ? 1 : 0,
        'updated_at': updatedAt ?? DateTime.now().toUtc().toIso8601String(),
      };

  Map<String, dynamic> toFirestore() => {
        'id': id,
        'userId': userId,
        'name': name,
        'balance': balance,
        'updatedAt': updatedAt ?? DateTime.now().toUtc().toIso8601String(),
      };

  factory WalletModel.fromMap(Map<String, dynamic> map) {
    return WalletModel(
      id: map['id'] as String,
      userId: (map['user_id'] as String?) ?? 'default_user',
      name: map['name'] as String,
      balance: (map['balance'] as num).toDouble(),
      isSynced: (map['is_synced'] as int?) == 1,
      updatedAt: map['updated_at'] as String?,
    );
  }

  factory WalletModel.fromFirestore(Map<String, dynamic> data, String docId) {
    return WalletModel(
      id: (data['id'] as String?) ?? docId,
      userId: (data['userId'] as String?) ?? 'default_user',
      name: (data['name'] as String?) ?? 'Main Wallet',
      balance: ((data['balance'] as num?) ?? 0).toDouble(),
      isSynced: true,
      updatedAt: data['updatedAt'] as String?,
    );
  }
}
