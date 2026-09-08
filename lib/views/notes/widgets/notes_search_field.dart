import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../notes_ui_providers.dart';

class NotesSearchField extends StatelessWidget {
  const NotesSearchField({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) => TextField(
        onChanged: (value) => ref.read(notesSearchQueryProvider.notifier).state = value,
        decoration: InputDecoration(
          hintText: 'Search notes',
          prefixIcon: const Icon(Icons.search_rounded),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        ),
      ),
    );
  }
}
