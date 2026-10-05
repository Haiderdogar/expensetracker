import 'package:flutter/material.dart';

class BudgetsAddButton extends StatelessWidget {
  const BudgetsAddButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: 'fab_budgets',
      onPressed: onPressed,
      child: const Icon(Icons.add),
    );
  }
}
