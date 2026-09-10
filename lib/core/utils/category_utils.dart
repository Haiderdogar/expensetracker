import 'package:flutter/material.dart';

import '../../models/category_model.dart';
import '../../models/subcategory_model.dart';
import '../../models/transaction_model.dart';

IconData categoryIconFromName(String name) {
  return switch (name) {
    'work' => Icons.work_outline,
    'laptop' => Icons.laptop_mac,
    'restaurant' => Icons.restaurant,
    'directions_car' => Icons.directions_car,
    'shopping_bag' => Icons.shopping_bag_outlined,
    'receipt' => Icons.receipt_long,
    'movie' => Icons.movie_outlined,
    'favorite' => Icons.favorite_border,
    _ => Icons.category_outlined,
  };
}

Color categoryColorFromHex(String hex) {
  final value = hex.replaceFirst('#', '');
  return Color(int.parse('FF$value', radix: 16));
}

const List<String> commonCategoryPriorityKeywords = [
  'food',
  'transport',
  'transportation',
  'bills',
  'bill',
  'housing',
  'house',
  'rent',
  'shopping',
  'groceries',
  'grocery',
  'dining',
  'utilities',
  'salary',
  'business',
  'entertainment',
  'health',
  'healthcare',
  'education',
  'general',
];

const List<String> commonSubcategoryPriorityKeywords = [
  'general',
  'groceries',
  'grocery',
  'restaurant',
  'dining',
  'food',
  'fuel',
  'gas',
  'petrol',
  'bus',
  'metro',
  'train',
  'taxi',
  'uber',
  'electricity',
  'water',
  'internet',
  'wifi',
  'phone',
  'rent',
  'maintenance',
  'clothing',
  'clothes',
  'coffee',
  'snacks',
];

List<CategoryModel> sortCategories(
  List<CategoryModel> categories,
  List<TransactionModel> transactions,
) {
  final usageCounts = <String, int>{};
  for (final tx in transactions) {
    usageCounts[tx.categoryId] = (usageCounts[tx.categoryId] ?? 0) + 1;
  }

  int score(CategoryModel c) {
    final count = usageCounts[c.id] ?? 0;
    final name = c.name.toLowerCase().trim();
    final idx = commonCategoryPriorityKeywords.indexWhere((k) => name.contains(k));
    int pts = count * 1000;
    if (idx != -1) {
      pts += (100 - idx);
    }
    return pts;
  }

  final sorted = List<CategoryModel>.from(categories);
  sorted.sort((a, b) => score(b).compareTo(score(a)));
  return sorted;
}

List<SubcategoryModel> sortSubcategories(
  List<SubcategoryModel> subcategories,
  String categoryId,
  List<TransactionModel> transactions,
) {
  final usageCounts = <String, int>{};
  for (final tx in transactions) {
    if (tx.categoryId == categoryId && tx.subcategory.isNotEmpty) {
      final key = tx.subcategory.toLowerCase().trim();
      usageCounts[key] = (usageCounts[key] ?? 0) + 1;
    }
  }

  int score(SubcategoryModel s) {
    final name = s.name.toLowerCase().trim();
    final count = usageCounts[name] ?? 0;
    final idx = commonSubcategoryPriorityKeywords.indexWhere((k) => name.contains(k));
    int pts = count * 1000;
    if (idx != -1) {
      pts += (100 - idx);
    }
    return pts;
  }

  final sorted = List<SubcategoryModel>.from(subcategories);
  sorted.sort((a, b) => score(b).compareTo(score(a)));
  return sorted;
}
