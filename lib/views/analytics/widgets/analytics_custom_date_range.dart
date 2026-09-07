import 'package:flutter/material.dart';

class AnalyticsCustomDateRange extends StatelessWidget {
  const AnalyticsCustomDateRange({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.onStartDateTap,
    required this.onEndDateTap,
  });

  final DateTime startDate;
  final DateTime endDate;
  final VoidCallback onStartDateTap;
  final VoidCallback onEndDateTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _DateField(label: 'Start Date', date: startDate, onTap: onStartDateTap)),
        const SizedBox(width: 12),
        Expanded(child: _DateField(label: 'End Date', date: endDate, onTap: onEndDateTap)),
      ],
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({required this.label, required this.date, required this.onTap});

  final String label;
  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 4),
            Text('${date.day}/${date.month}/${date.year}', style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
