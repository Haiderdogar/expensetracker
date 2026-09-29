import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../profile_draft_provider.dart';
import 'profile_actions.dart';
import 'profile_form.dart';
import 'profile_header.dart';

class ProfileBody extends ConsumerWidget {
  const ProfileBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(profileDraftProvider);
    if (!draft.isInitialized) {
      WidgetsBinding.instance.addPostFrameCallback((_) => loadProfile(ref));
    }
    if (draft.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding = constraints.maxWidth > 600 ? 32.0 : 18.0;
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            12,
            horizontalPadding,
            32,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ProfileHeader(draft: draft),
                  const SizedBox(height: 22),
                  ProfileForm(draft: draft),
                  const SizedBox(height: 18),
                  ProfileActions(draft: draft),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
