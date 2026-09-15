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
      icon: Icons.receipt_long_rounded,
      color: AppColors.primaryEmerald,
      step: '01 / 03',
      title: AppStrings.introTrackTitle,
      body: AppStrings.introTrackBody,
      highlights: [
        AppStrings.introTrackPointOne,
        AppStrings.introTrackPointTwo,
      ],
    ),
    _IntroPageData(
      icon: Icons.account_balance_wallet_rounded,
      color: AppColors.incomeGreen,
      step: '02 / 03',
      title: AppStrings.introBudgetTitle,
      body: AppStrings.introBudgetBody,
      highlights: [
        AppStrings.introBudgetPointOne,
        AppStrings.introBudgetPointTwo,
      ],
    ),
    _IntroPageData(
      icon: Icons.insights_rounded,
      color: AppColors.expenseRed,
      step: '03 / 03',
      title: AppStrings.introInsightsTitle,
      body: AppStrings.introInsightsBody,
      highlights: [
        AppStrings.introInsightsPointOne,
        AppStrings.introInsightsPointTwo,
      ],
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
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
          const SizedBox(height: 24),
          Center(child: _IntroIllustration(data: data)),
          const SizedBox(height: 28),
          Text(
            data.title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            data.body,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 26),
          for (final highlight in data.highlights) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.check_circle_rounded, color: data.color, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    highlight,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _IntroIllustration extends StatelessWidget {
  const _IntroIllustration({required this.data});

  final _IntroPageData data;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      height: 190,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 152,
            height: 152,
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: data.color.withValues(alpha: 0.28),
                width: 2,
              ),
            ),
            child: Icon(data.icon, size: 72, color: data.color),
          ),
          Positioned(
            left: 10,
            bottom: 18,
            child: _MetricMark(color: data.color, icon: Icons.add_rounded),
          ),
          Positioned(
            right: 10,
            top: 18,
            child: _MetricMark(
              color: data.color,
              icon: Icons.check_rounded,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricMark extends StatelessWidget {
  const _MetricMark({required this.color, required this.icon});

  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}

class _IntroPageData {
  const _IntroPageData({
    required this.icon,
    required this.color,
    required this.step,
    required this.title,
    required this.body,
    required this.highlights,
  });

  final IconData icon;
  final Color color;
  final String step;
  final String title;
  final String body;
  final List<String> highlights;
}
