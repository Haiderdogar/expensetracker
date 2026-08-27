import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_strings.dart';
import '../../providers/database_provider.dart';

class ProfileViewScreen extends ConsumerStatefulWidget {
  const ProfileViewScreen({super.key});

  @override
  ConsumerState<ProfileViewScreen> createState() => _ProfileViewScreenState();
}

class _ProfileViewScreenState extends ConsumerState<ProfileViewScreen> {
  String _name = '';
  String _email = '';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final db = ref.read(databaseHelperProvider);
    final name = await db.getSetting('profile_name');
    final email = await db.getSetting('profile_email');
    setState(() {
      _name = name ?? '';
      _email = email ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => Navigator.of(context).maybePop(),
              )
            : null,
        title: const Text(AppStrings.profile),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header with gradient background
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primary,
                    colorScheme.primary.withValues(alpha: 0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  // Avatar with shadow
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withValues(alpha: 0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 56,
                      backgroundColor: Colors.white24,
                      child: Text(
                        _name.isNotEmpty ? _name[0].toUpperCase() : 'U',
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Name
                  Text(
                    _name.isNotEmpty ? _name : 'User',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 8),
                  // Email
                  Text(
                    _email.isNotEmpty ? _email : 'No email set',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Profile Info Cards
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name Card
                  _buildInfoCard(
                    context,
                    icon: Icons.person_rounded,
                    label: 'Full Name',
                    value: _name.isNotEmpty ? _name : 'Not set',
                    accentColor: colorScheme.primary,
                  ),
                  const SizedBox(height: 12),

                  // Email Card
                  _buildInfoCard(
                    context,
                    icon: Icons.email_rounded,
                    label: 'Email Address',
                    value: _email.isNotEmpty ? _email : 'Not set',
                    accentColor: colorScheme.secondary,
                  ),
                  const SizedBox(height: 12),

                  // Status Card
                  _buildInfoCard(
                    context,
                    icon: Icons.verified_user_rounded,
                    label: 'Account Status',
                    value: 'Active',
                    accentColor: Colors.green,
                  ),
                  const SizedBox(height: 32),

                  // Edit Profile Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton.tonal(
                      onPressed: () async {
                        final result = await Navigator.of(context).push<bool>(
                          MaterialPageRoute(
                            builder: (_) => const ProfileEditScreen(),
                          ),
                        );
                        if (result == true) {
                          await _loadProfile();
                        }
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.edit_rounded, size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            'Edit Profile',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accentColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final db = ref.read(databaseHelperProvider);
    _nameCtrl.text = await db.getSetting('profile_name') ?? '';
    _emailCtrl.text = await db.getSetting('profile_email') ?? '';
    setState(() {});
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final db = ref.read(databaseHelperProvider);
    await db.setSetting('profile_name', _nameCtrl.text.trim());
    await db.setSetting('profile_email', _emailCtrl.text.trim());
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Please enter your name' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailCtrl,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Please enter email';
                  final value = v.trim();
                  if (!RegExp(r"^[^@\s]+@[^@\s]+\.[^@\s]+$").hasMatch(value)) return 'Enter a valid email';
                  return null;
                },
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(onPressed: _save, child: const Text('Save')),
              )
            ],
          ),
        ),
      ),
    );
  }
}
