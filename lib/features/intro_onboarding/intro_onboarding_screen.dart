
import 'package:expensetracker/features/authentication/google/google_sign_in_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../providers/database_provider.dart';
import 'intro_providers.dart';

class IntroOnboardingScreen extends StatelessWidget {
  const IntroOnboardingScreen({super.key});

  static const List<_IntroPageData> pages = [
    _IntroPageData(
      imageAsset: 'assets/onboarding_screen_1.png',
      color: AppColors.primaryEmerald,
      step: '01 / 03',
      title: AppStrings.introTrackTitle,
      body: AppStrings.introTrackBody,
    ),
    _IntroPageData(
      imageAsset: 'assets/onboarding_screen_2.png',
      color: AppColors.incomeGreen,
      step: '02 / 03',
      title: AppStrings.introBudgetTitle,
      body: AppStrings.introBudgetBody,
    ),
    _IntroPageData(
      imageAsset: 'assets/onboarding_screen_3.png',
      color: AppColors.expenseRed,
      step: '03 / 03',
      title: AppStrings.introInsightsTitle,
      body: AppStrings.introInsightsBody,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _IntroPageView(),
            ),

            Padding(
              padding: EdgeInsets.fromLTRB(
                24,
                12,
                24,
                10,
              ),
              child: Column(
                children: [
                  _IntroPageIndicators(),

                  SizedBox(height: 28),

                  _IntroAdvanceButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// PAGE VIEW
// ============================================================

class _IntroPageView extends ConsumerWidget {
  const _IntroPageView();

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) {
    final pageController = ref.watch(
      introPageControllerProvider,
    );

    return PageView.builder(
      controller: pageController,

      itemCount: IntroOnboardingScreen.pages.length,

      onPageChanged: (index) {
        ref
            .read(
              introPageIndexProvider.notifier,
            )
            .setIndex(index);
      },

      itemBuilder: (
        context,
        index,
      ) {
        return _IntroPage(
          data: IntroOnboardingScreen.pages[index],
        );
      },
    );
  }
}

// ============================================================
// PAGE INDICATORS
// ============================================================

class _IntroPageIndicators extends ConsumerWidget {
  const _IntroPageIndicators();

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) {
    final pageIndex = ref.watch(
      introPageIndexProvider,
    );

    final currentPage =
        IntroOnboardingScreen.pages[pageIndex];

    final colorScheme =
        Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment:
          MainAxisAlignment.center,

      children: List.generate(
        IntroOnboardingScreen.pages.length,
        (index) {
          final isSelected =
              index == pageIndex;

          return AnimatedContainer(
            duration: const Duration(
              milliseconds: 180,
            ),

            margin:
                const EdgeInsets.symmetric(
              horizontal: 4,
            ),

            width: isSelected ? 24 : 8,

            height: 8,

            decoration: BoxDecoration(
              color: isSelected
                  ? currentPage.color
                  : colorScheme.outlineVariant,

              borderRadius:
                  BorderRadius.circular(4),
            ),
          );
        },
      ),
    );
  }
}

// ============================================================
// NEXT / CONTINUE BUTTON
// ============================================================

class _IntroAdvanceButton
    extends ConsumerWidget {
  const _IntroAdvanceButton();

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) {
    final pageIndex = ref.watch(
      introPageIndexProvider,
    );

    final isCompleting = ref.watch(
      introCompletingProvider,
    );

    final currentPage =
        IntroOnboardingScreen.pages[pageIndex];

    final isLastPage =
        pageIndex ==
        IntroOnboardingScreen.pages.length - 1;

    Future<void> advance() async {
  if (isCompleting) {
    return;
  }

  // Go to next onboarding page
  if (!isLastPage) {
    final controller = ref.read(
      introPageControllerProvider,
    );

    await controller.nextPage(
      duration: const Duration(
        milliseconds: 260,
      ),
      curve: Curves.easeOut,
    );

    return;
  }

  // Last onboarding page
  ref
      .read(
        introCompletingProvider.notifier,
      )
      .setCompleting(true);

  try {
    // Save onboarding completed
    await ref
        .read(secureStorageProvider)
        .setIntroOnboardingSeen();

    if (!context.mounted) {
      return;
    }

    // Navigate to Login
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const GoogleSignInScreen(),
      ),
    );
  } catch (error) {
    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Could not save onboarding progress: $error',
        ),
      ),
    );
  } finally {
    ref
        .read(
          introCompletingProvider.notifier,
        )
        .setCompleting(false);
  }
}

    return FilledButton(
      onPressed:
          isCompleting ? null : advance,

      style: FilledButton.styleFrom(
        backgroundColor:
            currentPage.color,

        minimumSize:
            const Size(
          double.infinity,
          52,
        ),

        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(14),
        ),
      ),

      child: isCompleting
          ? const SizedBox(
              width: 20,
              height: 20,

              child:
                  CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Text(
              isLastPage
                  ? AppStrings.continueLabel
                  : AppStrings.next,
            ),
    );
  }
}

