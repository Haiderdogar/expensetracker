import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/note_provider.dart';

class NotesRefreshButton extends StatelessWidget {
  const NotesRefreshButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) => IconButton(
        tooltip: 'Refresh notes',
        onPressed: () => ref.read(notesProvider.notifier).refresh(),
        icon: const Icon(Icons.refresh_rounded),
      ),
    );
  }
}
