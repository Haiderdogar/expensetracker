import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

import '../../../core/constants/app_colors.dart';
import '../session/auth_provider.dart';

class GoogleSignInScreen extends StatelessWidget {
  const GoogleSignInScreen({super.key});

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

                          /*
                           * Only the login button is reactive.
                           */
                          const _GoogleSignInButton(),

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
                                  color: colors.onSurface.withValues(
                                    alpha: 0.48,
                                  ),
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

/*
 * Only this widget manages the sign-in interaction.
 *
 * The complete GoogleSignInScreen does not rebuild when authentication
 * state changes.
 */
class _GoogleSignInButton extends ConsumerStatefulWidget {
  const _GoogleSignInButton();

  @override
  ConsumerState<_GoogleSignInButton> createState() =>
      _GoogleSignInButtonState();
}

class _GoogleSignInButtonState
    extends ConsumerState<_GoogleSignInButton> {
  bool _isSigningIn = false;

  @override
  Widget build(BuildContext context) {
    final isLoading = _isSigningIn;

    Future<void> handleGoogleSignIn() async {
      if (_isSigningIn) {
        return;
      }

      setState(() {
        _isSigningIn = true;
      });

      try {
        /*
         * First check REAL internet access.
         *
         * connectivity_plus only tells us whether an interface such
         * as Wi-Fi/mobile is available. It does not guarantee actual
         * internet access.
         */
        final hasInternet =
            await InternetConnection().hasInternetAccess;

        if (!hasInternet) {
          if (!context.mounted) {
            return;
          }

          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              const SnackBar(
                content: Text(
                  'No internet connection. Please connect to Wi-Fi or mobile data and try again.',
                ),
                behavior: SnackBarBehavior.floating,
              ),
            );

          return;
        }

        /*
         * Start Google authentication.
         *
         * The native Google account chooser will appear here.
         */
        final result = await ref
            .read(authControllerProvider.notifier)
            .signInWithGoogle();

        if (!context.mounted) {
          return;
        }

        /*
         * Success.
         *
         * AuthController has already:
         *
         * 1. Authenticated Firebase
         * 2. Created/initialized the local user
         * 3. Saved the Google profile
         * 4. Saved the local login session
         * 5. Changed AuthStatus to authenticated
         *
         * AppBootstrap will now move to _PostLoginFlow.
         */
        if (result == GoogleSignInResult.success) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              const SnackBar(
                content: Text('Google Sign-In successful.'),
                behavior: SnackBarBehavior.floating,
                duration: Duration(milliseconds: 900),
              ),
            );

          return;
        }

        String message;

        switch (result) {
          case GoogleSignInResult.cancelled:
            message = 'Google Sign-In was cancelled.';

          case GoogleSignInResult.configurationError:
            message =
                'Google Sign-In configuration error. Please check your Firebase and OAuth configuration.';

          case GoogleSignInResult.noInternet:
            message = 'No internet connection. Please check your network.';

          case GoogleSignInResult.failed:
            message =
                ref.read(authControllerProvider.notifier).lastGoogleSignInError ??
                'Google Sign-In failed. Please try again.';

          case GoogleSignInResult.success:
            message = 'Google Sign-In successful.';
        }

        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(message),
              behavior: SnackBarBehavior.floating,
            ),
          );
      } catch (error) {
        if (!context.mounted) {
          return;
        }

        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                'Unable to start Google Sign-In. Please try again. ($error)',
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
      } finally {
        if (mounted) {
          setState(() {
            _isSigningIn = false;
          });
        }
      }
    }

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryEmerald,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.primaryEmerald.withValues(
            alpha: 0.55,
          ),
          disabledForegroundColor: Colors.white.withValues(alpha: 0.85),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17),
          ),
        ),
        onPressed: isLoading ? null : handleGoogleSignIn,
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
              : const Row(
                  key: ValueKey('login'),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.account_circle_rounded, size: 25),
                    SizedBox(width: 11),
                    Text(
                      'Continue with Google',
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
      padding: const EdgeInsets.only(left: 52, top: 14, bottom: 14),
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
            border: Border.all(color: color.withValues(alpha: 0.08)),
          ),
          child: Icon(icon, color: color, size: 21),
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
