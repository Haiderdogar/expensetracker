import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../providers/auth_provider.dart';
import '../../providers/database_provider.dart';

class IntroOnboardingScreen extends ConsumerStatefulWidget {
  const IntroOnboardingScreen({super.key});

  @override
  ConsumerState<IntroOnboardingScreen> createState() =>
      _IntroOnboardingScreenState();
}

class _IntroOnboardingScreenState extends ConsumerState<IntroOnboardingScreen> {
  final PageController _pageController = PageController();
  var _pageIndex = 0;
  var _isCompleting = false;

  static const _pages = [
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
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _advance() async {
    if (_isCompleting) return;
    if (_pageIndex < _pages.length - 1) {
      await _pageController.nextPage(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
      );
      return;
    }

    setState(() => _isCompleting = true);
    try {
      await ref.read(secureStorageProvider).setIntroOnboardingSeen();
      ref.invalidate(introOnboardingSeenProvider);
    } finally {
      if (mounted) setState(() => _isCompleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final page = _pages[_pageIndex];
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) => setState(() => _pageIndex = index),
                itemBuilder: (context, index) => _IntroPage(data: _pages[index]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_pages.length, (index) {
                      final selected = index == _pageIndex;
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
                  ),
                  const SizedBox(height: 28),
                  FilledButton(
                    onPressed: _isCompleting ? null : _advance,
                    style: FilledButton.styleFrom(
                      backgroundColor: page.color,
                      minimumSize: const Size(double.infinity, 52),
                    ),
                    child: _isCompleting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            _pageIndex == _pages.length - 1
                                ? AppStrings.continueLabel
                                : AppStrings.next,
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