// ============================================================
// INDIVIDUAL ONBOARDING PAGE
// ============================================================

class _IntroPage extends StatelessWidget {
  const _IntroPage({
    required this.data,
  });

  final _IntroPageData data;

  @override
  Widget build(
    BuildContext context,
  ) {
    final screenHeight =
        MediaQuery.sizeOf(context).height;

    final imageHeight =
        (screenHeight * 0.40)
            .clamp(
              300.0,
              380.0,
            )
            .toDouble();

    final theme =
        Theme.of(context);

    return SingleChildScrollView(
      padding:
          const EdgeInsets.fromLTRB(
        28,
        24,
        28,
        16,
      ),

      child: Column(
        mainAxisSize:
            MainAxisSize.min,

        crossAxisAlignment:
            CrossAxisAlignment.center,

        children: [
          // ----------------------------------------------------
          // STEP + SWIPE ICON
          // ----------------------------------------------------

          Row(
            children: [
              Text(
                data.step,

                style: theme
                    .textTheme
                    .labelLarge
                    ?.copyWith(
                  color: data.color,
                  fontWeight:
                      FontWeight.w700,
                ),
              ),

              const Spacer(),

              Icon(
                Icons.swipe_left_rounded,
                color: data.color,
              ),
            ],
          ),

          const SizedBox(
            height: 16,
          ),

          // ----------------------------------------------------
          // IMAGE
          // ----------------------------------------------------

          Image.asset(
            data.imageAsset,

            height: imageHeight,

            width:
                double.infinity,

            fit: BoxFit.contain,

            errorBuilder: (
              context,
              error,
              stackTrace,
            ) {
              return SizedBox(
                height: imageHeight,

                child: Center(
                  child: Icon(
                    Icons
                        .broken_image_outlined,

                    size: 72,

                    color:
                        data.color,
                  ),
                ),
              );
            },
          ),

          const SizedBox(
            height: 24,
          ),

          // ----------------------------------------------------
          // TITLE
          // ----------------------------------------------------

          Text(
            data.title,

            textAlign:
                TextAlign.center,

            style: theme
                .textTheme
                .headlineMedium
                ?.copyWith(
              fontSize: 30,
              height: 1.15,
              fontWeight:
                  FontWeight.w800,
              letterSpacing: -0.5,
              color: theme
                  .colorScheme
                  .onSurface,
            ),
          ),

          const SizedBox(
            height: 14,
          ),

          // ----------------------------------------------------
          // DESCRIPTION
          // ----------------------------------------------------

          Text(
            data.body,

            textAlign:
                TextAlign.center,

            style: theme
                .textTheme
                .titleMedium
                ?.copyWith(
              fontSize: 17,
              fontWeight:
                  FontWeight.w500,
              color: theme
                  .colorScheme
                  .onSurfaceVariant,
              height: 1.5,
            ),
          ),

          const SizedBox(
            height: 8,
          ),
        ],
      ),
    );
  }
}

// ============================================================
// ONBOARDING PAGE DATA
// ============================================================

class _IntroPageData {
  const _IntroPageData({
    required this.imageAsset,
    required this.color,
    required this.step,
    required this.title,
    required this.body,
  });

  final String imageAsset;
  final Color color;
  final String step;
  final String title;
  final String body;
}
