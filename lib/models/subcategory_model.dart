class SubcategoryModel {
  const SubcategoryModel({
    required this.id,
    required this.categoryId,
    required this.name,
  });

  final String id;
  final String categoryId;
  final String name;

  Map<String, dynamic> toMap() => {
        'id': id,
        'category_id': categoryId,
        'name': name,
      };

  factory SubcategoryModel.fromMap(Map<String, dynamic> map) {
    return SubcategoryModel(
      id: map['id'] as String,
      categoryId: map['category_id'] as String,
      name: map['name'] as String,
    );
  }
}
