import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';

class GoogleSignInScreen extends ConsumerStatefulWidget {
  const GoogleSignInScreen({super.key});

  @override
  ConsumerState<GoogleSignInScreen> createState() => _GoogleSignInScreenState();
}

class _GoogleSignInScreenState extends ConsumerState<GoogleSignInScreen> {
  bool _attemptStarted = false;
  GoogleSignInResult? _result;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startSignIn());
  }

  Future<void> _startSignIn() async {
    if (!mounted || _attemptStarted) return;
    _attemptStarted = true;
    setState(() => _result = null);
    final result = await ref
        .read(authControllerProvider.notifier)
        .signInWithGoogle();
    if (!mounted) return;
    setState(() {
      _result = result;
      _attemptStarted = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colors = theme.colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? const [
                    Color(0xFF071A15),
                    Color(0xFF0B211B),
                    Color(0xFF0B1220),
                  ]
                : const [
                    Color(0xFFEAFBF5),
                    Color(0xFFF8FAFC),
                    Color(0xFFF0F6FF),
                  ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 30),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 58,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 460),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Large app icon
                          Container(
                            width: 150,
                            height: 150,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.07)
                                  : Colors.white.withValues(alpha: 0.88),
                              borderRadius: BorderRadius.circular(38),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.10)
                                    : Colors.white,
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primaryEmerald.withValues(
                                    alpha: 0.22,
                                  ),
                                  blurRadius: 35,
                                  spreadRadius: 2,
                                  offset: const Offset(0, 15),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(28),
                              child: Image.asset(
                                'assets/icon.png',
                                fit: BoxFit.contain,
                                semanticLabel: 'Expense Tracker',
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),

                          // App name
                          Text(
                            'Expense Tracker',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.8,
                            ),
                          ),
                          const SizedBox(height: 10),

                          Text(
                            'Manage your money with clarity and confidence.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              height: 1.5,
                              color: colors.onSurface.withValues(alpha: 0.62),
                            ),
                          ),
                          const SizedBox(height: 34),

                          // App features
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.055)
                                  : Colors.white.withValues(alpha: 0.80),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.09)
                                    : Colors.white.withValues(alpha: 0.95),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(
                                    alpha: isDark ? 0.14 : 0.045,
                                  ),
                                  blurRadius: 28,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                _FeatureRow(
                                  icon: Icons.bolt_rounded,
                                  color: const Color(0xFFF59E0B),
                                  title: 'Works Offline',
                                  subtitle:
                                      'Track expenses instantly with local storage',
                                ),
                                _FeatureDivider(isDark: isDark),
                                _FeatureRow(
                                  icon: Icons.sync_rounded,
                                  color: AppColors.primaryEmerald,
                                  title: 'Sync When Online',
                                  subtitle:
                                      'Keep your data synchronized when connected',
                                ),
                                _FeatureDivider(isDark: isDark),
                                _FeatureRow(
                                  icon: Icons.lock_outline_rounded,
                                  color: const Color(0xFF3B82F6),
                                  title: 'Private & Secure',
                                  subtitle:
                                      'Your personal financial data stays protected',
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 28),

                          _GoogleSignInButton(
                            onRetry: _startSignIn,
                            result: _result,
                          ),
                          if (_result != null &&
                              _result != GoogleSignInResult.success) ...[
                            const SizedBox(height: 10),
                            Text(
                              _result == GoogleSignInResult.cancelled
                                  ? 'Sign-in was cancelled.'
                                  : _result ==
                                        GoogleSignInResult.configurationError
                                  ? 'Google Sign-In is not configured for this app.'
                                  : 'Sign-in failed. Check your connection and try again.',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colors.error,
                              ),
                            ),
                          ],

                          const SizedBox(height: 22),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.shield_outlined,
                                size: 15,
                                color: colors.onSurface.withValues(alpha: 0.45),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Your data is handled securely',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color:
                                      colors.onSurface.withValues(alpha: 0.48),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _GoogleSignInButton extends ConsumerWidget {
  const _GoogleSignInButton({
    required this.onRetry,
    required this.result,
  });

  final VoidCallback onRetry;
  final GoogleSignInResult? result;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryEmerald,
          foregroundColor: Colors.white,
          disabledBackgroundColor:
              AppColors.primaryEmerald.withValues(alpha: 0.55),
          disabledForegroundColor: Colors.white.withValues(alpha: 0.85),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17),
          ),
        ),
        onPressed: isLoading ? null : onRetry,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: isLoading
              ? const SizedBox(
                  key: ValueKey('loading'),
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : Row(
                  key: const ValueKey('login'),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.login_rounded,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 11),
                    Text(
                      result == null
                          ? 'Continue with Google'
                          : 'Try Google Sign-In again',
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _FeatureDivider extends StatelessWidget {
  const _FeatureDivider({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 52,
        top: 14,
        bottom: 14,
      ),
      child: Divider(
        height: 1,
        thickness: 1,
        color: isDark
            ? Colors.white.withValues(alpha: 0.07)
            : Colors.black.withValues(alpha: 0.055),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: color.withValues(alpha: 0.08),
            ),
          ),
          child: Icon(
            icon,
            color: color,
            size: 21,
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.1,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  height: 1.35,
                  color: colors.onSurface.withValues(alpha: 0.58),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
