import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ads/admob_service.dart';
import 'settings_section.dart';
import 'settings_tile.dart';

class SettingsAdPrivacySection extends ConsumerWidget {
  const SettingsAdPrivacySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.watch(admobServiceProvider);
    return ListenableBuilder(
      listenable: service,
      builder: (context, _) {
        if (!service.privacyOptionsRequired) return const SizedBox.shrink();

        return SettingsSection(
          title: 'Privacy',
          child: SettingsTile(
            icon: Icons.privacy_tip_outlined,
            title: 'Ad privacy choices',
            subtitle: 'Manage your advertising consent.',
            onTap: service.isShowingPrivacyOptions
                ? null
                : () => unawaited(service.showPrivacyOptions()),
            trailing: service.isShowingPrivacyOptions
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : null,
          ),
        );
      },
    );
  }
}
