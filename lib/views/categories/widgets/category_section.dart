import 'package:flutter/material.dart';
import '../../../models/category_model.dart';
import 'category_tile.dart';

class CategorySection extends StatelessWidget {
  const CategorySection({super.key, required this.title, required this.icon, required this.categories});
  final String title;
  final IconData icon;
  final List<CategoryModel> categories;
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [Icon(icon, size: 20), const SizedBox(width: 8), Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800))]),
    const SizedBox(height: 10),
    if (categories.isEmpty) Text('No $title categories yet.') else ...categories.map((category) => CategoryTile(category: category)),
  ]);
}
