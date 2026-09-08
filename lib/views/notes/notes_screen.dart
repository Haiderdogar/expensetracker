import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import 'widgets/notes_add_button.dart';
import 'widgets/notes_list.dart';
import 'widgets/notes_refresh_button.dart';
import 'widgets/notes_search_field.dart';

class NotesScreen extends StatelessWidget {
  const NotesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => Navigator.of(context).maybePop(),
              )
            : null,
        title: const Text(AppStrings.notes),
        actions: const [NotesRefreshButton()],
      ),
      floatingActionButton: const NotesAddButton(),
      body: const Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: NotesSearchField(),
          ),
          SizedBox(height: 24),
          Expanded(child: NotesList()),
        ],
      ),
    );
  }
}
