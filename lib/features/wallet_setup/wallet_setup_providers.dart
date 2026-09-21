import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'wallet_setup_providers.g.dart';

class OnboardingDraft {
  const OnboardingDraft({
    this.walletName = 'Main Wallet',
    this.currencySymbol = '\$',
    this.currencyCode = 'USD',
    this.isLoading = false,
  });

  final String walletName;
  final String currencySymbol;
  final String currencyCode;
  final bool isLoading;

  OnboardingDraft copyWith({
    String? walletName,
    String? currencySymbol,
    String? currencyCode,
    bool? isLoading,
  }) {
    return OnboardingDraft(
      walletName: walletName ?? this.walletName,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      currencyCode: currencyCode ?? this.currencyCode,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

@riverpod
class OnboardingDraftNotifier extends _$OnboardingDraftNotifier {
  @override
  OnboardingDraft build() => const OnboardingDraft();

  void setWalletName(String name) => state = state.copyWith(walletName: name);
  void setCurrency(String symbol, String code) =>
      state = state.copyWith(currencySymbol: symbol, currencyCode: code);
  void setLoading(bool loading) => state = state.copyWith(isLoading: loading);
}
