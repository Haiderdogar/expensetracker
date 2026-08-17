import 'package:flutter/material.dart';

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
