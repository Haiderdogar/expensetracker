import 'package:flutter/material.dart';

import '../../models/category_model.dart';
import '../../models/transaction_model.dart';

IconData categoryIconFromName(String name) {
  return switch (name) {
    'work' => Icons.work_outline,
    'laptop' => Icons.laptop_mac,
    'trending_up' => Icons.trending_up_rounded,
    'home' => Icons.home_outlined,
    'store' => Icons.storefront_outlined,
    'restaurant' => Icons.restaurant,
    'directions_car' => Icons.directions_car,
    'shopping_bag' => Icons.shopping_bag_outlined,
    'receipt' => Icons.receipt_long,
    'movie' => Icons.movie_outlined,
    'favorite' => Icons.favorite_border,
    'school' => Icons.school_outlined,
    'shield' => Icons.shield_outlined,
    'flight' => Icons.flight_outlined,
    'spa' => Icons.spa_outlined,
    'account_balance' => Icons.account_balance_outlined,
    'percent' => Icons.percent_rounded,
    'savings' => Icons.savings_outlined,
    'card_giftcard' => Icons.card_giftcard,
    'currency_exchange' => Icons.currency_exchange_rounded,
    'payments' => Icons.payments_outlined,
    'groceries' => Icons.local_grocery_store_outlined,
    'utilities' => Icons.electrical_services_outlined,
    'clothing' => Icons.checkroom_outlined,
    'car_repair' => Icons.car_repair_outlined,
    'pets' => Icons.pets_outlined,
    'subscriptions' => Icons.subscriptions_outlined,
    'tax' => Icons.request_quote_outlined,
    'childcare' => Icons.child_care_outlined,
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
