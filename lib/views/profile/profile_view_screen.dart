import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_strings.dart';
import '../../core/database/database_tables.dart';
import '../../providers/database_provider.dart';
import '../../providers/wallet_provider.dart';

class ProfileViewScreen extends ConsumerStatefulWidget {
  const ProfileViewScreen({super.key});

  @override
  ConsumerState<ProfileViewScreen> createState() => _ProfileViewScreenState();
}

class _ProfileViewScreenState extends ConsumerState<ProfileViewScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _walletController = TextEditingController();
  String _savedName = '';
  String _savedEmail = '';
  String _savedWalletName = '';
  String? _walletId;
  bool _isEditing = false;
  bool _isLoading = true;

  bool get _hasChanges =>
      _nameController.text.trim() != _savedName ||
      _emailController.text.trim() != _savedEmail ||
      _walletController.text.trim() != _savedWalletName;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_onFieldChanged);
    _emailController.addListener(_onFieldChanged);
    _walletController.addListener(_onFieldChanged);
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final db = ref.read(databaseHelperProvider);
    final values = await Future.wait<String?>([
      db.getSetting('profile_name'),
      db.getSetting('profile_email'),
    ]);
    final wallets = await ref.read(walletsProvider.future);
    if (!mounted) return;
    _savedName = values[0] ?? '';
    _savedEmail = values[1] ?? '';
    final selectedId = ref.read(selectedWalletIdProvider);
    final wallet = wallets.where((item) => item.id == selectedId).isNotEmpty
        ? wallets.firstWhere((item) => item.id == selectedId)
        : (wallets.isNotEmpty ? wallets.first : null);
    _walletId = wallet?.id;
    _savedWalletName = wallet?.name ?? '';
    _nameController.text = _savedName;
    _emailController.text = _savedEmail;
    _walletController.text = _savedWalletName;
    setState(() => _isLoading = false);
  }

  void _onFieldChanged() {
    if (mounted) setState(() {});
  }

  void _startEditing() => setState(() => _isEditing = true);

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    final db = ref.read(databaseHelperProvider);
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final walletName = _walletController.text.trim();
    await db.setSetting('profile_name', name);
    await db.setSetting('profile_email', email);
    if (_walletId != null) {
      final database = await ref.read(databaseProvider.future);
      await database.update(
        DatabaseTables.wallets,
        {'name': walletName},
        where: 'id = ?',
        whereArgs: [_walletId],
      );
      ref.invalidate(walletsProvider);
    }
    if (!mounted) return;
    setState(() {
      _savedName = name;
      _savedEmail = email;
      _savedWalletName = walletName;
      _isEditing = false;
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Profile saved')));
  }

  @override
  void dispose() {
    _nameController
      ..removeListener(_onFieldChanged)
      ..dispose();
    _emailController
      ..removeListener(_onFieldChanged)
      ..dispose();
    _walletController
      ..removeListener(_onFieldChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final initial = _nameController.text.trim().isNotEmpty
        ? _nameController.text.trim()[0].toUpperCase()
        : 'U';

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.profile)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 42,
                      backgroundColor: colorScheme.primary,
                      child: Text(
                        initial,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _nameController.text.trim().isEmpty
                          ? 'Your profile'
                          : _nameController.text.trim(),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 28),
                    TextFormField(
                      controller: _nameController,
                      enabled: _isEditing,
                      decoration: const InputDecoration(
                        labelText: 'Full name',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                      validator: (_) => null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _emailController,
                      enabled: _isEditing,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email address',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return null;
                        if (!RegExp(
                          r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                        ).hasMatch(value.trim())) {
                          return 'Enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _walletController,
                      enabled: _isEditing && _walletId != null,
                      decoration: const InputDecoration(
                        labelText: 'Wallet name',
                        prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                      ),
                      validator: (_) => null,
                    ),
                    if (!_isEditing) ...[
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.tonalIcon(
                          onPressed: _startEditing,
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('Edit profile'),
                        ),
                      ),
                    ],
                    if (_isEditing && _hasChanges) ...[
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _saveProfile,
                          icon: const Icon(Icons.check_rounded),
                          label: const Text('Save changes'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}
