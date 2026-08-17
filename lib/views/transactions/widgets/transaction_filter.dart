import 'package:flutter/material.dart';

class TransactionFilter extends StatelessWidget {
  const TransactionFilter({
    super.key,
    required this.selectedType,
    required this.onTypeChanged,
    required this.onSearchChanged,
  });

  final String? selectedType;
  final ValueChanged<String?> onTypeChanged;
  final ValueChanged<String> onSearchChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          onChanged: onSearchChanged,
          decoration: const InputDecoration(
            hintText: 'Search transactions...',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              FilterChip(
                label: const Text('All'),
                selected: selectedType == null,
                onSelected: (_) => onTypeChanged(null),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('Income'),
                selected: selectedType == 'income',
                onSelected: (_) => onTypeChanged('income'),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('Expense'),
                selected: selectedType == 'expense',
                onSelected: (_) => onTypeChanged('expense'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
