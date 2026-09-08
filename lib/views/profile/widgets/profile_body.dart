import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../profile_draft_provider.dart';
import 'profile_actions.dart';
import 'profile_form.dart';
import 'profile_header.dart';

class ProfileBody extends StatelessWidget {
  const ProfileBody({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final draft = ref.watch(profileDraftProvider);
        if (!draft.isInitialized) {
          WidgetsBinding.instance.addPostFrameCallback((_) => loadProfile(ref));
        }
        if (draft.isLoading) return const Center(child: CircularProgressIndicator());
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
          child: Column(
            children: [
              ProfileHeader(draft: draft),
              const SizedBox(height: 28),
              ProfileForm(draft: draft),
              const SizedBox(height: 24),
              ProfileActions(draft: draft),
            ],
          ),
        );
      },
    );
  }
}
