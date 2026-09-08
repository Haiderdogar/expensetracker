import 'package:flutter/material.dart';

class BudgetsAddButton extends StatelessWidget {
  const BudgetsAddButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 90),
      child: FloatingActionButton(
        heroTag: 'fab_budgets',
        onPressed: onPressed,
        child: const Icon(Icons.add),
      ),
    );
  }
}
