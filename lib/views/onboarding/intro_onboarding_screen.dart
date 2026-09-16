import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../providers/auth_provider.dart';
import '../../providers/database_provider.dart';
import 'intro_providers.dart';

class IntroOnboardingScreen extends StatelessWidget {
  const IntroOnboardingScreen({super.key});

  static const pages = [
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
            Expanded(child: _IntroPageView()),
            Padding(
              padding: EdgeInsets.fromLTRB(24, 12, 24, 32),
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

class _IntroPageView extends ConsumerWidget {
  const _IntroPageView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(introPageControllerProvider);

    return PageView.builder(
      controller: controller,
      itemCount: IntroOnboardingScreen.pages.length,
      onPageChanged: (index) =>
          ref.read(introPageIndexProvider.notifier).setIndex(index),
      itemBuilder: (context, index) =>
          _IntroPage(data: IntroOnboardingScreen.pages[index]),
    );
  }
}

class _IntroPageIndicators extends ConsumerWidget {
  const _IntroPageIndicators();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pageIndex = ref.watch(introPageIndexProvider);
    final page = IntroOnboardingScreen.pages[pageIndex];
    final colors = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(IntroOnboardingScreen.pages.length, (index) {
        final selected = index == pageIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: selected ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: selected ? page.color : colors.outlineVariant,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

class _IntroAdvanceButton extends ConsumerWidget {
  const _IntroAdvanceButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pageIndex = ref.watch(introPageIndexProvider);
    final isCompleting = ref.watch(introCompletingProvider);
    final page = IntroOnboardingScreen.pages[pageIndex];

    Future<void> advance() async {
      if (isCompleting) return;
      if (pageIndex < IntroOnboardingScreen.pages.length - 1) {
        final controller = ref.read(introPageControllerProvider);
        await controller.nextPage(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOut,
        );
        return;
      }

      ref.read(introCompletingProvider.notifier).setCompleting(true);
      try {
        await ref.read(secureStorageProvider).setIntroOnboardingSeen();
        ref.invalidate(introOnboardingSeenProvider);
      } catch (error) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not save onboarding progress: $error')),
          );
        }
      } finally {
        ref.read(introCompletingProvider.notifier).setCompleting(false);
      }
    }

    return FilledButton(
      onPressed: isCompleting ? null : advance,
      style: FilledButton.styleFrom(
        backgroundColor: page.color,
        minimumSize: const Size(double.infinity, 52),
      ),
      child: isCompleting
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Text(
              pageIndex == IntroOnboardingScreen.pages.length - 1
                  ? AppStrings.continueLabel
                  : AppStrings.next,
            ),
    );
  }
}

class _IntroPage extends StatelessWidget {
  const _IntroPage({required this.data});

  final _IntroPageData data;

  @override
  Widget build(BuildContext context) {
    final imageHeight =
        (MediaQuery.sizeOf(context).height * 0.40)
            .clamp(300.0, 380.0)
            .toDouble();
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            children: [
              Text(
                data.step,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: data.color,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Icon(Icons.swipe_left_rounded, color: data.color),
            ],
          ),
          const SizedBox(height: 16),
          Image.asset(
            data.imageAsset,
            height: imageHeight,
            width: double.infinity,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Icon(
              Icons.broken_image_outlined,
              size: 72,
              color: data.color,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontSize: 30,
              height: 1.15,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            data.body,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontSize: 17,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

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
