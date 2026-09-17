class NoteModel {
  const NoteModel({
    required this.id,
    this.userId = 'default_user',
    this.walletId = '',
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.isSynced = false,
  });

  final String id;
  final String userId;
  final String walletId;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSynced;

  NoteModel copyWith({
    String? id,
    String? userId,
    String? walletId,
    String? title,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
  }) {
    return NoteModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      walletId: walletId ?? this.walletId,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'wallet_id': walletId,
        'title': title,
        'content': content,
        'created_at': createdAt.toUtc().toIso8601String(),
        'updated_at': updatedAt.toUtc().toIso8601String(),
        'is_synced': isSynced ? 1 : 0,
      };

  Map<String, dynamic> toFirestore() => {
        'id': id,
        'userId': userId,
        'walletId': walletId,
        'title': title,
        'content': content,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'updatedAt': updatedAt.toUtc().toIso8601String(),
      };

  factory NoteModel.fromMap(Map<String, dynamic> map) => NoteModel(
        id: map['id'] as String,
        userId: (map['user_id'] as String?) ?? 'default_user',
        walletId: (map['wallet_id'] as String?) ?? '',
        title: map['title'] as String,
        content: map['content'] as String,
        createdAt: DateTime.parse(map['created_at'] as String),
        updatedAt: DateTime.parse(map['updated_at'] as String),
        isSynced: (map['is_synced'] as int?) == 1,
      );

  factory NoteModel.fromFirestore(Map<String, dynamic> data, String docId) =>
      NoteModel(
        id: (data['id'] as String?) ?? docId,
        userId: (data['userId'] as String?) ?? 'default_user',
         walletId: (data['walletId'] as String?) ?? '',
        title: (data['title'] as String?) ?? '',
        content: (data['content'] as String?) ?? '',
        createdAt: DateTime.tryParse(data['createdAt'] as String? ?? '') ??
            DateTime.now(),
        updatedAt: DateTime.tryParse(data['updatedAt'] as String? ?? '') ??
            DateTime.now(),
        isSynced: true,
      );
}
