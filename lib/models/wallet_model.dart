class WalletModel {
  const WalletModel({
    required this.id,
    required this.name,
    required this.balance,
  });

  final String id;
  final String name;
  final double balance;

  WalletModel copyWith({String? id, String? name, double? balance}) {
    return WalletModel(
      id: id ?? this.id,
      name: name ?? this.name,
      balance: balance ?? this.balance,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'balance': balance,
      };

  factory WalletModel.fromMap(Map<String, dynamic> map) {
    return WalletModel(
      id: map['id'] as String,
      name: map['name'] as String,
      balance: (map['balance'] as num).toDouble(),
    );
  }
}
